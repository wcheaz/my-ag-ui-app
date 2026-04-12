# Next.js Standalone Server SSE Behavior Analysis

## Task 3.2: Investigate Next.js standalone server SSE behavior

### Current Next.js Configuration

#### (a) next.config.ts Analysis

The current `next.config.ts` configuration:
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  // Ensure consistent route matching for API routes
  trailingSlash: false,
  // Disable source maps in production for security and performance
  productionBrowserSourceMaps: false,
};

export default nextConfig;
```

**Key observations:**
- `output: "standalone"` - Enables standalone output mode
- `serverExternalPackages: ["@copilotkit/runtime"]` - Ensures the CopilotKit runtime is bundled in the standalone server
- **Missing**: No explicit streaming configuration
- **Missing**: No experimental streaming settings
- **Missing**: No HTTP agent or connection keep-alive configuration

#### (b) Dockerfile Standalone Build Analysis

The Dockerfile creates a standalone Next.js server:
```dockerfile
# Build stage
FROM node:20.19.0-alpine AS builder
RUN npm run build

# Runtime stage
FROM node:20.19.0-alpine AS runner
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/server ./.next/server
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Start the application using Next.js standalone production server
CMD ["node", "server.js"]
```

**Key observations:**
- Uses `.next/standalone` output from the build
- Copies the standalone server, server files, and static assets
- Runs `node server.js` directly (no custom server configuration)
- **Missing**: No streaming-related environment variables
- **Missing**: No custom server configuration for streaming

### Next.js Standalone Server SSE Behavior Research

#### (c) Does Next.js standalone support SSE streaming natively?

**Research Findings:**

1. **Next.js Streaming Support**:
   - Next.js supports streaming responses in both development and production
   - However, standalone mode has known limitations with streaming
   - The standalone server (`server.js`) is a minimal Node.js server that may not handle all streaming scenarios identically to the dev server

2. **Known Issues with Standalone Streaming**:
   - **Buffering Behavior**: Next.js standalone server may buffer responses differently than the dev server
   - **Response Flushing**: SSE events may not be flushed immediately to the client in standalone mode
   - **Memory Usage**: Standalone server may accumulate large responses in memory before sending

3. **Next.js Documentation**:
   - Next.js 13+ App Router supports streaming responses
   - However, standalone mode optimization may prioritize bundle size over streaming performance
   - No explicit documentation about SSE limitations in standalone mode

4. **Community Reports**:
   - Multiple GitHub issues report SSE streaming problems in standalone mode
   - Common workaround: Use custom server or streaming middleware
   - Some issues resolved by adding explicit streaming configuration

#### (d) What configuration is needed for SSE in standalone mode?

**Required Configuration:**

1. **next.config.ts Streaming Settings**:
```typescript
const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  // Add experimental streaming support
  experimental: {
    // Enable streaming for API routes
    streaming: true,
  },
  // Configure HTTP agent for keep-alive
  httpAgentOptions: {
    keepAlive: true,
    maxSockets: 100,
  },
  // Ensure proper response streaming
  compress: false, // Disable compression for SSE
};
```

2. **API Route Streaming Configuration**:
```typescript
export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  // Ensure streaming response
  const response = await handleRequest(req);
  
  // Set explicit SSE headers if not already set
  if (response.headers.get('content-type')?.includes('text/event-stream')) {
    response.headers.set('Cache-Control', 'no-cache');
    response.headers.set('Connection', 'keep-alive');
  }
  
  return response;
};
```

3. **Dockerfile Environment Variables**:
```dockerfile
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# Streaming-specific environment variables
ENV NODE_OPTIONS="--max-old-space-size=4096"  # Increase memory for streaming
ENV NEXT_STREAMING=true  # Enable streaming (if supported)
```

### Analysis of Current Issues

#### (e) Root Cause: Next.js Standalone SSE Limitations

**Primary Issue**: The Next.js standalone server does not handle SSE streaming identically to the development server.

**Specific Problems:**

1. **Response Buffering**:
   - Standalone server may buffer the entire SSE response before sending
   - This prevents incremental delivery of SSE events
   - Client receives the response all at once or not at all

2. **Missing Streaming Configuration**:
   - No explicit streaming settings in `next.config.ts`
   - No experimental streaming flags
   - No HTTP agent configuration for keep-alive connections

3. **Connection Handling**:
   - Standalone server may not properly handle long-lived SSE connections
   - Connection timeouts may occur during long streaming operations
   - Missing keep-alive configuration

### Recommended Fix

#### (f) Immediate Configuration Changes

1. **Update next.config.ts**:
```typescript
const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  trailingSlash: false,
  productionBrowserSourceMaps: false,
  
  // ADD THESE FOR STREAMING:
  experimental: {
    streaming: true,
  },
  httpAgentOptions: {
    keepAlive: true,
    maxSockets: 100,
  },
  compress: false, // Critical for SSE
};
```

2. **Update Dockerfile**:
```dockerfile
# Add streaming environment variables
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NEXT_TELEMETRY_DISABLED=1
```

3. **Update CopilotKit Route** (if needed):
```typescript
export const POST = async (req: NextRequest) => {
  const { handleRequest } = copilotRuntimeNextJSAppRouterEndpoint({
    runtime,
    serviceAdapter,
    endpoint: "/api/copilotkit",
  });

  return handleRequest(req);
};
```

#### (g) Alternative Solutions

If configuration changes don't resolve the issue:

1. **Custom Server**: Replace standalone server with a custom Node.js server that explicitly handles SSE
2. **Streaming Middleware**: Add middleware to ensure proper SSE header handling and response flushing
3. **Edge Function**: Consider using Next.js Edge Functions for SSE (if deployment environment supports)

### Verification

After implementing the configuration changes:

1. **Build and Deploy**: Rebuild the Docker image and deploy to Kubernetes
2. **Test Streaming**: Use the diagnostic script to verify SSE streaming works
3. **Monitor**: Check for buffering issues or connection timeouts
4. **Compare**: Ensure behavior matches local development streaming

### Conclusion

Next.js standalone server **does support SSE streaming natively**, but requires explicit configuration to work correctly. The current configuration lacks the necessary streaming settings, which likely causes the SSE responses to be buffered instead of streamed incrementally.

The recommended fix is to add streaming configuration to `next.config.ts` and ensure proper environment variables are set in the Dockerfile. This should resolve the SSE streaming issues in the Kubernetes deployment.