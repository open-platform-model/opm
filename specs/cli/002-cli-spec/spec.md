# Feature Specification: OPM CLI v2

**Feature Branch**: `002-cli-spec`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: User description: "I want you to create a new specification based on the information we have gathered. call it 002-cli-spec"

## Clarifications

### Session 2026-01-22

- Q: How does the CLI uniquely identify and track Kubernetes resources belonging to a module? → A: Using labels: `app.kubernetes.io/managed-by: open-platform-model`, `module.opmodel.dev/name`, `module.opmodel.dev/namespace`, `module.opmodel.dev/version`, and `component.opmodel.dev/name`.
- Q: How should the CLI handle multiple `--values` flags? → A: Support multiple CUE, YAML, and JSON files. Convert all to CUE and rely on CUE unification for merging and schema validation (Timoni-style).
- Q: How should the CLI handle secrets? → A: Delegate to standard patterns (ExternalSecrets/SOPS). Users can include secret values in `values.yaml` (or CUE/JSON), which are unified like other values.
- Q: How should the CLI handle OCI registry authentication? → A: Leverage standard `~/.docker/config.json` (OCI standard).

### Session 2026-01-24

- Q: What is the scope of OPM_REGISTRY for CUE module resolution? → A: Global redirect — all CUE imports resolve through OPM_REGISTRY when configured.
- Q: How does OPM_REGISTRY integrate with the CUE toolchain? → A: Environment passthrough — set `CUE_REGISTRY` env var when invoking `cue` binary.
- Q: What happens when configured registry is unreachable? → A: Fail fast — exit with error code and clear message about registry connectivity.

### Session 2026-01-28 (Experiment 004 Findings)

- Q: What format should config use? → A: CUE (not YAML) to enable type-safe provider references via imports.
- Q: How is config.registry extracted without causing bootstrap issues? → A: Simple CUE parsing extracts `config.registry` value without resolving imports. The resolved registry (from precedence chain) is then used to load full config with provider imports.
- Q: What is the complete registry precedence? → A: `--registry` flag > `OPM_REGISTRY` env > `config.registry` value. CUE_REGISTRY is not supported.
- Q: Where are providers configured? → A: Only in `~/.opm/config.cue`. Modules MUST NOT declare or reference providers.

### Session 2026-01-28 (Performance & Behavior)

- Q: What is the target time for OCI publish/get round-trip? → A: 30 seconds (assumes local or low-latency registry).
- Q: How should the CLI handle Kubernetes API rate limiting? → A: Use client-go's built-in rate limiter with defaults.
- Q: How should the CLI handle server-side apply field ownership conflicts? → A: Warn and proceed (take ownership), matching kubectl default behavior.
- Q: Should the CLI display progress indicators during long operations? → A: No progress indicators; silent until completion or timeout.
- Q: Should the CLI enforce resource count limits per module? → A: No limits; rely on timeouts and system resources.

### Session 2026-01-29

- Q: How should security/credentials be handled? → A: No secrets stored in config.cue; CLI sets secure file permissions (0700 dir, 0600 files) during init.
- Q: What is explicitly out of scope? → A: GUI config editor, config sync, encrypted fields.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Module Authoring (Priority: P1)

A new OPM user wants to create their first module and validate it locally. This journey covers module scaffolding and validation.

**Why this priority**: This is the most critical user journey as it represents the primary "getting started" experience for OPM. A smooth first experience with module creation is essential for user adoption.

**Independent Test**: A user with the CLI installed can create a module from a template and validate it passes CUE syntax and schema checks.

**Acceptance Scenarios**:

1. **Given** a developer has the OPM CLI installed, **When** they run `opm mod init my-app`, **Then** a new module directory is created with the standard template structure.
2. **Given** a newly initialized module, **When** the user runs `opm mod vet`, **Then** validation passes with no errors.
3. **Given** a module with missing CUE dependencies, **When** the user runs `opm mod tidy`, **Then** dependencies are resolved and `cue.mod/module.cue` is updated.
4. **Given** a module with invalid CUE syntax or schema violations, **When** the user runs `opm mod vet --concrete`, **Then** they see clear error messages with file locations, line numbers, and suggestions for fixing the issues.

---

A platform operator setting up OPM for the first time needs to initialize the CLI configuration with default settings and the kubernetes provider. This enables developers on the team to immediately start rendering modules.

**Why this priority**: Without configuration, the CLI cannot resolve providers needed for module rendering. This is the foundational setup step.

**Independent Test**: Run `opm config init` on a fresh system and verify the config file is created with kubernetes provider configured.

**Acceptance Scenarios**:

1. **Given** a fresh OPM installation with no existing config, **When** the operator runs `opm config init`, **Then** a config directory is created at `~/.opm/` containing a valid CUE module with `config.cue` and `cue.mod/module.cue`, with secure permissions (0700 directory, 0600 files).
2. **Given** a fresh installation, **When** the operator runs `opm config init`, **Then** the generated config includes the kubernetes provider configured by default.
3. **Given** an existing config at `~/.opm/config.cue`, **When** the operator runs `opm config init`, **Then** the command fails with a clear error message unless `--force` is specified.
4. **Given** a fresh installation, **When** the operator runs `opm config init --force`, **Then** any existing config is overwritten with defaults.

---

When a developer runs any module command (e.g., `opm mod vet`), the CLI must load the configuration, resolve the registry, and fetch provider modules.

**Why this priority**: This is the core runtime behavior that enables all module operations. Without config loading, providers cannot be resolved and modules cannot be validated.

**Independent Test**: With a valid config.cue containing a registry and kubernetes provider, run `opm mod vet` on a sample module and verify the provider is loaded.

**Acceptance Scenarios**:

1. **Given** a valid `~/.opm/config.cue` with `registry: "localhost:5001"` and kubernetes provider, **When** the CLI loads configuration, **Then** it successfully fetches the provider module from the specified registry.
2. **Given** a `--registry` flag is provided, **When** the CLI resolves the registry, **Then** the flag value takes precedence over `OPM_REGISTRY` env var and `config.registry`.
3. **Given** `OPM_REGISTRY` is set and no `--registry` flag, **When** the CLI resolves the registry, **Then** the env var takes precedence over `config.registry`.
4. **Given** only `config.registry` is set, **When** the CLI resolves the registry, **Then** the config value is used.
5. **Given** providers are configured but no registry is resolvable, **When** the CLI attempts to load config, **Then** it fails fast with a clear error message.
6. **Given** the registry is unreachable, **When** the CLI attempts to fetch provider modules, **Then** it fails with a specific error indicating which provider could not be loaded.

---

A developer who has modified their configuration needs to validate it before running module commands to catch errors early.

**Why this priority**: Validation provides fast feedback on configuration errors, improving developer experience and reducing debugging time.

**Independent Test**: Create a config.cue with intentional errors and run `opm config vet` to verify errors are reported.

**Acceptance Scenarios**:

1. **Given** a valid `~/.opm/config.cue`, **When** the user runs `opm config vet`, **Then** validation succeeds with a confirmation message.
2. **Given** a config.cue with invalid CUE syntax, **When** the user runs `opm config vet`, **Then** validation fails with file location and line numbers.
3. **Given** a config.cue with invalid field values (e.g., invalid namespace pattern), **When** the user runs `opm config vet`, **Then** validation fails with specific field names and expected formats.
4. **Given** a config.cue referencing a non-existent provider, **When** the user runs `opm config vet`, **Then** validation fails with a message about the missing provider.

---

An advanced platform operator wants to extend or customize provider configuration, such as adding custom transformers or configuring multiple providers.

**Why this priority**: This supports advanced use cases but is not required for basic operation.

**Independent Test**: Modify config.cue to add a custom transformer and verify it's available during rendering.

**Acceptance Scenarios**:

1. **Given** a config.cue with multiple providers configured, **When** the CLI loads configuration, **Then** all providers are available and selectable via `--provider` flag.
2. **Given** a config.cue that extends a provider with custom transformers via CUE unification, **When** the CLI loads the provider, **Then** custom transformers are included alongside standard transformers.

---

### Edge Cases

- **Registry Unreachable**: When `OPM_REGISTRY` is configured and the registry is unreachable during `mod tidy`, `mod vet`, or any command requiring CUE module resolution, the CLI fails fast with a clear error message (e.g., "Error: cannot connect to registry localhost:5000"). No silent fallback to original module domains occurs.
- **Config directory does not exist**: `config init` creates `~/.opm/` directory structure.
- **Config file exists but cue.mod is missing**: Treated as invalid config; suggest running `config init --force`.
- **Registry in config but no providers**: Config loads successfully; providers map is empty.
- **Circular import in config**: CUE loader reports circular dependency error with clear message.
- **Provider module version mismatch**: CUE dependency resolution handles version constraints; report clear error on incompatibility.
- **Network timeout during provider fetch**: Fail with timeout error specifying which module timed out.
- **OPM_CONFIG environment variable**: Allows specifying alternate config path; full precedence is flag > env > default.

> **Note**: Edge cases related to cluster operations (apply, delete, diff, status), secret management, RBAC permissions, and server-side apply are specified in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md).

## Requirements *(mandatory)*

### Functional Requirements

#### Module Commands

- **FR-001**: The CLI MUST provide a `mod init` command to create a new module from a template. The command MUST support `--template` flag accepting `simple`, `standard` (default), or `advanced`. The command MUST display a file tree with descriptions aligned at column 30 showing the created module structure.
- **FR-002**: The CLI MUST provide `mod vet` and `mod tidy` commands for module validation and dependency management.
- **FR-003**: The CLI MUST provide a `mod build` command. *(Implementation details in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md))*
- **FR-004**: The CLI MUST provide a `mod apply` command. *(Implementation details in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md))*
- **FR-005**: The CLI MUST provide a `mod delete` command. *(Implementation details in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md))*
- **FR-006**: The CLI MUST provide a `mod diff` command. *(Implementation details in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md))*
- **FR-007**: The CLI MUST provide a `mod status` command. *(Implementation details in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md))*

#### Configuration

- **FR-008**: The CLI MUST use a CUE module at `~/.opm/` as the configuration directory, containing `config.cue` and `cue.mod/module.cue`. The config.cue file MUST define a `config` struct containing configuration fields. The config module MUST be able to import provider modules using standard CUE import syntax (e.g., `import providers "opmodel.dev/providers@v0"`). Providers MUST be referenced using the registry lookup pattern: `providers.#Registry["<provider-name>"]`. The CLI MUST provide `config init` and `config vet` commands for configuration management. The `config init` command MUST include the kubernetes provider in the default configuration and MUST fail if config already exists unless `--force` flag is specified. The `config init` command MUST set secure file permissions: 0700 for `~/.opm/` directory, 0600 for `config.cue` and files under `cue.mod/`. The `config vet` command MUST report validation errors with file locations, line numbers, field names, and expected formats.
- **FR-009**: The CLI MUST resolve the registry URL using this precedence (highest to lowest): (1) `--registry` flag, (2) `OPM_REGISTRY` environment variable, (3) `config.registry` from `~/.opm/config.cue`. The `config.registry` value MUST be extractable via simple CUE parsing without requiring module/import resolution. The resolved registry URL MUST be used for all CUE module operations, including loading provider imports in config.cue itself. When set (e.g., `localhost:5000`), all CUE imports (e.g., `opmodel.dev/core@v0`) MUST resolve from the configured registry. The CLI MUST pass this configuration to the `cue` binary via the `CUE_REGISTRY` environment variable when executing `mod tidy` and `mod vet` commands.
- **FR-010**: When `OPM_REGISTRY` is configured and the registry is unreachable, commands that require module resolution MUST fail fast with a clear error message indicating registry connectivity failure. The CLI MUST NOT silently fall back to alternative registries.
- **FR-011**: The config MUST support the following optional fields: `registry` (default OCI registry for module resolution), `kubeconfig` (path to kubeconfig file, default: `~/.kube/config`), `context` (Kubernetes context to use, default: current-context), `namespace` (default namespace for operations, default: `default`), `cacheDir` (local cache directory path, default: `~/.opm/cache`).
- **FR-012**: The `config.providers` field MUST be a map of provider aliases to provider definitions loaded via CUE imports.
- **FR-013**: The CLI MUST implement a two-phase config loading process: (1) **Phase 1 (Bootstrap)**: Extract `config.registry` via simple CUE parsing without import resolution; (2) **Phase 2 (Full Load)**: Use resolved registry to load config.cue with all imports resolved.
- **FR-014**: When providers are configured but no registry is resolvable (no flag, no env, no config.registry), the CLI MUST fail fast with a clear error message. When the registry is unreachable during provider fetch, the CLI MUST fail with a specific error indicating registry connectivity failure and which provider module could not be loaded.

#### CLI Behavior

- **FR-015**: All commands MUST be non-interactive.
- **FR-016**: The CLI MUST provide structured, human-readable logging to `stderr`. Logs MUST use colors to distinguish categories (Info, Warning, Error, Debug). The `--verbose` flag MUST increase the detail of logs.
- **FR-017**: The CLI MUST provide a global `--output-format` flag (alias `-o`) supporting `text` (default), `yaml`, and `json` values. The `text` format MUST provide the most appropriate human-readable output for the command (e.g., tables for status, YAML for manifests) on `stdout`.
- **FR-018**: The CLI MUST resolve configuration values using the following precedence (highest to lowest): (1) Command-line flags, (2) Environment variables (e.g., `OPM_NAMESPACE`), (3) Configuration file (`~/.opm/config.cue` or path specified by `--config`/`OPM_CONFIG`), (4) Built-in defaults. When a value is provided at multiple levels, the higher-precedence source MUST win. When `--verbose` is specified, the CLI MUST log each configuration value's resolution at DEBUG level, including which source provided the value and which lower-precedence sources were overridden.

### Key Entities

- **ModuleDefinition**: The primary authoring artifact. A CUE file (`module.cue`) that defines the components, schemas, and logic of a reusable piece of infrastructure or application.
- **Project Structure**: A strictly defined directory layout ensuring portability and compatibility (see [Reference: Project Structure](reference/project-structure.md)).
- **Config Module**: A CUE module at `~/.opm/` that defines CLI configuration. Contains `config.cue` (main config) and `cue.mod/module.cue` (module metadata and dependencies).
- **Config Struct**: The `config` field in config.cue containing registry, kubeconfig, context, namespace, cacheDir, and providers.
- **Provider Registry**: A CUE definition (`#Registry`) in the providers module that maps provider names to provider definitions.
- **Provider Definition**: A CUE struct conforming to `core.#Provider` that defines transformers and metadata for a target platform.

> **Note**: Render-related entities (Values Files, Kubernetes Resources, Manifests) are specified in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can initialize and validate a module with `opm mod init` and `opm mod vet` in under 30 seconds.
  - *Measurement*: Timed from `opm mod init my-app` to successful `opm mod vet` completion.
  - *Assumptions*: Warm local cache for CUE dependencies.
  - *Exclusions*: CUE dependency download time on first run.

- **SC-002**: Platform operators can create a valid configuration with `opm config init` in under 10 seconds.

- **SC-003**: Configuration validation (`opm config vet`) completes in under 2 seconds for typical configurations.

- **SC-004**: Provider modules are fetched and loaded in under 5 seconds on first use (warm cache: under 1 second).

- **SC-005**: 100% of configuration errors produce actionable error messages with file location and field name.

- **SC-006**: Registry precedence chain works correctly: flag overrides env, env overrides config, for all tested scenarios.

- **SC-007**: Configuration loading fails fast (under 5 seconds timeout) when registry is unreachable, with clear error message.

> **Note**: Success criteria for build, apply, diff, delete, and status commands are specified in [004-render-and-lifecycle-spec](../004-render-and-lifecycle-spec/spec.md).

## Assumptions

- Provider modules are published to OCI registries following CUE module conventions.
- The `opmodel.dev/providers@v0` module exports a `#Registry` definition mapping provider names to definitions.
- Users have network access to configured registries (or use local registries for air-gapped environments).
- CUE SDK v0.14+ is used, supporting the module system and registry features.

## Out of Scope

- GUI config editor (CLI-only interface)
- Config sync across machines
- Encrypted config fields (no secrets stored in config.cue)
- Windows registry integration

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
    
    kubernetes: {
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
    }
    
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
module: "opmodel.dev/config@v0"

language: {
    version: "v0.15.0"
}

deps: {
    "opmodel.dev/providers@v0": {
        v: "v0.1.0"
    }
}
```

## 6. Module Templates

The `mod init` command supports three templates to scaffold new modules. Templates provide progressively more structure for different use cases.

### 6.1. Available Templates

| Template | Description | Use Case |
| :--- | :--- | :--- |
| `simple` | Single-file inline | Learning OPM, prototypes, minimal projects |
| `standard` | Separated components | Team projects, production modules |
| `advanced` | Multi-package with subpackages | Complex platforms, enterprise deployments |

### 6.2. Template Selection

- **Default**: `standard` is used when `--template` is omitted.
- **Flag**: `opm mod init --template <name>` selects a specific template.
- **Validation**: Unknown template names result in exit code `2` (Validation Error).

### 6.3. Template Data

Templates are rendered with the following variables:

| Variable | Source | Description |
| :--- | :--- | :--- |
| `ModuleName` | `--name` flag or directory name | Module metadata name |
| `ModulePath` | `--module` flag or derived from name | CUE module path (e.g., `example.com/my-app`) |
| `Version` | Hardcoded | Initial version (`0.1.0`) |
| `PackageName` | Sanitized from `ModuleName` | CUE package name |

### 6.4. Template Structures

See [Reference: Project Structure](reference/project-structure.md) for detailed file layouts of each template.
