# OPM repository guide

## Purpose

Landing project for Open Platform Model — internal docs, specs, benchmarks, Taskfile automation. Source of truth for specifications, glossary, and meta-project tooling. Public docs site lives separately in `opmodel.dev/`.

## Repository Rules

- `CONSTITUTION.md` is the principle source; `openspec/config.yaml` is normative. Governance: Constitution supersedes this file on conflict.
- Follow [Semantic Versioning v2.0.0](https://semver.org) for all repos.
- Follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) for all repos. Format: `type(scope): description` — scopes: `vision`, `architecture`, `resource`, `trait`, `cli`, `module`.
- Tone: extremely concise. No preamble/postamble. Skip explanations unless asked. Only show changed code, not entire files.

## Entrypoint

Read these on entry:

- `CLAUDE.md` — repo working rules (this file).
- `CONSTITUTION.md` — full design principles (Type Safety First, Separation of Concerns, Composability, Declarative Intent, Portability by Design, Semantic Versioning, Simplicity & YAGNI).
- `openspec/config.yaml` — normative source for OpenSpec artifact rules.
- `docs/STYLE.md` — doc prose style rules (read before writing/editing any docs).
- `docs/glossary.md` — **canonical glossary for entire workspace**. All other repos link to it; don't duplicate.
- `Taskfile.yml` — authoritative build/test entrypoints.

## Repository Layout

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

## Build And Dev Commands

### Task commands

- Format: `task fmt` or `task module:fmt:all`
- Validate: `task vet` or `task module:vet MODULE=core`
- Single module: `task module:vet MODULE=examples`
- Registry: `task registry:start`, `task registry:stop`
- Benchmarks: `cd benchmarks/rendering && go test -bench=.`

### Spec creation scripts

`create-new-feature.sh` creates new feature branch + spec directory. `--category` organizes specs:

- `--category application` → `specs/application-model/`
- `--category platform` → `specs/platform-model/`
- `--category root` (default) → `specs/` (root level)

Examples:

```bash
.specify/scripts/bash/create-new-feature.sh "Add bundle definitions" --category application
.specify/scripts/bash/create-new-feature.sh "Add runtime API" --category platform
.specify/scripts/bash/create-new-feature.sh "Update taskfile" --category root
```

## Coding Standards

- **CUE**: `#` for defs, `_` for hidden fields, `!` for required. See `CUE_GUIDE.md`.
- **Specs**: Markdown in `V1ALPHA1_SPECS/`. Consistent heading structure.
- **Commits**: `type(scope): description` — scopes: `vision`, `architecture`, `resource`, `trait`, `cli`, `module`.

### Patterns

- Definition structure: `apiVersion`, `kind`, `metadata` (with `name!`, `fqn`), `#spec`.
- Two-layer module: Module → ModuleRelease.

## Working Style for Agents

- Read `docs/STYLE.md` before writing/editing any docs in this repo.
- New glossary terms: follow format in `docs/glossary.md` — one-sentence definition, optional CUE snippet, correct table. Don't duplicate terms in other repos; link to the canonical glossary instead.
- Update the Project Structure tree above when adding new specs/directories.

### Glossary — personas (quick reference)

See [full glossary](docs/glossary.md) for detailed definitions.

- **Infrastructure Operator** — Operates underlying infra (clusters, cloud, networking).
- **Module Author** — Develops/maintains ModuleDefinitions with sane defaults.
- **Platform Operator** — Curates module catalog, bridges infra and end-users.
- **End-user** — Consumes modules via ModuleRelease with concrete values.
