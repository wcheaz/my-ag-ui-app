import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["@copilotkit/runtime"],
  experimental: {
    // Ensure API routes are properly included in standalone builds
    serverComponentsExternalPackages: ["@copilotkit/runtime"],
  },
  // Ensure consistent route matching for API routes
  trailingSlash: false,
  // Disable source maps in production for security and performance
  productionBrowserSourceMaps: false,
};

export default nextConfig;
