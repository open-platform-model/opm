# Tasks: OPM Template Distribution

**Input**: Design documents from `/opm/specs/cli/012-template-oci-spec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)

## Path Conventions

- CLI code: `cli/internal/`
- Template system: `cli/internal/template/`
- Commands: `cli/internal/cmd/template/`, `cli/internal/cmd/mod/`
- Official templates: `cli/internal/template/official/`

---

## Phase 1: Template Reference Resolution

**Purpose**: Parse and resolve template references (oci://, file://, shorthand)

- [ ] T001 Create directory structure `cli/internal/template/`
- [ ] T002 [P] Implement `cli/internal/template/reference.go` with TemplateRef type and parsing
- [ ] T003 [P] Implement ref type detection (oci/file/shorthand) in reference.go
- [ ] T004 Implement shorthand resolution with registry precedence (flag > env > config > default)
- [ ] T005 Implement URL scheme normalization (implicit oci:// when path contains `/`)
- [ ] T006 Unit tests for all reference formats and edge cases

**Checkpoint**: `ParseRef("standard")` → `oci://registry.opmodel.dev/templates/standard:latest`

---

## Phase 2: Template Manifest

**Purpose**: Parse and validate template.cue manifests

- [ ] T007 Define manifest CUE schema in `cli/internal/template/schema/manifest.cue`
- [ ] T008 Implement `cli/internal/template/manifest.go` for parsing template.cue
- [ ] T009 [P] Implement validation: required fields (name, version, description)
- [ ] T010 [P] Implement validation: name format (lowercase alphanumeric with hyphens)
- [ ] T011 [P] Implement validation: placeholder validation (only ModuleName, ModulePath, Version)
- [ ] T012 Unit tests for valid and invalid manifests

**Checkpoint**: `ParseManifest("template.cue")` returns validated manifest struct

---

## Phase 3: OCI Client Integration

**Purpose**: Fetch and push templates via OCI registries

- [ ] T013 Implement `cli/internal/template/client.go` wrapping ORAS
- [ ] T014 [P] Implement `Pull(ref)` for fetching templates from OCI
- [ ] T015 [P] Implement `Push(dir, ref)` for publishing templates to OCI
- [ ] T016 Implement `List(registry)` for listing templates from registry
- [ ] T017 Implement `Resolve(ref)` for fetching manifest metadata without full pull
- [ ] T018 [P] Implement authentication via `~/.docker/config.json`
- [ ] T019 Integration tests with local registry (zot)

**Checkpoint**: Templates can be pulled from and pushed to OCI registries

---

## Phase 4: Template Caching

**Purpose**: Cache templates locally following CUE cache patterns

- [ ] T020 Implement `cli/internal/template/cache.go` with CUE cache directory structure
- [ ] T021 [P] Implement cache key generation from OCI reference
- [ ] T022 [P] Implement cache lookup before OCI fetch
- [ ] T023 Implement cache write after successful fetch
- [ ] T024 Unit tests for cache operations

**Checkpoint**: Repeated fetches use local cache, no redundant network calls

---

## Phase 5: Template Rendering

**Purpose**: Render templates with placeholder substitution

- [ ] T025 Implement `cli/internal/template/renderer.go` with text/template
- [ ] T026 [P] Implement placeholder context struct (ModuleName, ModulePath, Version)
- [ ] T027 [P] Implement `.tmpl` suffix stripping during render
- [ ] T028 [P] Implement ModulePath derivation (hyphen → underscore, example.com/ prefix)
- [ ] T029 Implement directory structure preservation during render
- [ ] T030 Unit tests for rendering edge cases (special characters, nested dirs)

**Checkpoint**: Template files rendered with placeholders substituted, .tmpl removed

---

## Phase 6: CLI Commands - Discovery (US1, US2, US3)

**Purpose**: `opm template list` and `opm template show`

- [ ] T031 Create `cli/internal/cmd/template/template.go` command group
- [ ] T032 [P] [US2] Implement `opm template list` in `cli/internal/cmd/template/list.go`
- [ ] T033 [P] [US2] Implement table output format for list (Name, Version, Description)
- [ ] T034 [P] [US2] Implement JSON output format for list (`-o json`)
- [ ] T035 [US3] Implement `opm template show <ref>` in `cli/internal/cmd/template/show.go`
- [ ] T036 [US3] Display: name, version, description, placeholders, file tree
- [ ] T037 Handle registry errors with appropriate exit codes (3 for connectivity, 5 for not found)
- [ ] T038 Integration tests for list and show commands

**Checkpoint**: `opm template list` and `opm template show standard` work

---

## Phase 7: CLI Commands - Get & Validate (US4)

**Purpose**: `opm template get` and `opm template validate`

- [ ] T039 [US4] Implement `opm template get <ref>` in `cli/internal/cmd/template/get.go`
- [ ] T040 [P] [US4] Implement `--dir` flag for custom output directory
- [ ] T041 [P] [US4] Implement `--force` flag for overwriting existing directories
- [ ] T042 [US4] Default output directory to template name if --dir not specified
- [ ] T043 Implement `opm template validate` in `cli/internal/cmd/template/validate.go`
- [ ] T044 Validate: manifest present, at least one .tmpl file, valid placeholders
- [ ] T045 Integration tests for get and validate commands

**Checkpoint**: `opm template get standard --dir ./my-tpl` downloads template files

---

## Phase 8: CLI Commands - Publish (US5)

**Purpose**: `opm template publish`

- [ ] T046 [US5] Implement `opm template publish <oci-ref>` in `cli/internal/cmd/template/publish.go`
- [ ] T047 [US5] Run validation before publish (reuse validate logic)
- [ ] T048 [US5] Pack template directory as OCI artifact with correct media types
- [ ] T049 [US5] Push to registry using ORAS client
- [ ] T050 Integration tests with local registry

**Checkpoint**: `opm template publish registry.example.com/my-template:v1` works

---

## Phase 9: Mod Init Integration (US1)

**Purpose**: Wire templates into `opm mod init --template`

- [ ] T051 [US1] Modify `cli/internal/cmd/mod/init.go` to use template system
- [ ] T052 [US1] Implement template reference resolution (oci://, file://, shorthand)
- [ ] T053 [P] [US1] Implement `--name` flag for ModuleName override
- [ ] T054 [P] [US1] Implement `--module` flag for ModulePath override
- [ ] T055 [US1] Implement `--force` flag for overwriting existing directories
- [ ] T056 [US1] Verify generated module passes `opm mod vet`
- [ ] T057 E2E tests: init from OCI, init from file://, init with shorthand

**Checkpoint**: `opm mod init my-app --template standard` creates valid module

---

## Phase 10: Official Templates

**Purpose**: Create and publish official templates to registry.opmodel.dev

### Simple Template

- [ ] T058 [P] Create `cli/internal/template/official/simple/template.cue`
- [ ] T059 [P] Create `cli/internal/template/official/simple/module.cue.tmpl`
- [ ] T060 [P] Create `cli/internal/template/official/simple/values.cue.tmpl`
- [ ] T061 [P] Create `cli/internal/template/official/simple/cue.mod/module.cue.tmpl`

### Standard Template

- [ ] T062 [P] Create `cli/internal/template/official/standard/template.cue`
- [ ] T063 [P] Create `cli/internal/template/official/standard/module.cue.tmpl`
- [ ] T064 [P] Create `cli/internal/template/official/standard/values.cue.tmpl`
- [ ] T065 [P] Create `cli/internal/template/official/standard/components.cue.tmpl`
- [ ] T066 [P] Create `cli/internal/template/official/standard/cue.mod/module.cue.tmpl`

### Advanced Template

- [ ] T067 [P] Create `cli/internal/template/official/advanced/template.cue`
- [ ] T068 [P] Create `cli/internal/template/official/advanced/module.cue.tmpl`
- [ ] T069 [P] Create `cli/internal/template/official/advanced/values.cue.tmpl`
- [ ] T070 [P] Create `cli/internal/template/official/advanced/components.cue.tmpl`
- [ ] T071 [P] Create `cli/internal/template/official/advanced/scopes.cue.tmpl`
- [ ] T072 [P] Create `cli/internal/template/official/advanced/policies.cue.tmpl`
- [ ] T073 [P] Create `cli/internal/template/official/advanced/debug_values.cue.tmpl`
- [ ] T074 [P] Create `cli/internal/template/official/advanced/cue.mod/module.cue.tmpl`
- [ ] T075 [P] Create `cli/internal/template/official/advanced/components/*.cue.tmpl` (web, api, worker, db)
- [ ] T076 [P] Create `cli/internal/template/official/advanced/scopes/*.cue.tmpl` (frontend, backend)

### Validation & Publishing

- [ ] T077 Validate all official templates generate modules that pass `opm mod vet`
- [ ] T078 Publish official templates to `registry.opmodel.dev/templates/`
- [ ] T079 Test shorthand resolution: `standard` → `registry.opmodel.dev/templates/standard:latest`

**Checkpoint**: All three official templates published and resolvable via shorthand

---

## Phase 11: Testing and Polish

**Purpose**: Production readiness

- [ ] T080 E2E tests for all user stories (US1-US6)
- [ ] T081 [P] Performance test: SC-001 (init < 10s warm cache)
- [ ] T082 [P] Performance test: SC-003 (list < 5s)
- [ ] T083 Registry compatibility tests (GHCR, Docker Hub, Harbor, Zot)
- [ ] T084 [P] Add help text and examples for all commands
- [ ] T085 [P] Add debug-level logging via charmbracelet/log
- [ ] T086 Update CLI documentation

**Checkpoint**: All tests passing, documentation complete

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Reference) ──┐
Phase 2 (Manifest) ───┼──► Phase 3 (OCI) ──► Phase 4 (Cache)
                      │
                      └──► Phase 5 (Renderer) ──┐
                                                │
Phase 6 (list/show) ◄───────────────────────────┤
Phase 7 (get/validate) ◄────────────────────────┤
Phase 8 (publish) ◄─────────────────────────────┤
Phase 9 (mod init) ◄────────────────────────────┘
                                                │
Phase 10 (Official Templates) ◄─────────────────┤
Phase 11 (Polish) ◄─────────────────────────────┘
```

### Parallel Opportunities

- **Phase 1**: T002, T003 can run in parallel
- **Phase 2**: T009, T010, T011 can run in parallel
- **Phase 3**: T014, T015, T018 can run in parallel
- **Phase 4**: T021, T022 can run in parallel
- **Phase 5**: T026, T027, T028 can run in parallel
- **Phase 6**: T032, T033, T034 can run in parallel
- **Phase 7**: T040, T041 can run in parallel
- **Phase 9**: T053, T054 can run in parallel
- **Phase 10**: ALL template file tasks (T058-T076) can run in parallel
- **Phase 11**: T081, T082, T084, T085 can run in parallel

---

## MVP Definition

**Minimal Viable Product**: User can initialize module from OCI template

### MVP Tasks (32 tasks)

1. Phase 1: Reference Resolution (6 tasks)
2. Phase 2: Manifest (6 tasks)
3. Phase 3: OCI Client (7 tasks)
4. Phase 4: Caching (5 tasks)
5. Phase 5: Rendering (6 tasks)
6. Phase 9: Mod Init Integration (7 tasks) - partial

**MVP Test**: `opm mod init my-app --template oci://registry.example.com/standard:v1`

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 86 |
| Phase 1-5 (Core) | 30 |
| Phase 6-8 (CLI Commands) | 20 |
| Phase 9 (Integration) | 7 |
| Phase 10 (Official Templates) | 22 |
| Phase 11 (Polish) | 7 |
| MVP Tasks | ~32 |
| Parallel Opportunities | 10+ phases |
