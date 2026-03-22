# Build stage - includes all build dependencies
FROM node:20.12.0-alpine AS builder

WORKDIR /app

# Install build dependencies
COPY package.json package-lock.json ./

# First try npm ci for reproducible builds (preferred method)
RUN echo "🔍 Attempting reproducible install with npm ci..." && \
    if npm ci --ignore-scripts; then \
        echo "✅ SUCCESS: npm ci completed - using reproducible dependencies from lock file"; \
    else \
        echo "⚠️  WARNING: npm ci failed - lock file may be out of sync"; \
        echo "🔄 FALLING BACK to npm install to continue build..."; \
        echo "ℹ️  NOTE: This allows deployment but reduces build reproducibility"; \
        echo "🔧 FIX: Run 'npm install' locally and commit updated package-lock.json"; \
        npm install --ignore-scripts; \
        echo "✅ SUCCESS: npm install completed - build continuing with fallback dependencies"; \
    fi && \
    npm cache clean --force

# Copy source code and build
COPY . .
RUN npm run build

# Runtime stage - lightweight image with only runtime dependencies
FROM node:20.12.0-alpine AS runner

WORKDIR /app

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Application environment variables
ENV NODE_ENV=production
ENV PORT=3000

# OpenAI Configuration (build-time args with runtime env defaults)
ARG OPENAI_API_KEY=""
ARG OPENAI_BASE_URL=""
ARG OPENAI_MODEL=""
ENV OPENAI_API_KEY=$OPENAI_API_KEY
ENV OPENAI_BASE_URL=$OPENAI_BASE_URL
ENV OPENAI_MODEL=$OPENAI_MODEL

# Procurement Agent Configuration (build-time args with runtime env defaults)
ARG LLM_MAX_TOKENS=""
ARG LLM_CONTEXT_WINDOW=""
ARG EMBEDDING_MODEL=""
ENV LLM_MAX_TOKENS=$LLM_MAX_TOKENS
ENV LLM_CONTEXT_WINDOW=$LLM_CONTEXT_WINDOW
ENV EMBEDDING_MODEL=$EMBEDDING_MODEL

# Logging Configuration (build-time args with runtime env defaults)
ARG LOGFIRE_TOKEN=""
ENV LOGFIRE_TOKEN=$LOGFIRE_TOKEN

# Copy necessary files from builder - only what's needed for runtime
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Switch to non-root user
USER nextjs

# Expose application port
EXPOSE 3000

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application
CMD ["node", "server.js"]
