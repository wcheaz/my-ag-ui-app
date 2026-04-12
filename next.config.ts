import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  // Ensure consistent route matching for API routes
  trailingSlash: false,
  // Disable source maps in production for security and performance
  productionBrowserSourceMaps: false,
  
  // Configure HTTP agent for keep-alive connections (SSE fix)
  httpAgentOptions: {
    keepAlive: true,
  },
  // Disable compression for SSE streaming
  compress: false,
};

export default nextConfig;
