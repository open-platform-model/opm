# Tasks: OPM CLI v2

**Input**: Design documents from `/opm/specs/cli/002-cli-spec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/exit-codes.md, contracts/error-format.md, reference/commands.md, reference/project-structure.md

**Tests**: Not explicitly requested in spec. Integration/E2E tests marked as "Not implemented now" in plan.md.

**Scope Note**: Commands `mod build`, `mod apply`, `mod delete`, `mod diff`, `mod status` are specified in 004-render-and-lifecycle-spec. This task list covers only functionality in 002-cli-spec scope.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize Go project with dependencies and tooling

- [ ] T001 Create Go module at cli/go.mod with module path `opmodel.dev/cli`
- [ ] T002 [P] Create Taskfile.yml at cli/Taskfile.yml with build, test, lint tasks
- [ ] T003 [P] Configure golangci-lint at cli/.golangci.yml
- [ ] T004 Add core dependencies to go.mod: spf13/cobra, spf13/viper, cuelang.org/go, charmbracelet/{lipgloss,log}

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Shared infrastructure that ALL user stories depend on. MUST complete before any user story.

### Exit Codes & Error Handling

- [ ] T005 Define exit code constants per contracts/exit-codes.md in cli/internal/cmd/exit.go
- [ ] T006 [P] Define sentinel errors (ErrValidation, ErrConnectivity, ErrNotFound, ErrVersion, ErrPermission) in cli/internal/errors/errors.go
- [ ] T007 Implement exitCodeFromError() function mapping errors to exit codes in cli/internal/cmd/exit.go

### Output Infrastructure

- [ ] T008 [P] Define OutputFormat enum (text, yaml, json) per data-model.md in cli/internal/output/format.go
- [ ] T009 [P] Setup charmbracelet/log with levels and colors per research.md in cli/internal/output/log.go
- [ ] T010 [P] Implement lipgloss table rendering for status output in cli/internal/output/table.go

### Version Infrastructure

- [ ] T011 [P] Define Info and CUEBinaryInfo structs per data-model.md in cli/internal/version/version.go
- [ ] T012 Implement CUEVersionCompatible() comparing MAJOR.MINOR in cli/internal/version/version.go
- [ ] T013 Implement GetCUEBinaryInfo() detecting CUE binary and version in cli/internal/version/version.go

### Root Command

- [ ] T014 Create root cobra command with global flags (--kubeconfig, --context, --namespace, --config, --output-format, --verbose) in cli/internal/cmd/root.go
- [ ] T015 Implement PersistentPreRunE in root.go for logging setup and config loading
- [ ] T016 Create entry point at cli/cmd/opm/main.go calling root command

### Paths Infrastructure

- [ ] T017 Define Paths struct (ConfigFile, CacheDir, HomeDir) and helper functions in cli/internal/config/paths.go

**Checkpoint**: Foundation ready - user story implementation can begin

---

## Phase 3: User Story 1 - First-Time Module Authoring (Priority: P1)

**Goal**: A new user can create a module from template, validate it, and manage dependencies

**Independent Test**: Run `opm mod init my-app && cd my-app && opm mod vet && opm mod tidy` and verify success

### Templates

- [ ] T018 [P] [US1] Create simple template files in cli/internal/templates/simple/ (module.cue.tmpl, values.cue.tmpl, cue.mod/module.cue.tmpl)
- [ ] T019 [P] [US1] Create standard template files in cli/internal/templates/standard/ (module.cue.tmpl, components.cue.tmpl, values.cue.tmpl, cue.mod/module.cue.tmpl)
- [ ] T020 [P] [US1] Create advanced template files in cli/internal/templates/advanced/ (module.cue.tmpl, components.cue.tmpl, scopes.cue.tmpl, policies.cue.tmpl, values.cue.tmpl, debug_values.cue.tmpl, cue.mod/module.cue.tmpl, components/*.cue.tmpl, scopes/*.cue.tmpl)
- [ ] T021 [US1] Implement go:embed for templates and template rendering in cli/internal/templates/embed.go

### CUE Binary Delegation

- [ ] T022 [US1] Implement checkCueVersion() validating CUE binary compatibility in cli/internal/cue/binary.go
- [ ] T023 [US1] Implement runCueCommand() with CUE_REGISTRY passthrough in cli/internal/cue/binary.go

### Module Commands

- [ ] T024 [US1] Create mod command group in cli/internal/cmd/mod.go
- [ ] T025 [US1] Implement `mod init` command with --template and --dir flags in cli/internal/cmd/mod_init.go
- [ ] T026 [US1] Add template validation (simple/standard/advanced) with exit code 2 for unknown templates in mod_init.go
- [ ] T027 [US1] Implement aligned file tree output (column 30) after successful init in mod_init.go
- [ ] T028 [US1] Implement `mod vet` command delegating to CUE binary with --concrete flag in cli/internal/cmd/mod_vet.go
- [ ] T029 [US1] Implement `mod tidy` command delegating to CUE binary in cli/internal/cmd/mod_tidy.go
- [ ] T030 [US1] Implement version command showing CLI/CUE info per reference/commands.md in cli/internal/cmd/version.go

**Checkpoint**: User Story 1 complete - module authoring workflow functional

---

## Phase 4: User Story 2 - First-Time Configuration Initialization (Priority: P1)

**Goal**: Platform operator can initialize CLI config with kubernetes provider using `opm config init`

**Independent Test**: Run `opm config init` on fresh system and verify ~/.opm/config.cue and ~/.opm/cue.mod/module.cue exist with correct permissions

### Config Types

- [ ] T031 [P] [US2] Define Config struct with fields per data-model.md in cli/internal/config/config.go
- [ ] T032 [P] [US2] Define OPMConfig struct with Providers map in cli/internal/config/config.go
- [ ] T033 [US2] Implement DefaultConfig() returning default values in cli/internal/config/config.go

### Config Init Command

- [ ] T034 [US2] Create config command group in cli/internal/cmd/config.go
- [ ] T035 [US2] Implement embedded default config.cue template with kubernetes provider in cli/internal/config/templates.go
- [ ] T036 [US2] Implement embedded cue.mod/module.cue template with opmodel.dev/providers@v0 dep in cli/internal/config/templates.go
- [ ] T037 [US2] Implement `config init` command creating ~/.opm/ directory structure in cli/internal/cmd/config_init.go
- [ ] T038 [US2] Set secure file permissions (0700 dir, 0600 files) in config_init.go
- [ ] T039 [US2] Fail with exit code 1 if config exists and --force not specified in config_init.go
- [ ] T040 [US2] Implement --force flag to overwrite existing config in config_init.go

**Checkpoint**: User Story 2 complete - config init workflow functional

---

## Phase 5: User Story 3 - Runtime Configuration Resolution (Priority: P1)

**Goal**: CLI loads config, resolves registry with correct precedence, and fetches provider modules

**Independent Test**: Set OPM_REGISTRY env, run `opm mod vet` on a module, verify registry used for CUE operations

### Two-Phase Config Loading

- [ ] T041 [US3] Implement Phase 1 (bootstrap): Extract config.registry via simple CUE parsing in cli/internal/config/loader.go
- [ ] T042 [US3] Implement resolveRegistry() with precedence: --registry flag > OPM_REGISTRY env > config.registry in cli/internal/config/resolver.go
- [ ] T043 [US3] Implement resolveConfigPath() with precedence: --config flag > OPM_CONFIG env > ~/.opm/config.cue default in cli/internal/config/resolver.go
- [ ] T044 [US3] Implement Phase 2 (full load): Load config.cue with CUE_REGISTRY set to resolved registry in cli/internal/config/loader.go
- [ ] T045 [US3] Implement LoadOPMConfig() returning OPMConfig with resolved providers in cli/internal/config/loader.go

### Registry Precedence Resolution

- [ ] T046 [US3] Implement ResolvedValue tracking for config values (key, value, source, shadowed) in cli/internal/config/resolver.go
- [ ] T047 [US3] Log config resolution at DEBUG level when --verbose is set in cli/internal/config/resolver.go

### Fail-Fast Error Handling

- [ ] T048 [US3] Fail fast with clear error if providers configured but no registry resolvable in loader.go
- [ ] T049 [US3] Fail fast with specific error (provider name + registry) if registry unreachable during provider fetch in loader.go
- [ ] T050 [US3] Implement 5-second timeout for registry connectivity checks in loader.go

### Integration with Commands

- [ ] T051 [US3] Update PersistentPreRunE to call LoadOPMConfig() and set CUE_REGISTRY for child commands in root.go
- [ ] T052 [US3] Update mod_vet.go and mod_tidy.go to pass CUE_REGISTRY env to cue binary

**Checkpoint**: User Story 3 complete - runtime config resolution functional

---

## Phase 6: User Story 4 - Configuration Validation (Priority: P2)

**Goal**: Developer can validate config with `opm config vet` and get actionable error messages

**Independent Test**: Create config.cue with errors, run `opm config vet`, verify errors include file location and field names

### Config Validation

- [ ] T053 [US4] Define embedded CUE schema for config validation in cli/internal/config/schema.cue (via go:embed)
- [ ] T054 [US4] Implement validateConfig() validating config.cue against embedded schema in cli/internal/config/validator.go
- [ ] T055 [US4] Format validation errors with file location, line numbers, field names per FR-008 and contracts/error-format.md in validator.go

### Config Vet Command

- [ ] T056 [US4] Implement `config vet` command calling validateConfig() in cli/internal/cmd/config_vet.go
- [ ] T057 [US4] Output success message with config file path on valid config in config_vet.go
- [ ] T058 [US4] Return exit code 2 on validation errors, exit code 5 if config not found in config_vet.go

**Checkpoint**: User Story 4 complete - config validation functional

---

## Phase 7: User Story 5 - Advanced Provider Configuration (Priority: P3)

**Goal**: Advanced operators can configure multiple providers and custom transformers

**Independent Test**: Add second provider to config.cue, verify both available via LoadOPMConfig()

### Multi-Provider Support

- [ ] T059 [US5] Support multiple providers in OPMConfig.Providers map during Phase 2 loading in loader.go
- [ ] T060 [US5] Add --provider global flag for provider selection in root.go

### Custom Transformers

- [ ] T061 [US5] Support CUE unification for provider extension in loader.go (provider + custom transformers)

**Checkpoint**: User Story 5 complete - advanced provider configuration functional

---

## Phase 8: Stub Commands (Out of Scope - 004-render-and-lifecycle-spec)

**Purpose**: Create stub commands that exit with "not implemented" for deferred functionality

- [ ] T062 [P] Create stub `mod build` command in cli/internal/cmd/mod_build.go (exits with message pointing to 004-spec)
- [ ] T063 [P] Create stub `mod apply` command in cli/internal/cmd/mod_apply.go
- [ ] T064 [P] Create stub `mod delete` command in cli/internal/cmd/mod_delete.go
- [ ] T065 [P] Create stub `mod diff` command in cli/internal/cmd/mod_diff.go
- [ ] T066 [P] Create stub `mod status` command in cli/internal/cmd/mod_status.go

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and validation

- [ ] T067 Run golangci-lint and fix all issues
- [ ] T068 [P] Add helpful usage examples to all cobra command long descriptions
- [ ] T069 Verify all commands return correct exit codes per contracts/exit-codes.md
- [ ] T070 Run quickstart.md validation: execute all commands in quickstart.md and verify expected behavior
- [ ] T071 [P] Verify all commands are non-interactive (no stdin reads) per FR-015
- [ ] T072 [P] Add shell completion generation (bash, zsh, fish, powershell) to root command per FR-019

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 - BLOCKS all user stories
- **Phase 3-7 (User Stories)**: All depend on Phase 2 completion
  - US1 (P1): Can start after Phase 2
  - US2 (P1): Can start after Phase 2, independent of US1
  - US3 (P1): Depends on US2 (needs config types)
  - US4 (P2): Depends on US2 (validates config)
  - US5 (P3): Depends on US3 (extends loading)
- **Phase 8 (Stubs)**: Can run after Phase 2, independent of user stories
- **Phase 9 (Polish)**: Depends on all user stories complete

### User Story Dependencies

```text
Phase 2 (Foundation)
    │
    ├──► US1 (Module Authoring) ──► Phase 9
    │
    ├──► US2 (Config Init)
    │         │
    │         ├──► US3 (Config Resolution)
    │         │         │
    │         │         └──► US5 (Advanced Providers)
    │         │
    │         └──► US4 (Config Validation)
    │
    └──► Phase 8 (Stubs - parallel)
```

### Parallel Opportunities

**Within Phase 2:**
- T005, T006 can run in parallel (separate files)
- T008, T009, T010, T011 can run in parallel (output/* and version/*)

**Within Phase 3 (US1):**
- T018, T019, T020 can run in parallel (different template directories)

**Within Phase 4 (US2):**
- T031, T032 can run in parallel (same file but additive)

**Within Phase 8:**
- All stub commands (T062-T066) can run in parallel

---

## Parallel Example: Phase 2 Foundational

```bash
# Launch output infrastructure tasks in parallel:
Task: "Define OutputFormat enum in cli/internal/output/format.go"
Task: "Setup charmbracelet/log in cli/internal/output/log.go"
Task: "Implement lipgloss table rendering in cli/internal/output/table.go"
Task: "Define Info and CUEBinaryInfo structs in cli/internal/version/version.go"
```

## Parallel Example: Phase 3 Templates

```bash
# Launch all template creation tasks in parallel:
Task: "Create simple template files in cli/internal/templates/simple/"
Task: "Create standard template files in cli/internal/templates/standard/"
Task: "Create advanced template files in cli/internal/templates/advanced/"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Module Authoring)
4. Complete Phase 4: User Story 2 (Config Init)
5. **STOP and VALIDATE**: Test both stories independently
6. Deploy/demo if ready - users can create modules and init config

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Users can author modules (MVP!)
3. Add US2 → Users can init config
4. Add US3 → Full config resolution
5. Add US4 → Config validation
6. Add US5 → Advanced providers
7. Polish → Production ready

### Suggested MVP Scope

**Minimum viable product = Phase 1 + Phase 2 + Phase 3 (US1)**

This allows users to:
- Create modules from templates (`opm mod init`)
- Validate modules (`opm mod vet`)
- Manage dependencies (`opm mod tidy`)
- Check version compatibility (`opm version`)

Config commands (US2-US5) can be added incrementally.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Commands mod build/apply/delete/diff/status deferred to 004-render-and-lifecycle-spec
- Templates based on reference/templates/ directory structure
- All exit codes must match contracts/exit-codes.md
- CUE binary version check is CRITICAL - blocks mod vet/tidy on mismatch
