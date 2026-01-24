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
│   ├── 001-opm-cue-spec/
│   ├── 002-interface-spec/
│   ├── 003-lifecycle-spec/
│   ├── 004-cli-spec/
│   ├── 005-taskfile-spec/
│   └── 006-cli-module-template-spec/
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

## Personas

### Module Developer

A developer of an OPM module. Responsible for maintaing the ModuleDefinition.

### Platform team

A team of operators consuming Modules and optinally modifying them to fit their needs. Responsible for the platform catalog (a catalog of curated modules).
Consumes either an OPM Module (optimized and unchanged) or a ModuleDefinition when platform specifc modifications are required.

### End-user

The user that consumes a ModuleRelease.

## Terms and Definitions

- `ModuleDefinition` - A CUE OPM definition that acts as the RAW input for the model.
- `CompiledModule` - A CUE OPM definition that acts as the optimized (flattened) version of the ModuleDefintion.
- `ModuleRelease` - A CUE OPM definition that is used by end-users to reference either a ModuleDefintion or a CompiledModule for deployment.
- `` -  
