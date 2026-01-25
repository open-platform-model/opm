# Project Structure & File Naming

**Specification**: [../spec.md](../spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-22

## Overview

This document defines the mandatory project structure, directory layout, and protected filenames for OPM Module and Bundle projects. Adhering to these standards ensures portability, predictability, and compatibility with the OPM CLI and OCI registry distribution.

## 1. Module Project Structure

A **Module Project** is a directory containing the source code for an OPM Module. The OPM CLI enforces a strict structure for these projects.

### 1.1. Mandatory Files

Every Module project MUST contain the following files at its root:

| Filename | Purpose | Requirement |
| :--- | :--- | :--- |
| `module.cue` | Main file containing the `#Module` definition. | **REQUIRED** |
| `values.cue` | Concrete default values satisfying the `#Module.#spec` schema. | **REQUIRED** |
| `cue.mod/module.cue` | Standard CUE module definition and dependency management. | **REQUIRED** |

### 1.2. Protected Conventional Files

The following filenames are reserved for specific OPM conventions. If present, they SHOULD be used for their designated purpose:

| Filename | Purpose |
| :--- | :--- |
| `components.cue` | Extraction of component definitions to keep `module.cue` lean. |
| `scopes.cue` | Extraction of scope definitions. |
| `policies.cue` | Extraction of policy definitions. |
| `debug_values.cue` | A comprehensive set of values used for `opm mod vet` and debugging. |

### 1.3. Example Layout (Standard)

```text
my-app/
├── cue.mod/
│   └── module.cue      # CUE module definition
├── module.cue          # Main #Module definition
├── values.cue          # Default values
├── components.cue      # Components
└── scopes.cue          # Scopes
```

---

## 2. Bundle Project Structure

A **Bundle Project** aggregates multiple modules into a single deployable unit.

### 2.1. Mandatory Files

| Filename | Purpose | Requirement |
| :--- | :--- | :--- |
| `bundle.cue` | Main file containing the `#Bundle` definition. | **REQUIRED** |
| `values.cue` | Bundle-level default values. | **REQUIRED** |
| `cue.mod/module.cue` | Standard CUE module definition. | **REQUIRED** |

### 2.2. Protected Conventional Files

| Filename | Purpose |
| :--- | :--- |
| `modules.cue` | Extraction of the module registry (`#modules`). |
| `debug_values.cue` | Debug values for `opm bundle vet`. |

### 2.3. Example Layout

```text
my-platform/
├── cue.mod/
│   └── module.cue      # CUE module definition
├── bundle.cue          # Main #Bundle definition
├── values.cue          # Bundle defaults
└── modules.cue         # Module imports/registry
```

---

## 3. Protected Filenames Reference

The following table summarizes all protected filenames across the OPM ecosystem. These names MUST NOT be used for other purposes within the project root.

| Filename | Level | Context | Description |
| :--- | :--- | :--- | :--- |
| `module.cue` | REQUIRED | Module | Entry point for Module definition. |
| `bundle.cue` | REQUIRED | Bundle | Entry point for Bundle definition. |
| `values.cue` | REQUIRED | Both | Mandatory default values file. |
| `components.cue` | RESERVED | Module | Component logic. |
| `scopes.cue` | RESERVED | Module | Scope logic. |
| `policies.cue` | RESERVED | Module | Policy logic. |
| `modules.cue` | RESERVED | Bundle | Module registry. |
| `debug_values.cue` | RESERVED | Both | Extended values for validation. |

---

## 4. CLI Enforcement & Validation

The OPM CLI performs structural validation during `init`, `vet`, `build`, `apply`, and `publish` operations.

### 4.1. Validation Rules

1. **Root Verification**: The CLI identifies a project root by searching for the `cue.mod/` directory.
2. **Mandatory Check**: If `module.cue` or `values.cue` is missing from a Module project root, the CLI MUST exit with code `2` (Validation Error).
3. **Collision Detection**: If a user attempts to use a protected filename for an incompatible CUE package or purpose, validation fails.

### 4.2. Error Messages

Example of a missing required file:

```text
Error: invalid module project structure
  Missing required file: /path/to/my-app/module.cue
  
A module project must contain both 'module.cue' and 'values.cue' at the root.
```

---

## 5. File Examples

### 5.1. Module Entry Point (`module.cue`)

The `module.cue` file binds metadata, components, and schema together.

```cue
package main

import "opm.dev/core@v0"

// The #Module definition is mandatory
core.#Module

metadata: {
    apiVersion: "example.com/modules@v0"
    name:       "web-app"
    version:    "1.0.0"
}

// Reference to components (can be defined in components.cue)
#components: _components

// Configuration schema
#spec: {
    image: string
    port:  int | *8080
}

// Default values (unified with values.cue)
values: {
    image: "nginx:stable"
}
```

### 5.2. Component Extraction (`components.cue`)

Conventional file for housing component logic.

```cue
package main

import "opm.dev/core@v0"

// Internal identifier used in module.cue
_components: {
    frontend: core.#Component & {
        // ... component definition ...
    }
}
```

### 5.3. Default Values (`values.cue`)

The `values.cue` file provides the concrete defaults that satisfy the `#spec`.

```cue
package main

// Concrete values matching #Module.#spec
values: {
    image: "nginx:latest"
    port:  80
}
```

### 5.4. Module Registry (`modules.cue`)

Conventional file for housing bundle module imports.

```cue
package main

import (
    "example.com/frontend@v1"
    "example.com/backend@v1"
)

_modules: {
    web: frontend.#Module
    api: backend.#Module
}
```

### 5.5. Bundle Entry Point (`bundle.cue`)

```cue
package main

import "opm.dev/core@v0"

core.#Bundle

metadata: {
    apiVersion: "example.com/bundles@v0"
    name:       "full-stack"
}

#modules: _modules

#spec: {
    domain: string
}

values: {
    domain: "example.com"
}
```

## 6. Implementation Guidance

- **Package Naming**: All CUE files at the root of a Module SHOULD belong to the same package (typically the module name or `module`).
- **Internal Directories**: Users ARE encouraged to use subdirectories for complex logic (e.g., `templates/`, `schemas/`), provided they are correctly imported or included in the root files.
- **OCI Artifacts**: When `opm mod publish` is called, the CLI packs all files in the directory, respecting the project structure defined here.
