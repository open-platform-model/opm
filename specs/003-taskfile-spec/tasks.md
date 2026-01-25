# Tasks: OPM Development Taskfile

**Input**: Design documents from `/opm/specs/003-taskfile-spec/`
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, quickstart.md

**Tests**: Not included (manual validation per plan.md)

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)
- Include exact file paths in descriptions

## Path Conventions

- **Root orchestration**: `./Taskfile.yml`, `./.tasks/`
- **Sub-repositories**: `core/Taskfile.yml`, `catalog/Taskfile.yml`, `cli/Taskfile.yml`
- **Version registry**: `./versions.yml`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and configuration files

- [X] T001 [P] Create `.tasks/` directory structure per plan.md project structure
- [X] T002 [P] Create `.tasks/config.yml` with centralized variables (REGISTRY_PORT, LOCAL_REGISTRY, CUE_VERSION, MODULES list)
- [X] T003 [P] Create `versions.yml` with initial module versions (core, schemas, resources, traits, blueprints, policies, statusprobes all at v0.1.0)
- [X] T004 [P] Add `.registry-data/` to `.gitignore` for local registry persistence

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Root Taskfile.yml with includes structure - BLOCKS all user stories

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create `./Taskfile.yml` with version 3, silent mode, dotenv, and includes structure for config, cue, registry, module namespaces
- [X] T006 Add `default` task to `./Taskfile.yml` showing available tasks via `task --list`
- [X] T007 Create placeholder files for included Taskfiles (`.tasks/core/cue.yml`, `.tasks/registry/docker.yml`, `.tasks/modules/main.yml`, `.tasks/release/main.yml`) with version 3 and empty tasks section

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Developer Environment Setup (Priority: P1)

**Goal**: New contributor can initialize local development environment with all tools and dependencies

**Independent Test**: Run `task setup` on fresh clone - should complete in <5min with registry running and dependencies tidied

### Implementation for User Story 1

- [X] T008 [US1] Implement `registry:start` task in `.tasks/registry/docker.yml` to start local OCI registry (FR-023)
- [X] T009 [US1] Implement `registry:stop` task in `.tasks/registry/docker.yml` to stop registry preserving data (FR-023)
- [X] T010 [US1] Implement `registry:status` task in `.tasks/registry/docker.yml` to show registry status via curl
- [X] T011 [US1] Implement `setup` task in `./Taskfile.yml` to start registry and tidy dependencies (FR-001)
- [X] T012 [US1] Implement `clean` task in `./Taskfile.yml` to remove generated artifacts across all repos (FR-002)
- [X] T013 [US1] Implement `env` task in `./Taskfile.yml` to display environment config and tool versions (FR-003)

**Checkpoint**: User Story 1 complete - `task setup`, `task clean`, `task env` all functional

---

## Phase 4: User Story 2 - CUE Module Development Workflow (Priority: P1)

**Goal**: Developer can format, validate, and test CUE changes with fast feedback loops

**Independent Test**: Modify CUE file, run `task fmt` and `task vet` - should receive clear feedback in seconds

### Implementation for User Story 2

- [X] T014 [US2] Implement `fmt` task in `.tasks/core/cue.yml` to format CUE files using `cue fmt` (FR-007)
- [X] T015 [US2] Implement `vet` task in `.tasks/core/cue.yml` to validate CUE files using `cue vet` (FR-008)
- [X] T016 [US2] Implement `tidy` task in `.tasks/core/cue.yml` to manage module dependencies using `cue mod tidy` (FR-009)
- [X] T017 [US2] Implement `watch:fmt` and `watch:vet` tasks in `.tasks/core/cue.yml` using watchexec (FR-010)
- [X] T018 [P] [US2] Create `core/Taskfile.yml` with fmt, vet, tidy, watch tasks for core/v0 module (FR-035)
- [X] T019 [P] [US2] Create `catalog/Taskfile.yml` with fmt, vet, tidy, watch tasks aware of multi-module structure (FR-035)
- [X] T020 [US2] Add `fmt` and `vet` shortcut tasks to root `./Taskfile.yml` delegating to module:fmt:all and module:vet:all (FR-006)
- [X] T021 [US2] Add `module:fmt` and `module:vet` tasks accepting MODULE parameter to `.tasks/modules/main.yml` for single module operations

**Checkpoint**: User Story 2 complete - CUE format/validate workflow functional from root and sub-repos

---

## Phase 5: User Story 3 - CLI Development Workflow (Priority: P2)

**Goal**: Developer can build, test, and lint Go CLI changes

**Independent Test**: Modify Go code in cli/, run `task build` and `task test` - should compile and run tests

### Implementation for User Story 3

- [X] T022 [US3] Add `test:run` task to `cli/Taskfile.yml` accepting TEST parameter to run specific tests (FR-020)
- [X] T023 [US3] Verify existing cli/Taskfile.yml tasks satisfy FR-015 to FR-019, FR-021, FR-022 (build, test, test:unit, test:integration, test:verbose, lint, clean)

**Checkpoint**: User Story 3 complete - CLI development workflow fully functional

---

## Phase 6: User Story 4 - Cross-Repository Orchestration (Priority: P2)

**Goal**: Developer or CI can run operations across all repositories consistently

**Independent Test**: Run `task all:vet` - should validate all CUE and Go code across all repos

### Implementation for User Story 4

- [X] T024 [US4] Implement `all:fmt` task in `./Taskfile.yml` to format all repos (CUE in core/catalog, Go in cli) (FR-004)
- [X] T025 [US4] Implement `all:vet` task in `./Taskfile.yml` to validate all repos and report aggregated results (FR-004)
- [X] T026 [US4] Implement `ci` task in `./Taskfile.yml` to run all CI checks in correct order (format, validate, test) (FR-005)

**Checkpoint**: User Story 4 complete - cross-repo orchestration functional

---

## Phase 7: User Story 5 - Module Publishing Workflow (Priority: P3)

**Goal**: Maintainer can publish CUE modules to OCI registry for distribution

**Independent Test**: Run `task module:publish:local MODULE=core` - should push module to local registry

### Implementation for User Story 5

- [X] T027 [US5] Implement `module:publish` task in `.tasks/modules/main.yml` to publish module to production registry (FR-011, FR-024)
- [X] T028 [US5] Implement `module:publish:local` task in `.tasks/modules/main.yml` to publish to local registry (FR-012, FR-025)
- [X] T029 [US5] Implement `module:version` task in `.tasks/modules/main.yml` to display module version from versions.yml (FR-013)
- [X] T030 [US5] Implement `module:version:bump` task in `.tasks/modules/main.yml` accepting TYPE parameter (patch/minor/major) following SemVer (FR-014)
- [X] T031 [US5] Implement `module:publish:all:local` task in `.tasks/modules/main.yml` to publish all modules in dependency order

**Checkpoint**: User Story 5 complete - module publishing workflow functional

---

## Phase 8: User Story 6 - Release & Versioning Workflow (Priority: P3)

**Goal**: Maintainer can manage versions, generate changelogs, and create releases

**Independent Test**: Run `task version:bump MODULE=core TYPE=minor` - should update versions.yml and generate changelog entry

### Implementation for User Story 6

- [X] T032 [US6] Implement `version` task in `.tasks/release/main.yml` to display all component versions (FR-026)
- [X] T033 [US6] Implement `version:bump` task in `.tasks/release/main.yml` accepting MODULE and TYPE parameters (FR-027, FR-031)
- [X] T034 [US6] Implement `changelog` task in `.tasks/release/main.yml` to generate changelog from Conventional Commits (FR-028)
- [X] T035 [US6] Implement `release` task in `.tasks/release/main.yml` to orchestrate version bump, changelog, and tagging (FR-029)
- [X] T036 [US6] Implement `release:dry-run` task in `.tasks/release/main.yml` to preview release changes (FR-030)

**Checkpoint**: User Story 6 complete - release workflow functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, documentation, and verification

- [X] T037 [P] Archive `.tasks_old/` directory (move to `old_stuff/.tasks_old/` or delete after verification)
- [X] T038 [P] Update `AGENTS.md` Build/Test Commands section with new task commands
- [X] T039 Verify all FR-032 to FR-036 cross-cutting requirements (non-interactive, verbose flag, exit codes, self-contained, orchestration)
- [X] T040 Run quickstart.md validation - verify all documented commands work as expected

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Phase 2 completion
  - US1 (P1): Can start after Phase 2
  - US2 (P1): Can start after Phase 2
  - US3 (P2): Can start after Phase 2 (cli/Taskfile.yml already exists)
  - US4 (P2): Depends on US1 (registry) and US2 (CUE tasks)
  - US5 (P3): Depends on US1 (registry) and US2 (CUE tasks)
  - US6 (P3): Depends on versions.yml from Phase 1
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────────────────────────────────>
       │
       v
Phase 2 (Foundational) ──────────────────────────────────────────────────────────>
       │
       ├──> Phase 3 (US1 - Setup) ───────────────────────────────────────────────>
       │           │
       │           ├──> Phase 6 (US4 - Orchestration) ───────────────────────────>
       │           │
       │           └──> Phase 7 (US5 - Publishing) ──────────────────────────────>
       │
       ├──> Phase 4 (US2 - CUE Dev) ─────────────────────────────────────────────>
       │           │
       │           ├──> Phase 6 (US4 - Orchestration) ───────────────────────────>
       │           │
       │           └──> Phase 7 (US5 - Publishing) ──────────────────────────────>
       │
       ├──> Phase 5 (US3 - CLI Dev) ─────────────────────────────────────────────>
       │
       └──> Phase 8 (US6 - Release) ─────────────────────────────────────────────>
                                                                                  │
                                                                                  v
                                                               Phase 9 (Polish) ──>
```

### Within Each User Story

- Registry tasks before setup task (US1)
- Core CUE tasks before shortcut tasks (US2)
- Sub-repo Taskfiles can be created in parallel (US2: T018, T019)
- Version tasks before release tasks (US6)

### Parallel Opportunities

**Phase 1 (all [P])**:

```
T001 Create .tasks/ structure
T002 Create .tasks/config.yml
T003 Create versions.yml
T004 Update .gitignore
```

**Phase 4 (sub-repo Taskfiles)**:

```
T018 Create core/Taskfile.yml
T019 Create catalog/Taskfile.yml
```

**Phase 9 (cleanup)**:

```
T037 Archive .tasks_old/
T038 Update AGENTS.md
```

---

## Parallel Example: Phase 1

```bash
# Launch all Phase 1 tasks together:
Task: "Create .tasks/ directory structure per plan.md"
Task: "Create .tasks/config.yml with centralized variables"
Task: "Create versions.yml with initial module versions"
Task: "Add .registry-data/ to .gitignore"
```

## Parallel Example: User Story 2 (Sub-repo Taskfiles)

```bash
# After T017 completes, launch sub-repo Taskfiles in parallel:
Task: "Create core/Taskfile.yml with fmt, vet, tidy, watch tasks"
Task: "Create catalog/Taskfile.yml with multi-module aware tasks"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T007)
3. Complete Phase 3: User Story 1 - Environment Setup (T008-T013)
4. **STOP and VALIDATE**: Run `task setup`, `task env`, `task clean`
5. Deploy/demo if ready - developer can now set up local environment

### Incremental Delivery

1. Setup + Foundational -> Basic Taskfile structure ready
2. Add US1 (Setup) -> `task setup` works (MVP!)
3. Add US2 (CUE Dev) -> `task fmt`, `task vet` work
4. Add US3 (CLI Dev) -> `task test:run TEST=...` works in cli/
5. Add US4 (Orchestration) -> `task ci` works
6. Add US5 (Publishing) -> `task module:publish` works
7. Add US6 (Release) -> `task release` works
8. Each story adds value without breaking previous stories

### File Creation Order

```
1. .tasks/                           # Directory structure
2. .tasks/config.yml                 # Configuration first
3. versions.yml                      # Version tracking
4. .gitignore (update)               # Ignore registry data
5. ./Taskfile.yml                    # Root orchestration
6. .tasks/registry/docker.yml        # Registry tasks (US1)
7. .tasks/core/cue.yml               # CUE tasks (US2)
8. core/Taskfile.yml                 # Core module (US2)
9. catalog/Taskfile.yml              # Catalog module (US2)
10. cli/Taskfile.yml (update)        # Add test:run (US3)
11. .tasks/modules/main.yml          # Module tasks (US5)
12. .tasks/release/main.yml          # Release tasks (US6)
```

---

## Requirement Traceability

### Functional Requirements Coverage

| FR | Description | Task(s) |
|----|-------------|---------|
| FR-001 | setup task | T011 |
| FR-002 | clean task | T012 |
| FR-003 | env task | T013 |
| FR-004 | all:fmt, all:vet | T024, T025 |
| FR-005 | ci task | T026 |
| FR-006 | fmt, vet shortcuts | T020 |
| FR-007 | CUE fmt | T014 |
| FR-008 | CUE vet | T015 |
| FR-009 | CUE tidy | T016 |
| FR-010 | watch:fmt, watch:vet | T017 |
| FR-011 | module:publish | T027 |
| FR-012 | module:publish:local | T028 |
| FR-013 | module:version | T029 |
| FR-014 | module:version:bump | T030 |
| FR-015-019, 021-022 | CLI tasks | T023 (verify existing) |
| FR-020 | test:run | T022 |
| FR-023 | registry:start/stop | T008, T009 |
| FR-024 | module:publish (production) | T027 |
| FR-025 | local/remote targets | T028 |
| FR-026 | version display | T032 |
| FR-027 | version:bump | T033 |
| FR-028 | changelog | T034 |
| FR-029 | release | T035 |
| FR-030 | release:dry-run | T036 |
| FR-031 | per-repo versioning | T033 |
| FR-032-036 | cross-cutting | T039 |

### Success Criteria Verification

| SC | How to Verify | Task |
|----|---------------|------|
| SC-001 | Time `task setup` <5min | T011 |
| SC-002 | Time `task fmt` <10s | T020 |
| SC-003 | Run `task vet` with error | T015 |
| SC-004 | Time `task ci` <5min | T026 |
| SC-005 | Run in CI environment | T039 |
| SC-006 | Single command workflows | All tasks |
| SC-007 | Time `task release` <2min | T035 |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Reference `.tasks_old/` for implementation patterns but do not copy directly
