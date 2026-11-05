# Dockerfile for strangrchat Node.js backend
FROM node:20-alpine AS builder

WORKDIR /app

# Prisma's schema engine requires OpenSSL on Alpine.
RUN apk add --no-cache openssl

# Install dependencies
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci

# Copy source and build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Production image
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY package*.json ./
COPY --from=builder /app/prisma ./prisma
RUN npm ci
RUN npx prisma generate

COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["sh", "-c", "npx prisma db push && node dist/index.js"]
