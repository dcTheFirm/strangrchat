import express from 'express';
import http from 'http';
import cors from 'cors';
import dotenv from 'dotenv';
import { Server, Socket } from 'socket.io';
import { prisma } from './config/prisma';
import { verifyToken, AuthPayload, generateToken } from './utils/auth';
import { MatchmakingService, MatchCriteria } from './services/MatchmakingService';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// --- REST Routes ---

// Anonymous Auth Endpoint
app.post('/auth/anonymous', async (req, res) => {
  const { deviceId } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'deviceId is required' });

  try {
    let user = await prisma.user.findUnique({
      where: { deviceId },
      include: { entitlements: true, preference: true }
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          deviceId,
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

    if (user.isBanned) {
      return res.status(403).json({ error: 'User is banned' });
    }

    const token = generateToken({ userId: user.id, deviceId: user.deviceId });
    res.json({ token, user });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.status(200).json({ status: 'ok', database: 'connected' });
  } catch (error) {
    res.status(500).json({ status: 'error', database: 'disconnected' });
  }
});

// --- Socket.IO Middleware ---

interface AuthenticatedSocket extends Socket {
  user?: AuthPayload;
  currentQueue?: { intent: string; preferredGender: string };
}


io.use((socket: AuthenticatedSocket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));

  try {
    const decoded = verifyToken(token);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

// --- Socket.IO Handlers ---

io.on('connection', (socket: AuthenticatedSocket) => {
  const userId = socket.user!.userId;
  // Join a personal room for targeted notifications
  socket.join(`user:${userId}`);

  console.log(`[Socket] User connected: ${userId}`);

  socket.on('join_queue', async (data) => {
    const { intent, gender, preferredGender, city } = data;
    
    const criteria: MatchCriteria = {
      userId,
      socketId: socket.id,
      intent: intent || 'FRIENDS',
      gender: gender || 'ANY',
      preferredGender: preferredGender || 'ANY',
      city: city || undefined
    };

    socket.currentQueue = { intent: criteria.intent, preferredGender: criteria.preferredGender };

    const match = await MatchmakingService.findMatch(criteria);

    if (match) {
      const roomId = `room:${userId}:${match.partnerId}`;
      
      // Notify both
      await MatchmakingService.setPartner(userId, match.partnerId);
      
      socket.join(roomId);
      io.to(match.partnerSocketId).emit('match_found', { roomId, partnerId: userId });
      
      // Partner joins room via their own logic or we can force it if we have access to their socket object
      // But usually they emit 'join_room' or we emit to them to join.
      // For simplicity here, we assume match_found tells them which room to join or they are already paired.
      socket.emit('match_found', { roomId, partnerId: match.partnerId });
    } else {
      await MatchmakingService.addToQueue(criteria);
      socket.emit('waiting', { message: 'Searching for a partner...' });
    }
  });

  socket.on('join_room', (data) => {
    const { roomId } = data;
    socket.join(roomId);
    console.log(`[Socket] User ${userId} joined room ${roomId}`);
  });

  socket.on('chat_message', async (data) => {
    const { roomId, message } = data;
    // Relay only - ZERO PERSISTENCE
    socket.to(roomId).emit('chat_message', {
      senderId: userId,
      message,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('chat_image', async (data) => {
    const { roomId, image } = data; // image is base64
    // Relay only - ZERO PERSISTENCE
    socket.to(roomId).emit('chat_image', {
      senderId: userId,
      image,
      timestamp: new Date().toISOString()
    });
  });

  socket.on('leave_chat', async (data) => {
    const { roomId } = data;
    const partnerId = await MatchmakingService.endChat(userId);
    socket.to(roomId).emit('partner_left');
    socket.leave(roomId);
  });

  socket.on('disconnect', async () => {
    console.log(`[Socket] User disconnected: ${userId}`);
    
    // Remove from queue if waiting
    if (socket.currentQueue) {
      await MatchmakingService.removeFromQueue(userId, socket.currentQueue.intent, socket.currentQueue.preferredGender);
    }

    const partnerId = await MatchmakingService.endChat(userId);
    if (partnerId) {
      // In a real scenario, we might need the roomId to notify the partner
      // or use a user-specific room
      io.to(`user:${partnerId}`).emit('partner_left');
    }
  });
});

server.listen(PORT, () => {
  console.log(`[strangrchat_server] Server running on port ${PORT}`);
});
