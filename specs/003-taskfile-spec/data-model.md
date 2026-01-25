# Data Model: OPM Development Taskfile

**Feature**: 003-taskfile-spec  
**Date**: 2026-01-23

## Entities

### 1. Taskfile

The configuration file defining available tasks, their dependencies, and execution.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| version | string | Yes | Taskfile schema version (always "3") |
| silent | boolean | No | Suppress command echoing (default: true) |
| dotenv | string[] | No | Environment files to load |
| includes | map[string]Include | No | Included Taskfiles |
| vars | map[string]any | No | Global variables |
| tasks | map[string]Task | Yes | Task definitions |

**Relationships**:

- Root Taskfile includes sub-Taskfiles from `.tasks/` and sub-repositories
- Each Repository has exactly one Taskfile

### 2. Task

A named unit of work with commands, dependencies, and metadata.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| desc | string | Yes | Short description (shown in --list) |
| summary | string | No | Long description (shown in --summary) |
| cmds | Command[] | Yes | Commands to execute |
| deps | string[] | No | Tasks to run before this task |
| vars | map[string]any | No | Task-local variables |
| sources | string[] | No | Input files for caching |
| generates | string[] | No | Output files for caching |
| preconditions | Precondition[] | No | Conditions that must be true |
| status | string[] | No | Commands that determine if task is up-to-date |
| platforms | string[] | No | Platforms this task runs on |
| run | string | No | Execution mode: "always", "once", "when_changed" |

### 3. Include

Reference to an included Taskfile.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| taskfile | string | Yes | Path to included Taskfile |
| dir | string | No | Working directory for included tasks |
| internal | boolean | No | Hide from task listing |
| vars | map[string]any | No | Variables to pass to included Taskfile |

### 4. Module

A CUE module directory containing definitions and configuration.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Module identifier (e.g., "core", "schemas") |
| path | string | Yes | Relative path from repo root |
| enabled | boolean | Yes | Whether module is active |
| desc | string | No | Module description |
| dependencies | string[] | No | Other modules this depends on |

**Current Modules**:

| Name | Path | Dependencies |
|------|------|--------------|
| core | core/v0 | - |
| schemas | catalog/v0/schemas | - |
| resources | catalog/v0/resources | core, schemas |
| traits | catalog/v0/traits | core, schemas, resources |
| blueprints | catalog/v0/blueprints | core, schemas, resources, traits |
| policies | catalog/v0/policies | core, schemas |
| statusprobes | catalog/v0/statusprobes | core, schemas |

### 5. Repository

A sub-directory in the monorepo with its own Taskfile.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Repository identifier |
| path | string | Yes | Path relative to monorepo root |
| type | enum | Yes | "cue" or "go" |
| taskfile | string | Yes | Path to repository's Taskfile |

**Repositories**:

| Name | Path | Type | Tasks |
|------|------|------|-------|
| root | ./ | orchestration | setup, clean, env, all:*, ci |
| core | core/ | cue | fmt, vet, tidy, watch:*, module:* |
| catalog | catalog/ | cue | fmt, vet, tidy, watch:*, module:* |
| cli | cli/ | go | build, test, lint, clean |

### 6. Registry

An OCI-compliant container registry for distributing CUE modules.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Registry identifier |
| url | string | Yes | Registry URL |
| type | enum | Yes | "local" or "remote" |
| container | string | No | Docker container name (local only) |
| port | int | No | Port number (local only) |
| dataDir | string | No | Data persistence path (local only) |

**Registry Configurations**:

| Name | URL | Type | Container |
|------|-----|------|-----------|
| local | localhost:5000 | local | opm-registry |
| production | TBD | remote | - |

### 7. VersionRegistry

A file tracking versions of each module independently.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| path | string | Yes | Path to versions.yml |
| modules | map[string]string | Yes | Module name → SemVer version |

**Schema** (`versions.yml`):

```yaml
core: v0.1.0
schemas: v0.1.0
resources: v0.1.0
traits: v0.1.0
blueprints: v0.1.0
policies: v0.1.0
statusprobes: v0.1.0
```

## State Transitions

### Module Lifecycle

```
[Unvalidated] --fmt--> [Formatted] --vet--> [Validated] --tidy--> [Dependencies Resolved]
                                                                          |
                                                                          v
[Published] <--publish-- [Ready to Publish] <--version:bump-- [Dependencies Resolved]
```

### Registry Lifecycle

```
[Not Running] --start--> [Running] --stop--> [Stopped]
                           |
                           v
                      [Accepting Requests]
```

### Release Lifecycle

```
[Working] --changelog--> [Changelog Updated] --version:bump--> [Version Bumped]
                                                                      |
                                                                      v
[Released] <--release-- [Ready to Release] <--tag--> [Version Bumped]
```

## Validation Rules

### Task Naming

- Root tasks: `lowercase` or `lowercase:action` (e.g., `fmt`, `all:vet`)
- Namespaced tasks: `namespace:action` (e.g., `module:publish`, `registry:start`)
- Test tasks: `test`, `test:unit`, `test:integration`, `test:run`

### Version Format

- Must follow SemVer 2.0.0: `vMAJOR.MINOR.PATCH`
- Pre-release: `vMAJOR.MINOR.PATCH-alpha.1`
- Build metadata: `vMAJOR.MINOR.PATCH+build.123`

### Module Path Format

- Must include major version suffix: `opm.dev/core@v0`
- Path components: lowercase, alphanumeric, hyphens allowed

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| CUE_REGISTRY | OCI registry URL | localhost:5000+insecure |
| TASK_VERBOSE | Enable verbose output | 0 |
| MODULE | Target module for operations | (required) |
| TYPE | Version bump type | patch |
| VERSION | Explicit version for publish | (from versions.yml) |

## File Structure

```
./
├── Taskfile.yml                    # Root orchestration
├── .tasks/
│   ├── config.yml                  # Centralized variables
│   ├── core/
│   │   └── cue.yml                 # CUE format/vet/tidy
│   ├── registry/
│   │   └── docker.yml              # Local OCI registry
│   ├── modules/
│   │   └── main.yml                # Module publish/version
│   └── release/
│       └── main.yml                # Release/changelog
├── versions.yml                    # Module version registry
├── .registry-data/                 # Local registry storage (gitignored)
├── core/
│   ├── Taskfile.yml                # Core module tasks
│   └── v0/
│       └── cue.mod/module.cue
├── catalog/
│   ├── Taskfile.yml                # Catalog module tasks (multi-module)
│   └── v0/
│       ├── schemas/cue.mod/module.cue
│       ├── resources/cue.mod/module.cue
│       ├── traits/cue.mod/module.cue
│       ├── blueprints/cue.mod/module.cue
│       ├── policies/cue.mod/module.cue
│       └── statusprobes/cue.mod/module.cue
└── cli/
    └── Taskfile.yml                # CLI tasks (Go)
```
