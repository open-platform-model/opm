# Implementation Plan: OPM Template Distribution

**Branch**: `012-template-oci-spec` | **Date**: 2026-01-29 | **Spec**: [spec.md](./spec.md)  
**Related**: [002-cli-spec](../002-cli-spec/plan.md), [011-oci-distribution-spec](../011-oci-distribution-spec/spec.md)

## Summary

Implement OCI-based template distribution for OPM. Templates are published to OCI registries, discoverable via `opm template` commands, and used via `opm mod init --template`. Official templates (`simple`, `standard`, `advanced`) are published to `registry.opmodel.dev/templates/`.

## Technical Context

| Aspect | Decision | Source |
|--------|----------|--------|
| **Language** | Go 1.22+ | 002-cli-spec |
| **CLI Framework** | spf13/cobra | 002-cli-spec |
| **OCI Client** | oras.land/oras-go/v2 | 011-oci-distribution-spec |
| **Template Rendering** | Go `text/template` | research.md |
| **Authentication** | `~/.docker/config.json` | 011-oci-distribution-spec |
| **Caching** | CUE cache directory | 011-oci-distribution-spec |
| **Media Types** | `application/vnd.opmodel.template.*` | data-model.md |
| **Exit Codes** | [002-cli-spec/contracts/exit-codes.md](../002-cli-spec/contracts/exit-codes.md) | Shared |

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Definition-First** | PASS | Templates generate valid OPM definitions |
| **II. Type Safety via CUE** | PASS | Generated files pass `opm mod vet` |
| **III. Separation of Concerns** | PASS | Templates serve module developers |
| **IV. Portability by Design** | PASS | Templates are provider-agnostic, OCI portable |
| **V. Policy as Code** | PASS | Advanced template includes policies.cue |
| **VI. Simplicity** | PASS | Fixed placeholders, no parameterization |

## Project Structure Addition

```text
cli/internal/
├── template/                  # NEW: Template system
│   ├── client.go             # OCI client for template operations
│   ├── manifest.go           # template.cue parsing and validation
│   ├── reference.go          # Template reference resolution
│   ├── renderer.go           # Template rendering with placeholders
│   ├── cache.go              # Template caching
│   └── official/             # Official template content (for publishing)
│       ├── simple/
│       ├── standard/
│       └── advanced/
└── cmd/
    ├── template/              # NEW: opm template commands
    │   ├── template.go       # Root command
    │   ├── list.go           # opm template list
    │   ├── get.go            # opm template get
    │   ├── show.go           # opm template show
    │   ├── validate.go       # opm template validate
    │   └── publish.go        # opm template publish
    └── mod/
        └── init.go           # MODIFY: Template integration
```

## Implementation Phases

### Phase 1: Template Reference Resolution

**Goal**: Parse and resolve template references

| Task | Description | FR |
|------|-------------|-----|
| 1.1 | Implement `reference.go` with ref type detection (oci/file/shorthand) | FR-003, FR-004 |
| 1.2 | Implement shorthand resolution with registry precedence | FR-005 |
| 1.3 | Implement URL scheme normalization | FR-004 |
| 1.4 | Unit tests for all reference formats | - |

**Deliverable**: `ParseRef("standard")` → `oci://registry.opmodel.dev/templates/standard:latest`

### Phase 2: Template Manifest

**Goal**: Parse and validate template.cue

| Task | Description | FR |
|------|-------------|-----|
| 2.1 | Define manifest schema in CUE | data-model.md |
| 2.2 | Implement `manifest.go` for parsing template.cue | FR-009 |
| 2.3 | Implement validation rules (name, version, description, placeholders) | FR-010, FR-011 |
| 2.4 | Unit tests for valid and invalid manifests | - |

**Deliverable**: `ParseManifest("template.cue")` returns validated manifest

### Phase 3: OCI Client Integration

**Goal**: Fetch and push templates via OCI

| Task | Description | FR |
|------|-------------|-----|
| 3.1 | Implement `client.go` wrapping ORAS | FR-014, FR-015 |
| 3.2 | Implement `Pull()` for fetching templates | - |
| 3.3 | Implement `Push()` for publishing templates | FR-012, FR-013 |
| 3.4 | Implement `List()` for listing templates from registry | FR-001 |
| 3.5 | Implement `Resolve()` for fetching manifest metadata | FR-002 |
| 3.6 | Integration tests with local registry (zot) | - |

**Deliverable**: Templates can be pulled from and pushed to OCI registries

### Phase 4: Template Caching

**Goal**: Cache templates locally

| Task | Description | FR |
|------|-------------|-----|
| 4.1 | Implement `cache.go` with CUE cache directory structure | - |
| 4.2 | Implement cache lookup before OCI fetch | - |
| 4.3 | Implement cache invalidation strategy | - |
| 4.4 | Unit tests for cache operations | - |

**Deliverable**: Repeated fetches use local cache

### Phase 5: Template Rendering

**Goal**: Render templates with placeholder substitution

| Task | Description | FR |
|------|-------------|-----|
| 5.1 | Implement `renderer.go` with text/template | FR-017 |
| 5.2 | Implement `.tmpl` suffix stripping | FR-018 |
| 5.3 | Implement placeholder context (ModuleName, ModulePath, Version) | FR-019, FR-020 |
| 5.4 | Implement directory structure preservation | - |
| 5.5 | Unit tests for rendering edge cases | - |

**Deliverable**: Template files rendered with placeholders substituted

### Phase 6: CLI Commands - Discovery

**Goal**: `opm template list` and `opm template show`

| Task | Description | FR |
|------|-------------|-----|
| 6.1 | Create `cmd/template/template.go` command group | - |
| 6.2 | Implement `opm template list` with table/json output | FR-001 |
| 6.3 | Implement `opm template show <ref>` | FR-002 |
| 6.4 | Handle registry errors with appropriate exit codes | - |
| 6.5 | Integration tests | - |

**Deliverable**: Users can discover and inspect templates

### Phase 7: CLI Commands - Get & Validate

**Goal**: `opm template get` and `opm template validate`

| Task | Description | FR |
|------|-------------|-----|
| 7.1 | Implement `opm template get <ref> [--dir]` | FR-006, FR-007 |
| 7.2 | Implement `--force` flag for overwrite | FR-008 |
| 7.3 | Implement `opm template validate` | FR-009, FR-010 |
| 7.4 | Integration tests | - |

**Deliverable**: Users can download and validate templates

### Phase 8: CLI Commands - Publish

**Goal**: `opm template publish`

| Task | Description | FR |
|------|-------------|-----|
| 8.1 | Implement `opm template publish <oci-ref>` | FR-012 |
| 8.2 | Pre-publish validation | FR-013 |
| 8.3 | Authentication via docker config | FR-014 |
| 8.4 | Integration tests with local registry | - |

**Deliverable**: Users can publish templates

### Phase 9: Mod Init Integration

**Goal**: Wire templates into `opm mod init`

| Task | Description | FR |
|------|-------------|-----|
| 9.1 | Modify `opm mod init --template` to use template system | FR-016 |
| 9.2 | Support oci://, file://, and shorthand refs | FR-003 |
| 9.3 | Implement `--name` and `--module` flags | FR-019, FR-020 |
| 9.4 | Implement `--force` flag | - |
| 9.5 | Verify generated module passes `opm mod vet` | FR-021 |
| 9.6 | E2E tests | - |

**Deliverable**: `opm mod init --template standard` works end-to-end

### Phase 10: Official Templates

**Goal**: Create and publish official templates

| Task | Description | FR |
|------|-------------|-----|
| 10.1 | Create `simple` template with manifest and .tmpl files | FR-022 |
| 10.2 | Create `standard` template | FR-022 |
| 10.3 | Create `advanced` template with subdirectories | FR-022 |
| 10.4 | Validate all templates generate valid modules | FR-021 |
| 10.5 | Publish to `registry.opmodel.dev/templates/` | FR-022 |
| 10.6 | Test shorthand resolution | FR-023 |

**Deliverable**: Official templates published and resolvable

### Phase 11: Testing and Polish

**Goal**: Production readiness

| Task | Description | SC |
|------|-------------|-----|
| 11.1 | E2E tests for all user stories | - |
| 11.2 | Performance tests (SC-001, SC-003) | SC-001, SC-003 |
| 11.3 | Registry compatibility tests (GHCR, Docker Hub, Harbor) | SC-005 |
| 11.4 | Documentation updates | - |
| 11.5 | Help text and examples | - |

**Deliverable**: All tests passing, documentation complete

## Dependencies

| Package | Purpose | Source |
|---------|---------|--------|
| `oras.land/oras-go/v2` | OCI operations | 011-oci-distribution-spec |
| `text/template` (stdlib) | Template rendering | - |
| `cuelang.org/go` | Manifest parsing | 002-cli-spec |
| `spf13/cobra` | CLI framework | 002-cli-spec |
| `charmbracelet/log` | Logging | 002-cli-spec |

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Registry compatibility | Medium | Test against multiple registry implementations |
| Template validation drift | Medium | Automated tests run `opm mod vet` on generated output |
| OCI media type acceptance | Low | Use standard OCI patterns, custom types well-documented |
| Caching staleness | Low | Clear cache command, version-based cache keys |

## Success Metrics

| Metric | Target | Test |
|--------|--------|------|
| SC-001 | Init < 10s (warm cache) | E2E timing test |
| SC-002 | 100% pass `opm mod vet` | Integration tests |
| SC-003 | List < 5s | E2E timing test |
| SC-004 | Publish + init < 60s | E2E test |
| SC-005 | GHCR, Docker Hub, Harbor, Zot compatible | Integration tests |

## Next Steps

1. Review and approve this plan
2. Proceed to [tasks.md](./tasks.md) for detailed task breakdown
