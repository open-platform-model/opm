# OPM CLI v1

Command-line tool for working with Open Platform Model (OPM) modules.

## Overview

OPM CLI is a tool for validating, inspecting, and working with OPM modules. An OPM module is a **directory** containing a `module_definition.cue` file that defines infrastructure and application configuration using CUE.

### Key Concepts

- **OPM Module**: A directory containing `module_definition.cue` (required) and optionally other `.cue` files
- **CUE Unification**: All `.cue` files in the same package are automatically unified by CUE
- **Directory-Based**: Commands accept directory paths (e.g., `.`, `./my-app`), not file paths

## Installation

### Building from Source

```bash
# Clone the repository
cd opm/cli

# Build the CLI
task build

# The binary will be at ./bin/opm
./bin/opm version

# Or install to $GOPATH/bin
task install
```

### Requirements

- **Go 1.24+** (for building from source)
- **CUE v0.15.0+** (required for `opm mod tidy` command - must be in PATH)

## Usage

### Global Flags

- `--verbose`, `-v` - Verbose output
- `--config <path>` - Config file path
- `--output-dir <path>` - Output directory

### Commands

#### `opm version`

Show version information for the CLI and CUE.

```bash
# Text output (default)
opm version

# JSON output
opm version --json
```

**Example Output:**

```
opm version v0.1.0
CUE version v0.15.0
Build date: 2025-11-05T17:53:39Z
```

#### `opm mod vet <module-directory>`

Validate an OPM module directory.

**What it validates:**

- Module directory exists and contains `module_definition.cue`
- Required fields: `apiVersion`, `kind`, `metadata.name`
- Valid `kind` (ModuleDefinition, Module, ModuleRelease)
- Correct `apiVersion` (opm.dev/v1/core)
- CUE syntax and constraints
- Component structure (if present)

```bash
# Validate current directory
opm mod vet .

# Validate specific module
opm mod vet ./my-app

# Validate with verbose output
opm mod vet ./my-app --verbose
```

**Example Output:**

```
✓ Module 'my-app' is valid
```

**Error Example:**

```
Error: validation failed: missing required field 'metadata.name'
```

#### `opm mod show <module-directory>`

Display information about an OPM module.

**Information displayed:**

- Module name, kind, and API version
- Description (if present)
- Directory path
- List of components
- List of scopes
- Labels

```bash
# Show in text format (default)
opm mod show ./my-app

# Show in JSON format
opm mod show ./my-app --format json

# Show in YAML format
opm mod show ./my-app --format yaml

# Short form
opm mod show ./my-app -f json
```

**Example Output (text):**

```
Module: my-app
Kind: ModuleDefinition
API Version: opm.dev/v1/core
Description: My application module
Directory: ./my-app

Components (2):
  - web
  - api

Scopes (1):
  - production

Labels:
  env: production
  team: platform
```

**Example Output (JSON):**

```json
{
  "name": "my-app",
  "kind": "ModuleDefinition",
  "apiVersion": "opm.dev/v1/core",
  "description": "My application module",
  "directory": "./my-app",
  "components": ["web", "api"],
  "scopes": ["production"],
  "labels": {
    "env": "production",
    "team": "platform"
  }
}
```

#### `opm mod init <name> [flags]`

Initialize a new OPM module from a template.

**Features:**

- Creates module directory with proper structure
- Generates `module_definition.cue` from template
- Creates `cue.mod/module.cue` with correct CUE module path format
- Three built-in templates: simple, standard, advanced (embedded in CLI binary)

**Flags:**

- `--template <name>` - Template to use (simple|standard|advanced, default: standard)
- `--version <version>` - Initial version (default: v0.1.0)
- `--description <text>` - Module description

```bash
# Initialize with standard template (default)
opm mod init my-app

# Initialize with simple template
opm mod init my-app --template simple

# Initialize with advanced template
opm mod init my-app --template advanced

# Initialize with version and description
opm mod init my-app --version v1.0.0 --description "My application"
```

**Templates:**

- **simple**: Single file, minimal structure (best for learning or quick prototypes)
- **standard**: Multi-file organization (recommended for most projects)
- **advanced**: Full structure with scopes and policies (for complex applications)

**Generated Structure (standard template):**

```
my-app/
├── module_definition.cue     # Main module definition
├── components.cue            # Component definitions
├── values.cue                # Value schema
├── cue.mod/
│   └── module.cue            # CUE module configuration
└── README.md                 # Template documentation
```

#### `opm mod tidy`

Tidy module dependencies using CUE's module management.

**What it does:**

- Ensures `cue.mod/module.cue` matches actual dependencies
- Removes unused dependencies
- Adds missing dependencies
- Uses OPM's registry configuration (not CUE central registry)

**Requirements:**

- **CUE Binary**: CUE v0.15.0+ must be installed and in PATH
- **Module Directory**: Must run from directory containing `cue.mod/module.cue`

```bash
# Tidy dependencies (from module directory)
cd my-app
opm mod tidy

# The command will:
# 1. Check CUE binary exists and version >= v0.15.0
# 2. Check cue.mod/module.cue exists
# 3. Run: cue mod tidy (with CUE_REGISTRY set to OPM registry)
```

**CUE Version Checking:**

- Minimum: v0.15.0 (required)
- Tested: v0.15.x
- Behavior: Fails if < v0.15.0, warns if > v0.15.x

**Registry Integration:**

`opm mod tidy` automatically uses the registry configured in `~/.opm/config.cue` (default: `localhost:5000`). This ensures dependencies are pulled from your OPM registry instead of CUE's central registry.

**Error Messages:**

```bash
# If CUE not installed
cue binary not found in PATH

CUE is required for 'opm mod tidy'.
Install from: https://cuelang.org/docs/install/
Or use: go install cuelang.org/go/cmd/cue@v0.15.0

# If incompatible version
incompatible CUE version: v0.14.0

OPM requires CUE v0.15.0 or newer.
Install: go install cuelang.org/go/cmd/cue@v0.15.0
```

## Module Structure

An OPM module is a directory containing:

1. **`module_definition.cue`** (required) - The main module definition
2. **Additional `.cue` files** (optional) - Automatically unified with module_definition.cue
3. **`cue.mod/module.cue`** (optional) - CUE module configuration for dependencies

### Simple Module Example

```
my-app/
├── module_definition.cue          # Main module definition
└── cue.mod/
    └── module_definition.cue      # CUE module config (optional)
```

**`module_definition.cue`:**

```cue
package myapp

apiVersion: "opm.dev/v1/core"
kind:       "ModuleDefinition"

metadata: {
 name:        "my-app"
 description: "My application"
}

components: {
 web: {
  workloadType: "Deployment"
  image:        "nginx:latest"
 }
}
```

### Standard Module Example (Multiple Files)

```
my-app/
├── module_definition.cue          # Main definition
├── components.cue      # Component definitions
├── values.cue          # Value schema
└── cue.mod/
    └── module_definition.cue
```

CUE automatically unifies all `.cue` files in the same package (same directory with same `package` declaration).

## Development

### Project Structure

```
cli/
├── cmd/opm/            # Main entry point
├── pkg/
│   ├── loader/         # CUE module loader
│   └── version/        # Version information
├── internal/
│   └── commands/       # Command implementations
│       ├── root.go     # Root command
│       ├── version.go  # Version command
│       └── mod/        # Module commands
│           ├── mod.go
│           ├── vet.go
│           └── show.go
├── testdata/           # Test fixtures
├── Taskfile.yml        # Task runner configuration
└── go.mod
```

### Available Tasks

```bash
# Build the CLI
task build

# Run tests
task test

# Run tests with verbose output
task test:verbose

# Generate coverage report
task test:coverage

# Format code
task fmt

# Run go vet
task vet

# Run all checks (fmt, vet, test)
task check

# Clean build artifacts
task clean

# Install to $GOPATH/bin
task install

# Run CLI with arguments
task run -- mod vet ./my-app
```

### Running Tests

```bash
# All tests
task test

# Specific package
go test ./pkg/loader -v

# With coverage
task test:coverage

# Watch mode (requires watchexec)
watchexec -e go task test
```

### Adding New Commands

1. Create command file in `internal/commands/` or `internal/commands/mod/`
2. Implement `cobra.Command` with `RunE` function
3. Add to parent command in `root.go` or `mod.go`
4. Write tests in `*_test.go` file
5. Update documentation

## Architecture

### CUE Integration

The CLI uses the official CUE Go SDK (cuelang.org/go) following recommended patterns:

- **Fresh Context Per Command**: Each command creates a new CUE context to avoid memory bloat
- **Directory-Based Loading**: Uses `load.Instances()` with directory paths
- **Automatic Unification**: CUE handles package unification across multiple files
- **Module Support**: Respects `cue.mod/module.cue` for dependency resolution

### Module Loading Flow

1. **Validate Directory**: Check that the path is a directory
2. **Check `module_definition.cue`**: Ensure required file exists
3. **Find Module Root**: Walk up to find `cue.mod/` (optional)
4. **Load Package**: Use CUE's `load.Instances()` to discover all `.cue` files
5. **Build Value**: Unify all files into single CUE value
6. **Validate**: Check OPM-specific structure and constraints

## Troubleshooting

### Common Errors

**Error: `module_definition.cue not found in directory`**

- Ensure your module directory contains a `module_definition.cue` file
- OPM modules require this file to be present

**Error: `path is not a directory`**

- Commands expect directory paths, not file paths
- Use `opm mod vet ./my-app`, not `opm mod vet ./my-app/module_definition.cue`

**Error: `missing required field 'apiVersion'`**

- Add `apiVersion: "opm.dev/v1/core"` to your module_definition.cue

**Error: `invalid kind`**

- Use valid kinds: `ModuleDefinition`, `Module`, or `ModuleRelease`

**Error: `language version too new`**

- Update CUE dependency: `go get cuelang.org/go@latest`
- Or update `cue.mod/module.cue` to use compatible version

## Contributing

### Code Guidelines

- Follow Go conventions and style
- Write tests for all new functionality
- Use `task check` before committing
- Keep commits focused and concise
- Follow conventional commit format: `type(scope): description`

### Testing

- Unit tests for all packages
- Integration tests with real module directories
- Use testify for assertions
- Create fixtures in `testdata/`

## License

See LICENSE file in the repository root.

## Related Documentation

- [OPM Project](../README.md) - Project overview and vision
- [V1 Specifications](../V1ALPHA1_SPECS/) - Detailed API specifications
- [CUE Language](https://cuelang.org/) - CUE documentation

## Roadmap

### Implemented Commands

- ✅ `opm version` - Version information
- ✅ `opm mod init` - Initialize new OPM modules from templates
- ✅ `opm mod vet` - Validate OPM modules
- ✅ `opm mod show` - Display module information
- ✅ `opm mod tidy` - Tidy module dependencies (wraps CUE)
- ✅ `opm config init` - Initialize OPM configuration
- ✅ `opm config show` - Display configuration

### Future Commands (Not Yet Implemented)

- `opm mod render` - Render ModuleDefinition to platform resources (Kubernetes YAML, etc.)
- `opm mod publish` - Publish modules to OCI registry
- `opm mod get` - Retrieve modules from OCI registry
- `opm bundle` - Bundle operations for collections of modules
- `opm registry` - Definition registry operations (list, search, describe)
- `opm provider` - Provider and transformer operations
- `opm dev` - Development tools (watch, inspect, diff, graph)
