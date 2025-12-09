# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-12-09

### BREAKING CHANGES
- Complete rewrite from Node.js/TypeScript to pure bash composite action
- Removed automatic cleanup/post-run phase - k0s cluster persists after action completes
- No longer requires building or compilation
- Action now uses `composite` instead of `node24` runtime

### Changed
- Action implementation is now a single bash script in `action.yml`
- Simplified architecture with zero dependencies
- Removed all TypeScript source files and build tooling
- Removed `@actions/core` and `@actions/exec` dependencies
- Removed `dist/` directory - no compilation step needed

### Removed
- Automatic cleanup functionality (k0s no longer stopped/reset after workflow)
- Node.js runtime dependency
- TypeScript build step
- All npm dependencies and package.json
- Post-run hook mechanism

### Added
- Pure bash implementation for maximum simplicity
- Direct shell script execution without Node.js wrapper

### Why This Is Better
- Simpler to maintain - single file contains all logic
- No build step required - action works immediately
- Faster execution - no Node.js overhead
- More transparent - all code visible in action.yml
- Zero external dependencies

## [1.0.0] - 2025-11-09

### Added
- Initial release of setup-k0s action
- Automatic installation of k0s binary
- Single-node controller setup using systemd
- Configurable k0s version
- Wait for cluster readiness with configurable timeout
- Automatic cleanup using GitHub Actions post-run hook
- Export KUBECONFIG environment variable
- Admin kubeconfig extraction and configuration
