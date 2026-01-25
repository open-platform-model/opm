# AGENTS.md - OPM Repository (Documentation & Specs)

## Overview

Landing project with docs, specs, benchmarks, and Taskfile automation.

## Project Structure

```text
├── .specify/          # Spec-driven development configuration
│   ├── memory/        # Constitution and memory files
│   ├── scripts/       # Automation scripts
│   └── templates/     # Templates for specs, plans, tasks, checklists
├── benchmarks/        # Performance benchmarks
│   └── rendering/     # Module rendering benchmarks
├── docs/              # End-user documentation
├── specs/             # Specifications
│   ├── 001-core-definitions-spec/
│   ├── 002-cli-spec/
│   ├── 003-taskfile-spec/
│   ├── 004-definition-resource/
│   ├── 005-definition-trait/
│   ├── 006-definition-policy-spec/
│   ├── 007-definition-blueprint-spec/
│   ├── 008-definition-status-spec/
│   ├── 009-definition-interface-spec/
│   ├── 010-definition-lifecycle-spec/
│   ├── 011-distribution-spec/
│   ├── 012-cli-module-template-spec/
│   └── 013-cli-render-spec/
├── README.md
└── Taskfile.yml
```

## Maintenance Notes

- **Project Structure Tree**: Update the tree above when adding new specs or directories.

## Build/Test Commands

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
- Three-layer module: ModuleDefinition -> Module -> ModuleRelease.

## Glossary

See [full glossary](docs/glossary.md) for detailed definitions.

### Personas

- **Infrastructure Operator** - Operates underlying infrastructure (clusters, cloud, networking)
- **Module Author** - Develops and maintains ModuleDefinitions with sane defaults
- **Platform Operator** - Curates module catalog, bridges infrastructure and end-users
- **End-user** - Consumes modules via ModuleRelease with concrete values
