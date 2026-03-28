# AGENTS.md - OPM Repository (Documentation & Specs)

## Overview

Landing project with docs, specs, benchmarks, and Taskfile automation.

## Constitution

This project follows the **Open Platform Model Constitution**.
Read `CONSTITUTION.md` for the full list of design principles.
All agents MUST read and adhere to `openspec/config.yaml` (normative source).

**Core Principles:**

1. **Type Safety First**: All definitions in CUE. Validation at definition time.
2. **Separation of Concerns**: Module (Dev) -> ModuleRelease (Consumer). Clear ownership boundaries.
3. **Composability**: Definitions compose without implicit coupling. Resources, Traits, Blueprints are independent.
4. **Declarative Intent**: Express WHAT, not HOW. Provider-specific steps in ProviderDefinitions.
5. **Portability by Design**: Definitions must be runtime-agnostic.
6. **Semantic Versioning**: SemVer v2.0.0 and Conventional Commits v1 required.
7. **Simplicity & YAGNI**: Justify complexity. Prefer explicit over implicit.

**Governance**: The constitution supersedes this file in case of conflict.

## Project Structure

```text
├── adr/               # Architecture Decision Records
├── .specify/          # Spec-driven development configuration
│   ├── memory/        # Constitution and memory files
│   ├── scripts/       # Automation scripts
│   └── templates/     # Templates for specs, plans, tasks, checklists
├── benchmarks/        # Performance benchmarks
│   └── rendering/     # Module rendering benchmarks
├── docs/              # End-user documentation
├── specs/             # Specifications
│   ├── application-model/              # Application Model (index only, specs moved to core/)
│   ├── cli/                            # CLI specifications
│   │   ├── cli-core-spec/              # CLI configuration, initialization, project structure
│   │   ├── cli-build-spec/             # Render pipeline and mod build
│   │   ├── cli-deploy-spec/            # Deployment lifecycle (apply, delete, diff, status)
│   │   └── cli-validation-spec/        # Module validation with Go CUE SDK
│   ├── core/                           # Core type specifications
│   │   ├── core-types-spec/            # Resource, Trait, Blueprint definitions
│   │   └── module-composition-spec/    # Component, Module, ModuleRelease
│   ├── deferred/                       # Deferred specifications
│   │   ├── bundle-spec/                # Bundle definitions (deferred)
│   │   ├── governance-spec/            # Policy, Scope definitions (deferred)
│   │   ├── interface-spec/             # Interface definitions (deferred)
│   │   ├── lifecycle-spec/             # Lifecycle definitions (deferred)
│   │   └── status-spec/                # Status definitions (deferred)
│   ├── development/                    # Development tooling specifications
│   │   └── taskfile-spec/              # Development Taskfile specification
│   ├── distribution/                   # Distribution specifications
│   │   ├── distribution-spec/          # OCI-based module distribution
│   │   └── template-spec/              # Module template distribution
│   ├── platform/                       # Platform specifications
│   │   ├── catalog-spec/               # Module catalog and tiered values
│   │   └── platform-adapter-spec/      # Platform definitions (Provider, Transformer)
│   └── platform-model/                 # Platform Model (index only, specs moved to platform/)
├── README.md
└── Taskfile.yml
```

## Architecture Decision Records

ADRs capture significant technical decisions with their context and consequences.

- Location: `adr/`
- Template: `adr/TEMPLATE.md`
- Naming: `NNN-kebab-case-title.md` (three-digit, zero-padded)

### Creating a new ADR

1. Copy `adr/TEMPLATE.md` to `adr/NNN-title.md` using the next available number.
2. Set status to `Proposed`.
3. Fill in Context, Decision, and Consequences.
4. Update status to `Accepted` once the decision is agreed on.

### Updating an ADR

- Never delete an ADR — update its status instead.
- To retire a decision: set status to `Deprecated`.
- To replace a decision: set status to `Superseded by ADR-NNN` and create the new ADR.
- One decision per ADR.

## Maintenance Notes

- **Project Structure Tree**: Update the tree above when adding new specs or directories.

## Build/Test Commands

### Spec Creation Scripts

#### create-new-feature.sh

Creates a new feature branch and spec directory. Use `--category` to organize specs:

- `--category application` → Places spec in `specs/application-model/`
- `--category platform` → Places spec in `specs/platform-model/`
- `--category root` (default) → Places spec in `specs/` (root level)

Examples:

```bash
.specify/scripts/bash/create-new-feature.sh "Add bundle definitions" --category application
.specify/scripts/bash/create-new-feature.sh "Add runtime API" --category platform
.specify/scripts/bash/create-new-feature.sh "Update taskfile" --category root
```

### Task Commands

- Format: `task fmt` or `task module:fmt:all`
- Validate: `task vet` or `task module:vet MODULE=core`
- Single module: `task module:vet MODULE=examples`
- Registry: `task registry:start`, `task registry:stop`
- Benchmarks: `cd benchmarks/rendering && go test -bench=.`

## Tone and style

- Be extremely concise - only output essential information
- No preamble or postamble
- Skip explanations unless asked
- Only show changed code, not entire files

## Versioning

- **Follow [Semantic Versioning v2.0.0](https://semver.org) for all repositories.**
- **Follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) for all repositories.**

## Code Style

- **CUE**: Use `#` for definitions, `_` for hidden fields, `!` for required. See CUE_GUIDE.md.
- **Specs**: Markdown in V1ALPHA1_SPECS/. Use consistent heading structure.
- **Commits**: `type(scope): description` - scopes: vision/architecture/resource/trait/cli/module.

## Patterns

- Definition structure: `apiVersion`, `kind`, `metadata` (with `name!`, `fqn`), `#spec`.
- Two-layer module: Module -> ModuleRelease.

## Documentation Style

- Read `docs/STYLE.md` before writing or editing any documentation in this repo.
- `docs/glossary.md` is the **canonical glossary for the entire workspace**. All other repos link to it; do not duplicate it.
- When adding a new term, follow the format in `docs/glossary.md`: one-sentence definition, optional CUE snippet, placed in the correct table.

## Glossary

See [full glossary](docs/glossary.md) for detailed definitions.

### Personas

- **Infrastructure Operator** - Operates underlying infrastructure (clusters, cloud, networking)
- **Module Author** - Develops and maintains ModuleDefinitions with sane defaults
- **Platform Operator** - Curates module catalog, bridges infrastructure and end-users
- **End-user** - Consumes modules via ModuleRelease with concrete values

## Active Technologies

- YAML (Taskfile v3) + `go-task/task` v3.x, `cue` v0.15.0+, `go` 1.21+, `golangci-lint`, `watchexec` (003-taskfile-spec)
- Go 1.25+ (002-cli-spec)
- Local filesystem (~/.opm/), OCI registries (002-cli-spec)

## Recent Changes

- 005-validation: Added specification for `opm mod vet` command using Go CUE SDK for native module validation
- 003-taskfile-spec: Added YAML (Taskfile v3) + `go-task/task` v3.x, `cue` v0.15.0+, `go` 1.21+, `golangci-lint`, `watchexec`
