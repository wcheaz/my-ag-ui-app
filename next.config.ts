import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  // Ensure consistent route matching for API routes
  trailingSlash: false,
  // Disable source maps in production for security and performance
  productionBrowserSourceMaps: false,
  // Experimental features for standalone output
  experimental: {
    // Ensure API routes are properly included in standalone build
    serverComponentsExternalPackages: ["@copilotkit/runtime"],
  },
};

export default nextConfig;
