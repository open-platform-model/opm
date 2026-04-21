# OPM Repository (Documentation & Specs)

## Overview

Landing project w/ docs, specs, benchmarks, Taskfile automation.

## Constitution

Project follows **Open Platform Model Constitution**.
Read `CONSTITUTION.md` for full design principles.
All agents MUST read/adhere to `openspec/config.yaml` (normative source).

**Core Principles:**

1. **Type Safety First**: All defs in CUE. Validate at definition time.
2. **Separation of Concerns**: Module (Dev) -> ModuleRelease (Consumer). Clear ownership boundaries.
3. **Composability**: Defs compose w/o implicit coupling. Resources, Traits, Blueprints independent.
4. **Declarative Intent**: Express WHAT, not HOW. Provider-specific steps in ProviderDefinitions.
5. **Portability by Design**: Defs must be runtime-agnostic.
6. **Semantic Versioning**: SemVer v2.0.0 + Conventional Commits v1 required.
7. **Simplicity & YAGNI**: Justify complexity. Prefer explicit over implicit.

**Governance**: Constitution supersedes this file on conflict.

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

ADRs capture significant technical decisions w/ context and consequences.

- Location: `adr/`
- Template: `adr/TEMPLATE.md`
- Naming: `NNN-kebab-case-title.md` (three-digit, zero-padded)

### Creating a new ADR

1. Copy `adr/TEMPLATE.md` to `adr/NNN-title.md` using next available number.
2. Set status to `Proposed`.
3. Fill in Context, Decision, Consequences.
4. Update status to `Accepted` once agreed.

### Updating an ADR

- Never delete ADR — update status instead.
- Retire: set status to `Deprecated`.
- Replace: set status to `Superseded by ADR-NNN`, create new ADR.
- One decision per ADR.

## Maintenance Notes

- **Project Structure Tree**: Update tree above when adding new specs/directories.

## Build/Test Commands

### Spec Creation Scripts

#### create-new-feature.sh

Creates new feature branch + spec directory. `--category` organizes specs:

- `--category application` → `specs/application-model/`
- `--category platform` → `specs/platform-model/`
- `--category root` (default) → `specs/` (root level)

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

- Extremely concise - only essential info
- No preamble/postamble
- Skip explanations unless asked
- Only show changed code, not entire files

## Versioning

- **Follow [Semantic Versioning v2.0.0](https://semver.org) for all repos.**
- **Follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) for all repos.**

## Code Style

- **CUE**: `#` for defs, `_` for hidden fields, `!` for required. See CUE_GUIDE.md.
- **Specs**: Markdown in V1ALPHA1_SPECS/. Consistent heading structure.
- **Commits**: `type(scope): description` - scopes: vision/architecture/resource/trait/cli/module.

## Patterns

- Def structure: `apiVersion`, `kind`, `metadata` (w/ `name!`, `fqn`), `#spec`.
- Two-layer module: Module -> ModuleRelease.

## Documentation Style

- Read `docs/STYLE.md` before writing/editing any docs in this repo.
- `docs/glossary.md` = **canonical glossary for entire workspace**. All other repos link to it; don't duplicate.
- New terms: follow format in `docs/glossary.md`: one-sentence def, optional CUE snippet, correct table.

## Glossary

See [full glossary](docs/glossary.md) for detailed defs.

### Personas

- **Infrastructure Operator** - Operates underlying infra (clusters, cloud, networking)
- **Module Author** - Develops/maintains ModuleDefinitions w/ sane defaults
- **Platform Operator** - Curates module catalog, bridges infra and end-users
- **End-user** - Consumes modules via ModuleRelease w/ concrete values

## Active Technologies

- YAML (Taskfile v3) + `go-task/task` v3.x, `cue` v0.15.0+, `go` 1.21+, `golangci-lint`, `watchexec` (003-taskfile-spec)
- Go 1.25+ (002-cli-spec)
- Local filesystem (~/.opm/), OCI registries (002-cli-spec)

## Recent Changes

- 005-validation: Added spec for `opm mod vet` using Go CUE SDK for native module validation
- 003-taskfile-spec: Added YAML (Taskfile v3) + `go-task/task` v3.x, `cue` v0.15.0+, `go` 1.21+, `golangci-lint`, `watchexec`
