# Feature Specification: CLI Module Validation

**Feature Branch**: `005-module-validation`  
**Created**: 2026-01-29  
**Status**: Draft  
**Input**: User description: "Implement opm mod vet command using Go CUE SDK for native module validation with support for schema and concrete validation modes"

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## Overview

This specification defines the `opm mod vet` command, which validates OPM modules directly using the Go CUE SDK (`cuelang.org/go`) without relying on the external `cue` binary. This approach provides:

- **Custom error formatting**: Leverage the Charm ecosystem (lipgloss, log) for user-friendly error messages consistent with the CLI's visual design
- **Programmatic control**: Fine-grained control over validation phases and error aggregation
- **Better integration**: Seamless integration with the CLI's config system and registry resolution

The validation system supports two modes:

1. **Schema validation** (default): Validates CUE syntax, imports, and schema constraints without requiring concrete values
2. **Concrete validation** (`--concrete` flag): Additionally requires all values to be fully resolved (no open fields)

### Design Decisions

1. **Go CUE SDK over shelling out**: Direct use of `cuelang.org/go/cue/load` and `cuelang.org/go/cue` provides better error context, performance, and integration
2. **Timoni-inspired but OPM-native**: Borrows proven patterns from Timoni's `mod vet` (flag structure, validation phases) while adapting to OPM's definition types
3. **Entity summary output**: Shows validated entities on success (Module, Components, Scopes) for user confidence
4. **Registry consistency**: Uses the same registry resolution logic as other CLI commands (`--registry` > `OPM_REGISTRY` > `config.registry`)

## Clarifications

### Session 2026-01-29

- Q: What should be the validation scope? → A: Schema validation by default, with optional `--concrete` flag for full value resolution (similar to `cue vet -c`)
- Q: Should output show entity summary? → A: Yes, display validated entities (Module, Components, Scopes) on success for user confidence
- Q: How to load debug values? → A: Load directly by preferring `debug_values.cue` over `values.cue` in the CUE load config when `--debug` is specified
- Q: Should `--concrete` auto-enable `--debug`? → A: No, keep flags independent. `--concrete` validates whatever values are loaded (via `--debug` or default)
- Q: Which validation targets? → A: Module validation initially. Bundle validation builds on top later
- Q: Which spec number? → A: 005 (first available in CLI specs after 004)

## User Scenarios & Testing

### User Story 1 - Validate Module Structure and Schema (Priority: P1)

A module author developing a new OPM module needs immediate feedback on syntax errors, missing required fields, and schema violations before attempting to build or apply.

**Why this priority**: This is the core value proposition - fast, local validation catches errors before deployment attempts, dramatically improving developer experience.

**Independent Test**: Create a module with intentional schema violations and verify `opm mod vet` reports all errors with file locations and helpful messages.

**Acceptance Scenarios**:

1. **Given** a valid module with all required files, **When** the developer runs `opm mod vet`, **Then** validation succeeds and displays a summary of validated entities (Module, Components).
2. **Given** a module missing `cue.mod/module.cue`, **When** the developer runs `opm mod vet`, **Then** validation fails with error "invalid module project structure: Missing required file: cue.mod/module.cue".
3. **Given** a module with CUE syntax errors in `module.cue`, **When** the developer runs `opm mod vet`, **Then** validation fails with error messages showing exact file location (file:line:col) and the syntax issue.
4. **Given** a module where a component violates the `#Component` schema (e.g., missing `metadata.name`), **When** the developer runs `opm mod vet`, **Then** validation fails with a clear message indicating which component and which constraint was violated.
5. **Given** a module with unresolved imports, **When** the developer runs `opm mod vet`, **Then** validation fails with a message indicating which import could not be resolved and suggesting registry configuration checks.

---

### User Story 2 - Validate with Concrete Values (Priority: P2)

A module author wants to ensure their module has complete, concrete values suitable for rendering before publishing or sharing with platform operators.

**Why this priority**: Concrete validation ensures modules are "render-ready" and prevents runtime errors during build/apply operations.

**Independent Test**: Create a module with open fields in values and verify `--concrete` flag catches them.

**Acceptance Scenarios**:

1. **Given** a module with `values.cue` containing concrete values, **When** the developer runs `opm mod vet --concrete`, **Then** validation succeeds.
2. **Given** a module with open fields in `values.cue` (e.g., `port: int` without a concrete value), **When** the developer runs `opm mod vet --concrete`, **Then** validation fails with error indicating which field is incomplete.
3. **Given** a module with `--values values.cue` and additional `--values prod.cue`, **When** the developer runs `opm mod vet --concrete --values values.cue --values prod.cue`, **Then** validation unifies both files and checks the result is concrete.
4. **Given** a module without `--concrete` flag, **When** the developer runs `opm mod vet`, **Then** validation succeeds even if values have open fields (schema-only mode).

---

### User Story 3 - Debug Values Validation (Priority: P2)

A module author maintains comprehensive `debug_values.cue` for testing and wants to validate the module with debug values to ensure completeness.

**Why this priority**: Debug values often represent the most complete configuration, making them ideal for thorough validation testing.

**Independent Test**: Create a module with both `values.cue` (minimal) and `debug_values.cue` (comprehensive), verify `--debug` uses the debug file.

**Acceptance Scenarios**:

1. **Given** a module with both `values.cue` and `debug_values.cue`, **When** the developer runs `opm mod vet --debug`, **Then** validation uses `debug_values.cue` instead of `values.cue`.
2. **Given** a module with only `values.cue` (no `debug_values.cue`), **When** the developer runs `opm mod vet --debug`, **Then** validation falls back to `values.cue` with a warning message.
3. **Given** a module with `debug_values.cue`, **When** the developer runs `opm mod vet --debug --concrete`, **Then** validation ensures debug values are concrete.

---

### User Story 4 - Multi-Package Module Validation (Priority: P3)

A module author using the advanced template structure with multiple CUE packages (e.g., `components/`, `scopes/`) needs to validate a specific package.

**Why this priority**: Advanced users need flexibility to validate individual packages during development, but this is less common than validating the main package.

**Independent Test**: Create an advanced template module and validate different packages independently.

**Acceptance Scenarios**:

1. **Given** a module with default package `main`, **When** the developer runs `opm mod vet` (no `-p` flag), **Then** validation defaults to package `main`.
2. **Given** a module with subpackage `components`, **When** the developer runs `opm mod vet -p components`, **Then** validation loads and validates the `components` package.
3. **Given** a module with non-existent package `foo`, **When** the developer runs `opm mod vet -p foo`, **Then** validation fails with error "cannot find package foo".

---

### User Story 5 - Values Override Validation (Priority: P3)

A module author wants to validate their module with custom values files to test different deployment scenarios (staging, production).

**Why this priority**: Supports testing multiple configurations, but less critical than basic validation.

**Independent Test**: Create a module with staging and production values files, validate each independently.

**Acceptance Scenarios**:

1. **Given** a module with `staging.cue`, **When** the developer runs `opm mod vet --values staging.cue`, **Then** validation unifies `staging.cue` with `values.cue`.
2. **Given** a module with multiple values files, **When** the developer runs `opm mod vet --values staging.cue --values overrides.cue`, **Then** validation unifies all files in order: `values.cue`, `staging.cue`, `overrides.cue`.
3. **Given** conflicting values in multiple files, **When** the developer runs `opm mod vet --values conflict.cue`, **Then** validation fails with CUE's native unification error message.
4. **Given** a values file in YAML format, **When** the developer runs `opm mod vet --values config.yaml`, **Then** validation converts YAML to CUE and unifies it.

---

### Edge Cases

- **Missing values.cue**: What happens when `values.cue` is missing? → Validation fails with error "required file values.cue not found" (per 002-cli-spec, values.cue is mandatory).
- **Circular imports**: How are circular dependencies handled? → CUE loader reports the cycle with a clear error message showing the import chain.
- **Registry unreachable**: What if configured registry is down during validation? → Fail fast with error message about registry connectivity, same as other commands (per 002-cli-spec).
- **Large modules**: How does validation perform on modules with 100+ components? → No artificial limits; performance scales with CUE's native evaluation (NFR-001).
- **Invalid debug_values.cue**: What if `debug_values.cue` has syntax errors? → Validation fails with error location in `debug_values.cue`, same as any CUE file.
- **Mix of CUE/YAML/JSON values**: Can users provide `--values a.cue --values b.yaml --values c.json`? → Yes, all are converted to CUE and unified.
- **Empty module**: What if `#components` is empty? → Valid. Validation succeeds (module can have zero components initially).

## Requirements

### Functional Requirements

#### Command Interface

- **FR-001**: The CLI MUST provide an `opm mod vet` command that validates OPM modules using the Go CUE SDK.
- **FR-002**: The command MUST accept an optional path argument defaulting to the current directory (`.`).
- **FR-003**: The command MUST support a `--package` flag (short: `-p`) to specify the CUE package to validate (default: `"main"`).
- **FR-004**: The command MUST support a `--debug` flag that prefers `debug_values.cue` over `values.cue` when loading the module.
- **FR-005**: The command MUST support a `--concrete` flag that requires all values to be concrete (no open fields).
- **FR-006**: The command MUST support a `--values` flag (short: `-f`) accepting multiple values files in CUE, YAML, or JSON format.

#### Validation Phases

- **FR-007**: **Phase 1 - Project Structure Validation**: The CLI MUST verify the module project structure by checking for the existence of `cue.mod/module.cue`, `module.cue`, and either `values.cue` or `debug_values.cue` (when `--debug` is used). Missing required files MUST result in exit code `2` (Validation Error) with a clear error message indicating which file is missing.
- **FR-008**: **Phase 2 - CUE Syntax & Import Validation**: The CLI MUST load CUE instances using `cuelang.org/go/cue/load` with the specified package. The CLI MUST resolve all imports using the configured registry (per FR-013). Syntax errors or unresolved imports MUST result in exit code `2` with error messages showing file location (file:line:col).
- **FR-009**: **Phase 3 - Schema Validation**: The CLI MUST validate the loaded module against the `#Module` schema from `opmodel.dev/core@v0`. Components MUST be validated against `#Component` schema. Scopes (if present) MUST be validated against `#Scope` schema. Schema violations MUST result in exit code `2` with clear error messages indicating which entity and which constraint failed.
- **FR-010**: **Phase 4 - Concrete Validation (optional)**: When `--concrete` flag is specified, the CLI MUST validate that all values are concrete using `cue.Value.Validate(cue.Concrete(true))`. Open or incomplete fields MUST result in exit code `2` with error messages indicating which fields are not concrete.

#### Values Handling

- **FR-011**: When `--debug` is specified and `debug_values.cue` exists, the CLI MUST use `debug_values.cue` instead of `values.cue`.
- **FR-012**: When `--debug` is specified but `debug_values.cue` does not exist, the CLI MUST fall back to `values.cue` and log a warning to stderr.
- **FR-013**: When multiple `--values` files are provided, the CLI MUST unify them in order with the base values file (`values.cue` or `debug_values.cue`). YAML and JSON files MUST be converted to CUE before unification. Unification conflicts MUST produce CUE's native error message.

#### Registry Resolution

- **FR-014**: The CLI MUST resolve the CUE module registry using the same precedence chain as other commands (per 002-cli-spec): `--registry` flag > `OPM_REGISTRY` env var > `config.registry` from config.cue.
- **FR-015**: When the registry is unreachable, the CLI MUST fail fast with a clear error message indicating registry connectivity issues, consistent with 002-cli-spec behavior.

#### Output & Error Formatting

- **FR-016**: On successful validation, the CLI MUST display a summary of validated entities including:
  - Module name and version (with checkmark)
  - Count of validated components (with checkmark)
  - Count of validated scopes if present (with checkmark)
- **FR-017**: On validation failure, the CLI MUST output all collected errors with:
  - File location (file:line:col format where available)
  - Clear description of the error
  - Suggested fix or context where applicable
- **FR-018**: Error messages MUST use the Charm ecosystem's logging format (as specified in 002-cli-spec) with color-coded severity (Info, Warning, Error).
- **FR-019**: The CLI MUST exit with code `0` on success, code `2` on validation errors, and code `1` on other errors (usage, config issues).

#### Performance & Behavior

- **FR-020**: The CLI MUST NOT impose artificial limits on module size (number of components, CUE evaluation depth). Natural limits are provided by timeouts and system resources (per 002-cli-spec NFR).
- **FR-021**: When validation encounters multiple errors, the CLI MUST aggregate and display all errors before exiting (fail-on-end pattern), rather than stopping at the first error.

### Non-Functional Requirements

- **NFR-001**: Validation MUST complete in under 5 seconds for modules with up to 20 components on commodity hardware (warm cache for dependencies).
- **NFR-002**: Error messages MUST be actionable and beginner-friendly, avoiding CUE internals where possible.

### Key Entities

- **Module**: The `#Module` definition being validated (from `module.cue`)
- **Component**: Individual `#Component` definitions within the module's `#components` map
- **Scope**: Optional `#Scope` definitions within the module's `#scopes` map
- **Values**: Concrete or schema values from `values.cue`, `debug_values.cue`, or `--values` files
- **CUE Instance**: Loaded CUE package instance from `cue/load`
- **Validation Context**: Runtime state including selected package, registry configuration, and loaded values

## Success Criteria

### Measurable Outcomes

- **SC-001**: A module author can validate a standard template module (5 components) in under 2 seconds with warm CUE dependency cache.
  - *Measurement*: Time from command invocation to exit (success or failure)
  - *Assumptions*: Warm local cache for CUE modules, SSD storage, 4+ CPU cores
  - *Exclusions*: Initial `cue mod tidy` time for cold cache

- **SC-002**: 100% of CUE syntax errors, schema violations, and import failures produce error messages with file location (file:line:col format).
  - *Measurement*: Error message format validation across a test suite of invalid modules
  - *Exclusions*: Runtime errors in custom CUE functions (user code)

- **SC-003**: Module authors can validate a module with `--concrete` flag and receive clear feedback on incomplete fields in under 3 seconds.
  - *Measurement*: Time from command with `--concrete` to error output listing open fields

- **SC-004**: Error messages use beginner-friendly language 90% of the time, avoiding CUE implementation details.
  - *Measurement*: Manual review of error messages from common validation failures
  - *Criteria*: Error explains what's wrong and suggests a fix without mentioning "bottom", "disjunction", or other CUE internals

- **SC-005**: Validation output shows entity summary on success 100% of the time, giving users confidence in what was validated.
  - *Measurement*: Verify output includes module name, component count, and scope count on successful validation

- **SC-006**: When multiple errors exist, validation displays all errors in a single run 100% of the time (fail-on-end).
  - *Measurement*: Test suite with modules containing 3+ errors verifies all are reported before exit

## Assumptions

- Module authors have network access to configured CUE module registries (or use local registries for air-gapped environments)
- CUE SDK v0.14+ is used, supporting the module system and registry features
- Module projects follow the structure defined in 002-cli-spec (module.cue, values.cue, cue.mod/module.cue)
- Users understand basic CUE syntax and schema concepts
- The `opmodel.dev/core@v0` module is available in the configured registry

## Out of Scope

- **Bundle validation**: Separate command (`opm bundle vet`) will build on this foundation in a future spec
- **Provider validation**: Providers are validated in config.cue (covered in 002-cli-spec)
- **Auto-fix**: CLI does not automatically repair validation errors
- **Watch mode**: No file watching for continuous validation (users can use shell tools like `watchexec`)
- **Custom validation rules**: Module-specific validation beyond CUE schema constraints
- **Performance profiling**: No built-in profiling or performance metrics output

## Implementation Approach

The following pseudo-code illustrates the core validation pipeline using the Go CUE SDK:

```go
package main

import (
    "cuelang.org/go/cue"
    "cuelang.org/go/cue/cuecontext"
    "cuelang.org/go/cue/load"
)

func runModVet(cmd *cobra.Command, args []string) error {
    // Parse flags and determine module path
    modulePath := "."
    if len(args) > 0 {
        modulePath = args[0]
    }
    
    // Phase 1: Project Structure Validation
    if err := validateProjectStructure(modulePath, vetFlags.debug); err != nil {
        return exitWithCode(2, err)
    }
    
    // Phase 2: Load CUE Instances
    ctx := cuecontext.New()
    cfg := &load.Config{
        ModuleRoot: modulePath,
        Package:    vetFlags.pkg,
        Dir:        modulePath,
    }
    
    // Determine values file (debug_values.cue or values.cue)
    valuesFile := "values.cue"
    if vetFlags.debug {
        debugFile := filepath.Join(modulePath, "debug_values.cue")
        if fileExists(debugFile) {
            valuesFile = "debug_values.cue"
        } else {
            log.Warn("debug_values.cue not found, using values.cue")
        }
    }
    
    instances := load.Instances([]string{}, cfg)
    if len(instances) == 0 {
        return exitWithCode(2, "no CUE instances found")
    }
    
    inst := instances[0]
    if inst.Err != nil {
        return exitWithCode(2, formatCUEError(inst.Err))
    }
    
    // Build the instance
    value := ctx.BuildInstance(inst)
    if value.Err() != nil {
        return exitWithCode(2, formatCUEError(value.Err()))
    }
    
    // Phase 3: Schema Validation
    if err := value.Validate(); err != nil {
        return exitWithCode(2, formatCUEError(err))
    }
    
    // Validate against #Module schema
    moduleSchema := value.LookupPath(cue.ParsePath("#Module"))
    if moduleSchema.Err() != nil {
        return exitWithCode(2, "module does not conform to #Module schema")
    }
    
    // Phase 4: Concrete Validation (optional)
    if vetFlags.concrete {
        if err := value.Validate(cue.Concrete(true), cue.Final()); err != nil {
            return exitWithCode(2, formatConcreteError(err))
        }
    }
    
    // Extract entity counts for summary
    module := extractModule(value)
    componentCount := len(module.Components)
    scopeCount := len(module.Scopes)
    
    // Display success summary
    log.Info(fmt.Sprintf("✓ Module %s validated", module.Metadata.Name))
    log.Info(fmt.Sprintf("✓ %d components validated", componentCount))
    if scopeCount > 0 {
        log.Info(fmt.Sprintf("✓ %d scopes validated", scopeCount))
    }
    
    return nil
}

func validateProjectStructure(path string, debug bool) error {
    // Check for cue.mod/module.cue
    if !fileExists(filepath.Join(path, "cue.mod", "module.cue")) {
        return fmt.Errorf("invalid module project structure\n  Missing required file: %s/cue.mod/module.cue", path)
    }
    
    // Check for module.cue
    if !fileExists(filepath.Join(path, "module.cue")) {
        return fmt.Errorf("invalid module project structure\n  Missing required file: %s/module.cue", path)
    }
    
    // Check for values.cue or debug_values.cue
    valuesExists := fileExists(filepath.Join(path, "values.cue"))
    debugValuesExists := fileExists(filepath.Join(path, "debug_values.cue"))
    
    if !valuesExists && !(debug && debugValuesExists) {
        return fmt.Errorf("invalid module project structure\n  Missing required file: %s/values.cue", path)
    }
    
    return nil
}

func formatCUEError(err error) error {
    // Parse CUE error and format with file:line:col
    // Extract meaningful message
    // Provide suggested fix if possible
    // Return user-friendly error
}
```

## Command Reference

### Syntax

```bash
opm mod vet [path] [flags]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `path` | No | Path to module directory (default: current directory `.`) |

### Flags

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--package` | `-p` | string | `"main"` | CUE package to validate |
| `--debug` | | bool | `false` | Use `debug_values.cue` instead of `values.cue` |
| `--concrete` | | bool | `false` | Require all values to be concrete (no open fields) |
| `--values` | `-f` | []string | `[]` | Additional values files to unify (CUE, YAML, JSON) |
| `--registry` | | string | `""` | Override registry for CUE module resolution |

### Examples

```bash
# Validate current directory module
opm mod vet

# Validate specific module path
opm mod vet ./modules/my-app

# Validate with debug values
opm mod vet --debug

# Require concrete values
opm mod vet --concrete

# Validate with custom values file
opm mod vet --values staging.cue

# Validate specific package
opm mod vet -p components

# Combine flags
opm mod vet --debug --concrete --values overrides.cue
```

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Validation succeeded |
| `1` | General error (usage, config issues) |
| `2` | Validation failed (syntax, schema, concrete errors) |

## Appendix: Validation Pipeline Diagram

```text
┌─────────────────────────────────────────────────────────────────┐
│                    OPM Validation Pipeline                       │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: Project Structure Validation                          │
│           ├─ Check cue.mod/module.cue exists                    │
│           ├─ Check module.cue exists                            │
│           └─ Check values.cue or debug_values.cue exists        │
│                                                                  │
│           Exit on failure: code 2                               │
├─────────────────────────────────────────────────────────────────┤
│  Phase 2: CUE Syntax & Import Validation                        │
│           ├─ Load CUE instances via cue/load                    │
│           ├─ Resolve imports using configured registry          │
│           │   (--registry > OPM_REGISTRY > config.registry)     │
│           └─ Build instance with cuecontext                     │
│                                                                  │
│           Report: Syntax errors with file:line:col              │
│           Exit on failure: code 2                               │
├─────────────────────────────────────────────────────────────────┤
│  Phase 3: Schema Validation                                     │
│           ├─ Validate against #Module schema                    │
│           ├─ Validate components against #Component            │
│           ├─ Validate scopes against #Scope (if present)       │
│           └─ Check metadata constraints                         │
│                                                                  │
│           Report: Schema violations with entity context         │
│           Exit on failure: code 2                               │
├─────────────────────────────────────────────────────────────────┤
│  Phase 4: Concrete Validation (if --concrete flag)              │
│           ├─ Call value.Validate(cue.Concrete(true))           │
│           └─ Identify open/incomplete fields                    │
│                                                                  │
│           Report: List of non-concrete fields                   │
│           Exit on failure: code 2                               │
├─────────────────────────────────────────────────────────────────┤
│  Output: Success Summary                                        │
│           ├─ ✓ Module [name] validated                         │
│           ├─ ✓ [N] components validated                        │
│           └─ ✓ [N] scopes validated (if present)               │
│                                                                  │
│           Exit: code 0                                          │
└─────────────────────────────────────────────────────────────────┘
```

## Related Specifications

- **002-cli-spec**: CLI configuration, registry resolution, command structure
- **004-render-and-lifecycle-spec**: Module rendering and deployment (builds on validated modules)
- **001-application-definitions-spec**: #Module, #Component, #Scope schemas
