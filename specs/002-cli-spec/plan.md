# Implementation Plan: OPM CLI v2

**Branch**: `002-cli-spec` | **Date**: 2026-01-22 | **Spec**: [spec.md](./spec.md)

## Summary

Implement the OPM CLI v2 - a command-line tool for authoring, validating, building, and deploying OPM modules to Kubernetes clusters. The CLI provides module lifecycle management (`mod` commands), bundle orchestration (`bundle` commands), and configuration management (`config` commands).

## Technical Context

**Language/Version**: Go 1.21+  
**Primary Dependencies**: spf13/cobra, spf13/viper, cuelang.org/go v0.11+, k8s.io/client-go, oras.land/oras-go/v2, homeport/dyff, charmbracelet/{lipgloss,log,glamour,huh}  
**Storage**: ~/.opm/config.yaml, ~/.opm/cache/  
**Testing**: stretchr/testify, sigs.k8s.io/controller-runtime/pkg/envtest  
**Target Platform**: Linux, macOS, Windows (amd64, arm64)  
**Project Type**: CLI application  
**Performance Goals**: Module validation <5s, apply operations <30s for typical modules  
**Constraints**: Stateless operations, standard kubeconfig auth, OCI registry auth via ~/.docker/config.json  
**Scale/Scope**: 5 user stories, 3 command groups (mod, bundle, config), ~15 subcommands

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Definition-First Architecture | ✅ | CLI operates on OPM definitions (modules, bundles) |
| Type Safety via CUE | ✅ | All validation uses CUE, compile-time checks |
| Separation of Concerns | ✅ | CLI for users, definitions in core/catalog |
| Portability by Design | ✅ | CLI is portable, modules remain provider-agnostic |
| Policy as Code | ✅ | Policies validated during `mod vet` |
| Code Standards | ✅ | Go gofmt, golangci-lint, Conventional Commits |

**Gate Status**: ✅ PASS - No violations.

## Project Structure

### Documentation (this feature)

```text
opm/specs/002-cli-spec/
├── plan.md              # This file
├── research.md          # Technology decisions (cobra, dyff, charm, etc.)
├── data-model.md        # CLI entities and data structures
├── quickstart.md        # Developer guide for CLI usage
├── contracts/
│   └── exit-codes.md    # Exit code contract
├── reference/
│   ├── commands.md      # Command reference
│   └── project-structure.md
└── tasks.md             # Implementation tasks
```

### Source Code (repository root)

```text
cli/
├── cmd/opm/
│   └── main.go              # Entry point
├── internal/
│   ├── cmd/                 # Command implementations
│   │   ├── root.go
│   │   ├── mod/             # mod subcommands
│   │   ├── bundle/          # bundle subcommands
│   │   └── config/          # config subcommands
│   ├── cue/                 # CUE integration
│   ├── k8s/                 # Kubernetes client
│   ├── oci/                 # OCI registry client
│   ├── output/              # Terminal output (charm)
│   └── version/             # Version info
├── pkg/
│   ├── loader/              # Module/bundle loading
│   ├── flattener/           # Module flattening
│   └── renderer/            # Manifest rendering
├── tests/
│   ├── integration/         # Integration tests
│   ├── e2e/                 # End-to-end tests
│   └── fixtures/            # Test data
├── Taskfile.yml
├── go.mod
└── go.sum
```

## Key Decisions

Documented in [research.md](./research.md):

1. **CLI Framework**: spf13/cobra - industry standard, rich features
2. **Diff Library**: homeport/dyff - YAML-aware, colorized output
3. **Terminal UX**: Charm ecosystem (lipgloss, log, glamour, huh)
4. **Config Format**: YAML with CUE schema validation
5. **OCI Client**: oras.land/oras-go/v2 - standard OCI operations
6. **K8s Client**: client-go with server-side apply

## Command Groups

### mod - Module Operations (US1, US2, US3)

| Command | Description |
|---------|-------------|
| `mod init` | Initialize new module from template |
| `mod vet` | Validate module CUE definitions |
| `mod build` | Render module to K8s manifests |
| `mod apply` | Deploy module to cluster |
| `mod diff` | Show pending changes |
| `mod status` | Show deployment status |
| `mod delete` | Remove module from cluster |
| `mod publish` | Push module to OCI registry |
| `mod get` | Pull module from OCI registry |

### bundle - Bundle Operations (US4)

| Command | Description |
|---------|-------------|
| `bundle apply` | Deploy all modules in bundle |
| `bundle diff` | Show pending changes for bundle |
| `bundle status` | Show aggregate status |
| `bundle delete` | Remove all bundle resources |

### config - Configuration (US5)

| Command | Description |
|---------|-------------|
| `config init` | Create default config file |
| `config vet` | Validate config file |

## Implementation Phases

See [tasks.md](./tasks.md) for detailed task breakdown.

### Phase 1: Setup

- Project structure, Go module, Taskfile, linting

### Phase 2: Foundational

- Exit codes, error handling, output formatting, CUE integration

### Phase 3: US1 - First-Time Module Authoring

- `mod init`, `mod vet`, `mod apply`, `mod status`, `mod delete`

### Phase 4: US2 - Updating Modules

- `mod build`, `mod diff`

### Phase 5: US3 - Distribution

- `mod publish`, `mod get`

### Phase 6: US4 - Bundles

- `bundle apply`, `bundle diff`, `bundle status`, `bundle delete`

### Phase 7: US5 - Configuration

- `config init`, `config vet`

## Success Criteria

| Criterion | How to Verify |
|-----------|---------------|
| US1 complete | New user can init, apply, status, delete a module |
| US2 complete | User can build, diff, and apply changes |
| US3 complete | User can publish and get modules from OCI |
| US4 complete | User can manage multi-module bundles |
| US5 complete | User can configure CLI defaults |
| Exit codes | All commands return documented exit codes |
| Error messages | All errors include actionable guidance |
