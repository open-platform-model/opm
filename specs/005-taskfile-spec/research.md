# Research: OPM Development Taskfile

**Feature**: 005-taskfile-spec  
**Date**: 2026-01-23  
**Status**: Complete

## Research Questions

1. Taskfile v3 best practices for multi-repo monorepo
2. CUE module development workflow patterns
3. Local OCI registry setup for CUE modules
4. Watch mode tooling options
5. Multi-module version management

---

## 1. Taskfile v3 Multi-Repo Patterns

### Decision: Modular structure with `.tasks/` directory

**Rationale**:

- Separates concerns (CUE ops, registry, modules, releases)
- Centralized config prevents variable duplication
- `internal: true` hides utility Taskfiles from CLI listing

**Alternatives considered**:

- Single monolithic Taskfile - rejected: unwieldy with 36 functional requirements
- Per-command files - rejected: too granular, excessive overhead

### Key Patterns

#### Includes Structure

```yaml
version: '3'

includes:
  config:
    taskfile: .tasks/config.yml
    internal: true        # Hidden from --list
    
  module:
    taskfile: .tasks/modules/main.yml
    dir: .                # Run from root
    
  cli:
    taskfile: ./cli/Taskfile.yml
    dir: ./cli            # Run in cli/ directory
```

#### Centralized Config

```yaml
# .tasks/config.yml
version: '3'

vars:
  REGISTRY_PORT: 5000
  LOCAL_REGISTRY: localhost:{{.REGISTRY_PORT}}
  CUE_VERSION: v0.15.0
  
  MODULES:
    - name: core
      path: core/v0
      enabled: true
    - name: schemas
      path: catalog/v0/schemas
      enabled: true
```

#### Cross-Platform Compatibility

```yaml
tasks:
  build:
    cmds:
      - cmd: go build -o app.exe ./cmd
        platforms: [windows]
      - cmd: go build -o app ./cmd
        platforms: [linux, darwin]
```

#### CI/CD Integration

```yaml
output:
  group:
    begin: "::group::{{.TASK}}"
    end: "::endgroup::"

tasks:
  ci:
    preconditions:
      - sh: command -v cue
        msg: "CUE CLI required"
    cmds:
      - task: fmt
      - task: vet
      - task: test
```

#### Performance Optimizations

```yaml
tasks:
  build:
    sources:
      - '**/*.go'
      - go.mod
    generates:
      - './bin/app'
    method: checksum  # Skip if unchanged
```

---

## 2. CUE Module Development Workflows

### Decision: Dependency-ordered operations with centralized version registry

**Rationale**:

- CUE modules have interdependencies requiring topological order
- Centralized `versions.yml` prevents version drift
- `cue mod tidy` + `cue mod publish` follow Go modules patterns

### Module Dependency Graph

```
core ←── schemas
  ↑        ↑
  └── resources ←── traits ←── blueprints
         ↑            ↑
         └── policies ┘
```

### Key Workflows

#### Format and Validate

```bash
# Single module
cue fmt ./...
cue vet ./...

# With registry for dependencies
CUE_REGISTRY=localhost:5000+insecure cue mod tidy
```

#### Publish to Registry

```bash
export CUE_REGISTRY=localhost:5000+insecure

# Validate first
cue vet ./...

# Tidy dependencies
cue mod tidy

# Publish with version tag
cue mod publish v0.1.0
```

#### Module Requirements

- `cue.mod/module.cue` must have `source: kind: "self"` or `source: kind: "git"`
- Module path must match major version: `opm.dev/core@v0` for v0.x.x
- Language version pinned: `language: version: "v0.15.0"`

---

## 3. Local OCI Registry

### Decision: `registry:2` (distribution/distribution) with host-mounted data

**Rationale**:

- Official Docker registry, battle-tested
- CUE tutorials recommend this approach
- Simple setup with data persistence

**Alternatives considered**:

- `cue mod registry` built-in - rejected: ephemeral, no persistence
- Zot registry - rejected: overkill for local development

### Configuration

```bash
# Start registry
docker run -d \
  --name opm-registry \
  -p 5000:5000 \
  -v "$PWD/.registry-data:/var/lib/registry" \
  --restart=unless-stopped \
  registry:2

# Configure CUE to use it
export CUE_REGISTRY=localhost:5000+insecure
```

### Taskfile Integration

```yaml
tasks:
  registry:start:
    desc: Start Docker OCI registry
    cmds:
      - |
        if docker ps -f name={{.REGISTRY_CONTAINER}} | grep -q {{.REGISTRY_CONTAINER}}; then
          echo "Registry already running"
        elif docker ps -a -f name={{.REGISTRY_CONTAINER}} | grep -q {{.REGISTRY_CONTAINER}}; then
          docker start {{.REGISTRY_CONTAINER}}
        else
          mkdir -p "{{.REGISTRY_DATA_DIR}}"
          docker run -d \
            --name {{.REGISTRY_CONTAINER}} \
            -p {{.REGISTRY_PORT}}:5000 \
            -v "$(realpath {{.REGISTRY_DATA_DIR}}):/var/lib/registry" \
            --restart=unless-stopped \
            {{.REGISTRY_IMAGE}}
        fi

  registry:stop:
    desc: Stop registry (preserve data)
    cmds:
      - docker stop {{.REGISTRY_CONTAINER}} || true

  registry:status:
    desc: Show registry status
    cmds:
      - curl -s http://{{.LOCAL_REGISTRY}}/v2/_catalog | jq .
```

---

## 4. Watch Mode Tooling

### Decision: `watchexec`

**Rationale**:

- Cross-platform (Linux, macOS, Windows)
- Fast with built-in debouncing
- Simple CLI: `watchexec -e cue -- cue vet ./...`

**Alternatives considered**:

- Task's `--watch` flag - rejected: less flexible, no debounce control
- `entr` - rejected: Unix only, not Windows compatible
- `fswatch` - rejected: macOS primary, extra install on Linux

### Usage Patterns

```yaml
tasks:
  watch:vet:
    desc: Watch and validate on changes
    cmds:
      - watchexec -e cue -- cue vet ./...

  watch:fmt:
    desc: Watch and format on changes
    cmds:
      - watchexec -e cue -- cue fmt ./...
```

### Installation

| Platform | Command |
|----------|---------|
| macOS | `brew install watchexec` |
| Linux | `cargo install watchexec-cli` or distro package |
| Windows | `scoop install watchexec` |

---

## 5. Multi-Module Version Management

### Decision: Centralized `versions.yml` with independent module versioning

**Rationale**:

- Single source of truth prevents version drift
- Supports independent versioning per FR-031
- Easy to script version bumps

### Version Registry Format

```yaml
# versions.yml
core: v0.1.0
schemas: v0.1.0
resources: v0.1.0
traits: v0.1.0
blueprints: v0.1.0
policies: v0.1.0
```

### Version Bump Workflow

```yaml
tasks:
  version:bump:
    desc: Bump module version
    vars:
      MODULE: '{{.MODULE}}'
      TYPE: '{{.TYPE | default "patch"}}'
    cmds:
      - |
        current=$(yq '.{{.MODULE}}' versions.yml)
        new=$(semver bump {{.TYPE}} $current)
        yq -i '.{{.MODULE}} = "v'$new'"' versions.yml
        echo "Bumped {{.MODULE}}: $current → v$new"
```

### Publish Workflow (Dependency Order)

```bash
# Leaf modules first, then dependents
for mod in schemas core resources traits policies blueprints; do
  version=$(yq ".$mod" versions.yml)
  (cd catalog/v0/$mod && cue mod publish $version)
done
```

---

## Summary

| Topic | Decision | Key Tool/Pattern |
|-------|----------|------------------|
| Taskfile structure | Modular `.tasks/` directory | `internal: true`, centralized config |
| CUE workflows | Dependency-ordered ops | `cue mod tidy` → `cue mod publish` |
| Local registry | `registry:2` Docker image | Host-mounted `.registry-data/` |
| Watch mode | `watchexec` | `-e cue` filter, built-in debounce |
| Version management | `versions.yml` registry | Per-module SemVer, `yq` for updates |
