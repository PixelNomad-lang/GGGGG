# Multi-stage build for production optimization

# Stage 1: Build the frontend
FROM node:18-alpine AS frontend-builder
WORKDIR /app/frontend
COPY ../pockemen-frontend/package*.json ./
RUN npm ci --only=production
COPY ../pockemen-frontend/ ./
RUN npm run build

# Stage 2: Build the backend
FROM node:18-alpine AS backend-builder
WORKDIR /app/backend
COPY package*.json ./
RUN npm ci --only=production

# Stage 3: Production image
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production

# Copy backend dependencies and source
COPY --from=backend-builder /app/backend/node_modules ./node_modules
COPY . .

# Copy built frontend
COPY --from=frontend-builder /app/frontend/dist ./pockemen-frontend/dist

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/api/health || exit 1

# Start the application
CMD ["npm", "start"]