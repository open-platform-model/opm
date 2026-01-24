# Tasks: OPM Module Template System

**Input**: Design documents from `/opm/specs/006-cli-module-template-spec/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: Not explicitly requested - omitted per spec.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)

## Path Conventions

- CLI code: `cli/internal/`
- Templates: `cli/internal/templates/`
- Commands: `cli/internal/cmd/mod/`

---

## Phase 1: Setup

**Purpose**: Project initialization and directory structure

- [X] T001 Create directory structure `cli/internal/templates/` with simple/, standard/, advanced/ subdirs
- [X] T002 [P] Create `cli/internal/templates/types.go` with Template struct (Name, Description, Default, Files)
- [X] T003 [P] Create new `cli/internal/cmd/mod/init.go` with mod init command skeleton (extends 004-cli-spec cmd structure)
- [X] T004 [P] Create placeholder `cli/internal/cmd/mod/template.go` stub for template subcommands

---

## Phase 2: Foundational (Template Infrastructure)

**Purpose**: Core template system that ALL user stories depend on

**⚠️ CRITICAL**: No template implementation can begin until this phase is complete

- [X] T005 Implement `cli/internal/templates/embed.go` with `//go:embed` directive for all template directories
- [X] T006 [P] Implement `cli/internal/templates/registry.go` with template registration (simple, standard, advanced)
- [X] T007 [P] Implement `cli/internal/templates/renderer.go` with text/template rendering and placeholder substitution
- [X] T008 [P] Implement `cli/internal/templates/validator.go` with CUE identifier validation (FR-017)
- [X] T009 Implement `cli/internal/templates/generator.go` with directory creation, file writing, and --force logic (FR-019)

**Checkpoint**: Template infrastructure ready - user story implementation can begin

---

## Phase 3: User Story 1 - Simple Template (Priority: P1) 🎯 MVP

**Goal**: New users can create minimal module with inline components

**Independent Test**: `opm mod init my-app --template simple && cd my-app && opm mod vet`

### Implementation

- [X] T010 [P] [US1] Create `cli/internal/templates/simple/cue.mod/module.cue.tmpl` per data-model.md section 2.1
- [X] T011 [P] [US1] Create `cli/internal/templates/simple/module.cue.tmpl` per data-model.md section 3.1
- [X] T012 [P] [US1] Create `cli/internal/templates/simple/values.cue.tmpl` per data-model.md section 3.2
- [X] T013 [US1] Register simple template in registry.go with description "Single-file inline - Learning OPM, prototypes"

**Checkpoint**: `--template simple` generates 3 valid files that pass `opm mod vet`

---

## Phase 4: User Story 2 - Standard Template (Priority: P2)

**Goal**: Team projects with separated components

**Independent Test**: `opm mod init my-app --template standard && cd my-app && opm mod vet`

### Implementation

- [X] T014 [P] [US2] Create `cli/internal/templates/standard/cue.mod/module.cue.tmpl` per data-model.md section 2.1
- [X] T015 [P] [US2] Create `cli/internal/templates/standard/module.cue.tmpl` per data-model.md section 4.1
- [X] T016 [P] [US2] Create `cli/internal/templates/standard/components.cue.tmpl` per data-model.md section 4.2
- [X] T017 [US2] Create `cli/internal/templates/standard/values.cue.tmpl` and register template with Default: true

**Checkpoint**: `--template standard` generates 4 valid files that pass `opm mod vet`

---

## Phase 5: User Story 3 - Advanced Template (Priority: P3)

**Goal**: Multi-package module with components/, scopes/ subpackages

**Independent Test**: `opm mod init my-platform --template advanced && cd my-platform && opm mod vet`

### Implementation

- [X] T018 [P] [US3] Create `cli/internal/templates/advanced/cue.mod/module.cue.tmpl`
- [X] T019 [P] [US3] Create `cli/internal/templates/advanced/module.cue.tmpl` per data-model.md section 5.1
- [X] T020 [P] [US3] Create `cli/internal/templates/advanced/components.cue.tmpl` with import from components/ per section 5.2
- [X] T021a [P] [US3] Create `cli/internal/templates/advanced/scopes.cue.tmpl` per data-model.md section 5.3
- [X] T021b [P] [US3] Create `cli/internal/templates/advanced/policies.cue.tmpl` per data-model.md section 5.4
- [X] T021c [P] [US3] Create `cli/internal/templates/advanced/debug_values.cue.tmpl` per data-model.md section 5.5
- [X] T021d [P] [US3] Create `cli/internal/templates/advanced/values.cue.tmpl` per data-model.md section 5.6
- [X] T022 [P] [US3] Create `cli/internal/templates/advanced/components/web.cue.tmpl`, `api.cue.tmpl`, `worker.cue.tmpl`, `db.cue.tmpl` per section 6
- [X] T023 [P] [US3] Create `cli/internal/templates/advanced/scopes/frontend.cue.tmpl`, `backend.cue.tmpl` per section 7
- [X] T024 [US3] Register advanced template and verify cross-package imports work with `{{.ModulePath}}`

**Checkpoint**: `--template advanced` generates 13 valid files with working imports

---

## Phase 6: User Story 4 - Default Template (Priority: P4)

**Goal**: Omitting `--template` uses standard template by default

**Independent Test**: `opm mod init my-app` (no --template) creates standard template structure

### Implementation

- [X] T025 [US4] Implement default template selection in `cli/internal/cmd/mod/init.go` when --template not specified (FR-002)
- [X] T026 [US4] Output message showing which template was used when defaulting

**Checkpoint**: `opm mod init my-app` defaults to standard and shows "Using template: standard"

---

## Phase 7: User Story 5 - List Templates (Priority: P5)

**Goal**: Users can discover available templates

**Independent Test**: `opm mod template list` shows simple, standard (default), advanced with descriptions

### Implementation

- [X] T027 [US5] Implement `template list` subcommand in `cli/internal/cmd/mod/template.go` (FR-005)
- [X] T028 [US5] Format output as table with Name, Description, Default columns
- [X] T029 [US5] Mark default template with "(default)" indicator in output

**Checkpoint**: `opm mod template list` shows formatted table with 3 templates

---

## Phase 8: User Story 6 - Show Template (Priority: P6)

**Goal**: Users can inspect template details before using

**Independent Test**: `opm mod template show advanced` shows file listing with subdirectories

### Implementation

- [X] T030 [US6] Implement `template show <name>` subcommand in `cli/internal/cmd/mod/template.go` (FR-005a)
- [X] T031 [US6] Display template description, target use case, and file listing from embedded filesystem
- [X] T032 [US6] Handle unknown template name with exit code 2 and list valid options

**Checkpoint**: `opm mod template show advanced` displays 13 files including subdirectories

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final integration and production readiness

- [X] T033 Wire init command with --template, --name, --module, --force flags in `cli/internal/cmd/mod/init.go`
- [X] T034 [P] Add debug-level logging via charmbracelet/log for all template operations (FR-018)
- [X] T035 [P] Implement module path derivation: `example.com/<dirname>` with hyphen→underscore (FR-016)
- [X] T036 [P] Add help text and examples for all commands
- [ ] T037 Run quickstart.md validation: verify all templates with init→vet→build cycle; confirm SC-001 timing target (<30s per template)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **US1-US6 (Phases 3-8)**: All depend on Foundational phase completion
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (Simple)**: Can start after Foundational - No dependencies on other stories
- **US2 (Standard)**: Can start after Foundational - No dependencies on other stories
- **US3 (Advanced)**: Can start after Foundational - No dependencies on other stories
- **US4 (Default)**: Depends on US2 (needs standard template registered as default)
- **US5 (List)**: Depends on US1-US3 (needs all templates registered)
- **US6 (Show)**: Depends on US1-US3 (needs all templates registered)

### Within Each User Story

- Template files [P] can be created in parallel
- Registration task must follow file creation
- Checkpoint validation confirms story completion

### Parallel Opportunities

- **Setup**: T002, T003, T004 can run in parallel after T001
- **Foundational**: T006, T007, T008 can run in parallel after T005
- **US1**: T010, T011, T012 can run in parallel
- **US2**: T014, T015, T016 can run in parallel
- **US3**: T018-T023 can ALL run in parallel
- **Polish**: T034, T035, T036 can run in parallel

---

## Parallel Example: User Story 3

```bash
# Launch all template files together:
Task: "Create cli/internal/templates/advanced/cue.mod/module.cue.tmpl"
Task: "Create cli/internal/templates/advanced/module.cue.tmpl"
Task: "Create cli/internal/templates/advanced/components.cue.tmpl"
Task: "Create cli/internal/templates/advanced/scopes.cue.tmpl + policies.cue.tmpl + debug_values.cue.tmpl + values.cue.tmpl"
Task: "Create cli/internal/templates/advanced/components/web.cue.tmpl + api.cue.tmpl + worker.cue.tmpl + db.cue.tmpl"
Task: "Create cli/internal/templates/advanced/scopes/frontend.cue.tmpl + backend.cue.tmpl"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (4 tasks)
2. Complete Phase 2: Foundational (5 tasks)
3. Complete Phase 3: US1 - Simple Template (4 tasks)
4. **STOP and VALIDATE**: Test `opm mod init --template simple`
5. **Total MVP**: 13 tasks

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US1 → `--template simple` works (MVP!)
3. Add US2 → `--template standard` works + default
4. Add US3 → `--template advanced` works
5. Add US5/US6 → Discovery commands work
6. Polish → Production ready

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Simple)
   - Developer B: User Story 2 (Standard)
   - Developer C: User Story 3 (Advanced)
3. Stories complete and integrate independently
4. US4-US6 can proceed once dependencies met

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 40 |
| Setup Tasks | 4 |
| Foundational Tasks | 5 |
| User Story Tasks | 26 |
| Polish Tasks | 5 |
| MVP Tasks (US1) | 13 |
| Parallel Opportunities | 6 phases with [P] tasks |
