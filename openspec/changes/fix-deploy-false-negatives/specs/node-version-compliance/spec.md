## ADDED Requirements

The Docker image SHALL use Node.js version that meets minimum requirements for all npm dependencies.

The Dockerfile SHALL use Node.js 20.19.0 or later as base image.

The build system SHALL not display EBADENGINE warnings for Node version compatibility.

All npm dependencies SHALL meet their required Node version constraints in the Docker build environment.

#### Scenario: Docker build with compliant Node version
- **WHEN** Dockerfile uses `FROM node:20.19.0-alpine` as base image
- **THEN** Docker build SHALL complete without EBADENGINE warnings
- **THEN** eslint-visitor-keys@5.0.1 SHALL meet minimum Node version requirement (20.19.0+)
- **THEN** all dependencies SHALL install successfully
- **THEN** build log SHALL not contain "Unsupported engine" warnings

#### Scenario: Dependency requiring minimum Node version
- **WHEN** npm dependency specifies Node 20.19.0+ in engines field
- **THEN** Docker build SHALL use Node 20.19.0 or later
- **THEN** dependency SHALL install without engine compatibility warnings
- **THEN** ESLint SHALL function correctly in build environment
