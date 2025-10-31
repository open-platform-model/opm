# Open Platform Model - OPM Repository Context

This file provides comprehensive guidance for working with the OPM documentation and specification repository.

## Repository Overview

This is the **opm** repository (`github.com/open-platform-model/opm`), which contains:

- **Project vision and documentation** - High-level architecture and concepts
- **V1 API specifications** - Formal definitions of OPM v1alpha1 API
- **V1 core implementation** - Reference CUE implementation of v1 definitions
- **Benchmarks and research** - Performance testing and exploration

The OPM project consists of multiple independent repositories:

- **[core](https://github.com/open-platform-model/core)** - V0 CUE-based framework (legacy)
- **[elements](https://github.com/open-platform-model/elements)** - V0 element catalog (legacy)
- **[cli](https://github.com/open-platform-model/cli)** - Go-based OPM CLI tool
- **[opm](https://github.com/open-platform-model/opm)** - This repository (documentation and v1 specs)

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
│   ├── UNIT_DEFINITION.md       # Unit specification
│   ├── TRAIT_DEFINITION.md      # Trait specification
│   ├── POLICY_DEFINITION.md     # Policy specification
│   ├── CLI_SPEC.md              # CLI design specification
│   ├── FQN_SPEC.md              # Fully qualified names
│   ├── DOCUEMENTATION_PLAN.md   # Documentation strategy
│   └── module_redesign/         # Module architecture research
│       ├── VALUE_REFERENCES_DIAGRAM.md
│       ├── VALUE_REFERENCES_EXPLAINED.md
│       ├── IMPLEMENTATION_PLAN.md
│       └── FLATTENING_QUICK_START.md
├── v1/                   # V1 core implementation
│   ├── core/            # Core CUE definitions
│   │   ├── unit.cue              # UnitDefinition schema
│   │   ├── trait.cue             # TraitDefinition schema
│   │   ├── blueprint.cue         # BlueprintDefinition schema
│   │   ├── component.cue         # ComponentDefinition schema
│   │   ├── module.cue            # Module schemas (ModuleDefinition, Module, ModuleRelease)
│   │   ├── policy.cue            # PolicyDefinition schema
│   │   ├── scope.cue             # ScopeDefinition schema
│   │   ├── common.cue            # Common types and utilities
│   │   ├── *_testing.cue         # Test definitions
│   │   └── cue.mod/module.cue    # CUE module definition
│   ├── units/           # Unit library (future)
│   ├── traits/          # Trait library (future)
│   ├── blueprints/      # Blueprint library (future)
│   ├── policies/        # Policy library (future)
│   └── modules/         # Module examples (future)
├── benchmarks/          # Performance testing
│   └── precompilation_tests/
│       ├── elements/
│       └── modules/
└── cue.mod/            # CUE module definition for repository
```

## Quick Navigation

### By Task Type

**Understanding OPM vision?** → [README.md](README.md)

**Understanding architecture?** → [docs/architecture.md](docs/architecture.md)

**Working on v1 specifications?** → [V1ALPHA1_SPECS/](V1ALPHA1_SPECS/)

**Working on v1 core implementation?** → [v1/core/](v1/core/)

**Understanding definition types?** → [V1ALPHA1_SPECS/DEFINITION_TYPES.md](V1ALPHA1_SPECS/DEFINITION_TYPES.md)

**Understanding module architecture?** → [V1ALPHA1_SPECS/module_redesign/](V1ALPHA1_SPECS/module_redesign/)

**Comparing OPM to Helm?** → [docs/opm-vs-helm.md](docs/opm-vs-helm.md)

**Contributing?** → See [Development Workflow](#development-workflow) below

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

- `unit`: Unit definition specification
- `trait`: Trait definition specification
- `blueprint`: Blueprint definition specification
- `policy`: Policy definition specification
- `component`: Component definition specification
- `module`: Module architecture specification
- `cli`: CLI specification
- `fqn`: Fully qualified name specification

**V1 Core (`v1/`)**:

- `unit`: Unit CUE implementation
- `trait`: Trait CUE implementation
- `blueprint`: Blueprint CUE implementation
- `component`: Component CUE implementation
- `module`: Module CUE implementation
- `policy`: Policy CUE implementation
- `scope`: Scope CUE implementation
- `testing`: Test definitions

**Benchmarks**:

- `bench`: Benchmark additions/changes
- `perf`: Performance testing

#### Good Examples

```bash
✓ docs(vision): clarify component vs blueprint relationship
✓ feat(unit): add UnitDefinition schema to v1/core
✓ docs(architecture): add module lifecycle diagram
✓ feat(spec): add policy definition specification
✓ test(component): add component composition tests
✓ chore(deps): update CUE to v0.14.2
```

#### What to Avoid

```bash
✗ docs(vision): add comprehensive documentation explaining the relationship between components and blueprints

   This commit adds detailed documentation...
   [long multi-paragraph description]

   Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>

✗ Added some fixes and improvements
✗ WIP
✗ Update files
```

**Key Points**:

- Keep the description to one line
- Be specific about what changed
- Use the appropriate type and scope
- NO Claude attribution
- NO multi-paragraph messages

### Working with V1 Core Definitions

The [v1/core/](v1/core/) directory contains the reference CUE implementation of v1alpha1 definitions.

#### Testing V1 Definitions

```bash
# Navigate to v1/core directory
cd v1/core

# Format all CUE files
cue fmt .

# Validate definitions
cue vet .

# Run tests
cue vet *_testing.cue

# Export specific definition
cue export -e '#UnitDefinition' unit.cue
```

#### Adding New Definitions

When adding new definition types to v1:

1. **Create the specification** in `V1ALPHA1_SPECS/`
2. **Implement the CUE schema** in `v1/core/`
3. **Add tests** in `v1/core/*_testing.cue`
4. **Update documentation** in `docs/` and `README.md`

#### V1 Definition Structure

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

## Architecture Quick Reference

### V1 Core Concepts

**Units + Traits + Blueprints** → **Components** → **Modules** → **Platform Resources**

For detailed architecture, see [docs/architecture.md](docs/architecture.md)

#### Definition Type Hierarchy

```
Building Blocks (v1/core)
├── Unit: Container, Volume, ConfigMap, Secret (what exists)
├── Trait: Replicas, HealthCheck, Expose, RestartPolicy (how it behaves)
├── Blueprint: StatelessWorkload, StatefulWorkload, DaemonWorkload (blessed patterns)
├── Component: Units + Traits OR Blueprint reference
├── Policy: Security, compliance, residency rules
└── Scope: Where policies apply, component relationships
```

See [V1ALPHA1_SPECS/DEFINITION_TYPES.md](V1ALPHA1_SPECS/DEFINITION_TYPES.md) for complete details.

#### Module Architecture (Three Layers)

```
1. ModuleDefinition
   Created by developers and/or platform teams
   Components + scopes + value schema
   Platform teams can extend via CUE unification

2. Module
   Compiled/optimized form (flattened)
   Blueprints expanded to Units + Traits
   Ready for binding with concrete values

3. ModuleRelease
   Deployed instance
   Module reference + concrete values
   Targets specific environment
```

See [V1ALPHA1_SPECS/module_redesign/](V1ALPHA1_SPECS/module_redesign/) for module architecture details.

#### Component Composition Examples

```cue
// Using Blueprint (recommended)
webServer: #ComponentDefinition & {
    #StatelessWorkload  // Blueprint: Container + Replicas + traits
    #Expose             // Trait: Service exposure

    spec: {
        statelessWorkload: {
            container: {image: "nginx:latest", ports: [{containerPort: 80}]}
            replicas: {count: 3}
        }
        expose: {type: "LoadBalancer"}
    }
}

// Using Units + Traits (advanced)
custom: #ComponentDefinition & {
    #Container    // Unit
    #Replicas     // Trait
    #HealthCheck  // Trait

    spec: {
        container: {image: "myapp:latest"}
        replicas: {count: 2}
        healthCheck: {liveness: {httpGet: {path: "/health", port: 8080}}}
    }
}
```

## Common Development Commands

### CUE Commands (v1/core)

```bash
# Format all CUE files
cue fmt ./v1/core/...

# Validate v1 core definitions and tests
cd v1/core
cue vet .

# Show all errors
cue vet --all-errors .

# Export specific definition as JSON
cue export -e '#UnitDefinition' unit.cue --out json
cue export -e '#ComponentDefinition' component.cue --out json
cue export -e '#ModuleDefinition' module.cue --out json

# Evaluate specific value
cue eval -e '#UnitDefinition' unit.cue
```

### Documentation Commands

```bash
# Validate markdown links (if you have a link checker)
find . -name "*.md" -exec markdown-link-check {} \;

# Generate table of contents (if using doctoc)
doctoc README.md
doctoc docs/architecture.md

# Spell check documentation (if using aspell)
aspell check README.md
```

### Git Workflow

```bash
# Check status
git status

# Common workflow
git add .
git commit -m "docs(vision): clarify module architecture"
git push origin main

# Create version tag (for documentation releases)
git tag -a v1alpha1 -m "v1alpha1 specification release"
git push origin v1alpha1

# View commit history
git log --oneline --graph --all

# Check which remote you're using
git remote -v
```

## Project-Specific Context

### What is This Repository?

The **opm** repository serves as:

1. **Vision and Documentation Hub** - High-level architecture, concepts, and vision for OPM
2. **V1 API Specification** - Formal specifications for v1alpha1 API
3. **Reference Implementation** - CUE-based reference implementation of v1 core definitions
4. **Research and Planning** - Benchmarks, design proposals, and future planning

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
- **[DEFINITION_STRUCTURE.md](V1ALPHA1_SPECS/DEFINITION_STRUCTURE.md)** - Definition structure patterns and API versioning
- **[UNIT_DEFINITION.md](V1ALPHA1_SPECS/UNIT_DEFINITION.md)** - Unit specification
- **[TRAIT_DEFINITION.md](V1ALPHA1_SPECS/TRAIT_DEFINITION.md)** - Trait specification
- **[POLICY_DEFINITION.md](V1ALPHA1_SPECS/POLICY_DEFINITION.md)** - Policy specification
- **[CLI_SPEC.md](V1ALPHA1_SPECS/CLI_SPEC.md)** - CLI design specification
- **[FQN_SPEC.md](V1ALPHA1_SPECS/FQN_SPEC.md)** - Fully qualified name specification
- **[module_redesign/](V1ALPHA1_SPECS/module_redesign/)** - Module architecture research and design

#### V1 Core Implementation

Located in [v1/core/](v1/core/):

- **[unit.cue](v1/core/unit.cue)** - UnitDefinition schema
- **[trait.cue](v1/core/trait.cue)** - TraitDefinition schema
- **[blueprint.cue](v1/core/blueprint.cue)** - BlueprintDefinition schema
- **[component.cue](v1/core/component.cue)** - ComponentDefinition schema
- **[module.cue](v1/core/module.cue)** - Module schemas (ModuleDefinition, Module, ModuleRelease)
- **[policy.cue](v1/core/policy.cue)** - PolicyDefinition schema
- **[scope.cue](v1/core/scope.cue)** - ScopeDefinition schema
- **[common.cue](v1/core/common.cue)** - Common types and utilities
- **[*_testing.cue](v1/core/)** - Test definitions for each schema

### V1 vs V0 Terminology

**V0 (legacy in core/ and elements/ repositories):**

- Uses "Element" terminology (Primitive, Modifier, Composite, Custom)
- `#Element`, `#Component`, `#Module`

**V1 (this repository, v1/core/):**

- Uses "Definition" terminology (Unit, Trait, Blueprint, Policy)
- `#UnitDefinition`, `#TraitDefinition`, `#BlueprintDefinition`, `#ComponentDefinition`, `#ModuleDefinition`
- Clearer separation of concerns and responsibilities

### Related Repositories

- **[core](https://github.com/open-platform-model/core)** - V0 CUE framework (legacy, being replaced by v1)
- **[elements](https://github.com/open-platform-model/elements)** - V0 element catalog (legacy)
- **[cli](https://github.com/open-platform-model/cli)** - Go-based CLI tool (will implement v1 when stable)

## Important Notes

### Repository Purpose

This repository is primarily for:

- **Documentation** - Vision, architecture, and specifications
- **V1 Specification** - Formal API definitions for v1alpha1
- **Reference Implementation** - CUE schemas for v1 core definitions
- **Research** - Design proposals, benchmarks, and exploration

This is NOT:

- The implementation repository (that's [core](https://github.com/open-platform-model/core) for v0)
- The CLI repository (that's [cli](https://github.com/open-platform-model/cli))
- The element catalog (that's [elements](https://github.com/open-platform-model/elements) for v0)

### Versioning

**OPM follows [Semantic Versioning v2.0.0](https://semver.org) for all repositories.**

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

#### When to Bump Versions (for this repository)

**MAJOR (x.0.0):**

- Breaking API changes in v1 specifications
- Incompatible changes to definition structure
- Major architectural changes requiring updates to implementations

**MINOR (0.x.0):**

- New definition types added to specifications
- New features added to v1 API (backward compatible)
- Significant documentation additions
- Deprecations (but not removals)

**PATCH (0.0.x):**

- Bug fixes in specifications or schemas
- Documentation improvements and clarifications
- Internal refactoring with no API impact
- Typo fixes and formatting improvements

#### Initial Development (v0.x.x)

- Version `v0.x.x` indicates initial development
- Breaking changes may occur in MINOR versions during v0
- Once v1 API is stable, bump to `v1.0.0`

#### Pre-release Identifiers

- `alpha` - Early development, incomplete features (currently v1alpha1)
- `beta` - Feature complete, testing phase
- `rc` - Release candidate, production-ready pending validation

#### Versioning Across OPM Repositories

All OPM repositories follow Semver v2 independently:

- **core**: V0 framework versions
- **elements**: V0 element catalog versions
- **cli**: CLI tool versions
- **opm**: V1 specification versions (this repository)

### Development Best Practices

1. **Format CUE files before committing**: `cue fmt ./v1/core/...`
2. **Validate v1 schemas**: `cd v1/core && cue vet .`
3. **Run tests**: `cd v1/core && cue vet *_testing.cue`
4. **Keep commits focused and concise**
5. **Use appropriate scopes** in commit messages (see [Commit Message Guidelines](#commit-message-guidelines))
6. **Update specifications** when changing v1/core schemas
7. **Keep documentation in sync** with specifications and implementation

## Getting Help

- **Specification Issues**: [opm repository issues](https://github.com/open-platform-model/opm/issues)
- **Implementation Issues**: [core repository issues](https://github.com/open-platform-model/core/issues)
- **CLI Issues**: [cli repository issues](https://github.com/open-platform-model/cli/issues)
- **General Discussion**: [OPM Discussions](https://github.com/open-platform-model/opm/discussions)

## Related Documentation

### Within This Repository

- [README.md](README.md) - Project vision and overview
- [ROADMAP.md](ROADMAP.md) - Development roadmap
- [TODO.md](TODO.md) - Task tracking and research items
- [docs/architecture.md](docs/architecture.md) - Detailed architecture
- [docs/opm-vs-helm.md](docs/opm-vs-helm.md) - Comparison with Helm
- [V1ALPHA1_SPECS/](V1ALPHA1_SPECS/) - Complete v1 API specifications

### Other Repositories

- [core](https://github.com/open-platform-model/core) - V0 implementation
- [elements](https://github.com/open-platform-model/elements) - V0 element catalog
- [cli](https://github.com/open-platform-model/cli) - CLI tool

---

**Last Updated**: 2025-10-31
