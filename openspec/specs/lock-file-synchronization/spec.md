# Capability: Lock File Synchronization

## Purpose

Ensures package-lock.json stays synchronized with package.json for reproducible Docker builds.

## Requirements

The package-lock.json file SHALL remain synchronized with package.json dependencies.

The package-lock.json file SHALL use React 19 type definitions when package.json specifies React 19.

The `npm ci` command SHALL succeed during Docker build without falling back to `npm install`.

The build script SHALL use `npm ci` for reproducible dependency installation when lock file is synchronized.

The build script SHALL NOT display lock file mismatch warnings during dependency installation.

#### Scenario: Successful npm ci during Docker build
- **WHEN** Docker build runs `npm ci` with synchronized package-lock.json
- **THEN** npm ci SHALL complete successfully with exit code 0
- **THEN** no lock file mismatch warnings SHALL be displayed
- **THEN** dependencies SHALL be installed from lock file exactly as specified
- **THEN** build SHALL continue without fallback to `npm install`

#### Scenario: Package-lock.json synchronized with package.json
- **WHEN** package.json is updated to React 19 and `npm install` is run locally
- **THEN** package-lock.json SHALL contain React 19 type definitions
- **THEN** package-lock.json SHALL not contain @types/react@18.x
- **THEN** subsequent `npm ci` in Docker build SHALL succeed
