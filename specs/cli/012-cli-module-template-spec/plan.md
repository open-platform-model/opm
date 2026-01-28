# Implementation Plan: OPM Module Template System

**Branch**: `012-cli-module-template-spec` | **Date**: 2026-01-23 | **Spec**: [spec.md](./spec.md)  
**Extends**: [002-cli-spec](../002-cli-spec/plan.md)

## Summary

Extend the OPM CLI with a template system for `opm mod init`. Three hardcoded templates (simple, standard, advanced) are embedded in the binary, with `opm mod template list/show` for discovery. This is an interim implementation before OCI-based templates.

## Technical Context

| Aspect | Decision | Source |
|--------|----------|--------|
| **Language** | Go 1.22+ | 002-cli-spec |
| **CLI Framework** | spf13/cobra | 002-cli-spec |
| **Template Embedding** | Go `embed` package | FR-014 |
| **Template Rendering** | Go `text/template` | data-model.md placeholders |
| **Project Location** | `cli/internal/templates/`, `cli/internal/cmd/mod/` | 002-cli-spec structure |
| **Exit Codes** | [002-cli-spec/contracts/exit-codes.md](../002-cli-spec/contracts/exit-codes.md) | Shared |
| **Logging** | charmbracelet/log (debug-level via `--debug`) | Clarification #3 |
| **Module Path** | `example.com/<dirname>` (hyphens → underscores) | Clarification #2, FR-016 |
| **Name Validation** | Reject invalid CUE identifiers with exit code 2 | Clarification #5, FR-017 |
| **Force Behavior** | Overwrite conflicts only, no prompt | Clarifications #1, #4, FR-019 |

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Definition-First** | ✅ PASS | Templates generate valid OPM definitions |
| **II. Type Safety via CUE** | ✅ PASS | Generated files pass `opm mod vet` |
| **III. Separation of Concerns** | ✅ PASS | Templates serve module developers |
| **IV. Portability by Design** | ✅ PASS | Templates are provider-agnostic |
| **V. Policy as Code** | ✅ PASS | Advanced template includes policies.cue |

## Project Structure Addition

```text
cli/internal/
├── templates/                 # NEW: Template system
│   ├── embed.go              # go:embed directive
│   ├── registry.go           # Template metadata registry
│   ├── renderer.go           # Template rendering logic
│   ├── simple/               # Simple template files
│   ├── standard/             # Standard template files
│   └── advanced/             # Advanced template files
└── cmd/mod/
    ├── init.go               # MODIFY: Add --template flag
    └── template.go           # NEW: template list/show subcommands
```

## Implementation Phases

### Phase 1: Template Infrastructure

**Goal**: Embed system and registry working

| Task | Description | FR |
|------|-------------|-----|
| 1.1 | Create `internal/templates/` directory structure | - |
| 1.2 | Implement `embed.go` with `//go:embed` for all templates | FR-014 |
| 1.3 | Implement `registry.go` with Template struct and registration | FR-001 |
| 1.4 | Implement `renderer.go` with text/template rendering | - |
| 1.5 | Unit tests for registry and renderer | - |

**Deliverable**: Template registry loads embedded files, renderer substitutes placeholders

### Phase 2: Simple Template

**Goal**: Simple template generates valid module

| Task | Description | FR |
|------|-------------|-----|
| 2.1 | Create `simple/module.cue.tmpl` with inline components | FR-009 |
| 2.2 | Create `simple/values.cue.tmpl` | FR-008 |
| 2.3 | Create `simple/cue.mod/module.cue.tmpl` | FR-003 |
| 2.4 | Add explanatory comments per template complexity | FR-015 |
| 2.5 | Test: generated module passes `opm mod vet` | FR-004 |

**Deliverable**: `--template simple` generates 3 valid files

### Phase 3: Standard Template

**Goal**: Standard template with separated components

| Task | Description | FR |
|------|-------------|-----|
| 3.1 | Create `standard/module.cue.tmpl` with metadata only | FR-010 |
| 3.2 | Create `standard/components.cue.tmpl` with extracted components | FR-010 |
| 3.3 | Create `standard/values.cue.tmpl` | FR-008 |
| 3.4 | Create `standard/cue.mod/module.cue.tmpl` | FR-003 |
| 3.5 | Test: generated module passes `opm mod vet` | FR-004 |

**Deliverable**: `--template standard` generates 4 valid files

### Phase 4: Advanced Template

**Goal**: Multi-package template with subdirectories

| Task | Description | FR |
|------|-------------|-----|
| 4.1 | Create root files: module, values, components, scopes, policies, debug_values | FR-011 |
| 4.2 | Create `components/` subpackage: web, api, worker, db templates | FR-011 |
| 4.3 | Create `scopes/` subpackage: frontend, backend templates | FR-011 |
| 4.4 | Implement cross-package imports with `{{.ModulePath}}` | FR-011 |
| 4.5 | Test: generated module passes `opm mod vet` | FR-004 |
| 4.6 | Test: `opm mod vet --concrete` with debug_values works | SC-005 |

**Deliverable**: `--template advanced` generates 13 valid files with working imports

### Phase 5: Template Discovery Commands

**Goal**: `opm mod template list` and `opm mod template show`

| Task | Description | FR |
|------|-------------|-----|
| 5.1 | Create `cmd/mod/template.go` with template subcommand group | FR-005 |
| 5.2 | Implement `template list` with formatted output | FR-005 |
| 5.3 | Implement `template show <name>` with file listing | FR-005a |
| 5.4 | Mark default template in list output | FR-002 |
| 5.5 | Handle unknown template name with exit code 2 | Edge case |

**Deliverable**: Template discovery commands work

### Phase 6: Init Command Integration

**Goal**: Wire templates into `opm mod init`

| Task | Description | FR |
|------|-------------|-----|
| 6.1 | Add `--template` flag to init command | FR-001 |
| 6.2 | Default to standard template when not specified | FR-002 |
| 6.3 | Add `--name` flag for metadata.name override | FR-012 |
| 6.4 | Add `--module` flag for CUE module path override | FR-013 |
| 6.5 | Add `--force` flag for non-empty directory | FR-006 |
| 6.6 | Implement directory creation with nested paths | Edge case |
| 6.7 | Output message showing which template was used | US-4 |

**Deliverable**: `opm mod init` fully integrated with templates

### Phase 7: Testing and Polish

**Goal**: Production readiness

| Task | Description | FR |
|------|-------------|-----|
| 7.1 | Integration tests for all three templates | SC-002 |
| 7.2 | Test `opm mod build -o yaml` produces valid K8s manifests | SC-004 |
| 7.3 | E2E test: init → vet → build cycle | SC-001 |
| 7.4 | Error message improvements | - |
| 7.5 | Help text and examples | - |
| 7.6 | Update CLI documentation | - |

**Deliverable**: All tests passing, documentation complete

## Dependencies

No new dependencies required. Uses:

- `embed` (stdlib)
- `text/template` (stdlib)
- `io/fs` (stdlib)
- Existing 002-cli-spec dependencies (cobra, etc.)

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Template validation drift | Medium | Automated tests run `opm mod vet` on generated output |
| CUE version incompatibility | Low | Templates use stable CUE syntax |
| Placeholder escaping issues | Low | Unit tests for edge cases in names |

## Success Metrics

Per spec Success Criteria:

| Metric | Target | Test |
|--------|--------|------|
| SC-001 | Init + vet < 30s | E2E timing test |
| SC-002 | 100% pass `opm mod vet` | Integration tests |
| SC-003 | Template selection < 10s | UX review |
| SC-004 | Valid K8s manifests | `opm mod build` output validation |
| SC-005 | Multi-package imports work | Advanced template test |
| SC-006 | `template show` complete info | Integration test |

## Next Steps

1. Review and approve this plan
2. Proceed to `/speckit.tasks` for detailed task breakdown
