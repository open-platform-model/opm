# Implementation Plan: OPM CLI v2

**Branch**: `002-cli-spec` | **Date**: 2026-01-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/cli/002-cli-spec/spec.md`

## Summary

Build the OPM CLI v2 reference implementation in Go using cobra/viper for CLI framework, CUE SDK for module rendering and validation, and Charm libraries for terminal UX. The CLI manages module lifecycle (init, vet, tidy, build, apply, delete, diff, status) and configuration (init, vet).

## Technical Context

**Language/Version**: Go 1.25+
**Primary Dependencies**:

- CLI Framework: spf13/cobra v1.8+, spf13/viper
- CUE: cuelang.org/go v0.15+ (SDK), cue binary (vet/tidy delegation)
- Kubernetes: k8s.io/client-go (server-side apply)
- Diff: homeport/dyff v1.9+
- Terminal UX: charmbracelet/{lipgloss, log, glamour, huh/spinner}
**Storage**: Local filesystem (~/.opm/)
**Testing**: stretchr/testify, sigs.k8s.io/controller-runtime/pkg/envtest
**Target Platform**: Linux, macOS, Windows (cross-compiled)
**Project Type**: Single CLI application
**Performance Goals**: Module init+vet < 30s, config init < 10s
**Constraints**: CUE binary version must match SDK (MAJOR.MINOR)
**Scale/Scope**: Single-user CLI tool for module authoring and deployment

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Type Safety First | PASS | All definitions in CUE; config validated against embedded CUE schema |
| II. Separation of Concerns | PASS | CLI handles authoring; providers handle platform concerns |
| III. Policy Built-In | PASS | Policies applied via CUE unification during render |
| IV. Portability by Design | PASS | CLI delegates to providers; no runtime-specific logic in CLI |
| V. Semantic Versioning | PASS | SemVer for CLI, modules, providers; ldflags for build versioning |
| VI. Simplicity & YAGNI | PASS | Minimal command set; delegates vet/tidy to CUE binary |

**Technology Standards:**

- CUE Version: v0.15.0 (matches constitution requirement)
- Go: gofmt, golangci-lint compliance required
- Taskfile: Used for build automation (task build, task test, task lint)

## Project Structure

### Documentation (this feature)

```text
specs/cli/002-cli-spec/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Technology decisions (Phase 0 output)
├── data-model.md        # Go types and CUE schemas (Phase 1 output)
├── quickstart.md        # Getting started guide (Phase 1 output)
├── checklists/
│   └── requirements.md  # FR traceability checklist
├── contracts/
│   └── exit-codes.md    # Exit code contract
└── reference/
    ├── commands.md      # CLI command reference
    ├── project-structure.md  # Module structure reference
    └── templates/       # Module templates (simple, standard, advanced)
```

### Source Code (repository root)

```text
cli/
├── cmd/
│   └── opm/
│       └── main.go          # Entry point
├── internal/
│   ├── cmd/                 # Cobra commands → reference/commands.md for behavior specs
│   │   ├── root.go          # Root command, global flags → research.md §1 for cobra setup
│   │   ├── mod.go           # mod command group
│   │   ├── mod_init.go      # mod init → reference/project-structure.md for validation rules
│   │   ├── mod_vet.go       # mod vet (delegates to cue binary) → research.md §5
│   │   ├── mod_tidy.go      # mod tidy (delegates to cue binary) → research.md §5
│   │   ├── mod_build.go     # mod build (render manifests) → 004-render-and-lifecycle-spec
│   │   ├── mod_apply.go     # mod apply (server-side apply) → 004-render-and-lifecycle-spec
│   │   ├── mod_delete.go    # mod delete → 004-render-and-lifecycle-spec
│   │   ├── mod_diff.go      # mod diff (dyff) → research.md §2, 004-render-and-lifecycle-spec
│   │   ├── mod_status.go    # mod status → 004-render-and-lifecycle-spec
│   │   ├── config.go        # config command group
│   │   ├── config_init.go   # config init → spec.md §FR-008, data-model.md §Config Schema
│   │   ├── config_vet.go    # config vet → spec.md §FR-008
│   │   └── version.go       # version command → data-model.md §Version
│   ├── config/              # Configuration loading → data-model.md §Config
│   │   ├── config.go        # Config types → data-model.md lines 15-86
│   │   ├── loader.go        # Two-phase loader (bootstrap + full) → spec.md §FR-013
│   │   └── resolver.go      # Precedence resolution → spec.md §FR-018, research.md §1
│   ├── cue/                 # CUE SDK integration → research.md §5
│   │   ├── module.go        # Module loading → data-model.md §Module, research.md lines 271-306
│   │   ├── render.go        # Manifest rendering → 004-render-and-lifecycle-spec
│   │   └── binary.go        # CUE binary delegation → research.md lines 307-334
│   ├── k8s/                 # Kubernetes operations → 004-render-and-lifecycle-spec
│   │   ├── client.go        # Dynamic client setup
│   │   ├── apply.go         # Server-side apply → research.md §3
│   │   ├── delete.go        # Resource deletion
│   │   └── status.go        # Status checking
│   ├── output/              # Terminal output → research.md §4, data-model.md §Output
│   │   ├── format.go        # OutputFormat enum → data-model.md lines 246-257
│   │   ├── table.go         # lipgloss table rendering → research.md lines 223-241
│   │   ├── diff.go          # dyff integration → research.md §2
│   │   └── log.go           # charmbracelet/log setup → research.md lines 207-220
│   ├── templates/           # Embedded module templates → reference/templates/
│   │   ├── embed.go         # go:embed directives → reference/project-structure.md §1.3
│   │   ├── simple/          # Simple template files
│   │   ├── standard/        # Standard template files
│   │   └── advanced/        # Advanced template files
│   └── version/             # Version information → data-model.md §Version
│       └── version.go       # Info struct, CUE compatibility check → data-model.md lines 192-238
├── Taskfile.yml             # Build tasks
├── go.mod
└── go.sum

tests/
├── integration/             # envtest-based integration tests
│   ├── apply_test.go        # Not implemented now
│   ├── delete_test.go       # Not implemented now
│   └── status_test.go       # Not implemented now
├── e2e/                     # Full CLI execution tests
│   └── mod_test.go
└── fixtures/                # Test modules
    ├── valid/
    └── invalid/
```

**Structure Decision**: Single CLI project following standard Go layout. Internal packages isolate concerns (cmd, config, cue, k8s, oci, output, templates, version). Tests separated by layer (integration with envtest, e2e with binary execution).

**Error Handling**: All commands must implement exit codes per contracts/exit-codes.md. Error wrapping patterns and K8s error mapping are documented in contracts/exit-codes.md §Implementation Notes.

## Complexity Tracking

No constitution violations requiring justification. The design follows simplicity principles:

- Delegates vet/tidy to CUE binary instead of reimplementing
- Uses established libraries (cobra, dyff) instead of custom implementations
- Single CLI binary without external runtime dependencies beyond CUE binary
