# -------- Base Builder --------
FROM node:20-alpine AS builder
WORKDIR /app

# Copy orchestrator sources
# Expecting: server.js, package.json, package-lock.json (optional), src/, etc.
COPY . .

# Install deps (use ci if lockfile exists)
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# -------- Runtime --------
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup -S nodejs && adduser -S node -G nodejs

# App files
COPY --from=builder /app /app

# Data dir for SQLite
RUN mkdir -p /app/data && chown -R node:node /app
USER node

EXPOSE 3000
CMD ["node","server.js"]

#If you’re using ES modules (import ...), ensure "type": "module" exists in orchestrator/package.json.


