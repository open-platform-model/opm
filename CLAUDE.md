# Open Platform Model - Master Context for Claude

This file provides comprehensive guidance for working with the Open Platform Model (OPM) monorepo.

## Repository Structure

OPM is organized as a monorepo containing multiple independent git repositories:

```text
open-platform-model/
 core/          # CUE-based type system and framework (separate git repo)
 elements/      # Official element catalog (separate git repo)
 cli/           # Go-based OPM CLI tool (separate git repo)
 opm/           # Documentation and project overview (separate git repo)
 enhancements/  # Design proposals and research (separate git repo)
 Makefile.registry  # Local OCI registry management
```

### Subprojects

**core/** - CUE-based framework

- Element type system and base definitions
- Component and module architecture
- Provider interface and transformer system
- Core element implementations
- See [core/CLAUDE.md](core/CLAUDE.md) for detailed context

**elements/** - Element catalog (separate repository)

- Official OPM element library
- Organized by category: workload, data, connectivity
- Published as CUE modules to OCI registry
- Has its own versioning and releases

**cli/** - OPM CLI tool

- Go-based command-line tool
- Runtime computation and transformer execution
- Module building and rendering
- Element registry caching
- See [cli/CLAUDE.md](cli/CLAUDE.md) for detailed context

**opm/** - Documentation and overview

- Project vision and architecture
- User-facing documentation
- Getting started guides
- See [opm/README.md](opm/README.md) for project overview

**enhancements/** - Design proposals

- Research and exploration
- Design proposals and RFCs
- Experimental features

## Quick Navigation

### By Task Type

**Working on elements?** � `core/elements/core/` and see [core/CLAUDE.md](core/CLAUDE.md#adding-new-elements)

**Working on CLI?** � `cli/` and see [cli/CLAUDE.md](cli/CLAUDE.md)

**Working on module system?** � `core/module.cue` and see [core/CLAUDE.md](core/CLAUDE.md#module-architecture)

**Working on providers?** � `core/provider.cue` and see [core/CLAUDE.md](core/CLAUDE.md#provider-interface)

**Need architecture context?** � [core/docs/architecture/](core/docs/architecture/)

**Publishing modules?** � See [Makefile.registry Usage](#makefileregistry-usage) below

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

#### Scopes by Project

**Core (`core/`)**:

- `elements`: Element definitions
- `schema`: Schema changes
- `provider`: Provider/transformer work
- `component`: Component model changes
- `module`: Module definitions
- `registry`: Element registry

**CLI (`cli/`)**:

- `loader`: CUE file loading
- `registry`: Element registry management
- `transformer`: Transformer execution
- `renderer`: Renderer execution
- `cmd`: CLI commands
- `cache`: Caching system

**Elements (`elements/`)**:

- `workload`: Workload elements
- `data`: Data elements
- `connectivity`: Connectivity elements
- `kubernetes`: Kubernetes native resources

**Documentation**:

- `docs`: Architecture documentation
- `claude`: CLAUDE.md updates
- `examples`: Example modules

#### Good Examples

```bash
 feat(elements): add PodSecurity primitive
 fix(cli): resolve cache invalidation on file change
 refactor(provider): simplify transformer matching
 docs(architecture): update module lifecycle diagram
 test(examples): add stateful workload example
 chore(deps): update CUE to v0.14.2
```

#### What to Avoid

```bash
L feat(elements): add new PodSecurity primitive element for Kubernetes security contexts

   This commit adds a new PodSecurity primitive element that enables...
   [long multi-paragraph description]

   Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>

L Added some fixes and improvements
L WIP
L Update files
```

**Key Points**:

- Keep the description to one line
- Be specific about what changed
- Use the appropriate type and scope
- NO Claude attribution
- NO multi-paragraph messages

### Makefile.registry Usage

The `Makefile.registry` provides targets for managing a local OCI registry for developing and testing CUE modules. This is essential for testing module dependencies locally before publishing to remote registries.

#### Quick Reference

```bash
# Start the local registry (localhost:5000)
make -f Makefile.registry start

# Check status and list all modules
make -f Makefile.registry status

# List all modules with versions
make -f Makefile.registry list

# Show tags for a specific module
make -f Makefile.registry tags MODULE=github.com/open-platform-model/core

# View registry logs
make -f Makefile.registry logs

# Stop the registry (keeps data)
make -f Makefile.registry stop

# Clean everything (removes container and data)
make -f Makefile.registry clean

# Show help
make -f Makefile.registry help
```

#### Configuration

The registry runs with the following defaults:

- **Container Name**: `opm-registry`
- **Port**: `5000`
- **Image**: `registry:2`
- **Data Directory**: `.registry-data/` (in project root)

#### Integration with Module Publishing

##### Complete Workflow

```bash
# 1. Start local registry
make -f Makefile.registry start

# 2. Publish core module locally
cd core
make publish-local VERSION=v0.1.0
cd ..

# 3. Publish elements module locally
cd elements
make publish-local VERSION=v0.1.0
cd ..

# 4. Verify modules are published
make -f Makefile.registry status

# 5. Configure CLI to use local registry
export CUE_REGISTRY=localhost:5000

# 6. Build and test CLI with local modules
cd cli
make build
./bin/opm mod build ../core/examples/example_module.cue --output ./test-output --verbose
```

##### Publishing to Local Registry

Each subproject (core, elements) has a Makefile with publishing targets:

```bash
# From core/ directory
make validate              # Validate CUE files
make publish-local         # Publish to localhost:5000
make info                  # Show module information

# From elements/ directory
make validate              # Validate CUE files
make publish-local         # Publish to localhost:5000
make info                  # Show module information and dependencies
```

##### Using Local Registry in Development

```bash
# Set environment variable for local registry
export CUE_REGISTRY=localhost:5000

# Now CUE commands will use local registry
cue mod tidy
cue mod get github.com/open-platform-model/core@v0.1.0
```

#### Registry API

The registry exposes a standard OCI distribution API:

```bash
# List all repositories
curl http://localhost:5000/v2/_catalog

# List tags for a repository
curl http://localhost:5000/v2/github.com/open-platform-model/core/tags/list

# Get manifest for specific version
curl http://localhost:5000/v2/github.com/open-platform-model/core/manifests/v0.1.0
```

#### Common Issues

**Registry not accessible:**

```bash
# Check if container is running
docker ps -f name=opm-registry

# Restart if needed
make -f Makefile.registry stop
make -f Makefile.registry start
```

**Module not found after publishing:**

```bash
# Verify module was published
make -f Makefile.registry list

# Check specific module tags
make -f Makefile.registry tags MODULE=github.com/open-platform-model/core

# View registry logs for errors
make -f Makefile.registry logs
```

**Cache issues with CLI:**

```bash
# Clear CLI cache
cd cli
./bin/opm elements cache clear

# Or manually remove cache
rm -rf ~/.opm/cache/
```

### CUE Module System

OPM uses CUE's native module system for element registry imports. Understanding CUE module paths and package imports is essential for working with OPM configuration.

#### Module vs Package Path

- **Module path**: The canonical name of a CUE module (e.g., `github.com/open-platform-model/elements@v0`)
- **Package path**: Module path + subdirectory (e.g., `github.com/open-platform-model/elements@v0/core`)

A module is a collection of packages. The `@v0` suffix indicates the major version.

#### Import Syntax

**Correct:**

```cue
import "github.com/open-platform-model/elements@v0/core"
import opm "github.com/open-platform-model/elements@v0/core"
```

**Incorrect:**

```cue
import "github.com/open-platform-model/elements@v0:core"  // Wrong: colon instead of slash
import "github.com/open-platform-model/elements/core@v0"  // Wrong: version at end
```

#### Module Structure

Each CUE module requires a `cue.mod/module.cue` file:

```cue
module: "github.com/open-platform-model/elements@v0"
language: {
    version: "v0.14.2"
}
source: {
    kind: "git"
}
deps: {
    "github.com/open-platform-model/core@v0": {
        v:       "v0.1.0"
        default: true
    }
}
```

**Key fields:**

- `module`: Module path with major version suffix
- `language.version`: Minimum CUE version required
- `source.kind`: Source type (`git`, `self`, etc.)
- `deps`: Module dependencies with versions

#### OPM Module Organization

```
elements/                                    # Module root
├── cue.mod/module.cue                      # Module: github.com/open-platform-model/elements@v0
├── core/                                   # Package subdirectory
│   ├── registry.cue                        # Package: core
│   ├── workload_primitive_container.cue
│   └── ...
└── kubernetes/                             # Another package subdirectory
    └── ...
```

**Import paths:**

- Core elements: `github.com/open-platform-model/elements@v0/core`
- Kubernetes: `github.com/open-platform-model/elements@v0/kubernetes`

#### Publishing Modules

See [Makefile.registry Usage](#makefileregistry-usage) above for local registry setup.

```bash
# Publish to local registry
cd elements
make publish-local VERSION=v0.1.0

# Publish to remote registry (requires authentication)
make publish VERSION=v0.1.0
```

#### Using Modules in Config

The OPM CLI config uses standard CUE imports:

```cue
package opmconfig

import (
    // Package path = module-path/package-subdirectory
    opm_elements "github.com/open-platform-model/elements@v0/core"
)

// Extract element registry
_opmElements: opm_elements.#ElementRegistry.elements

// Make available to OPM
elements: _opmElements
```

**Important:**

- Package paths use forward slashes (`/`), not colons
- Major version suffix (`@v0`) goes with module name, before subdirectory
- CUE resolves imports using `cue.mod/module.cue` dependency declarations

#### Version Management

OPM maintains a centralized CUE version constant:

- **Current version**: v0.14.2
- **Location**: `cli/pkg/version/cue.go`
- **Runtime check**: `version.CheckCUEVersion()` validates installed CUE matches OPM requirements

All `cue.mod/module.cue` files should use the same language version.

## Architecture Quick Reference

### Core Concepts

**Elements** � **Components** � **Modules** � **Renderers** � **Platform Resources**

#### Element Hierarchy

```
Elements (building blocks)
 Primitive: Container, Volume, ConfigMap, Secret
 Modifier: Replicas, HealthCheck, Expose, RestartPolicy
 Composite: StatelessWorkload, StatefulWorkload, DaemonWorkload
 Custom: Platform-specific extensions
```

#### Module Layers

```
1. ModuleDefinition
    Created by developers and/or platform teams
    Components + scopes + value schema
    Platform teams can inherit and extend via CUE unification

2. Module
    Compiled/optimized form (flattened)
    Blueprints expanded to Units + Traits
    Ready for binding with concrete values

3. ModuleRelease
    Deployed instance
    Module reference + concrete values
    Targets specific environment
```

#### Component Types

- **Workload Components**: Deployable services (stateless, stateful, daemon, task, scheduled-task, function)
- **Resource Components**: Shared resources (volumes, configs, secrets)

### Element Composition

```cue
// Using composite (recommended)
webServer: #Component & {
    #StatelessWorkload  // Container + Replicas + modifiers
    #Expose             // Service exposure

    statelessWorkload: {
        container: {image: "nginx:latest", ports: [{containerPort: 80}]}
        replicas: {count: 3}
    }
    expose: {type: "LoadBalancer"}
}

// Using primitives + modifiers (advanced)
custom: #Component & {
    #Container    // Primitive
    #Replicas     // Modifier
    #HealthCheck  // Modifier

    container: {image: "myapp:latest"}
    replicas: {count: 2}
    healthCheck: {liveness: {httpGet: {path: "/health", port: 8080}}}
}
```

## Common Development Commands

### CUE Commands (for core and elements)

```bash
# Format all CUE files
cue fmt ./...

# Validate all definitions
cue vet ./...

# Show all errors
cue vet --all-errors ./...

# Export as JSON
cue export ./... --out json

# Export specific definition
cue export -e '#ModuleDefinition' module.cue --out json

# Evaluate specific value
cue eval . -e '#Component'

# Module management
cue mod init <module-name>
cue mod tidy
cue mod get <module>@<version>
```

### Go Commands (for CLI)

```bash
# Build CLI
cd cli
make build              # Builds to bin/opm
# or
go build -o opm ./cmd/opm

# Run tests
make test
go test ./...

# Format and lint
make fmt
make vet
make check             # fmt + vet + test

# Install to $GOPATH/bin
make install

# Clean build artifacts
make clean

# Development: build and run
make run
./bin/opm --help
```

### CLI Usage Commands

```bash
# Set element registry path
export OPM_ELEMENT_REGISTRY_PATH=/path/to/core/elements/core

# Build a module
./bin/opm mod build path/to/module.cue --output ./output

# With verbose output
./bin/opm mod build module.cue --output ./k8s --verbose

# With timing report
./bin/opm mod build module.cue --output ./k8s --timings

# Element registry commands
./bin/opm elements list
./bin/opm elements resolve elements.opm.dev/core/v0.StatelessWorkload
./bin/opm elements cache clear
```

### Git Workflow

```bash
# Each subproject is a separate git repository
cd core && git status
cd elements && git status
cd cli && git status

# Common workflow
git add .
git commit -m "feat(elements): add new primitive"
git push origin main

# Create version tag (for releases)
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

## Project-Specific Context

### Core Framework

The core framework defines OPM's fundamental abstractions:

- **Elements**: Building blocks (primitive, modifier, composite, custom)
- **Components**: Element compositions (workload or resource)
- **Modules**: Complete application definitions
- **Scopes**: Cross-cutting concerns (platform or module level)
- **Providers**: Platform-specific transformer system

**Key Files**:

- `element.cue` - Element type system
- `component.cue` - Component composition
- `module.cue` - Module architecture
- `provider.cue` - Provider interface
- `elements/elements.cue` - Element registry

**Detailed Documentation**: See [core/CLAUDE.md](core/CLAUDE.md)

### CLI Tool

The OPM CLI is a Go-based tool that handles runtime operations:

- Module loading and parsing
- Element registry management with caching
- Transformer matching and execution
- Parallel execution for performance
- YAML/JSON output rendering

**Key Packages**:

- `cmd/opm` - CLI commands
- `pkg/loader` - CUE file loading
- `pkg/registry` - Element registry with caching
- `pkg/transformer` - Transformer execution
- `pkg/renderer` - Output rendering

**Detailed Documentation**: See [cli/CLAUDE.md](cli/CLAUDE.md)

### Elements Catalog

Official element library organized by category:

- **Workload**: Container, StatelessWorkload, StatefulWorkload, DaemonWorkload, TaskWorkload, ScheduledTask
- **Data**: Volume, ConfigMap, Secret, SimpleDatabase
- **Connectivity**: NetworkScope, Expose
- **Kubernetes**: Native K8s resource primitives

Elements are published as separate CUE modules to OCI registries.

**File Organization**: `{category}_{kind}_{name}.cue`

- Example: `workload_primitive_container.cue`, `data_composite_simple_database.cue`

### Documentation Project (opm/)

Project overview, vision, and user-facing documentation:

- Getting started guides
- Architecture overview
- Use cases and examples
- Roadmap and inspiration

## Important Notes

### Repository Independence

- Each subproject (core, elements, cli, opm, enhancements) is a **separate git repository**
- Changes in one subproject don't automatically affect others
- Use local registry workflow to test cross-project dependencies

### Versioning

**OPM follows [Semantic Versioning v2.0.0](https://semver.org) for all subprojects.**

#### Version Format

```text
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

**Components:**

- **MAJOR**: Incremented for incompatible API changes or breaking changes
- **MINOR**: Incremented for backward-compatible functionality additions
- **PATCH**: Incremented for backward-compatible bug fixes
- **PRERELEASE** (optional): Identifiers like `alpha`, `beta`, `rc.1`
- **BUILD** (optional): Build metadata (ignored in precedence)

#### Version Examples

**Stable releases:**

- `v1.0.0` - Initial stable release
- `v1.2.3` - Minor feature addition with patches
- `v2.0.0` - Major version with breaking changes

**Pre-release versions:**

- `v1.0.0-alpha` - Alpha release for v1.0.0
- `v1.0.0-beta.1` - First beta release
- `v0.1.0-rc.1` - Release candidate

**With build metadata:**

- `v1.0.0+20130313144700` - With timestamp
- `v1.0.0-alpha+001` - Alpha with build number

#### When to Bump Versions

**MAJOR (x.0.0):**

- Breaking API changes in schemas
- Incompatible element definition changes
- Major architectural changes requiring user action

**MINOR (0.x.0):**

- New elements added to catalog
- New features added (backward compatible)
- Deprecations (but not removals)

**PATCH (0.0.x):**

- Bug fixes in existing elements
- Documentation improvements
- Internal refactoring with no API impact

#### Initial Development (v0.x.x)

- Version `v0.x.x` indicates initial development
- Breaking changes may occur in MINOR versions during v0
- Once stable, bump to `v1.0.0`

#### Pre-release Identifiers

- `alpha` - Early development, incomplete features
- `beta` - Feature complete, testing phase
- `rc` - Release candidate, production-ready pending validation

#### Versioning by Subproject

All OPM subprojects follow Semver v2 independently:

- **core**: Element schema and framework versions
- **elements**: Element catalog versions
- **cli**: CLI tool versions
- **opm**: Documentation versions (if applicable)

Core and elements versions may diverge based on their release cycles. The CLI tracks core/elements versions via dependencies and maintains its own Semver v2 version.

### CUE vs Go Separation

- **CUE**: Schema definitions, type constraints, validation logic
- **Go**: Runtime computation, algorithms, file I/O, execution orchestration
- Never reimplement CUE's constraint system in Go

### Development Best Practices

1. **Always format before committing**: `cue fmt ./...` or `go fmt ./...`
2. **Validate changes**: `cue vet ./...` or `go test ./...`
3. **Test with local registry** before publishing to remote
4. **Keep commits focused and concise**
5. **Use appropriate scopes** in commit messages
6. **Clear CLI cache** when debugging module issues

## Getting Help

- **Core Issues**: [core repository issues](https://github.com/open-platform-model/core/issues)
- **CLI Issues**: [cli repository issues](https://github.com/open-platform-model/cli/issues)
- **General Discussion**: [OPM Discussions](https://github.com/open-platform-model/opm/discussions)
- **Documentation**: See subproject CLAUDE.md files and docs/ directories

## Related Documentation

- [core/CLAUDE.md](core/CLAUDE.md) - Comprehensive core framework context
- [cli/CLAUDE.md](cli/CLAUDE.md) - CLI architecture and development
- [core/docs/architecture/](core/docs/architecture/) - Deep architecture documentation
- [opm/README.md](opm/README.md) - Project vision and overview
- [core/docs/architecture/element.md](core/docs/architecture/element.md) - Element system architecture

---

**Last Updated**: 2025-10-27
