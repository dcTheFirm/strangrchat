"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const express_1 = __importDefault(require("express"));
const http_1 = __importDefault(require("http"));
const cors_1 = __importDefault(require("cors"));
const crypto_1 = require("crypto");
const socket_io_1 = require("socket.io");
const redis_1 = require("./config/redis");
const prisma_1 = require("./config/prisma");
const auth_1 = require("./utils/auth");
const MatchmakingService_1 = require("./services/MatchmakingService");
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});
const PORT = process.env.PORT || 3000;
const AUTH_RATE_WINDOW_SECONDS = 600;
const AUTH_RATE_IP_LIMIT = 60;
const AUTH_RATE_DEVICE_LIMIT = 10;
app.use((0, cors_1.default)());
app.use(express_1.default.json({ limit: '16kb' }));
const consumeAnonymousAuthRate = async (ipAddress, deviceId) => {
    const ipHash = (0, crypto_1.createHash)('sha256').update(ipAddress).digest('hex');
    const deviceHash = (0, crypto_1.createHash)('sha256').update(deviceId).digest('hex');
    const counts = await redis_1.redis.eval("local ipCount = redis.call('INCR', KEYS[1]); if ipCount == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]); end; local deviceCount = redis.call('INCR', KEYS[2]); if deviceCount == 1 then redis.call('EXPIRE', KEYS[2], ARGV[1]); end; return {ipCount, deviceCount}", 2, `rate:auth:ip:${ipHash}`, `rate:auth:device:${deviceHash}`, AUTH_RATE_WINDOW_SECONDS);
    return (counts[0] <= AUTH_RATE_IP_LIMIT &&
        counts[1] <= AUTH_RATE_DEVICE_LIMIT);
};
// --- REST Routes ---
// Anonymous Auth Endpoint
app.post('/auth/anonymous', async (req, res) => {
    const { deviceId, name, age, country, city, captchaToken } = req.body ?? {};
    if (typeof deviceId !== 'string' ||
        deviceId.trim().length === 0 ||
        deviceId.length > 128) {
        return res.status(400).json({ error: 'A valid deviceId is required' });
    }
    try {
        const withinRateLimit = await consumeAnonymousAuthRate(req.ip ?? req.socket.remoteAddress ?? 'unknown', deviceId.trim());
        if (!withinRateLimit) {
            res.set('Retry-After', String(AUTH_RATE_WINDOW_SECONDS));
            return res.status(429).json({
                error: 'Too many sign-up attempts. Please wait before trying again.'
            });
        }
    }
    catch (error) {
        console.error('[Auth] Rate-limit service unavailable', error);
        return res.status(503).json({
            error: 'Sign-up is temporarily unavailable. Please try again shortly.'
        });
    }
    const normalizedName = typeof name === 'string' ? name.trim() : '';
    const normalizedCountry = typeof country === 'string' ? country.trim() : '';
    const normalizedCity = typeof city === 'string' ? city.trim() : '';
    if (normalizedName.length === 0 ||
        normalizedName.length > 50 ||
        typeof age !== 'number' ||
        !Number.isInteger(age) ||
        normalizedCountry.length === 0 ||
        normalizedCountry.length > 80 ||
        normalizedCity.length > 100 ||
        (city != null && typeof city !== 'string')) {
        return res.status(400).json({
            error: 'Valid name, age, and country are required'
        });
    }
    if (age < 18) {
        return res.status(403).json({ error: 'Users must be at least 18 years old' });
    }
    if (typeof captchaToken !== 'string' ||
        captchaToken.length === 0 ||
        captchaToken.length > 8192) {
        return res.status(400).json({ error: 'A valid CAPTCHA token is required' });
    }
    const captchaSecret = process.env.HCAPTCHA_SECRET;
    const expectedCaptchaSiteKey = process.env.HCAPTCHA_SITE_KEY;
    const allowedCaptchaHostnames = (process.env.HCAPTCHA_ALLOWED_HOSTNAMES ??
        process.env.HCAPTCHA_ALLOWED_HOSTNAME ??
        '')
        .split(',')
        .map((hostname) => hostname.trim().toLowerCase())
        .filter(Boolean);
    if (!captchaSecret ||
        !expectedCaptchaSiteKey ||
        allowedCaptchaHostnames.length === 0) {
        console.error('[Auth] hCaptcha server configuration is incomplete');
        return res.status(503).json({ error: 'Verification is temporarily unavailable' });
    }
    try {
        const verification = await fetch('https://api.hcaptcha.com/siteverify', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({
                secret: captchaSecret,
                response: captchaToken,
                sitekey: expectedCaptchaSiteKey
            }),
            signal: AbortSignal.timeout(8000)
        });
        if (!verification.ok) {
            return res.status(503).json({ error: 'Verification is temporarily unavailable' });
        }
        const result = await verification.json();
        if (result.success !== true ||
            typeof result.hostname !== 'string' ||
            !allowedCaptchaHostnames.includes(result.hostname.toLowerCase())) {
            return res.status(400).json({ error: 'CAPTCHA verification failed' });
        }
    }
    catch (error) {
        console.error('[Auth] CAPTCHA verification request failed', error);
        return res.status(503).json({ error: 'Verification is temporarily unavailable' });
    }
    const profile = {
        name: normalizedName,
        age,
        country: normalizedCountry,
        city: normalizedCity || null,
        isAdultVerified: true
    };
    try {
        const normalizedDeviceId = deviceId.trim();
        let user = await prisma_1.prisma.user.findUnique({
            where: { deviceId: normalizedDeviceId },
            include: { entitlements: true, preference: true }
        });
        if (user?.isBanned) {
            return res.status(403).json({ error: 'User is banned' });
        }
        if (!user) {
            user = await prisma_1.prisma.user.create({
                data: {
                    deviceId: normalizedDeviceId,
                    ...(profile ?? {}),
                    preference: {
                        create: {
                            gender: 'ANY',
                            intent: 'FRIENDS'
                        }
                    }
                },
                include: { entitlements: true, preference: true }
            });
        }
        else if (profile) {
            user = await prisma_1.prisma.user.update({
                where: { deviceId: normalizedDeviceId },
                data: profile,
                include: { entitlements: true, preference: true }
            });
        }
        const token = (0, auth_1.generateToken)({ userId: user.id, deviceId: user.deviceId });
        res.json({ token, user });
    }
    catch (error) {
        console.error('[Auth] Anonymous profile creation failed', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
app.get('/health', async (_req, res) => {
    try {
        await prisma_1.prisma.$queryRaw `SELECT 1`;
        res.status(200).json({ status: 'ok', database: 'connected' });
    }
    catch (error) {
        res.status(500).json({ status: 'error', database: 'disconnected' });
    }
});
const requireProfileAuth = (req, res, next) => {
    const authorization = req.header('Authorization');
    const token = authorization?.startsWith('Bearer ')
        ? authorization.slice('Bearer '.length)
        : '';
    if (!token)
        return res.status(401).json({ error: 'Authentication required' });
    let payload;
    try {
        payload = (0, auth_1.verifyToken)(token);
    }
    catch {
        return res.status(401).json({ error: 'Authentication required' });
    }
    void prisma_1.prisma.user.findUnique({
        where: { id: payload.userId },
        select: {
            id: true,
            age: true,
            name: true,
            country: true,
            isAdultVerified: true,
            isBanned: true
        }
    }).then((user) => {
        if (!user ||
            user.isBanned ||
            !user.isAdultVerified ||
            user.age == null ||
            user.age < 18 ||
            !user.name?.trim() ||
            !user.country?.trim()) {
            res.status(403).json({ error: 'A complete adult profile is required' });
            return;
        }
        res.locals.userId = user.id;
        next();
    }).catch((error) => {
        console.error('[Auth] Profile authorization failed', error);
        res.status(503).json({ error: 'Authentication is temporarily unavailable' });
    });
};
const isUuid = (value) => /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
const prohibitedWords = new Set([
    'abuse', 'ass', 'asshole', 'bastard', 'bitch', 'crap', 'cunt', 'damn',
    'dick', 'fuck', 'fucker', 'kill', 'nigger', 'penis', 'piss', 'porn', 'rape',
    'sex', 'shit', 'slut', 'suicide', 'whore', 'bhosdike', 'bhenchod', 'banchod',
    'chutiya', 'gandu', 'madarchod', 'mc', 'bc', 'randi', 'harami', 'saala',
    'kamine', 'kamina'
]);
const containsProhibitedWords = (text) => text
    .toLowerCase()
    .split(/\s+/)
    .some((word) => prohibitedWords.has(word.replace(/[^\w]/g, '')));
app.get('/friends', requireProfileAuth, async (_req, res) => {
    const userId = res.locals.userId;
    try {
        const records = await prisma_1.prisma.friendship.findMany({
            where: { OR: [{ user1Id: userId }, { user2Id: userId }] },
            include: {
                user1: { select: { id: true, name: true } },
                user2: { select: { id: true, name: true } }
            },
            orderBy: { createdAt: 'desc' }
        });
        const friends = records
            .filter((record) => record.status === 'ACCEPTED')
            .map((record) => {
            const other = record.user1Id === userId ? record.user2 : record.user1;
            return { id: other.id, name: other.name ?? 'Friend', connectedAt: record.createdAt };
        });
        const incomingRequests = records
            .filter((record) => record.status === 'PENDING' && record.initiatedById !== userId)
            .map((record) => {
            const sender = record.user1Id === userId ? record.user2 : record.user1;
            return {
                requestId: record.id,
                id: sender.id,
                name: sender.name ?? 'Stranger',
                createdAt: record.createdAt
            };
        });
        const outgoingRequests = records
            .filter((record) => record.status === 'PENDING' && record.initiatedById === userId)
            .map((record) => {
            const recipient = record.user1Id === userId ? record.user2 : record.user1;
            return {
                requestId: record.id,
                id: recipient.id,
                name: recipient.name ?? 'Stranger',
                createdAt: record.createdAt
            };
        });
        res.set('Cache-Control', 'no-store').json({
            friends,
            incomingRequests,
            outgoingRequests
        });
    }
    catch (error) {
        console.error('[Friends] Could not load friends', error);
        res.status(500).json({ error: 'Could not load friends' });
    }
});
app.post('/friends/requests', requireProfileAuth, async (req, res) => {
    const userId = res.locals.userId;
    const targetId = req.body?.toUserId;
    if (typeof targetId !== 'string' || !isUuid(targetId) || targetId === userId) {
        return res.status(400).json({ error: 'A valid friend ID is required' });
    }
    try {
        const target = await prisma_1.prisma.user.findUnique({
            where: { id: targetId },
            select: { id: true, isAdultVerified: true, isBanned: true }
        });
        if (!target || target.isBanned || !target.isAdultVerified) {
            return res.status(404).json({ error: 'Friend not found' });
        }
        const [user1Id, user2Id] = [userId, targetId].sort();
        const existing = await prisma_1.prisma.friendship.findUnique({
            where: { user1Id_user2Id: { user1Id, user2Id } }
        });
        if (existing?.status === 'BLOCKED') {
            return res.status(403).json({ error: 'This connection is blocked' });
        }
        if (existing) {
            return res.status(409).json({ error: 'A request or friendship already exists' });
        }
        const request = await prisma_1.prisma.friendship.create({
            data: { user1Id, user2Id, initiatedById: userId },
            select: { id: true, status: true, createdAt: true }
        });
        res.status(201).json(request);
    }
    catch (error) {
        console.error('[Friends] Could not send friend request', error);
        res.status(400).json({ error: 'Could not send friend request' });
    }
});
app.post('/friends/requests/:requestId/accept', requireProfileAuth, async (req, res) => {
    const userId = res.locals.userId;
    if (!isUuid(req.params.requestId)) {
        return res.status(400).json({ error: 'Invalid friend request ID' });
    }
    try {
        const request = await prisma_1.prisma.friendship.findFirst({
            where: {
                id: req.params.requestId,
                initiatedById: { not: userId },
                status: 'PENDING',
                OR: [{ user1Id: userId }, { user2Id: userId }]
            }
        });
        if (!request)
            return res.status(404).json({ error: 'Request not found' });
        const accepted = await prisma_1.prisma.friendship.update({
            where: { id: request.id },
            data: { status: 'ACCEPTED' },
            select: { id: true, status: true }
        });
        res.json(accepted);
    }
    catch (error) {
        console.error('[Friends] Could not accept friend request', error);
        res.status(500).json({ error: 'Could not accept friend request' });
    }
});
app.delete('/friends/requests/:requestId', requireProfileAuth, async (req, res) => {
    const userId = res.locals.userId;
    if (!isUuid(req.params.requestId)) {
        return res.status(400).json({ error: 'Invalid friend request ID' });
    }
    try {
        const request = await prisma_1.prisma.friendship.findFirst({
            where: {
                id: req.params.requestId,
                initiatedById: { not: userId },
                status: 'PENDING',
                OR: [{ user1Id: userId }, { user2Id: userId }]
            }
        });
        if (!request)
            return res.status(404).json({ error: 'Request not found' });
        await prisma_1.prisma.friendship.delete({ where: { id: request.id } });
        res.status(204).end();
    }
    catch (error) {
        console.error('[Friends] Could not reject friend request', error);
        res.status(500).json({ error: 'Could not reject friend request' });
    }
});
app.post('/friends/:friendId/block', requireProfileAuth, async (req, res) => {
    const userId = res.locals.userId;
    const targetId = req.params.friendId;
    if (!isUuid(targetId) || targetId === userId) {
        return res.status(400).json({ error: 'Invalid friend ID' });
    }
    try {
        const target = await prisma_1.prisma.user.findUnique({ where: { id: targetId }, select: { id: true } });
        if (!target)
            return res.status(404).json({ error: 'Friend not found' });
        const [user1Id, user2Id] = [userId, targetId].sort();
        const existing = await prisma_1.prisma.friendship.findUnique({
            where: { user1Id_user2Id: { user1Id, user2Id } }
        });
        if (existing) {
            await prisma_1.prisma.friendship.update({
                where: { id: existing.id },
                data: { initiatedById: userId, status: 'BLOCKED' }
            });
        }
        else {
            await prisma_1.prisma.friendship.create({
                data: { user1Id, user2Id, initiatedById: userId, status: 'BLOCKED' }
            });
        }
        res.json({ blocked: true });
    }
    catch (error) {
        console.error('[Safety] Could not block user', error);
        res.status(500).json({ error: 'Could not block user' });
    }
});
app.post('/reports', requireProfileAuth, async (req, res) => {
    const userId = res.locals.userId;
    const reportedUserId = req.body?.reportedUserId;
    const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';
    if (typeof reportedUserId !== 'string' ||
        !isUuid(reportedUserId) ||
        reportedUserId === userId ||
        reason.length === 0 ||
        reason.length > 200) {
        return res.status(400).json({ error: 'A valid user and report reason are required' });
    }
    try {
        await prisma_1.prisma.moderationReport.create({
            data: { reporterId: userId, reportedUserId, reason }
        });
        res.status(201).json({ reported: true });
    }
    catch (error) {
        console.error('[Safety] Could not submit report', error);
        res.status(400).json({ error: 'Could not submit report' });
    }
});
io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token)
        return next(new Error('Authentication error'));
    try {
        const decoded = (0, auth_1.verifyToken)(token);
        const user = await prisma_1.prisma.user.findUnique({
            where: { id: decoded.userId },
            select: { age: true, name: true, country: true, isAdultVerified: true, isBanned: true }
        });
        if (!user ||
            user.isBanned ||
            !user.isAdultVerified ||
            !user.name?.trim() ||
            !user.country?.trim() ||
            user.age == null ||
            user.age < 18) {
            return next(new Error('A complete adult profile is required'));
        }
        socket.user = decoded;
        next();
    }
    catch (err) {
        next(new Error('Authentication error'));
    }
});
// --- Socket.IO Handlers ---
io.on('connection', (socket) => {
    const userId = socket.user.userId;
    socket.friendPartners = new Set();
    // Join a personal room for targeted notifications
    socket.join(`user:${userId}`);
    console.log(`[Socket] User connected: ${userId}`);
    socket.on('join_queue', async (data) => {
        try {
            const { intent, gender, preferredGender, city } = data ?? {};
            if (await MatchmakingService_1.MatchmakingService.getPartner(userId)) {
                socket.emit('operation_error', {
                    operation: 'join_queue',
                    message: 'Leave your current chat before matching again.'
                });
                return;
            }
            if (socket.currentQueue) {
                await MatchmakingService_1.MatchmakingService.removeFromQueue(userId, socket.currentQueue.intent, socket.currentQueue.preferredGender);
            }
            const criteria = {
                userId,
                socketId: socket.id,
                intent: intent || 'FRIENDS',
                gender: gender || 'ANY',
                preferredGender: preferredGender || 'ANY',
                city: city || undefined
            };
            socket.currentQueue = { intent: criteria.intent, preferredGender: criteria.preferredGender };
            const match = await MatchmakingService_1.MatchmakingService.findMatch(criteria);
            if (match) {
                const roomId = `room:${userId}:${match.partnerId}`;
                // Notify both
                await MatchmakingService_1.MatchmakingService.setPartner(userId, match.partnerId);
                socket.join(roomId);
                io.to(match.partnerSocketId).emit('match_found', { roomId, partnerId: userId });
                // Partner joins room via their own logic or we can force it if we have access to their socket object
                // But usually they emit 'join_room' or we emit to them to join.
                // For simplicity here, we assume match_found tells them which room to join or they are already paired.
                socket.emit('match_found', { roomId, partnerId: match.partnerId });
            }
            else {
                await MatchmakingService_1.MatchmakingService.addToQueue(criteria);
                socket.emit('waiting', { message: 'Searching for a partner...' });
            }
        }
        catch (error) {
            console.error('[Socket] join_queue failed', error);
            socket.emit('operation_error', {
                operation: 'join_queue',
                message: 'Matching is temporarily unavailable. Check your connection and try again.'
            });
        }
    });
    socket.on('join_room', async (data) => {
        try {
            const { roomId } = data ?? {};
            const partnerId = await MatchmakingService_1.MatchmakingService.getPartner(userId);
            if (typeof roomId !== 'string' ||
                !partnerId ||
                ![`room:${userId}:${partnerId}`, `room:${partnerId}:${userId}`].includes(roomId)) {
                socket.emit('operation_error', {
                    operation: 'join_room',
                    message: 'Chat room is unavailable.'
                });
                return;
            }
            socket.join(roomId);
        }
        catch (error) {
            console.error('[Socket] join_room failed', error);
            socket.emit('operation_error', {
                operation: 'join_room',
                message: 'Chat room is temporarily unavailable.'
            });
        }
    });
    socket.on('chat_message', async (data) => {
        try {
            const { roomId, message } = data ?? {};
            const partnerId = await MatchmakingService_1.MatchmakingService.getPartner(userId);
            if (typeof roomId !== 'string' ||
                typeof message !== 'string' ||
                !message.trim() ||
                message.length > 4000 ||
                !partnerId ||
                !socket.rooms.has(roomId) ||
                ![`room:${userId}:${partnerId}`, `room:${partnerId}:${userId}`].includes(roomId))
                return;
            if (containsProhibitedWords(message)) {
                socket.emit('operation_error', {
                    operation: 'chat_message',
                    message: 'Please keep the conversation respectful.'
                });
                return;
            }
            socket.to(roomId).emit('chat_message', {
                senderId: userId,
                message,
                timestamp: new Date().toISOString()
            });
        }
        catch (error) {
            console.error('[Socket] chat_message failed', error);
            socket.emit('operation_error', {
                operation: 'chat_message',
                message: 'Message could not be sent.'
            });
        }
    });
    socket.on('chat_image', () => {
        socket.emit('operation_error', {
            operation: 'chat_image',
            message: 'Image sharing is unavailable while safety checks are updated.'
        });
    });
    socket.on('leave_chat', async (data) => {
        try {
            const { roomId } = data ?? {};
            const partnerId = await MatchmakingService_1.MatchmakingService.getPartner(userId);
            if (typeof roomId !== 'string' ||
                !partnerId ||
                !socket.rooms.has(roomId) ||
                ![`room:${userId}:${partnerId}`, `room:${partnerId}:${userId}`].includes(roomId))
                return;
            await MatchmakingService_1.MatchmakingService.endChat(userId);
            socket.to(roomId).emit('partner_left');
            socket.leave(roomId);
        }
        catch (error) {
            console.error('[Socket] leave_chat failed', error);
            socket.emit('operation_error', {
                operation: 'leave_chat',
                message: 'Could not end the conversation cleanly.'
            });
        }
    });
    socket.on('friend_join', async (data) => {
        try {
            const friendId = data?.friendId;
            if (typeof friendId !== 'string' || friendId === userId)
                return;
            const friendship = await prisma_1.prisma.friendship.findFirst({
                where: {
                    status: 'ACCEPTED',
                    OR: [
                        { user1Id: userId, user2Id: friendId },
                        { user1Id: friendId, user2Id: userId }
                    ]
                },
                select: { id: true }
            });
            if (!friendship) {
                socket.emit('operation_error', {
                    operation: 'friend_join',
                    message: 'This friend conversation is unavailable.'
                });
                return;
            }
            await socket.join(`friend:${[userId, friendId].sort().join(':')}`);
            socket.friendPartners?.add(friendId);
            socket.emit('friend_joined', { friendId });
        }
        catch (error) {
            console.error('[Socket] friend_join failed', error);
            socket.emit('operation_error', {
                operation: 'friend_join',
                message: 'Could not open this friend conversation.'
            });
        }
    });
    socket.on('friend_message', async (data, acknowledge) => {
        try {
            const friendId = data?.friendId;
            const message = data?.message;
            const ack = typeof acknowledge === 'function' ? acknowledge : () => { };
            if (typeof friendId !== 'string' ||
                typeof message !== 'string' ||
                message.trim().length === 0 ||
                message.length > 4000 ||
                !socket.friendPartners?.has(friendId)) {
                ack({ ok: false });
                return;
            }
            if (containsProhibitedWords(message)) {
                ack({ ok: false });
                return;
            }
            const roomId = `friend:${[userId, friendId].sort().join(':')}`;
            if (!socket.rooms.has(roomId)) {
                ack({ ok: false });
                return;
            }
            const friendship = await prisma_1.prisma.friendship.findFirst({
                where: {
                    status: 'ACCEPTED',
                    OR: [
                        { user1Id: userId, user2Id: friendId },
                        { user1Id: friendId, user2Id: userId }
                    ]
                },
                select: { id: true }
            });
            if (!friendship) {
                ack({ ok: false });
                return;
            }
            socket.to(roomId).emit('friend_message', {
                senderId: userId,
                message,
                timestamp: new Date().toISOString()
            });
            ack({ ok: true });
        }
        catch (error) {
            console.error('[Socket] friend_message failed', error);
            if (typeof acknowledge === 'function')
                acknowledge({ ok: false });
            socket.emit('operation_error', {
                operation: 'friend_message',
                message: 'Message could not be sent.'
            });
        }
    });
    socket.on('disconnect', async () => {
        console.log(`[Socket] User disconnected: ${userId}`);
        try {
            if (socket.currentQueue) {
                await MatchmakingService_1.MatchmakingService.removeFromQueue(userId, socket.currentQueue.intent, socket.currentQueue.preferredGender);
            }
            const partnerId = await MatchmakingService_1.MatchmakingService.endChat(userId);
            if (partnerId)
                io.to(`user:${partnerId}`).emit('partner_left');
        }
        catch (error) {
            console.error('[Socket] disconnect cleanup failed', error);
        }
    });
});
server.listen(PORT, () => {
    console.log(`[strangrchat_server] Server running on port ${PORT}`);
});
