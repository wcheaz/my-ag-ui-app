import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

const eslintConfig = [
  ...nextCoreWebVitals,
  ...nextTypescript,
  {
    ignores: [
      "node_modules/**",
      ".next/**",
      "out/**",
      "build/**",
      "next-env.d.ts",
      ".venv/**",
      "agent/.venv/**",
      "*.min.js",
      "*.min.css",
      "*.log",
      ".env*",
      "openspec/**/*.md",
      "ralph-docs/**/*.md",
    ],
  },
];

export default eslintConfig;
