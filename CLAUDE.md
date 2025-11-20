# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Open Platform Model - OPM Repository Context

This file provides comprehensive guidance for working with the OPM documentation and specification repository.

## Repository Overview

This is the **opm** repository (`github.com/open-platform-model/opm`), which contains:

- **Project vision and documentation** - High-level architecture and concepts
- **V1 API specifications** - Formal definitions of OPM v1alpha1 API
- **V1 core implementation** - Reference CUE implementation of v1 definitions
- **CLI** - Go-based reference implementation of the OPM CLI
- **Benchmarks and research** - Performance testing and exploration

The OPM project consists of multiple independent repositories:

- **[opm](https://github.com/open-platform-model/opm)** - This repository (V1 implementation)

## Repository Structure

```text
opm/
├── README.md              # Project vision and high-level overview
├── ROADMAP.md            # Development roadmap by phases
├── TODO.md               # Task tracking and research items
├── CLAUDE.md             # This file - context for AI assistance
├── docs/                 # Architecture documentation
│   ├── architecture.md   # Detailed architecture explanation
│   └── opm-vs-helm.md   # Comparison with Helm
├── V1ALPHA1_SPECS/       # Formal v1alpha1 API specifications
│   ├── DEFINITION_TYPES.md      # Core definition types deep dive
│   ├── DEFINITION_STRUCTURE.md  # Definition structure patterns
│   ├── RESOURCE_DEFINITION.md   # Resource specification
│   ├── TRAIT_DEFINITION.md      # Trait specification
│   ├── POLICY_DEFINITION.md     # Policy specification
│   ├── PROVIDER_DEFINITION.md   # Provider specification
│   ├── TRANSFORMER_MATCHING.md  # Transformer matching logic
│   ├── CLI_SPEC.md              # CLI design specification
│   ├── FQN_SPEC.md              # Fully qualified names
│   └── module_redesign/         # Module architecture research
├── v1/                   # V1 core implementation
│   ├── core/            # Core CUE definitions
│   │   ├── resource.cue         # ResourceDefinition schema
│   │   ├── trait.cue            # TraitDefinition schema
│   │   ├── blueprint.cue        # BlueprintDefinition schema
│   │   ├── component.cue        # ComponentDefinition schema
│   │   ├── module.cue           # Module schemas
│   │   ├── policy.cue           # PolicyDefinition schema
│   │   ├── provider.cue         # Provider schema
│   │   ├── transformer.cue      # Transformer schema
│   │   ├── renderer.cue         # Renderer schema
│   │   └── scope.cue            # ScopeDefinition schema
│   ├── resources/       # Resource implementations
│   ├── traits/          # Trait implementations
│   ├── blueprints/      # Blueprint implementations
│   ├── policies/        # Policy implementations
│   ├── providers/       # Provider implementations
│   ├── schemas/         # Shared schemas
│   ├── examples/        # Example workflows
│   └── registry/        # Registry package definitions
├── cli/                 # Go-based CLI implementation
│   ├── cmd/opm/        # Main entry point
│   ├── pkg/            # Public reusable packages
│   │   ├── flatten/    # Flattening engine
│   │   ├── provider/   # Provider loading and execution
│   │   ├── transformer/# Transformer matching and execution
│   │   ├── renderer/   # Output rendering
│   │   ├── loader/     # CUE module loader
│   │   ├── template/   # OCI template management
│   │   ├── version/    # Version information
│   │   ├── config/     # Configuration management
│   │   ├── logger/     # Structured logging
│   │   └── ui/         # Terminal UI components
│   ├── internal/       # Internal CLI logic
│   │   ├── commands/   # Command implementations
│   │   │   ├── mod/    # Module commands
│   │   │   ├── config/ # Config commands
│   │   │   ├── provider/# Provider commands
│   │   │   └── registry/# Registry commands
│   │   ├── appcontext/ # Application context
│   │   └── registry/   # Registry client
│   ├── testdata/       # Test fixtures
│   └── Taskfile.yml    # CLI-specific tasks
├── .tasks/             # Task automation system
│   ├── config.yml      # Centralized module configuration
│   ├── scripts/        # Bash scripts
│   ├── core/           # CUE operations
│   ├── registry/       # Docker registry management
│   └── modules/        # Module operations
└── benchmarks/         # Performance testing
```

## Quick Navigation

### By Task Type

**Understanding OPM vision?** → [README.md](README.md)

**Understanding architecture?** → [docs/architecture.md](docs/architecture.md)

**Working on v1 specifications?** → [V1ALPHA1_SPECS/](V1ALPHA1_SPECS/)

**Working on v1 core implementation?** → [v1/core/](v1/core/)

**Working on CLI?** → [cli/](cli/)

**Understanding definition types?** → [V1ALPHA1_SPECS/DEFINITION_TYPES.md](V1ALPHA1_SPECS/DEFINITION_TYPES.md)

**Understanding module architecture?** → [V1ALPHA1_SPECS/module_redesign/](V1ALPHA1_SPECS/module_redesign/)

**Understanding provider/transformer system?** → [V1ALPHA1_SPECS/PROVIDER_DEFINITION.md](V1ALPHA1_SPECS/PROVIDER_DEFINITION.md)

**Comparing OPM to Helm?** → [docs/opm-vs-helm.md](docs/opm-vs-helm.md)

## Development Workflow

### Commit Message Guidelines

**IMPORTANT**: Keep commit messages short and concise. Do NOT include Claude authorship references or "Generated with Claude Code" footers.

#### Format

```text
<type>(<scope>): <description>
```

#### Types

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `test`: Test additions/changes
- `chore`: Maintenance tasks

#### Scopes for OPM Repository

**Documentation (`docs/`)**:

- `vision`: README.md and high-level vision
- `architecture`: Architecture documentation
- `comparison`: OPM vs other tools (Helm, etc.)
- `roadmap`: ROADMAP.md updates
- `claude`: CLAUDE.md updates

**Specifications (`V1ALPHA1_SPECS/`)**:

- `resource`: Resource definition specification
- `trait`: Trait definition specification
- `blueprint`: Blueprint definition specification
- `policy`: Policy definition specification
- `provider`: Provider definition specification
- `transformer`: Transformer specification
- `component`: Component definition specification
- `module`: Module architecture specification
- `cli`: CLI specification
- `fqn`: Fully qualified name specification

**V1 Core (`v1/`)**:

- `resource`: Resource CUE implementation
- `trait`: Trait CUE implementation
- `blueprint`: Blueprint CUE implementation
- `component`: Component CUE implementation
- `module`: Module CUE implementation
- `policy`: Policy CUE implementation
- `provider`: Provider CUE implementation
- `transformer`: Transformer CUE implementation
- `scope`: Scope CUE implementation
- `examples`: Example workflows and compositions

**CLI (`cli/`)**:

- `cli`: General CLI changes
- `provider`: Provider system
- `transformer`: Transformer system
- `renderer`: Rendering system
- `loader`: CUE loader
- `template`: Template management
- `commands`: Command implementations

**Benchmarks**:

- `bench`: Benchmark additions/changes
- `perf`: Performance testing

#### Good Examples

```bash
✓ docs(vision): clarify component vs blueprint relationship
✓ feat(resource): add ResourceDefinition schema to v1/core
✓ feat(cli): add module render command
✓ feat(transformer): implement transformer matching logic
✓ test(provider): add transformer matching tests
✓ chore(deps): update CUE to v0.15.0
```

#### What to Avoid

```bash
✗ Long multi-paragraph commit messages
✗ Added some fixes and improvements
✗ WIP
✗ Update files
```

## CLI Development

### Building and Installing

```bash
# From cli/ directory
cd cli

# Build the CLI
task build
# Output: ./bin/opm

# Run tests
task test

# Run tests with verbose output
task test:verbose

# Run tests with coverage
task test:coverage

# Format code
task fmt

# Run go vet
task vet

# Run all checks (fmt, vet, test)
task check

# Install to $GOPATH/bin
task install

# Clean build artifacts
task clean

# Run directly with arguments
task run -- mod vet ./testdata/test-module
```

### CLI Architecture

The CLI is organized into clear layers:

**Entry Point:**

- `cmd/opm/main.go` - Minimal entry point, delegates to commands

**Commands (`internal/commands/`):**

- `root.go` - Root command configuration
- `mod/` - Module commands (init, vet, show, tidy, render, template)
- `config/` - Configuration commands (init, show)
- `provider/` - Provider commands (list, describe, validate)
- `registry/` - Registry commands (list, describe)

**Public Packages (`pkg/`):**

- `provider/` - Provider loading and execution
- `transformer/` - Transformer matching and execution
- `renderer/` - Output rendering (YAML, JSON)
- `loader/` - CUE module loading
- `template/` - OCI template management
- `version/` - Version information
- `config/` - Configuration management (~/.opm/config.cue)
- `logger/` - Structured logging with zap
- `ui/` - Terminal UI (tables, trees, styles)

**Internal Packages (`internal/`):**

- `appcontext/` - Application context (logger, config)
- `registry/` - OCI registry client

### Key Architectural Patterns

**1. CUE Integration**

The CLI uses the official CUE Go SDK (cuelang.org/go) following best practices:

- **Fresh Context Per Command**: Create new `cue.Context` for each command to avoid memory bloat
- **Directory-Based Loading**: Use `load.Instances()` with directory paths
- **Automatic Unification**: CUE handles package unification across multiple files
- **Module Support**: Respects `cue.mod/module.cue` for dependency resolution

**2. Provider/Transformer System (`pkg/provider/`, `pkg/transformer/`)**

The provider system enables platform-agnostic module definitions:

- **Provider**: Declares transformers and target platform (e.g., Kubernetes)
- **Transformer**: Converts Components to platform-specific resources
- **Matcher**: Determines which transformer to use for each component
- **Executor**: Runs transformers with proper context

```go
// Load provider
provider, err := providerPkg.LoadProvider(ctx, providerPath)

// Match transformer for component
transformer, err := transformerPkg.MatchTransformer(provider, component)

// Execute transformer
resources, err := transformerPkg.ExecuteTransformer(ctx, transformer, component, context)
```

See:

- `v1/core/provider.cue` - Provider schema
- `v1/core/transformer.cue` - Transformer schema
- `V1ALPHA1_SPECS/PROVIDER_DEFINITION.md` - Provider specification
- `V1ALPHA1_SPECS/TRANSFORMER_MATCHING.md` - Matching logic

**3. Configuration Management (`pkg/config/`)**

The CLI uses `~/.opm/config.cue` for configuration:

```cue
// ~/.opm/config.cue
config: {
    registry: "localhost:5000"  // Default registry
    cacheDir: "~/.opm/cache"    // Cache directory
    verbose:  false              // Verbose logging
}
```

The config package handles:

- Path resolution (OS-specific)
- Default configuration initialization
- Configuration loading and validation

**4. Logging (`pkg/logger/`)**

Structured logging with zap:

```go
// Get logger from context
logger := logger.FromContext(ctx)

// Log with fields
logger.Info("Loading module",
    zap.String("path", modulePath),
    zap.String("name", moduleName))
```

### Running Tests

```bash
# All tests
cd cli && task test

# Specific package
go test ./pkg/provider -v

# Specific test
go test ./pkg/transformer -v -run TestMatchTransformer

# With coverage
task test:coverage

# Watch mode (requires watchexec)
watchexec -e go task test
```

### Adding New Commands

1. Create command file in `internal/commands/` or subdirectory
2. Implement `cobra.Command` with `RunE` function
3. Add to parent command in appropriate file
4. Write tests in `*_test.go` file
5. Update CLI README.md

Example:

```go
// internal/commands/mod/example.go
package mod

import (
    "github.com/spf13/cobra"
)

func newExampleCommand() *cobra.Command {
    return &cobra.Command{
        Use:   "example",
        Short: "Example command",
        RunE: func(cmd *cobra.Command, args []string) error {
            // Implementation
            return nil
        },
    }
}

// Add to mod.go:
func NewModCommand() *cobra.Command {
    cmd := &cobra.Command{...}
    cmd.AddCommand(newExampleCommand())
    return cmd
}
```

## Working with V1 Core Definitions

The [v1/core/](v1/core/) directory contains the reference CUE implementation of v1alpha1 definitions.

### Validating V1 Definitions

```bash
# From repository root, use Taskfile commands

# Format all CUE files
task fmt

# Validate all packages
task vet

# Validate specific packages (shortcuts)
task core:vet
task resources:vet
task traits:vet
task blueprints:vet
task examples:vet

# Or use the module namespace directly
task module:vet MODULE=core
task module:vet MODULE=providers
```

### Adding New Definitions

When adding new definition types to v1:

1. **Create the specification** in `V1ALPHA1_SPECS/`
2. **Implement the CUE schema** in `v1/core/`
3. **Add implementations** in appropriate v1/ subdirectories
4. **Add examples** in `v1/examples/` demonstrating usage
5. **Update CLI** if new commands are needed
6. **Update documentation** in `docs/` and `README.md`

### V1 Definition Structure

All v1 definitions follow a consistent pattern:

```cue
#<Type>Definition: {
    apiVersion!: "opm.dev/v1/core"
    kind!:       "<Type>"
    metadata!: {
        apiVersion!: string  // Element-specific version
        name!:       string  // Definition name
        // ... other metadata
    }
    spec!: {
        // Type-specific specification
    }
}
```

## Using the Task System

The OPM repository uses [Taskfile](https://taskfile.dev) for automation. All tasks are organized under clear namespaces.

### Common Task Workflows

**Daily development:**

```bash
# Format and validate everything
task fmt
task vet

# Validate specific module
task core:vet
task module:vet MODULE=policies

# Check what changed since last publish
task module:checksum:check
```

**Module operations:**

```bash
# Publish a module
task module:publish MODULE=core
task module:publish MODULE=core VERSION=v1.2.3

# Version management
task module:show                      # Show all versions
task module:bump:patch MODULE=core    # Bump patch
task module:bump:minor MODULE=core    # Bump minor

# Dependencies
task module:deps:update MODULE=core   # Update one module's deps
task module:deps:update:all           # Update all deps
```

**Complete release workflow:**

```bash
# Auto-detect changes and publish (recommended)
task module:release

# This does:
# 1. Format all modules
# 2. Detect which modules changed
# 3. Bump patch version for changed modules only
# 4. Validate all
# 5. Publish only changed modules
# 6. Update checksums
# 7. Refresh dependencies
# 8. Create git tags
```

**CLI development:**

```bash
# Build and test CLI
cd cli
task build
task test
task check

# Install to $GOPATH/bin
task install

# Run specific command
task run -- mod vet ../v1/examples
```

### Task Namespaces

**`module:`** - All module operations (version, publish, deps, checksum, vet, fmt)

- `module:show`, `module:set`, `module:bump:*`
- `module:publish`, `module:publish:all`, `module:release`
- `module:deps:update`, `module:deps:update:all`
- `module:checksum:check`, `module:checksum:update`
- `module:vet`, `module:vet:all`, `module:fmt`, `module:fmt:all`

**`cue:`** - CUE-specific operations

- `cue:fmt`, `cue:vet`, `cue:mod:tidy`
- `cue:def`, `cue:import`, `cue:trim`

**`registry:`** - Docker OCI registry management

- `registry:start`, `registry:stop`, `registry:status`
- `registry:list`, `registry:cleanup`

### Adding New Modules

Adding a module is simple with the dynamic task system. See [.tasks/README.md](.tasks/README.md) for complete guide.

**Quick version:**

1. Add to `.tasks/config.yml` (in dependency order)
2. Create module directory structure
3. All tasks work automatically

See [.tasks/README.md](.tasks/README.md) for detailed instructions.

## Architecture Quick Reference

### V1 Core Concepts

**Resources + Traits + Blueprints** → **Components** → **Modules** → **Platform Resources**

For detailed architecture, see [docs/architecture.md](docs/architecture.md)

#### Definition Type Hierarchy

```text
Building Blocks (v1/core)
├── Resource: Container, Volume, ConfigMap, Secret (what exists)
├── Trait: Replicas, HealthCheck, Expose, RestartPolicy (how it behaves)
├── Blueprint: StatelessWorkload, StatefulWorkload (blessed patterns)
├── Component: Resources + Traits OR Blueprint reference
├── Policy: Security, compliance, residency rules
├── Scope: Where policies apply, component relationships
├── Provider: Platform-specific transformation system
└── Transformer: Component → platform resources
```

See [V1ALPHA1_SPECS/DEFINITION_TYPES.md](V1ALPHA1_SPECS/DEFINITION_TYPES.md) for complete details.

#### Module Architecture (Three Layers)

```text
1. ModuleDefinition
   Created by developers and/or platform teams
   Components + scopes + value schema
   Platform teams can extend via CUE unification

2. Module
   Compiled/optimized form (flattened)
   Blueprints expanded to Resources + Traits + Policies
   Ready for binding with concrete values

3. ModuleRelease
   Deployed instance
   Module reference + concrete values
   Targets specific environment
```

See [V1ALPHA1_SPECS/module_redesign/](V1ALPHA1_SPECS/module_redesign/) for module architecture details.

#### Provider/Transformer Architecture

```text
Module (flattened)
  ↓
Provider (e.g., Kubernetes)
  ↓
Transformer Matching
  ↓
Component → Platform Resources
  ↓
Renderer (YAML, JSON, etc.)
```

The provider system enables:

- Platform-agnostic module definitions
- Multiple target platforms from single module
- Declarative transformation logic in CUE
- Extensible transformer registry

See:

- [V1ALPHA1_SPECS/PROVIDER_DEFINITION.md](V1ALPHA1_SPECS/PROVIDER_DEFINITION.md)
- [V1ALPHA1_SPECS/TRANSFORMER_MATCHING.md](V1ALPHA1_SPECS/TRANSFORMER_MATCHING.md)
- [v1/providers/kubernetes/](v1/providers/kubernetes/)

## Project-Specific Context

### What is This Repository?

The **opm** repository serves as:

1. **Vision and Documentation Hub** - High-level architecture, concepts, and vision for OPM
2. **V1 API Specification** - Formal specifications for v1alpha1 API
3. **Reference Implementation** - CUE-based reference implementation of v1 core definitions
4. **CLI Implementation** - Go-based CLI for working with OPM modules
5. **Research and Planning** - Benchmarks, design proposals, and future planning

### Key Documentation Files

#### High-Level Vision

- **[README.md](README.md)** - Project vision, definition types, delivery flow
- **[ROADMAP.md](ROADMAP.md)** - Development roadmap organized by phases
- **[TODO.md](TODO.md)** - Task tracking, v0/v1/v1+ items, research topics
- **[docs/architecture.md](docs/architecture.md)** - Detailed architecture explanation
- **[docs/opm-vs-helm.md](docs/opm-vs-helm.md)** - Comparison with Helm

#### V1 Specifications

Located in [V1ALPHA1_SPECS/](V1ALPHA1_SPECS/):

- **[DEFINITION_TYPES.md](V1ALPHA1_SPECS/DEFINITION_TYPES.md)** - Deep dive on all definition types
- **[DEFINITION_STRUCTURE.md](V1ALPHA1_SPECS/DEFINITION_STRUCTURE.md)** - Definition structure patterns
- **[RESOURCE_DEFINITION.md](V1ALPHA1_SPECS/RESOURCE_DEFINITION.md)** - Resource specification
- **[TRAIT_DEFINITION.md](V1ALPHA1_SPECS/TRAIT_DEFINITION.md)** - Trait specification
- **[POLICY_DEFINITION.md](V1ALPHA1_SPECS/POLICY_DEFINITION.md)** - Policy specification
- **[PROVIDER_DEFINITION.md](V1ALPHA1_SPECS/PROVIDER_DEFINITION.md)** - Provider specification
- **[TRANSFORMER_MATCHING.md](V1ALPHA1_SPECS/TRANSFORMER_MATCHING.md)** - Transformer matching
- **[CLI_SPEC.md](V1ALPHA1_SPECS/CLI_SPEC.md)** - CLI design specification
- **[FQN_SPEC.md](V1ALPHA1_SPECS/FQN_SPEC.md)** - Fully qualified name specification
- **[module_redesign/](V1ALPHA1_SPECS/module_redesign/)** - Module architecture research

#### V1 Core Implementation

Located in [v1/core/](v1/core/):

- **[resource.cue](v1/core/resource.cue)** - ResourceDefinition schema
- **[trait.cue](v1/core/trait.cue)** - TraitDefinition schema
- **[blueprint.cue](v1/core/blueprint.cue)** - BlueprintDefinition schema
- **[component.cue](v1/core/component.cue)** - ComponentDefinition schema
- **[module.cue](v1/core/module.cue)** - Module schemas
- **[policy.cue](v1/core/policy.cue)** - PolicyDefinition schema
- **[provider.cue](v1/core/provider.cue)** - Provider schema
- **[transformer.cue](v1/core/transformer.cue)** - Transformer schema
- **[scope.cue](v1/core/scope.cue)** - ScopeDefinition schema
- **[common.cue](v1/core/common.cue)** - Common types and utilities

**V1 Implementations:**

- **[v1/resources/](v1/resources/)** - Resource implementations
- **[v1/traits/](v1/traits/)** - Trait implementations
- **[v1/blueprints/](v1/blueprints/)** - Blueprint implementations
- **[v1/policies/](v1/policies/)** - Policy implementations
- **[v1/providers/](v1/providers/)** - Provider implementations
- **[v1/schemas/](v1/schemas/)** - Shared schemas
- **[v1/examples/](v1/examples/)** - Example workflows

#### CLI Documentation

- **[cli/README.md](cli/README.md)** - Complete CLI documentation
- **[cli/pkg/](cli/pkg/)** - Public package documentation (see godoc)

### V1 vs V0 Terminology

**V0 (legacy):**

- Uses "Element" terminology (Primitive, Modifier, Composite, Custom)
- `#Element`, `#Component`, `#Module`

**V1 (this repository):**

- Uses "Definition" terminology (Resource, Trait, Blueprint, Policy)
- `#ResourceDefinition`, `#TraitDefinition`, `#BlueprintDefinition`, `#ComponentDefinition`, `#ModuleDefinition`
- Clearer separation of concerns and responsibilities

### Related Repositories

- **[core](https://github.com/open-platform-model/core)** - V0 CUE framework (legacy, being replaced by v1)
- **[elements](https://github.com/open-platform-model/elements)** - V0 element catalog (legacy)

## Important Notes

### Versioning

**OPM follows [Semantic Versioning v2.0.0](https://semver.org) for all repositories.**

See existing CLAUDE.md for complete versioning guidelines.

### Development Best Practices

#### Task Usage

1. **Format before committing**: `task fmt`
2. **Validate before committing**: `task vet`
3. **Check for changes**: `task module:checksum:check`
4. **Use tasks for repeatable workflows**

#### CLI Development

5. **Run tests before committing**: `cd cli && task test`
6. **Format Go code**: `cd cli && task fmt`
7. **Run all checks**: `cd cli && task check`
8. **Test CLI commands**: `task run -- <command> <args>`

#### Code Organization

9. **Keep commits focused and concise**
10. **Use appropriate scopes** in commit messages
11. **Update specifications** when changing v1/core schemas
12. **Add implementations** to appropriate subdirectories
13. **Add examples** in v1/examples/ to demonstrate new features
14. **Write tests** for all new CLI functionality
15. **Update documentation** in README.md and relevant specs

#### Testing

16. **Unit tests** for all Go packages
17. **Integration tests** with real CUE modules
18. **Use testify** for assertions in Go tests
19. **Create fixtures** in testdata/
20. **Test error cases** and edge conditions

## Getting Help

- **Specification Issues**: [opm repository issues](https://github.com/open-platform-model/opm/issues)
- **CLI Issues**: [opm repository issues](https://github.com/open-platform-model/opm/issues) (CLI tag)
- **General Discussion**: [OPM Discussions](https://github.com/open-platform-model/opm/discussions)

## Related Documentation

### Within This Repository

- [README.md](README.md) - Project vision and overview
- [ROADMAP.md](ROADMAP.md) - Development roadmap
- [TODO.md](TODO.md) - Task tracking and research items
- [docs/architecture.md](docs/architecture.md) - Detailed architecture
- [docs/opm-vs-helm.md](docs/opm-vs-helm.md) - Comparison with Helm
- [V1ALPHA1_SPECS/](V1ALPHA1_SPECS/) - Complete v1 API specifications
- [cli/README.md](cli/README.md) - CLI documentation
- [.tasks/README.md](.tasks/README.md) - Task system documentation
- [TASKFILE.md](TASKFILE.md) - Complete task reference

---

**Last Updated**: 2025-11-20
- Add to memory. Always use conventional commits when commiting to git
- When writing commit messages, claude should NEVER include itself as the author