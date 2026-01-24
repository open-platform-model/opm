# Research: OPM Module Template System

**Specification**: [spec.md](./spec.md)  
**Date**: 2026-01-23

## Overview

This document records technology decisions for the module template system. The implementation extends 004-cli-spec with minimal new dependencies.

## Decisions

### 1. Template Embedding

**Decision**: Use Go's `embed` package  
**Rationale**: Standard library, no external dependencies, works with `go:embed` directive  
**Alternatives Considered**:

- `go-bindata`: Third-party, unmaintained
- Runtime file loading: Violates FR-014 (embedded in binary)

### 2. Template Rendering

**Decision**: Use Go's `text/template` package  
**Rationale**: Standard library, supports `{{.Field}}` syntax defined in data-model.md  
**Alternatives Considered**:

- `html/template`: HTML escaping not needed for CUE files
- Mustache/Handlebars: External dependency, no benefit over text/template

### 3. Directory Structure Embedding

**Decision**: Embed entire template directories with `//go:embed templates/*`  
**Rationale**: Preserves directory structure for advanced template's `components/` and `scopes/`  
**Pattern**: Use `fs.WalkDir` to iterate embedded files during generation

### 4. Template Registry

**Decision**: Simple map-based registry with template metadata  
**Rationale**: Only 3 hardcoded templates, no need for plugin architecture  
**Pattern**: Registry struct with Name, Description, Files, Default flag

## References

- [004-cli-spec](../004-cli-spec/spec.md) - Parent CLI specification
- [004-cli-spec/contracts/exit-codes.md](../004-cli-spec/contracts/exit-codes.md) - Exit code contract
