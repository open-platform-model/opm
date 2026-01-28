# Feature Specification: OPM CLI v2

**Feature Branch**: `002-cli-spec`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: User description: "I want you to create a new specification based on the information we have gathered. call it 002-cli-spec"

## Clarifications

### Session 2026-01-22

- Q: How does the CLI uniquely identify and track Kubernetes resources belonging to a module? → A: Using labels: `app.kubernetes.io/managed-by: open-platform-model`, `module.opmodel.dev/name`, `module.opmodel.dev/namespace`, `module.opmodel.dev/version`, and `component.opmodel.dev/name`.
- Q: How should the CLI handle multiple `--values` flags? → A: Support multiple CUE, YAML, and JSON files. Convert all to CUE and rely on CUE unification for merging and schema validation (Timoni-style).
- Q: How should `opm mod status` determine resource health? → A: Success on creation for passive resources; wait for standard `Ready` conditions on workloads (`Deployment`, `StatefulSet`, etc.).
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

### Session 2026-01-28

- Q: What is the target time for OCI publish/get round-trip? → A: 30 seconds (assumes local or low-latency registry).
- Q: How should the CLI handle Kubernetes API rate limiting? → A: Use client-go's built-in rate limiter with defaults.
- Q: How should the CLI handle server-side apply field ownership conflicts? → A: Warn and proceed (take ownership), matching kubectl default behavior.
- Q: Should the CLI display progress indicators during long operations? → A: No progress indicators; silent until completion or timeout.
- Q: Should the CLI enforce resource count limits per module? → A: No limits; rely on timeouts and system resources.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Module Authoring and Deployment (Priority: P1)

A new OPM user wants to create their first module and deploy it to a Kubernetes cluster to see it running. This journey covers the "inner loop" of creation and the first deployment.

**Why this priority**: This is the most critical user journey as it represents the primary "getting started" experience for OPM. A smooth and successful first run is essential for user adoption.

**Independent Test**: This can be tested by providing a user with the CLI and a Kubernetes cluster. They should be able to follow a quickstart guide, successfully deploy a simple "hello-world" module, and see it running via `kubectl`.

**Acceptance Scenarios**:

1. **Given** a developer has the OPM CLI installed and a valid kubeconfig, **When** they run `opm mod init my-app --template oci://registry.opm.dev/templates/standard:latest`, `cd my-app`, and then `opm mod apply`, **Then** the default application is deployed to their cluster.
2. **Given** a module has been deployed, **When** the user runs `opm mod status`, **Then** they see a status summary of the Kubernetes resources that were created.
3. **Given** a module has been deployed, **When** the user runs `opm mod delete`, **Then** all resources associated with that module are removed from the cluster.
4. **Given** a module with invalid CUE syntax or schema violations, **When** the user runs `opm mod vet --concrete`, **Then** they see clear error messages with file locations, line numbers, and suggestions for fixing the issues.

---

### User Story 2 - Updating an Existing Module (Priority: P2)

A module author needs to make a change to an existing module (e.g., update a container image) and wants to safely preview and apply this change to the cluster.

**Why this priority**: This represents the common day-to-day workflow of a module author. The ability to safely diff and apply changes is a core competency of the CLI.

**Independent Test**: This can be tested by deploying a module, then making a local change to the `module.cue` file. The `diff` and `apply` commands should reflect and enact these changes on the cluster.

**Acceptance Scenarios**:

1. **Given** a module is deployed and the local `module.cue` has been modified, **When** the user runs `opm mod diff`, **Then** they see a clear, colorized diff of the pending changes.
2. **Given** `opm mod diff` shows pending changes, **When** the user runs `opm mod apply`, **Then** the changes are applied to the cluster and `opm mod diff` subsequently shows no differences.
3. **Given** a developer wants to render the manifests locally without applying them, **When** they run `opm mod build -o yaml`, **Then** the full Kubernetes manifests are printed to standard output.

---

### User Story 3 - Platform Provider Configuration (Priority: P2)

A platform operator needs to configure which providers are available for rendering modules, enabling developers to render without provider knowledge.

**Why this priority**: Providers are essential for the render pipeline. Platform operators must be able to configure providers before developers can successfully render modules.

**Independent Test**: Platform operator runs `opm config init`, adds kubernetes provider to config.cue, and developers can then render modules using that provider.

**Acceptance Scenarios**:

1. **Given** a fresh OPM installation, **When** the operator runs `opm config init`, **Then** a config.cue file is created at `~/.opm/config.cue` with the kubernetes provider configured by default.
2. **Given** a valid config.cue with kubernetes provider, **When** a developer runs `opm mod build`, **Then** the module renders using kubernetes transformers from the configured provider.
3. **Given** an unreachable registry, **When** config.cue references a provider module that cannot be fetched, **Then** the CLI fails fast with a clear error indicating registry connectivity failure and which provider module could not be loaded.
4. **Given** an invalid provider configuration (malformed CUE), **When** the user runs `opm config vet`, **Then** validation errors are reported with field names and line numbers.

---

### User Story 4 - CLI Configuration Setup (Priority: P5)

A new user needs to configure the OPM CLI with their preferred defaults (namespace, registry, kubeconfig path) before using it regularly.

**Why this priority**: This is a one-time setup task that improves the ongoing user experience. Lower priority because CLI works with defaults and environment variables without explicit configuration.

**Independent Test**: User runs `opm config init`, edits the generated file, then runs `opm config vet` to validate their changes.

**Acceptance Scenarios**:

1. **Given** a user has installed the OPM CLI, **When** they run `opm config init`, **Then** a config file is created at `~/.opm/config.cue` with documented defaults and kubernetes provider configured.
2. **Given** a user has modified their config file, **When** they run `opm config vet`, **Then** validation errors are clearly reported with field names, line numbers, and expected formats.

---

### Edge Cases

- **Secret Management**: When secrets are provided via `--values` files, they are unified into the CUE definition. It is the user's responsibility to manage the security of these files (e.g., using SOPS to decrypt before passing to OPM). Manifests rendered via `build` will contain these secrets in plaintext unless the module definition targets resources like `ExternalSecret`.
- **Cluster Connectivity**: What happens when a user runs `apply`, `delete`, `diff`, or `status` without a valid or reachable Kubernetes cluster? The CLI should fail gracefully with a clear error message about cluster connectivity.
- **Invalid Values**: How does the system handle an `apply` or `build` when the user provides a `--values` file that does not satisfy the module's schema? The operation should fail with a clear CUE validation error.
- **Permissions**: What happens if the user tries to `apply` or `delete` resources in a namespace where they don't have sufficient RBAC permissions? The CLI should output the server-side error from the Kubernetes API.
- **Registry Unreachable**: When `OPM_REGISTRY` is configured and the registry is unreachable during `mod tidy`, `mod vet`, or any command requiring CUE module resolution, the CLI fails fast with a clear error message (e.g., "Error: cannot connect to registry localhost:5000"). No silent fallback to original module domains occurs.
- **Server-Side Apply Field Conflicts**: When another controller (e.g., HPA) owns a field that the module also specifies, the CLI warns to stderr and proceeds with the apply, taking ownership of the conflicting field. This matches kubectl's default SSA behavior.
- **API Rate Limiting**: The CLI uses client-go's built-in rate limiter with defaults. When the Kubernetes API returns 429 (Too Many Requests), client-go handles exponential backoff automatically.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST provide a `mod init` command to create a new module from a template. The command MUST display a file tree with descriptions aligned at column 30 showing the created module structure.
- **FR-002**: The CLI MUST provide `mod vet` and `mod tidy` commands for module validation and dependency management.
- **FR-003**: The CLI MUST provide a `mod build` command that renders a module's CUE definition into Kubernetes manifests in YAML, JSON, or a directory structure.
- **FR-004**: The CLI MUST provide a `mod apply` command to idempotently create or update a module's resources on a Kubernetes cluster, applying them in a weighted order to respect hard dependencies (see Section 6).
- **FR-005**: The `mod apply` command MUST support `--dry-run` and `--diff` flags to allow users to preview changes before they are made.
- **FR-006**: The CLI MUST provide a `mod delete` command to remove all Kubernetes resources discovered via the `module.opmodel.dev/name` and `module.opmodel.dev/namespace` labels, deleting them in the reverse weighted order (see Section 6).
- **FR-007**: The CLI MUST provide a `mod diff` command to show a diff between the local module definition and the live resources on the cluster.
- **FR-008**: The CLI MUST provide a `mod status` command to report the readiness and health of a deployed module's Kubernetes resources, following the health evaluation logic in Section 6.3.
- **FR-009**: All deployment-related commands (`build`, `apply`, `diff`, `delete`) MUST support multiple `--values` flags accepting CUE, YAML, or JSON files. These inputs MUST be unified with the module's CUE definitions to ensure schema compliance and produce the final configuration.
- **FR-011**: All commands MUST be non-interactive.
- **FR-012**: The CLI MUST use a CUE configuration file at `~/.opm/config.cue`, validated against an internal CUE schema. The CLI MUST provide `config init` and `config vet` commands for configuration management. The config file MUST be a valid CUE module that can import provider modules for type-safe provider configuration.
- **FR-013**: The CLI MUST apply and delete resources based on a predefined weighting system to ensure hard dependencies (e.g., CRDs, Namespaces) are managed correctly).
- **FR-014**: The CLI MUST resolve the registry URL using this precedence (highest to lowest): (1) `--registry` flag, (2) `OPM_REGISTRY` environment variable, (3) `config.registry` from `~/.opm/config.cue`. The `config.registry` value MUST be extractable via simple CUE parsing without requiring module/import resolution. The resolved registry URL MUST be used for all CUE module operations, including loading provider imports in config.cue itself. When set (e.g., `localhost:5000`), all CUE imports (e.g., `opm.dev/core@v0`) MUST resolve from the configured registry. The CLI MUST pass this configuration to the `cue` binary via the `CUE_REGISTRY` environment variable when executing `mod tidy` and `mod vet` commands.
- **FR-015**: When `OPM_REGISTRY` is configured and the registry is unreachable, commands that require module resolution MUST fail fast with a clear error message indicating registry connectivity failure. The CLI MUST NOT silently fall back to alternative registries.
- **FR-016**: The CLI MUST provide structured, human-readable logging to `stderr`. Logs MUST use colors to distinguish categories (Info, Warning, Error, Debug). The `--verbose` flag MUST increase the detail of logs.
- **FR-017**: The CLI MUST provide a global `--output-format` flag (alias `-o`) supporting `text` (default), `yaml`, and `json` values. The `text` format MUST provide the most appropriate human-readable output for the command (e.g., tables for status, YAML for manifests) on `stdout`.
- **FR-018**: The CLI MUST resolve configuration values using the following precedence (highest to lowest): (1) Command-line flags, (2) Environment variables (e.g., `OPM_NAMESPACE`), (3) Configuration file (`~/.opm/config.cue` or path specified by `--config`/`OPM_CONFIG`), (4) Built-in defaults. When a value is provided at multiple levels, the higher-precedence source MUST win. When `--verbose` is specified, the CLI MUST log each configuration value's resolution at DEBUG level, including which source provided the value and which lower-precedence sources were overridden.
- **FR-019**: The CLI MUST use client-go's built-in rate limiter with default settings for all Kubernetes API operations. The CLI MUST NOT implement custom rate limiting or backoff logic.
- **FR-020**: When server-side apply encounters field ownership conflicts, the CLI MUST log a warning to stderr identifying the conflicting fields and their current owners, then proceed with the apply (taking ownership). The CLI MUST NOT fail on field conflicts by default.
- **FR-021**: Long-running operations (`apply --wait`, `delete`, `status --watch`) MUST NOT display progress indicators. Output is silent until completion, timeout, or error.
- **FR-022**: The CLI MUST NOT enforce limits on module complexity (resource count, CUE evaluation depth). Natural limits are provided by operation timeouts and system resources.

### Key Entities

- **ModuleDefinition**: The primary authoring artifact. A CUE file (`module.cue`) that defines the components, schemas, and logic of a reusable piece of infrastructure or application.
- **Project Structure**: A strictly defined directory layout ensuring portability and compatibility (see [Reference: Project Structure](reference/project-structure.md)).
- **Values File**: A user-provided CUE, YAML, or JSON file that supplies concrete configuration. Multiple files are unified using CUE semantics to validate against the `ModuleDefinition` and render resources.

- **Kubernetes Resource**: The output of the `build` process. Standard Kubernetes manifests (e.g., Deployment, Service, ConfigMap) that are applied to a cluster.

### Resource Labeling

All resources generated or managed by the OPM CLI MUST include the following labels for identification and lifecycle management:

| Label | Purpose |
| :--- | :--- |
| `app.kubernetes.io/managed-by` | Set to `open-platform-model`. |
| `module.opmodel.dev/name` | The name of the module. |
| `module.opmodel.dev/namespace` | The target namespace for the module. |
| `module.opmodel.dev/version` | The version of the module being deployed. |
| `component.opmodel.dev/name` | The name of the specific component within the module. |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can successfully initialize, build, and apply a default "hello-world" module to a local Kubernetes cluster in under 3 minutes.
  - *Measurement*: Timed from `opm mod init` to successful `opm mod apply` completion with resources visible in cluster.
  - *Assumptions*: Warm local cache for CUE dependencies, local cluster (kind/k3d), network latency < 100ms.
  - *Exclusions*: CUE dependency download time on first run, cluster provisioning time.

- **SC-002**: The `opm mod diff` command accurately reflects the delta between a local configuration change and the live cluster state 100% of the time for supported Kubernetes resources.
  - *Measurement*: Diff output MUST show all field changes in supported Kubernetes resource kinds.
  - *Exclusions*: Server-managed fields (metadata.generation, metadata.resourceVersion, status.*) are excluded from diff comparison.

- **SC-003**: The `opm mod apply` command's server-side apply operation is fully idempotent; running it multiple times with the same inputs results in no changes after the first successful application.
  - *Measurement*: Second consecutive `opm mod apply` with identical inputs MUST result in zero server-side changes.
  - *Exclusions*: Server-managed timestamp fields (metadata.managedFields timestamps) are excluded from idempotency comparison.

- **SC-004**: The `opm mod status` command correctly reports the `Ready` or `NotReady` status for all managed Kubernetes workloads (Deployments, StatefulSets) within 60 seconds of a change.
  - *Measurement*: Time from `opm mod apply` completion to `opm mod status` reporting all workloads as Ready.
  - *Assumptions*: Standard workloads (Deployment, StatefulSet) with readiness probes responding within 30s.

- **SC-005**: The `opm mod publish` and `opm mod get` commands successfully complete a round-trip within 30 seconds: publishing a module to an OCI registry and retrieving it produces an identical module.
  - *Measurement*: Module published with `opm mod publish`, deleted locally, retrieved with `opm mod get`, and `opm mod vet` passes on retrieved module.
  - *Assumptions*: Local or low-latency OCI registry, valid credentials in `~/.docker/config.json`, module size < 10MB.

## 6. Deployment Lifecycle & Resource Ordering

To ensure reliable and predictable deployments, the OPM CLI will use a weighted system to determine the order in which Kubernetes resources are applied and deleted. This approach correctly handles "hard dependencies" where applying a resource would fail if another resource (like a CRD or Namespace) does not yet exist.

### 6.1. Resource Weighting System

The core mechanic is a predefined weight assigned to each Kubernetes resource Kind.

- **Apply Order**: Resources are applied in **ascending** order of their weights (lower weights first).
- **Delete Order**: Resources are deleted in **descending** order of their weights (higher weights first).

This ensures that foundational resources are created before the workloads that depend on them, and that workloads are terminated before their foundational resources are removed.

### 6.2. Resource Weights

| Resource Kind | Weight | Rationale |
| :--- | :--- | :--- |
| `CustomResourceDefinition` | -100 | **Defines new APIs.** Must be created first so the Kubernetes API server can recognize custom resources. |
| `Namespace` | 0 | **Creates boundaries.** Must exist before any namespaced resources can be created within it. |
| `ClusterRole`, `ClusterRoleBinding` | 5 | **Cluster-wide permissions.** Applied early as they are fundamental to cluster operation. |
| `ResourceQuota`, `LimitRange` | 5 | **Namespace policies.** Defines constraints within a namespace. |
| `ServiceAccount` | 10 | **Identity.** Pods are rejected if their referenced `ServiceAccount` doesn't exist. |
| `Role`, `RoleBinding` | 10 | **Namespaced permissions.** Depends on `Namespace` and `ServiceAccount`. |
| `Secret`, `ConfigMap` | 15 | **Configuration.** Pods depend on these for configuration and secrets, so they must exist first. |
| `StorageClass`, `PersistentVolume`, `PersistentVolumeClaim` | 20 | **Storage.** Workloads depend on `PersistentVolumeClaim`s to mount storage. |
| `Service` | 50 | **Networking.** Creates a stable DNS endpoint that workloads can be configured to use upon startup. |
| `DaemonSet`, `Deployment`, `StatefulSet`, `ReplicaSet` | 100 | **Core Workloads.** The primary applications and services that run on the cluster. |
| `Job`, `CronJob` | 110 | **Tasks.** Applied just after core workloads, as they might depend on services being available. |
| `Ingress` | 150 | **External Routing.** Depends on `Service`s being present to route traffic to them. |
| `NetworkPolicy` | 150 | **Traffic Rules.** Applies policies to running pods, so it should be created after the pods are defined. |
| `HorizontalPodAutoscaler` | 200 | **Autoscaling.** Acts upon running workloads like `Deployment`s, so it must be applied after them. |
| `ValidatingWebhookConfiguration`, `MutatingWebhookConfiguration` | 500 | **Admission Control.** Applied last to ensure their backing services (which are `Deployment`s and `Service`s) are running and ready, preventing cluster-wide apply blockages. |

### 6.3. Resource Health & Readiness

The `mod status` command evaluates resource health based on the following rules:

1. **Workloads**: Resources of kind `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, and `CronJob` are considered healthy only when their standard Kubernetes `Ready` or `Complete` conditions are met.
2. **Passive Resources**: Resources like `ConfigMap`, `Secret`, `Service`, `Namespace`, and `RBAC` entities are considered healthy immediately upon successful creation or update in the cluster.
3. **Custom Resources**: If a custom resource defines a `Ready` condition in its status, it is used; otherwise, it is treated as a passive resource.
