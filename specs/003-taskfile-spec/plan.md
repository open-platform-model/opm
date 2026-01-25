# Implementation Plan: OPM Development Taskfile

**Branch**: `003-taskfile-spec` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)

## Summary

Implement a comprehensive Taskfile-based development workflow for the OPM multi-repo monorepo. Replace existing `.tasks_old/` with a clean, modular Taskfile structure supporting CUE development (format, validate, tidy), CLI builds, cross-repo orchestration, local OCI registry for module publishing, and release management with SemVer and Conventional Commits.

## Technical Context

**Language/Version**: YAML (Taskfile v3)  
**Primary Dependencies**: `go-task/task` v3.x, `cue` v0.15.0+, `go` 1.21+, `golangci-lint`, `watchexec`  
**Storage**: N/A  
**Testing**: Manual validation via task execution  
**Target Platform**: Linux/macOS (POSIX), Windows (partial)  
**Project Type**: Multi-repo monorepo  
**Performance Goals**: `task fmt` <10s, `task ci` <5min (per SC-002/SC-004)  
**Constraints**: Non-interactive (FR-032), CI-compatible (SC-005)  
**Scale/Scope**: 4 repos: root, core/, cli/, catalog/

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Definition-First Architecture | N/A | Taskfile is tooling, not OPM definitions |
| Type Safety via CUE | ✅ | CUE tasks enforce `cue fmt`/`cue vet` |
| Separation of Concerns | ✅ | Tasks for developers, orchestration for CI |
| Portability by Design | N/A | Development tooling |
| Policy as Code | N/A | Development tooling |
| Code Standards | ✅ | Enforces SemVer, Conventional Commits patterns |
| Multi-Repo Workflow | ✅ | Supports core/, cli/, catalog/ independently |

**Gate Status**: ✅ PASS - No violations.

**Post-Design Re-evaluation**: ✅ PASS

- Design maintains clear separation between orchestration (root) and execution (sub-repos)
- No complexity violations; structure follows established patterns from `.tasks_old/`
- All modules can be operated independently per FR-035

## Project Structure

### Documentation (this feature)

```text
opm/specs/003-taskfile-spec/
├── plan.md              # This file
├── research.md          # Phase 0 output - technology decisions
├── data-model.md        # Phase 1 output - entities and relationships
└── quickstart.md        # Phase 1 output - developer onboarding
```

### Source Code (repository root)

```text
# Root orchestration
./Taskfile.yml              # Main entry point (FR-001 to FR-006)
./.tasks/
├── config.yml              # Centralized variables
├── core/
│   └── cue.yml             # CUE format/vet/tidy tasks
├── registry/
│   └── docker.yml          # Local OCI registry tasks (FR-023 to FR-025)
├── modules/
│   └── main.yml            # Module publish/version tasks (FR-011 to FR-014)
└── release/
    └── main.yml            # Release/changelog tasks (FR-026 to FR-031)

# Version registry
./versions.yml              # Module version tracking (per FR-031)

# Sub-repository Taskfiles (self-contained per FR-035)
core/Taskfile.yml           # CUE module tasks for core/v0
catalog/Taskfile.yml        # CUE module tasks for catalog/v0/* (multi-module aware)
cli/Taskfile.yml            # Go CLI tasks (exists, add FR-020)

# Local development (gitignored)
.registry-data/             # OCI registry persistence
```

## Task Inventory

### Root-Level Tasks (FR-001 to FR-006)

| Task | Requirement | Description |
|------|-------------|-------------|
| `setup` | FR-001 | Initialize dev environment |
| `clean` | FR-002 | Remove generated artifacts |
| `env` | FR-003 | Display environment config |
| `all:fmt` | FR-004 | Format all repos |
| `all:vet` | FR-004 | Validate all repos |
| `ci` | FR-005 | Run all CI checks |
| `fmt` | FR-006 | Shortcut → all CUE modules |
| `vet` | FR-006 | Shortcut → all CUE modules |

### CUE Module Tasks (FR-007 to FR-014)

| Task | Requirement | Description |
|------|-------------|-------------|
| `fmt` | FR-007 | Format CUE files |
| `vet` | FR-008 | Validate CUE files |
| `tidy` | FR-009 | Module dependency management |
| `watch:fmt` | FR-010 | Continuous formatting |
| `watch:vet` | FR-010 | Continuous validation |
| `module:publish` | FR-011 | Publish to OCI registry |
| `module:publish:local` | FR-012 | Publish to local registry |
| `module:version` | FR-013 | Display module version |
| `module:version:bump` | FR-014 | Bump version (SemVer) |

### CLI Tasks (FR-015 to FR-022)

| Task | Requirement | Status |
|------|-------------|--------|
| `build` | FR-015 | ✅ Exists |
| `test` | FR-016 | ✅ Exists |
| `test:unit` | FR-017 | ✅ Exists |
| `test:integration` | FR-018 | ✅ Exists |
| `test:verbose` | FR-019 | ✅ Exists |
| `test:run` | FR-020 | ⚠️ Missing - needs TEST parameter |
| `lint` | FR-021 | ✅ Exists |
| `clean` | FR-022 | ✅ Exists |

### Registry Tasks (FR-023 to FR-025)

| Task | Requirement | Description |
|------|-------------|-------------|
| `registry:start` | FR-023 | Start local OCI registry |
| `registry:stop` | FR-023 | Stop local registry |
| `registry:status` | - | Show registry status (helper) |
| `module:publish` | FR-024 | Push to production registry |
| `module:publish:local` | FR-025 | Push to local registry |

### Release & Versioning Tasks (FR-026 to FR-031)

| Task | Requirement | Description |
|------|-------------|-------------|
| `version` | FR-026 | Display all versions |
| `version:bump` | FR-027 | Bump version (SemVer) |
| `changelog` | FR-028 | Generate changelog |
| `release` | FR-029 | Orchestrate release |
| `release:dry-run` | FR-030 | Preview release changes |

### Cross-Cutting Requirements

| Requirement | Implementation |
|-------------|----------------|
| FR-032 | All tasks non-interactive, suitable for CI |
| FR-033 | `TASK_VERBOSE=1` or `--verbose` flag |
| FR-034 | Non-zero exit codes on failure |
| FR-035 | Each sub-repo self-contained |
| FR-036 | Root orchestrates, doesn't duplicate |

## Key Decisions

Documented in [research.md](./research.md):

1. **Taskfile Structure**: Modular `.tasks/` directory with centralized config
2. **Watch Tool**: `watchexec` - cross-platform, debounced file watching
3. **Local Registry**: `registry:2` Docker image with host-mounted data
4. **Catalog Multi-Module**: Single Taskfile operating on individual or all modules
5. **Version Management**: Centralized `versions.yml` with per-module SemVer

## Implementation Order

### Phase 1: Core Infrastructure

1. Create root `Taskfile.yml` with includes
2. Create `.tasks/config.yml` with centralized variables
3. Create `.tasks/registry/docker.yml` for local registry
4. Create `versions.yml` for version tracking

### Phase 2: CUE Tasks

1. Create `.tasks/core/cue.yml` for format/vet/tidy
2. Create `.tasks/modules/main.yml` for publish/version
3. Create `core/Taskfile.yml` (self-contained)
4. Create `catalog/Taskfile.yml` (multi-module aware)

### Phase 3: Release Tasks

1. Create `.tasks/release/main.yml` for changelog/release
2. Add `test:run` task to `cli/Taskfile.yml`

### Phase 4: Cleanup

1. Archive `.tasks_old/` directory
2. Update AGENTS.md with new task commands
3. Verify all FR-* requirements met

## Success Criteria Verification

| Criterion | How to Verify |
|-----------|---------------|
| SC-001: Setup <5min | Time `task setup` on fresh clone |
| SC-002: `task fmt` <10s | Time `task fmt` on all modules |
| SC-003: Actionable errors | Run `task vet` with intentional error |
| SC-004: `task ci` <5min | Time full CI run |
| SC-005: CI compatible | Run in GitHub Actions |
| SC-006: Single command | Verify common workflows |
| SC-007: Release <2min | Time `task release` workflow |
