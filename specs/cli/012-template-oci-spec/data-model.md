# Template Data Model

**Specification**: [spec.md](./spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-29

## Overview

This document defines the data structures for the OPM template system, including the template manifest schema, template reference formats, and placeholder definitions.

---

## 1. Template Manifest (`template.cue`)

The template manifest defines metadata about a template. It MUST be located at the root of the template directory.

### 1.1. Schema

```cue
package template

// Required: Template name (used for shorthand resolution)
name!: string & =~"^[a-z][a-z0-9-]*$"

// Required: Template version (SemVer recommended)
version!: string & =~"^[0-9]+\\.[0-9]+\\.[0-9]+.*$"

// Required: Human-readable description
description!: string & strings.MinRunes(10)

// Optional: List of supported placeholders
// Defaults to ["ModuleName", "ModulePath", "Version"]
placeholders: [...#Placeholder] | *["ModuleName", "ModulePath", "Version"]

// Auto-derived: List of template files (populated during validation/publish)
// Not specified by template author
_files: [...string]

#Placeholder: "ModuleName" | "ModulePath" | "Version"
```

### 1.2. Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | Yes | Template identifier. Lowercase, alphanumeric with hyphens. |
| `version` | `string` | Yes | Template version. SemVer format recommended. |
| `description` | `string` | Yes | Human-readable description (min 10 characters). |
| `placeholders` | `[...string]` | No | Supported placeholders. Defaults to all three. |

### 1.3. Example

```cue
package template

name:        "standard"
version:     "1.0.0"
description: "Standard OPM module template for team projects with separated components"

placeholders: ["ModuleName", "ModulePath", "Version"]
```

---

## 2. Template Reference

A template reference is a string that identifies a template for fetching or initialization.

### 2.1. Reference Types

```cue
#TemplateRef: #ShorthandRef | #OCIRef | #FileRef

// Shorthand: resolves via registry
// Examples: "standard", "simple", "my-template"
#ShorthandRef: string & =~"^[a-z][a-z0-9-]*$"

// OCI reference with explicit scheme
// Examples: "oci://registry.example.com/templates/web:v1"
#OCIRef: string & =~"^oci://[a-z0-9.-]+(/[a-z0-9._-]+)+(:[a-z0-9._-]+)?$"

// Local file path
// Examples: "file://./my-template", "file:///absolute/path"
#FileRef: string & =~"^file://.*$"
```

### 2.2. Resolution Rules

| Input | Type | Resolved URL |
|-------|------|--------------|
| `standard` | Shorthand | `oci://${REGISTRY}/templates/standard:latest` |
| `oci://reg.io/tpl:v1` | OCI | `oci://reg.io/tpl:v1` |
| `reg.io/templates/web:v1` | OCI (implied) | `oci://reg.io/templates/web:v1` |
| `file://./my-template` | File | Local path `./my-template` |

### 2.3. Registry Precedence

When resolving shorthand references, the registry is determined by:

1. `--registry` flag (highest priority)
2. `OPM_REGISTRY` environment variable
3. `config.registry` from `~/.opm/config.cue`
4. Default: `registry.opmodel.dev`

---

## 3. Placeholders

Placeholders are substituted when rendering a template into a module.

### 3.1. Placeholder Definitions

| Placeholder | Source | Default Value | Description |
|-------------|--------|---------------|-------------|
| `{{.ModuleName}}` | `--name` flag or directory name | Directory name | Module identifier used in `metadata.name` |
| `{{.ModulePath}}` | `--module` flag or derived | `example.com/<dirname>` | CUE module path for imports |
| `{{.Version}}` | Hardcoded | `0.1.0` | Initial module version |

### 3.2. ModulePath Derivation

When `--module` flag is not provided, `ModulePath` is derived from the directory name:

1. Take directory name (e.g., `my-app`)
2. Replace hyphens with underscores (e.g., `my_app`)
3. Prefix with `example.com/` (e.g., `example.com/my_app`)

This ensures CUE compatibility (CUE identifiers cannot contain hyphens).

### 3.3. Template Syntax

Template files use Go's `text/template` syntax:

```cue
// Basic substitution
name: "{{.ModuleName}}"

// In imports
import "{{.ModulePath}}/components"

// In metadata
metadata: {
    apiVersion: "{{.ModulePath}}@v0"
    name:       "{{.ModuleName}}"
    version:    "{{.Version}}"
}
```

---

## 4. Template Directory Structure

### 4.1. Required Structure

```text
<template-name>/
├── template.cue              # Manifest (required)
└── *.tmpl                    # At least one template file (required)
```

### 4.2. Standard Structure (Simple Template)

```text
simple/
├── template.cue
├── module.cue.tmpl
├── values.cue.tmpl
└── cue.mod/
    └── module.cue.tmpl
```

### 4.3. Standard Structure (Standard Template)

```text
standard/
├── template.cue
├── module.cue.tmpl
├── values.cue.tmpl
├── components.cue.tmpl
└── cue.mod/
    └── module.cue.tmpl
```

### 4.4. Standard Structure (Advanced Template)

```text
advanced/
├── template.cue
├── module.cue.tmpl
├── values.cue.tmpl
├── components.cue.tmpl
├── scopes.cue.tmpl
├── policies.cue.tmpl
├── debug_values.cue.tmpl
├── cue.mod/
│   └── module.cue.tmpl
├── components/
│   ├── web.cue.tmpl
│   ├── api.cue.tmpl
│   ├── worker.cue.tmpl
│   └── db.cue.tmpl
└── scopes/
    ├── frontend.cue.tmpl
    └── backend.cue.tmpl
```

---

## 5. OCI Artifact Structure

Templates are stored in OCI registries as artifacts.

### 5.1. Media Types

| Layer | Media Type |
|-------|------------|
| Manifest | `application/vnd.oci.image.manifest.v1+json` |
| Config | `application/vnd.opmodel.template.config.v1+json` |
| Content | `application/vnd.opmodel.template.content.v1.tar+gzip` |

### 5.2. Config Blob

```json
{
  "name": "standard",
  "version": "1.0.0",
  "description": "Standard OPM module template",
  "placeholders": ["ModuleName", "ModulePath", "Version"],
  "files": [
    "template.cue",
    "module.cue.tmpl",
    "values.cue.tmpl",
    "components.cue.tmpl",
    "cue.mod/module.cue.tmpl"
  ]
}
```

### 5.3. Content Layer

A gzipped tarball containing all template files preserving directory structure.

---

## 6. CLI Output Formats

### 6.1. Template List (`opm template list`)

**Table format (default):**

```text
NAME        VERSION  DESCRIPTION
simple      1.0.0    Single-file module for learning and prototypes
standard    1.0.0    Separated files for team projects
advanced    1.0.0    Multi-package structure for complex applications
```

**JSON format (`-o json`):**

```json
{
  "templates": [
    {
      "name": "simple",
      "version": "1.0.0",
      "description": "Single-file module for learning and prototypes",
      "ref": "registry.opmodel.dev/templates/simple:1.0.0"
    }
  ]
}
```

### 6.2. Template Show (`opm template show`)

**Text format (default):**

```text
Name:        standard
Version:     1.0.0
Description: Separated files for team projects
Reference:   registry.opmodel.dev/templates/standard:1.0.0

Placeholders:
  - ModuleName
  - ModulePath
  - Version

Files:
  template.cue
  module.cue.tmpl
  values.cue.tmpl
  components.cue.tmpl
  cue.mod/
    module.cue.tmpl
```

---

## 7. Validation Rules

### 7.1. Manifest Validation

| Rule | Error Message |
|------|---------------|
| `template.cue` missing | "template.cue manifest not found" |
| `name` missing | "manifest: name is required" |
| `name` invalid format | "manifest: name must be lowercase alphanumeric with hyphens" |
| `version` missing | "manifest: version is required" |
| `description` missing | "manifest: description is required" |
| `description` too short | "manifest: description must be at least 10 characters" |
| Unknown placeholder | "manifest: unknown placeholder 'X', must be one of: ModuleName, ModulePath, Version" |

### 7.2. File Validation

| Rule | Error Message |
|------|---------------|
| No `.tmpl` files | "template must contain at least one .tmpl file" |
| Template syntax error | "file.cue.tmpl: template syntax error at line N: ..." |
| Unknown placeholder used | "file.cue.tmpl: unknown placeholder 'X' used but not declared in manifest" |

---

## 8. Cache Structure

Templates are cached following the CUE cache pattern:

```text
~/.cache/cue/mod/
└── extract/
    └── registry.opmodel.dev/
        └── templates/
            └── standard/
                └── v1.0.0/
                    ├── template.cue
                    ├── module.cue.tmpl
                    └── ...
```
