# ─── Build stage ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install build tools needed for native modules (bcrypt uses node-gyp)
RUN apk add --no-cache python3 make g++

# Install ALL dependencies (including devDeps for nest build)
COPY package*.json ./
RUN npm ci

# Copy source and compile TypeScript
COPY . .
RUN npm run build

# ─── Production stage ─────────────────────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

# Install build tools again for native modules in production install
RUN apk add --no-cache python3 make g++

# Install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled output from builder
COPY --from=builder /app/dist ./dist

# Expose port (Railway sets PORT env var)
EXPOSE 3000

CMD ["node", "dist/main.js"]
