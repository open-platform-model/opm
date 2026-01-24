# Tasks: OPM CLI v2

**Input**: Design documents from `/opm/specs/004-cli-spec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/exit-codes.md, reference/

**Tests**: Test tasks are included per phase as the plan.md specifies testing requirements (stretchr/testify, envtest).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md project structure:

- Source: `cli/`
- Entry point: `cli/cmd/opm/`
- Internal packages: `cli/internal/`
- Public API: `cli/pkg/`
- Tests: `cli/tests/`

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize Go project with tooling and basic structure

- [X] T001 Create `cli/` directory structure per plan.md (cmd/opm, internal/, pkg/, tests/)
- [X] T002 Initialize Go module with `go mod init github.com/opmodel/cli` in cli/go.mod
- [X] T003 [P] Create Taskfile.yml with build, test, lint, fmt tasks in cli/Taskfile.yml
- [X] T004 [P] Configure golangci-lint in cli/.golangci.yml
- [X] T005 Add core dependencies to cli/go.mod (cobra, viper, cue, client-go, oras-go, dyff, charm libs, testify)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Exit Code Constants

- [X] T006 Define exit code constants per contracts/exit-codes.md in cli/internal/cmd/exit.go
- [X] T007 [P] Implement error-to-exit-code mapping functions in cli/internal/cmd/errors.go

### Version Infrastructure

- [X] T008 [P] Create version info types (Info, CUEBinaryInfo) in cli/internal/version/version.go
- [X] T009 [P] Implement CUE version compatibility checking in cli/internal/version/version.go
- [X] T010 [P] Implement CUE binary detection and version extraction in cli/internal/version/cue.go

### Configuration

- [X] T011 Implement config types (Config, Paths, DefaultConfig) per data-model.md in cli/internal/config/config.go
- [X] T012 [P] Implement config file paths (~/.opm/config.yaml, cache) in cli/internal/config/paths.go
- [X] T013 Implement YAML config loading with viper + env var support in cli/internal/config/loader.go
- [X] T013a [P] Create embedded CUE schema for config validation in cli/internal/config/schema.cue
- [X] T013b Implement config validation against CUE schema in cli/internal/config/validator.go

### Config Commands (US5)

- [X] T013c [US5] Create config command group in cli/internal/cmd/config/config.go
- [X] T013d [US5] Implement `opm config init` with --force in cli/internal/cmd/config/init.go
- [X] T013e [US5] Implement `opm config vet` in cli/internal/cmd/config/vet.go

### Output Infrastructure

- [X] T014 [P] Define output format constants (yaml, json, table, dir) in cli/internal/output/format.go
- [X] T015 [P] Create lipgloss styles (status colors, table borders) in cli/internal/output/styles.go
- [X] T016 [P] Implement charmbracelet/log setup with --verbose flag in cli/internal/output/log.go
- [X] T017 [P] Implement huh/spinner wrapper for progress indication in cli/internal/output/spinner.go

### Root Command

- [X] T018 Implement root command with global flags per reference/commands.md in cli/cmd/opm/root.go
- [X] T019 Implement entry point with PersistentPreRunE for config/logging init in cli/cmd/opm/main.go
- [X] T020 Implement version command showing CLI, CUE SDK, CUE binary info in cli/internal/cmd/version.go

### Resource Weights (Shared)

- [X] T021 Define resource weight constants per spec Section 6.2 in cli/pkg/weights/weights.go
- [X] T022 [P] Define label constants (managed-by, module name/namespace/version, component) in cli/internal/kubernetes/labels.go

### Unit Tests for Foundational

- [X] T023 [P] Unit tests for exit code mapping in cli/internal/cmd/errors_test.go
- [X] T024 [P] Unit tests for CUE version compatibility in cli/internal/version/version_test.go
- [X] T025 [P] Unit tests for config loading in cli/internal/config/loader_test.go

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - First-Time Module Authoring and Deployment (Priority: P1) MVP

**Goal**: A new user can create their first module and deploy it to a Kubernetes cluster

**Independent Test**: User with CLI and K8s cluster can follow quickstart, deploy hello-world module, see it running via kubectl

### CUE Integration for US1

- [X] T026 [US1] Create Module and ModuleMetadata types per data-model.md in cli/internal/cue/types.go
- [X] T027 [US1] Implement CUE module loader using cuelang.org/go in cli/internal/cue/loader.go
- [X] T028 [US1] Implement values file loading (CUE, YAML, JSON) with unification in cli/internal/cue/values.go
- [X] T029 [US1] Implement CUE binary delegation (run external cue command) in cli/internal/cue/binary.go
- [X] T030 [US1] Implement manifest renderer (CUE -> K8s unstructured objects) in cli/internal/cue/renderer.go
- [X] T031 [P] [US1] Create Manifest and ManifestSet types with weight sorting in cli/internal/cue/manifest.go

### Kubernetes Client for US1

- [X] T032 [US1] Implement K8s client setup from kubeconfig with context selection in cli/internal/kubernetes/client.go
- [X] T033 [US1] Implement label injection for all manifests in cli/internal/kubernetes/labels.go
- [X] T034 [US1] Implement weighted resource sorting for apply order in cli/internal/kubernetes/sort.go
- [X] T035 [US1] Implement server-side apply with field manager "opm" in cli/internal/kubernetes/apply.go
- [X] T036 [US1] Implement resource discovery by labels for delete in cli/internal/kubernetes/discovery.go
- [X] T037 [US1] Implement weighted deletion in reverse order in cli/internal/kubernetes/delete.go

### Health & Status for US1

- [X] T038 [US1] Create HealthStatus, ResourceStatus, ModuleStatus types per data-model.md in cli/internal/kubernetes/status.go
- [X] T039 [US1] Implement health evaluation per spec Section 6.3 in cli/internal/kubernetes/health.go
- [X] T040 [P] [US1] Implement lipgloss table output for status in cli/internal/output/table.go

### Module Commands for US1

- [X] T041 [US1] Create mod command group in cli/internal/cmd/mod/mod.go
- [X] T041a [US1] Implement `opm mod init <name>` with --template, --dir in cli/internal/cmd/mod/init.go
- [X] T042 [US1] Implement `opm mod vet` delegating to cue vet with version check in cli/internal/cmd/mod/vet.go
- [X] T043 [US1] Implement `opm mod tidy` delegating to cue mod tidy in cli/internal/cmd/mod/tidy.go
- [X] T044 [US1] Implement `opm mod build` with --output yaml/json/dir, --values in cli/internal/cmd/mod/build.go
- [X] T045 [US1] Implement `opm mod apply` with --dry-run, --wait, --timeout in cli/internal/cmd/mod/apply.go
- [X] T046 [US1] Implement `opm mod status` with --output table/json/yaml in cli/internal/cmd/mod/status.go
- [X] T047 [US1] Implement `opm mod delete` with --force, --dry-run in cli/internal/cmd/mod/delete.go

### Integration Tests for US1

- [X] T048 [US1] Setup envtest infrastructure in cli/tests/integration/setup_test.go
- [X] T049 [P] [US1] Integration test for apply (server-side apply) in cli/tests/integration/apply_test.go
- [X] T050 [P] [US1] Integration test for delete (weighted reverse order) in cli/tests/integration/delete_test.go
- [X] T051 [P] [US1] Integration test for status (health evaluation) in cli/tests/integration/status_test.go
- [X] T052 [US1] Create test fixtures (hello-world module) in cli/tests/fixtures/hello-world/

### Edge Case Tests for US1

- [X] T052a [P] [US1] Integration test for cluster connectivity error (exit code 3) in cli/tests/integration/errors_test.go
- [X] T052b [P] [US1] Integration test for CUE validation error (exit code 2) in cli/tests/integration/errors_test.go
- [X] T052c [P] [US1] Integration test for RBAC permission denied (exit code 4) in cli/tests/integration/errors_test.go

**Checkpoint**: User Story 1 complete - user can init, build, apply, status, delete a module

---

## Phase 4: User Story 2 - Updating an Existing Module (Priority: P2)

**Goal**: Module author can preview and apply changes to an existing deployment

**Independent Test**: Deploy a module, modify module.cue locally, run diff to see changes, apply changes, verify diff shows no differences

### Diff Implementation for US2

- [X] T053 [US2] Create DiffResult and ModifiedResource types per data-model.md in cli/internal/output/diff.go
- [X] T054 [US2] Implement dyff integration for YAML-aware diff in cli/internal/output/dyff.go
- [X] T055 [US2] Implement live vs desired comparison in cli/internal/kubernetes/diff.go
- [X] T056 [US2] Implement `opm mod diff` with --no-color in cli/internal/cmd/mod/diff.go

### Apply Enhancements for US2

- [X] T057 [US2] Add --diff flag to apply command showing diff before applying in cli/internal/cmd/mod/apply.go

### Unit Tests for US2

- [X] T058 [P] [US2] Unit tests for dyff integration in cli/internal/output/dyff_test.go
- [X] T059 [P] [US2] Unit tests for diff computation in cli/internal/kubernetes/diff_test.go

### Integration Tests for US2

- [X] T060 [US2] Integration test for diff command in cli/tests/integration/diff_test.go

**Checkpoint**: User Story 2 complete - user can diff, preview changes with apply --diff

---

## Phase 5: User Story 3 - Distributing and Consuming a Module (Priority: P3)

**Goal**: Platform team can publish modules to OCI registry, developers can download and use them

**Independent Test**: With local OCI registry, publish a module, delete locally, get it back from registry

### OCI Infrastructure for US3

- [ ] T061 [US3] Create Artifact, PublishOptions, FetchOptions types per data-model.md in cli/internal/oci/types.go
- [ ] T062 [US3] Implement oras-go client wrapper in cli/internal/oci/client.go
- [ ] T063 [US3] Implement docker config auth integration (~/.docker/config.json) in cli/internal/oci/auth.go
- [ ] T064 [US3] Implement module packaging for OCI artifact (tar.gz) in cli/internal/oci/package.go
- [ ] T065 [US3] Implement publish (push to registry) in cli/internal/oci/publish.go
- [ ] T066 [US3] Implement fetch (pull from registry) in cli/internal/oci/fetch.go

### OCI Commands for US3

- [ ] T067 [US3] Implement `opm mod publish <oci-url>` with --tag, --force in cli/internal/cmd/mod/publish.go
- [ ] T068 [US3] Implement `opm mod get <oci-url>` with --version, --output-dir in cli/internal/cmd/mod/get.go

### Integration Tests for US3

- [ ] T070 [P] [US3] Integration test for publish/get with local registry in cli/tests/integration/oci_test.go

**Checkpoint**: User Story 3 complete - user can publish to and get from OCI registries

---

## Phase 6: User Story 4 - Multi-Module Platform Deployment (Priority: P4)

**Goal**: Bundle support for deploying multiple modules as a coordinated unit

**Independent Test**: Create a bundle with 2-3 modules, apply it to cluster, verify all modules deploy correctly with `opm bundle status`

### Bundle Types for US4

- [ ] T071 [US4] Create Bundle and BundleMetadata types per data-model.md in cli/internal/cue/bundle.go
- [ ] T072 [US4] Implement bundle loader (bundle.cue + modules.cue) in cli/internal/cue/bundle_loader.go
- [ ] T073 [US4] Implement bundle renderer (all modules -> combined ManifestSet) in cli/internal/cue/bundle_renderer.go

### Bundle Commands for US4

- [ ] T074 [US4] Create bundle command group in cli/internal/cmd/bundle/bundle.go
- [ ] T075 [P] [US4] Implement `opm bundle init` in cli/internal/cmd/bundle/init.go
- [ ] T076 [P] [US4] Implement `opm bundle vet` in cli/internal/cmd/bundle/vet.go
- [ ] T077 [P] [US4] Implement `opm bundle tidy` in cli/internal/cmd/bundle/tidy.go
- [ ] T078 [P] [US4] Implement `opm bundle build` in cli/internal/cmd/bundle/build.go
- [ ] T079 [US4] Implement `opm bundle apply` in cli/internal/cmd/bundle/apply.go
- [ ] T080 [US4] Implement `opm bundle delete` in cli/internal/cmd/bundle/delete.go
- [ ] T081 [P] [US4] Implement `opm bundle diff` in cli/internal/cmd/bundle/diff.go
- [ ] T082 [P] [US4] Implement `opm bundle status` in cli/internal/cmd/bundle/status.go
- [ ] T083 [P] [US4] Implement `opm bundle publish` in cli/internal/cmd/bundle/publish.go
- [ ] T084 [P] [US4] Implement `opm bundle get` in cli/internal/cmd/bundle/get.go

### Integration Tests for US4

- [ ] T085 [US4] Create test fixtures (multi-component bundle) in cli/tests/fixtures/multi-component/
- [ ] T086 [P] [US4] Integration tests for bundle apply/delete in cli/tests/integration/bundle_test.go
- [ ] T087 [P] [US4] E2E tests for bundle workflow in cli/tests/e2e/bundle_test.go

**Checkpoint**: User Story 4 complete - platform team can deploy multi-module bundles

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Production readiness and developer experience

### Error Handling

- [ ] T088 Improve error messages with context and suggestions per contracts/exit-codes.md in cli/internal/cmd/errors.go
- [ ] T089 [P] Map Kubernetes API errors to exit codes in cli/internal/kubernetes/errors.go

### Help & Completion

- [ ] T090 [P] Add glamour markdown rendering for help text in cli/internal/output/help.go
- [ ] T091 Implement shell completion (bash, zsh, fish, powershell) in cli/cmd/opm/completion.go

### Environment Support

- [ ] T092 [P] Implement NO_COLOR environment variable support in cli/internal/output/styles.go
- [ ] T093 [P] Add --watch flag to status command for continuous updates in cli/internal/cmd/mod/status.go

### E2E Tests

- [ ] T094 E2E test suite for module workflow in cli/tests/e2e/mod_test.go
- [ ] T095 [P] Validate against quickstart.md scenarios in cli/tests/e2e/quickstart_test.go

### Build & Release

- [ ] T096 Setup goreleaser for cross-platform builds in cli/.goreleaser.yml
- [ ] T097 [P] Add build-time version injection via ldflags in cli/Taskfile.yml

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational + US5)**: Depends on Phase 1 - BLOCKS all user stories
- **Phase 3 (US1 - P1)**: Depends on Phase 2 completion
- **Phase 4 (US2 - P2)**: Depends on Phase 2 completion; can run in parallel with US1 (different files)
- **Phase 5 (US3 - P3)**: Depends on Phase 2 completion; can run in parallel with US1/US2
- **Phase 6 (US4 - P4)**: Depends on US1 core infrastructure (loader, renderer, K8s client)
- **Phase 7 (Polish)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundation only - establishes core CUE and K8s integration
- **User Story 2 (P2)**: Foundation only - adds diff capability (builds on US1 infrastructure)
- **User Story 3 (P3)**: Foundation only - adds OCI distribution (independent of US1/US2)
- **User Story 4 (P4)**: Depends on US1 core infrastructure (loader, renderer, K8s client)
- **User Story 5 (P5)**: Foundation only - config commands (can be done early in Phase 2)

### Within Each User Story

- Types/Models before implementations
- CUE integration before K8s client operations
- Core implementation before commands
- Commands before integration tests

### Parallel Opportunities

**Phase 1 (Setup)**:

```
T003, T004 can run in parallel
```

**Phase 2 (Foundational)**:

```
T007, T008, T009, T010 can run in parallel
T012, T014, T015, T016, T017 can run in parallel
T023, T024, T025 can run in parallel
```

**Phase 3 (US1)**:

```
T031 can run in parallel with T026-T030
T038, T040 can run in parallel
T049, T050, T051 can run in parallel
```

**Phase 4 (US2)**:

```
T058, T059 can run in parallel
```

**Phase 5 (US3)**:

```
T070 independent of other US3 implementation tasks (write test first)
```

**Phase 6 (Bundle)**:

```
T075, T076, T077, T078 can run in parallel
T081, T082, T083, T084 can run in parallel
T086, T087 can run in parallel
```

---

## Parallel Example: Phase 2 Foundational

```bash
# Wave 1 - Types and constants:
Task: T006 "Define exit code constants in cli/internal/cmd/exit.go"
Task: T008 "Create version info types in cli/internal/version/version.go"
Task: T014 "Define output format constants in cli/internal/output/format.go"
Task: T021 "Define resource weight constants in cli/pkg/weights/weights.go"

# Wave 2 - Implementations (after Wave 1):
Task: T007 "Implement error-to-exit-code mapping in cli/internal/cmd/errors.go"
Task: T009 "Implement CUE version compatibility in cli/internal/version/version.go"
Task: T010 "Implement CUE binary detection in cli/internal/version/cue.go"
Task: T015 "Create lipgloss styles in cli/internal/output/styles.go"
Task: T016 "Implement charmbracelet/log setup in cli/internal/output/log.go"
Task: T017 "Implement huh/spinner wrapper in cli/internal/output/spinner.go"

# Wave 3 - Config and root command (after Wave 2):
Task: T011 "Implement config types in cli/internal/config/config.go"
Task: T012 "Implement config file paths in cli/internal/config/paths.go"
Task: T013a "Create embedded CUE schema for config validation in cli/internal/config/schema.cue"
Task: T018 "Implement root command in cli/cmd/opm/root.go"

# Wave 4 - Config commands (after Wave 3):
Task: T013c "Create config command group in cli/internal/cmd/config/config.go"
Task: T013d "Implement opm config init in cli/internal/cmd/config/init.go"
Task: T013e "Implement opm config vet in cli/internal/cmd/config/vet.go"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test with quickstart.md scenarios
5. Deploy/demo with: `opm mod init`, `opm mod build`, `opm mod apply`, `opm mod status`, `opm mod delete`

**MVP Scope**: ~60 tasks (Phase 1-3 including config commands and edge case tests)

### Incremental Delivery

1. **MVP (Phase 1-3)**: First module authoring and deployment
2. **+Diff (Phase 4)**: Module update workflow with preview
3. **+Distribution (Phase 5)**: OCI registry publish/get
4. **+Bundles (Phase 6)**: Multi-module deployments
5. **+Polish (Phase 7)**: Production readiness

### Success Criteria Mapping

| Criteria | Tasks | Validation |
|----------|-------|------------|
| SC-001: First deployment < 3 min | T041a, T044, T045, T046 | E2E test timing |
| SC-002: Diff accuracy 100% | T054, T055, T056 | Integration test T060 |
| SC-003: Apply idempotency | T035 | Integration test T049 |
| SC-004: Status convergence < 60s | T039, T046, T093 | Integration test T051 |
| SC-005: OCI round-trip success | T067, T068 | Integration test T070 |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in same wave
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Exit codes per contracts/exit-codes.md must be consistent across all commands
- Resource weights per spec Section 6.2 must be exact matches
