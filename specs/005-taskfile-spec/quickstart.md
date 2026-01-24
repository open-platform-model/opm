# Quickstart: OPM Development Taskfile

**Feature**: 005-taskfile-spec  
**Date**: 2026-01-23

## Prerequisites

Install required tools:

```bash
# Task runner (https://taskfile.dev)
brew install go-task  # macOS
# or: sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin

# CUE language (https://cuelang.org)
brew install cue  # macOS
# or: go install cuelang.org/go/cmd/cue@latest

# Go (for CLI development)
# https://go.dev/dl/

# File watcher (for watch mode)
brew install watchexec  # macOS
# or: cargo install watchexec-cli

# Docker (for local registry)
# https://docs.docker.com/get-docker/
```

Verify installations:

```bash
task --version   # v3.x.x
cue version      # v0.15.0+
go version       # go1.21+
watchexec --version
docker --version
```

## Getting Started

### 1. Environment Setup

```bash
# Clone the repository
git clone <repo-url> open-platform-model
cd open-platform-model

# Initialize development environment
task setup
```

This will:

- Start the local OCI registry
- Tidy all module dependencies
- Display environment configuration

### 2. View Available Tasks

```bash
# List all available tasks
task --list

# Show detailed help for a task
task --summary setup
```

### 3. Check Environment

```bash
task env
```

Output:

```
Module Configuration:
  LOCAL_REGISTRY=localhost:5000
  CUE_VERSION=v0.15.0

Registry:
  CONTAINER=opm-registry
  PORT=5000

Paths:
  CORE_DIR=core/v0
  CATALOG_DIR=catalog/v0
```

## Common Workflows

### CUE Development

```bash
# Format all CUE files
task fmt

# Validate all CUE files
task vet

# Format and validate a specific module
task module:fmt MODULE=core
task module:vet MODULE=resources

# Watch mode - auto-validate on save
task watch:vet

# Tidy module dependencies
task module:tidy MODULE=schemas
```

### CLI Development

```bash
# Build the CLI
cd cli && task build

# Run tests
task test              # All tests
task test:unit         # Unit tests only
task test:verbose      # Verbose output
task test:run TEST=TestModuleLoad  # Specific test

# Lint and format
task lint
task fmt
```

### Module Publishing

```bash
# Start local registry (if not running)
task registry:start

# Check registry status
task registry:status

# Publish a module to local registry
task module:publish:local MODULE=core

# Publish with specific version
task module:publish:local MODULE=core VERSION=v0.2.0

# Publish all modules (dependency order)
task module:publish:all:local
```

### Version Management

```bash
# Show all module versions
task version

# Bump a module version
task version:bump MODULE=core TYPE=patch   # v0.1.0 → v0.1.1
task version:bump MODULE=core TYPE=minor   # v0.1.0 → v0.2.0
task version:bump MODULE=core TYPE=major   # v0.1.0 → v1.0.0
```

### Release Workflow

```bash
# Generate/update changelog
task changelog

# Preview release (dry run)
task release:dry-run

# Create release
task release
```

### CI Pipeline

```bash
# Run full CI check (format, validate, test)
task ci
```

## Task Reference

### Root Tasks

| Task | Description |
|------|-------------|
| `task setup` | Initialize development environment |
| `task clean` | Remove generated artifacts |
| `task env` | Display environment configuration |
| `task fmt` | Format all CUE files |
| `task vet` | Validate all CUE files |
| `task ci` | Run all CI checks |

### Module Tasks

| Task | Description |
|------|-------------|
| `task module:fmt MODULE=<name>` | Format specific module |
| `task module:vet MODULE=<name>` | Validate specific module |
| `task module:tidy MODULE=<name>` | Tidy module dependencies |
| `task module:publish MODULE=<name>` | Publish to production registry |
| `task module:publish:local MODULE=<name>` | Publish to local registry |
| `task module:version MODULE=<name>` | Show module version |

### Watch Tasks

| Task | Description |
|------|-------------|
| `task watch:fmt` | Auto-format on file changes |
| `task watch:vet` | Auto-validate on file changes |

### Registry Tasks

| Task | Description |
|------|-------------|
| `task registry:start` | Start local OCI registry |
| `task registry:stop` | Stop local registry |
| `task registry:status` | Show registry status and modules |

### Version Tasks

| Task | Description |
|------|-------------|
| `task version` | Show all module versions |
| `task version:bump MODULE=<name> TYPE=<type>` | Bump version (patch/minor/major) |

### Release Tasks

| Task | Description |
|------|-------------|
| `task changelog` | Generate changelog from commits |
| `task release` | Create release (version, changelog, tag) |
| `task release:dry-run` | Preview release changes |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TASK_VERBOSE` | Enable verbose output | `0` |
| `CUE_REGISTRY` | OCI registry URL | `localhost:5000+insecure` |
| `MODULE` | Target module for operations | (required for module tasks) |
| `TYPE` | Version bump type | `patch` |
| `VERSION` | Explicit version for publish | (from versions.yml) |

## Troubleshooting

### Registry not running

```bash
# Check if registry container exists
docker ps -a | grep opm-registry

# Start registry
task registry:start

# If issues, clean and restart
docker rm -f opm-registry
task registry:start
```

### CUE validation errors

```bash
# Run with verbose output
TASK_VERBOSE=1 task vet

# Check specific module
task module:vet MODULE=core

# Ensure dependencies are tidied
task module:tidy MODULE=core
```

### Watch mode not working

```bash
# Verify watchexec is installed
watchexec --version

# Run manually to debug
watchexec -e cue -- cue vet ./...
```

### Version conflicts

```bash
# Check versions.yml for conflicts
cat versions.yml

# Tidy all modules in order
task module:tidy:all
```
