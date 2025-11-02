# OPM Taskfile Documentation

Comprehensive task automation for `opm.dev@v1` module development.

## Quick Start

```bash
# Install Taskfile (if not already installed)
# See: https://taskfile.dev/installation/

# View all available tasks
task --list

# Setup development environment
task setup

# Format and validate
task fmt
task vet

# Publish to local registry
task publish:local VERSION=v1.0.0

# Show verbose output (display commands being run)
task --verbose registry:status
task -v fmt  # Short form
```

## Output Control

**Tasks run in silent mode by default** - only output is shown, not the commands being executed.

To see the commands being run:

```bash
# Use --verbose or -v flag
task --verbose <taskname>
task -v <taskname>

# Examples
task -v registry:status
task --verbose publish:local VERSION=v1.0.0
```

This keeps the output clean while still allowing you to debug when needed.

## Installation

### Install Taskfile

**macOS/Linux (Homebrew):**
```bash
brew install go-task/tap/go-task
```

**Linux (snap):**
```bash
snap install task --classic
```

**Go install:**
```bash
go install github.com/go-task/task/v3/cmd/task@latest
```

**Manual install:**
See [Taskfile installation docs](https://taskfile.dev/installation/)

### Verify Installation

```bash
task --version
# Should show: Task version: v3.x.x
```

## Project Structure

```
opm/
├── Taskfile.yml              # Main taskfile (orchestration)
├── .tasks/                   # Modular task definitions
│   ├── registry-cue.yml     # CUE registry & cache management
│   ├── registry-docker.yml  # Docker OCI registry management
│   ├── cue-common.yml       # Common CUE operations
│   └── publish.yml          # Module publishing workflows
├── .env.example             # Environment configuration template
├── TASKFILE.md              # This file
└── v1/                      # CUE module source
    ├── cue.mod/
    ├── core/
    ├── units/
    ├── traits/
    └── ...
```

## Configuration

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Available environment variables:

- `CUE_CACHE_DIR` - CUE module cache location
- `CUE_REGISTRY` - Registry URL for CUE operations
- `REGISTRY_CONTAINER` - Docker container name
- `REGISTRY_PORT` - Local registry port
- `MODULE_PATH` - Module path for publishing

## Task Categories

### 1. Development Setup

| Task | Description |
|------|-------------|
| `task setup` | Initialize development environment (start registry, tidy deps) |
| `task clean` | Clean all generated files and caches |
| `task env` | Show current environment configuration |

### 2. CUE Operations

#### Formatting

| Task | Description |
|------|-------------|
| `task fmt` | Format all CUE files |
| `task cue:fmt:check` | Check formatting without changes |
| `task cue:fmt:diff` | Show formatting differences |

#### Validation

| Task | Description |
|------|-------------|
| `task vet` | Validate all CUE files |
| `task cue:vet:strict` | Validate with all errors shown |
| `task cue:vet:concrete` | Ensure all values are concrete |

#### Evaluation & Export

| Task | Description |
|------|-------------|
| `task cue:eval` | Evaluate all configurations |
| `task cue:eval:expr EXPR='#UnitDefinition'` | Evaluate specific expression |
| `task cue:export:json` | Export as JSON |
| `task cue:export:yaml` | Export as YAML |
| `task cue:export:expr EXPR='units' FORMAT=json` | Export specific expression |

#### Module Management

| Task | Description |
|------|-------------|
| `task cue:mod:tidy` | Update module dependencies |
| `task cue:mod:get MODULE=github.com/foo/bar@v1` | Get specific dependency |
| `task cue:mod:graph` | Show dependency graph |
| `task cue:mod:info` | Show module information |

### 3. Package-Specific Validation

| Task | Description |
|------|-------------|
| `task core:vet` | Validate core definitions |
| `task units:vet` | Validate units package |
| `task traits:vet` | Validate traits package |
| `task blueprints:vet` | Validate blueprints package |
| `task policies:vet` | Validate policies package |
| `task modules:vet` | Validate example modules |
| `task examples:vet` | Validate examples |

#### Comprehensive Validation

| Task | Description |
|------|-------------|
| `task validate:all` | Validate all packages sequentially |
| `task validate:parallel` | Validate all packages in parallel |

### 4. Registry Management

#### Docker OCI Registry (Persistent)

| Task | Description |
|------|-------------|
| `task registry:start` | Start Docker OCI registry |
| `task registry:stop` | Stop Docker registry |
| `task registry:status` | Show status and list modules |
| `task registry-docker:logs` | View registry logs |
| `task registry-docker:list` | List all modules with versions |
| `task registry-docker:tags MODULE=opm.dev` | Show tags for specific module |
| `task registry-docker:show MODULE=opm.dev TAG=v1` | Show module details |
| `task registry-docker:delete MODULE=opm.dev TAG=v1` | Delete specific tag |
| `task registry-docker:cleanup` | Remove all registry data |
| `task registry-docker:reset` | Full reset (container + data + cache) |
| `task registry-docker:health` | Run health checks |

#### CUE In-Memory Registry

| Task | Description |
|------|-------------|
| `task registry-cue:start` | Start temporary CUE registry (foreground - Ctrl+C to stop) |

**Note**: The CUE in-memory registry runs in the foreground and blocks your terminal. Use the Docker registry (`task registry:start`) for persistent development work.

#### Cache Management

| Task | Description |
|------|-------------|
| `task cache:clear` | Clear CUE module cache |
| `task cache:path` | Show cache directory |
| `task registry-cue:cache:info` | Show detailed cache information |
| `task registry-cue:cache:list` | List all cached modules |
| `task registry-cue:cache:show MODULE=github.com/foo/bar@v1` | Show cached module details |

### 5. Publishing

#### Version Management

| Task | Description |
|------|-------------|
| `task version` | Show current module version |
| `task publish:version:set VERSION=v1.0.0` | Set module version |
| `task publish:bump:patch` | Bump patch version (1.2.3 → 1.2.4) |
| `task publish:bump:minor` | Bump minor version (1.2.3 → 1.3.0) |
| `task publish:bump:major` | Bump major version (1.2.3 → 2.0.0) |

#### Module Information

| Task | Description |
|------|-------------|
| `task info` | Show module information |
| `task publish:info:deps` | Show module dependencies |

#### Publishing Workflows

| Task | Description |
|------|-------------|
| `task publish:validate` | Comprehensive pre-publish validation |
| `task publish:check` | Quick validation check |
| `task publish:local VERSION=v1.0.0` | Publish to local registry |
| `task publish:local:force VERSION=v1.0.0-dev` | Force publish (skip validation) |
| `task publish:dry-run` | Simulate publishing |
| `task publish:test:local VERSION=v1.0.0` | Test fetching from local registry |

#### Complete Workflows

| Task | Description |
|------|-------------|
| `task publish:release:local` | Complete local release (auto-bump patch) |
| `task publish:release:local VERSION=v1.2.3` | Local release with specific version |
| `task publish:release:local BUMP=minor` | Local release with minor bump |

### 6. Watch Mode

| Task | Description |
|------|-------------|
| `task watch:fmt` | Auto-format on file changes |
| `task watch:vet` | Auto-validate on file changes |

## Common Workflows

### Daily Development

```bash
# Start your session
task setup

# Make changes to CUE files...

# Format and validate
task fmt
task vet

# Validate specific package
task units:vet

# Export for inspection
task cue:export:expr EXPR='units.workload' FORMAT=yaml
```

### Publishing New Version

```bash
# Validate everything
task publish:validate

# Bump version and publish
task publish:release:local BUMP=minor

# Or manually set version
task publish:version:set VERSION=v1.2.0
task publish:local VERSION=v1.2.0

# Verify
task registry:status
```

### Testing Module Changes

```bash
# Publish development version
task publish:local:force VERSION=v0.1.0-dev

# Test fetching it
task publish:test:local VERSION=v0.1.0-dev

# View in registry
task registry-docker:tags MODULE=opm.dev
```

### Registry Maintenance

```bash
# Check registry status
task registry:status

# View logs
task registry-docker:logs:tail

# List all modules
task registry-docker:list

# Delete old version
task registry-docker:delete MODULE=opm.dev TAG=v0.9.0

# Full cleanup (start fresh)
task registry-docker:reset
```

### Cache Management

```bash
# View cache info
task registry-cue:cache:info

# List cached modules
task registry-cue:cache:list

# Show specific module
task registry-cue:cache:show MODULE=github.com/foo/bar@v1

# Clear cache
task cache:clear
```

## Advanced Usage

### Custom Registry

Set a different registry for CUE operations:

```bash
# In .env
CUE_REGISTRY=registry.opm.dev

# Or override per command
CUE_REGISTRY=registry.opm.dev task cue:mod:tidy
```

### Parallel Validation

Validate all packages simultaneously:

```bash
task validate:parallel
```

### Export to File

```bash
task cue:export:file OUTPUT=units.json FORMAT=json EXPR='units'
task cue:export:file OUTPUT=config.yaml FORMAT=yaml
```

### Module Dependency Management

```bash
# View dependency graph
task cue:mod:graph

# Add new dependency
task cue:mod:get MODULE=github.com/external/lib@v1

# Update all dependencies
task cue:mod:tidy
```

## Troubleshooting

### Task not found

```bash
# Ensure you're in the opm/ directory
cd /path/to/open-platform-model/opm

# List available tasks
task --list
```

### Registry not accessible

```bash
# Check registry health
task registry-docker:health

# Restart registry
task registry-docker:restart

# View logs for errors
task registry-docker:logs:tail
```

### Cache issues

```bash
# Clear all caches
task cache:clear
task registry-docker:reset

# Rebuild
task setup
```

### CUE validation errors

```bash
# Check formatting first
task cue:fmt:check

# Format files
task fmt

# Validate with all errors shown
task cue:vet:strict
```

### Module publish fails

```bash
# Run comprehensive validation
task publish:validate

# Check registry is running
task registry:status

# Check module.cue syntax
task publish:info

# Try force publish for testing
task publish:local:force VERSION=v0.0.1-test
```

## Dependencies

- **Taskfile** v3.x - Task runner
- **CUE** v0.15.0+ - CUE language tools
- **Docker** - For OCI registry
- **jq** - JSON processing (for registry queries)
- **curl** - HTTP requests (for registry API)

### Install Dependencies

**macOS:**
```bash
brew install go-task cue docker jq
```

**Linux (Debian/Ubuntu):**
```bash
# Taskfile
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d

# CUE
go install cuelang.org/go/cmd/cue@latest

# Docker (varies by distro)
# See: https://docs.docker.com/engine/install/

# jq
apt install jq
```

## Tips

1. **Use tab completion**: Many shells support Taskfile tab completion
2. **Check task summaries**: `task --summary <task-name>` shows detailed info
3. **Watch mode**: Keep `task watch:vet` running in a terminal for instant feedback
4. **Parallel tasks**: Taskfile automatically parallelizes independent tasks
5. **Environment override**: You can override any variable: `VERSION=v1.0.0 task publish:local`

## Getting Help

- List all tasks: `task --list`
- Show task details: `task --summary <task-name>`
- View task documentation: Check this file or inline task `desc` fields

## Contributing

When adding new tasks:

1. Add to appropriate modular file in `.tasks/`
2. Use descriptive names with colons for hierarchy
3. Include `desc` for short description
4. Include `summary` for detailed help
5. Add to this documentation under relevant section

## Related Documentation

- [Taskfile Documentation](https://taskfile.dev/)
- [CUE Documentation](https://cuelang.org/docs/)
- [OPM Architecture](../core/docs/architecture/)
- [CLAUDE.md](CLAUDE.md) - Master context for Claude
