# Research: OPM Template Distribution

**Specification**: [spec.md](./spec.md)  
**Date**: 2026-01-29

## Overview

This document records technology decisions for the OCI-based template distribution system.

## Decisions

### 1. OCI Distribution

**Decision**: Use OCI artifacts for template distribution  
**Rationale**: Aligns with 011-oci-distribution-spec patterns, reuses existing OCI infrastructure, standard registry compatibility  
**Alternatives Considered**:

- Git-based templates: Requires git dependency, less portable
- HTTP downloads: No versioning, no authentication standard
- CUE module format: Templates are not CUE modules (they contain `.tmpl` files)

### 2. OCI Client Library

**Decision**: Use `oras.land/oras-go/v2`  
**Rationale**: Same library as 011-oci-distribution-spec, standard OCI operations, well-maintained  
**Reference**: [011-oci-distribution-spec](../011-oci-distribution-spec/spec.md)

### 3. Template Rendering

**Decision**: Use Go's `text/template` package  
**Rationale**: Standard library, well-understood syntax, sufficient for simple placeholders  
**Alternatives Considered**:

- `html/template`: HTML escaping not needed for CUE files
- Mustache/Handlebars: External dependency, no additional benefit
- Custom syntax: Unnecessary complexity

### 4. Media Types

**Decision**: Define OPM-specific media types for templates  
**Rationale**: Distinguishes templates from modules and other OCI artifacts  
**Types**:

| Purpose | Media Type |
|---------|------------|
| Config | `application/vnd.opmodel.template.config.v1+json` |
| Content | `application/vnd.opmodel.template.content.v1.tar+gzip` |

### 5. Template File Extension

**Decision**: Use `.tmpl` suffix for template files  
**Rationale**: Clear distinction between template files and rendered output, standard convention  
**Examples**:

- `module.cue.tmpl` → `module.cue` (after rendering)
- `values.cue.tmpl` → `values.cue`

### 6. Shorthand Resolution

**Decision**: Shorthand names resolve to `oci://${REGISTRY}/templates/${name}:latest`  
**Rationale**: Convenient for official templates, allows `:latest` for templates (unlike modules)  
**Examples**:

- `standard` → `oci://registry.opmodel.dev/templates/standard:latest`
- `simple` → `oci://registry.opmodel.dev/templates/simple:latest`

### 7. URL Scheme Detection

**Decision**: Support `oci://`, `file://`, and implicit OCI (when path contains `/`)  
**Rationale**: Flexible for different use cases while maintaining clear defaults  
**Rules**:

1. `oci://...` → OCI reference
2. `file://...` → Local filesystem
3. Contains `/` without scheme → Implicit `oci://`
4. Single word → Shorthand name

### 8. Authentication

**Decision**: Reuse `~/.docker/config.json` credentials  
**Rationale**: Consistent with 011-oci-distribution-spec, no custom auth implementation  
**Reference**: [011-oci-distribution-spec FR-007](../011-oci-distribution-spec/spec.md)

### 9. Caching

**Decision**: Use CUE cache directory structure  
**Rationale**: Consistent with module caching, familiar location for users  
**Path**: `~/.cache/cue/mod/extract/<registry>/<path>/<version>/`

### 10. Manifest Format

**Decision**: Use CUE for template manifest (`template.cue`)  
**Rationale**: Consistent with OPM ecosystem, type-safe, self-documenting  
**Alternatives Considered**:

- YAML: Less type-safe, not consistent with OPM patterns
- JSON: Verbose, no comments
- TOML: Not used elsewhere in OPM

### 11. Placeholder Set

**Decision**: Fixed set of three placeholders: `ModuleName`, `ModulePath`, `Version`  
**Rationale**: Simplicity, covers all common use cases, no parameterization complexity  
**Alternatives Considered**:

- User-defined parameters: Added complexity, YAGNI
- Environment variable injection: Security concerns, less portable

## References

- [002-cli-spec](../002-cli-spec/spec.md) - Parent CLI specification
- [011-oci-distribution-spec](../011-oci-distribution-spec/spec.md) - OCI distribution patterns
- [ORAS Go library](https://oras.land/docs/) - OCI artifact operations
- [Go text/template](https://pkg.go.dev/text/template) - Template rendering
