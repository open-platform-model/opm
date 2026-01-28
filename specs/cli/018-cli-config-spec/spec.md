# Feature Specification: CLI Configuration (.opm/config.cue)

**Feature Branch**: `018-cli-config-spec`  
**Created**: 2026-01-28  
**Status**: Draft  
**Input**: User description: "CLI configuration specification for .opm/config.cue handling - change from config.yaml to config.cue to enable CUE imports for providers"

## Clarifications

### Session 2026-01-28

- Q: Should config use YAML or CUE format? → A: CUE, to enable type-safe provider references via CUE imports.
- Q: What domain should provider modules use? → A: `opmodel.dev` (e.g., `opmodel.dev/providers@v0`).
- Q: How should providers be referenced? → A: Via registry lookup pattern: `providers.#Registry["kubernetes"]`.
- Q: What additional config fields are needed? → A: kubeconfig path, default namespace, default context, cacheDir.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Platform Operator Creates Initial Configuration (Priority: P1)

A platform operator setting up OPM for the first time needs to initialize the CLI configuration with default settings and the kubernetes provider. This enables developers on the team to immediately start rendering modules.

**Why this priority**: Without configuration, the CLI cannot resolve providers needed for module rendering. This is the foundational setup step.

**Independent Test**: Run `opm config init` on a fresh system and verify the config file is created with kubernetes provider configured.

**Acceptance Scenarios**:

1. **Given** a fresh OPM installation with no existing config, **When** the operator runs `opm config init`, **Then** a config directory is created at `~/.opm/` containing a valid CUE module with `config.cue` and `cue.mod/module.cue`.
2. **Given** a fresh installation, **When** the operator runs `opm config init`, **Then** the generated config includes the kubernetes provider configured by default.
3. **Given** an existing config at `~/.opm/config.cue`, **When** the operator runs `opm config init`, **Then** the command fails with a clear error message unless `--force` is specified.
4. **Given** a fresh installation, **When** the operator runs `opm config init --force`, **Then** any existing config is overwritten with defaults.

---

### User Story 2 - CLI Loads Configuration and Resolves Providers (Priority: P1)

When a developer runs any module command (e.g., `opm mod build`), the CLI must load the configuration, resolve the registry, fetch provider modules, and make providers available for rendering.

**Why this priority**: This is the core runtime behavior that enables all module operations. Without config loading, providers cannot be resolved and modules cannot be rendered.

**Independent Test**: With a valid config.cue containing a registry and kubernetes provider, run `opm mod build` on a sample module and verify the provider is loaded.

**Acceptance Scenarios**:

1. **Given** a valid `~/.opm/config.cue` with `registry: "localhost:5001"` and kubernetes provider, **When** the CLI loads configuration, **Then** it successfully fetches the provider module from the specified registry.
2. **Given** a `--registry` flag is provided, **When** the CLI resolves the registry, **Then** the flag value takes precedence over `OPM_REGISTRY` env var and `config.registry`.
3. **Given** `OPM_REGISTRY` is set and no `--registry` flag, **When** the CLI resolves the registry, **Then** the env var takes precedence over `config.registry`.
4. **Given** only `config.registry` is set, **When** the CLI resolves the registry, **Then** the config value is used.
5. **Given** providers are configured but no registry is resolvable, **When** the CLI attempts to load config, **Then** it fails fast with a clear error about registry connectivity.
6. **Given** the registry is unreachable, **When** the CLI attempts to fetch provider modules, **Then** it fails with a specific error indicating which provider could not be loaded.

---

### User Story 3 - Developer Validates Configuration (Priority: P2)

A developer who has modified their configuration needs to validate it before running module commands to catch errors early.

**Why this priority**: Validation provides fast feedback on configuration errors, improving developer experience and reducing debugging time.

**Independent Test**: Create a config.cue with intentional errors and run `opm config vet` to verify errors are reported.

**Acceptance Scenarios**:

1. **Given** a valid `~/.opm/config.cue`, **When** the user runs `opm config vet`, **Then** validation succeeds with a confirmation message.
2. **Given** a config.cue with invalid CUE syntax, **When** the user runs `opm config vet`, **Then** validation fails with file location and line numbers.
3. **Given** a config.cue with invalid field values (e.g., invalid namespace pattern), **When** the user runs `opm config vet`, **Then** validation fails with specific field names and expected formats.
4. **Given** a config.cue referencing a non-existent provider, **When** the user runs `opm config vet`, **Then** validation fails with a message about the missing provider.

---

### User Story 4 - Advanced User Customizes Provider Configuration (Priority: P3)

An advanced platform operator wants to extend or customize provider configuration, such as adding custom transformers or configuring multiple providers.

**Why this priority**: This supports advanced use cases but is not required for basic operation.

**Independent Test**: Modify config.cue to add a custom transformer and verify it's available during rendering.

**Acceptance Scenarios**:

1. **Given** a config.cue with multiple providers configured, **When** the CLI loads configuration, **Then** all providers are available and selectable via `--provider` flag.
2. **Given** a config.cue that extends a provider with custom transformers via CUE unification, **When** the CLI loads the provider, **Then** custom transformers are included alongside standard transformers.

---

### Edge Cases

- **Config directory does not exist**: `config init` creates `~/.opm/` directory structure.
- **Config file exists but cue.mod is missing**: Treated as invalid config; suggest running `config init --force`.
- **Registry in config but no providers**: Config loads successfully; providers map is empty.
- **Circular import in config**: CUE loader reports circular dependency error with clear message.
- **Provider module version mismatch**: CUE dependency resolution handles version constraints; report clear error on incompatibility.
- **Network timeout during provider fetch**: Fail with timeout error specifying which module timed out.
- **OPM_CONFIG environment variable**: Allows specifying alternate config path; full precedence is flag > env > default.

## Requirements *(mandatory)*

### Functional Requirements

#### Config File Structure

- **FR-001**: The CLI MUST use a CUE module at `~/.opm/` as the configuration directory, containing `config.cue` and `cue.mod/module.cue`.
- **FR-002**: The config.cue file MUST define a `config` struct containing configuration fields.
- **FR-003**: The config module MUST be able to import provider modules using standard CUE import syntax (e.g., `import providers "opmodel.dev/providers@v0"`).
- **FR-004**: Providers MUST be referenced using the registry lookup pattern: `providers.#Registry["<provider-name>"]`.

#### Config Fields

- **FR-005**: The `config.registry` field MUST be extractable via simple CUE parsing without resolving imports (to solve the bootstrap problem).
- **FR-006**: The config MUST support the following optional fields:
  - `registry`: Default OCI registry for module resolution (string)
  - `kubeconfig`: Path to kubeconfig file (string, default: `~/.kube/config`)
  - `context`: Kubernetes context to use (string, default: current-context)
  - `namespace`: Default namespace for operations (string, default: `default`)
  - `cacheDir`: Local cache directory path (string, default: `~/.opm/cache`)
- **FR-007**: The `config.providers` field MUST be a map of provider aliases to provider definitions loaded via CUE imports.

#### Registry Precedence

- **FR-008**: The CLI MUST resolve the registry URL using this precedence (highest to lowest):
  1. `--registry` command-line flag
  2. `OPM_REGISTRY` environment variable
  3. `config.registry` from config.cue
- **FR-009**: The resolved registry URL MUST be used for all CUE module operations, including fetching provider imports in config.cue itself.

#### Config Loading Algorithm

- **FR-010**: The CLI MUST implement a two-phase config loading process:
  1. **Phase 1 (Bootstrap)**: Extract `config.registry` via simple CUE parsing without import resolution
  2. **Phase 2 (Full Load)**: Use resolved registry to load config.cue with all imports resolved
- **FR-011**: When providers are configured but no registry is resolvable (no flag, no env, no config.registry), the CLI MUST fail fast with a clear error message.
- **FR-012**: When the registry is unreachable during provider fetch, the CLI MUST fail with a specific error indicating registry connectivity failure and which provider module could not be loaded.

#### Config Commands

- **FR-013**: The CLI MUST provide a `config init` command that creates the config directory and files with defaults.
- **FR-014**: The `config init` command MUST include the kubernetes provider in the default configuration.
- **FR-015**: The `config init` command MUST fail if config already exists unless `--force` flag is specified.
- **FR-016**: The CLI MUST provide a `config vet` command that validates the configuration against an internal schema.
- **FR-017**: The `config vet` command MUST report validation errors with file locations, line numbers, field names, and expected formats.

#### Config Value Resolution

- **FR-018**: For all config values except registry, the CLI MUST resolve using this precedence (highest to lowest):
  1. Command-line flags
  2. Environment variables (e.g., `OPM_NAMESPACE`, `OPM_KUBECONFIG`)
  3. Config file values
  4. Built-in defaults
- **FR-019**: When `--verbose` is specified, the CLI MUST log each configuration value's resolution at DEBUG level, including which source provided the value.

### Key Entities

- **Config Module**: A CUE module at `~/.opm/` that defines CLI configuration. Contains `config.cue` (main config) and `cue.mod/module.cue` (module metadata and dependencies).
- **Config Struct**: The `config` field in config.cue containing registry, kubeconfig, context, namespace, cacheDir, and providers.
- **Provider Registry**: A CUE definition (`#Registry`) in the providers module that maps provider names to provider definitions.
- **Provider Definition**: A CUE struct conforming to `core.#Provider` that defines transformers and metadata for a target platform.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Platform operators can create a valid configuration with `opm config init` in under 10 seconds.
- **SC-002**: Configuration validation (`opm config vet`) completes in under 2 seconds for typical configurations.
- **SC-003**: Provider modules are fetched and loaded in under 5 seconds on first use (warm cache: under 1 second).
- **SC-004**: 100% of configuration errors produce actionable error messages with file location and field name.
- **SC-005**: Registry precedence chain works correctly: flag overrides env, env overrides config, for all tested scenarios.
- **SC-006**: Configuration loading fails fast (under 5 seconds timeout) when registry is unreachable, with clear error message.

## Assumptions

- Provider modules are published to OCI registries following CUE module conventions.
- The `opmodel.dev/providers@v0` module exports a `#Registry` definition mapping provider names to definitions.
- Users have network access to configured registries (or use local registries for air-gapped environments).
- CUE SDK v0.14+ is used, supporting the module system and registry features.

## Config Schema Reference

### Default Config Template (generated by `config init`)

```cue
// ~/.opm/config.cue
package config

import (
    providers "opmodel.dev/providers@v0"
)

config: {
    // registry is the default OCI registry for module resolution.
    // Override with --registry flag or OPM_REGISTRY env var.
    registry: "registry.opmodel.dev"
    
    // kubeconfig is the path to the kubeconfig file.
    // Override with --kubeconfig flag or OPM_KUBECONFIG env var.
    kubeconfig: "~/.kube/config"
    
    // context is the Kubernetes context to use.
    // Override with --context flag or OPM_CONTEXT env var.
    // Default: current-context from kubeconfig
    context?: string
    
    // namespace is the default namespace for operations.
    // Override with --namespace flag or OPM_NAMESPACE env var.
    namespace: "default"
    
    // cacheDir is the local cache directory path.
    // Override with OPM_CACHE_DIR env var.
    cacheDir: "~/.opm/cache"
    
    // providers maps provider aliases to their definitions.
    // Providers are loaded from the registry via CUE imports.
    providers: {
        kubernetes: providers.#Registry["kubernetes"]
    }
}
```

### Module Metadata (generated by `config init`)

```cue
// ~/.opm/cue.mod/module.cue
module: "local.opmodel.dev/config@v0"

language: {
    version: "v0.15.0"
}

deps: {
    "opmodel.dev/providers@v0": {
        v: "v0.1.0"
    }
}
```
