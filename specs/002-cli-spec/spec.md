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

### User Story 3 - Distributing and Consuming a Module (Priority: P3)

A platform team has created a standardized module and wants to publish it to an OCI registry so that other developers can download and use it.

**Why this priority**: This workflow enables reusability and sharing, which is a core promise of OPM. It's lower priority than the initial authoring experience but crucial for team-based and enterprise adoption.

**Independent Test**: This can be tested with a local OCI registry. A user should be able to `publish` a module, delete it locally, and then `get` it back from the registry.

**Acceptance Scenarios**:

1. **Given** a developer has a valid module, **When** they run `opm mod publish <oci-url>`, **Then** the module is successfully pushed to the OCI registry.
2. **Given** a module exists in an OCI registry, **When** a user runs `opm mod get <oci-url>`, **Then** the module is downloaded to the local OPM cache.

---

### User Story 4 - Multi-Module Platform Deployment (Priority: P4)

A platform team wants to deploy a complete platform stack consisting of multiple modules as a single coordinated unit, ensuring consistent versions and proper dependency ordering across all modules.

**Why this priority**: This workflow enables enterprise-scale deployments where multiple services must be deployed together. It builds on the foundation of single-module operations established in US1-US3.

**Independent Test**: This can be tested by creating a bundle with 2-3 modules, applying it to a cluster, and verifying all modules deploy correctly with `opm bundle status` showing aggregate health.

**Acceptance Scenarios**:

1. **Given** a bundle definition with multiple modules, **When** the user runs `opm bundle apply`, **Then** all modules are deployed in correct weighted order with proper labeling.
2. **Given** a deployed bundle, **When** the user runs `opm bundle status`, **Then** they see the aggregate health status of all modules in the bundle.
3. **Given** a deployed bundle, **When** the user runs `opm bundle delete`, **Then** all resources from all modules are removed in reverse weighted order.
4. **Given** a deployed bundle with local changes, **When** the user runs `opm bundle diff`, **Then** they see a clear, colorized diff of pending changes across all modules.

---

### User Story 5 - CLI Configuration Setup (Priority: P5)

A new user needs to configure the OPM CLI with their preferred defaults (namespace, registry, kubeconfig path) before using it regularly.

**Why this priority**: This is a one-time setup task that improves the ongoing user experience. Lower priority because CLI works with defaults and environment variables without explicit configuration.

**Independent Test**: User runs `opm config init`, edits the generated file, then runs `opm config vet` to validate their changes.

**Acceptance Scenarios**:

1. **Given** a user has installed the OPM CLI, **When** they run `opm config init`, **Then** a config file is created at `~/.opm/config.yaml` with documented defaults.
2. **Given** a user has modified their config file, **When** they run `opm config vet`, **Then** validation errors are clearly reported with field names and expected formats.

---

### Edge Cases

- **Secret Management**: When secrets are provided via `--values` files, they are unified into the CUE definition. It is the user's responsibility to manage the security of these files (e.g., using SOPS to decrypt before passing to OPM). Manifests rendered via `build` will contain these secrets in plaintext unless the module definition targets resources like `ExternalSecret`.
- **Cluster Connectivity**: What happens when a user runs `apply`, `delete`, `diff`, or `status` without a valid or reachable Kubernetes cluster? The CLI should fail gracefully with a clear error message about cluster connectivity.
- **Invalid Values**: How does the system handle an `apply` or `build` when the user provides a `--values` file that does not satisfy the module's schema? The operation should fail with a clear CUE validation error.
- **Permissions**: What happens if the user tries to `apply` or `delete` resources in a namespace where they don't have sufficient RBAC permissions? The CLI should output the server-side error from the Kubernetes API.
- **Registry Unreachable**: When `OPM_REGISTRY` is configured and the registry is unreachable during `mod tidy`, `mod vet`, or any command requiring CUE module resolution, the CLI fails fast with a clear error message (e.g., "Error: cannot connect to registry localhost:5000"). No silent fallback to original module domains occurs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST provide a `mod init` command to create a new module from a template.
- **FR-002**: The CLI MUST provide `mod vet` and `mod tidy` commands for module validation and dependency management.
- **FR-003**: The CLI MUST provide a `mod build` command that renders a module's CUE definition into Kubernetes manifests in YAML, JSON, or a directory structure.
- **FR-004**: The CLI MUST provide a `mod apply` command to idempotently create or update a module's resources on a Kubernetes cluster, applying them in a weighted order to respect hard dependencies (see Section 6).
- **FR-005**: The `mod apply` command MUST support `--dry-run` and `--diff` flags to allow users to preview changes before they are made.
- **FR-006**: The CLI MUST provide a `mod delete` command to remove all Kubernetes resources discovered via the `module.opmodel.dev/name` and `module.opmodel.dev/namespace` labels, deleting them in the reverse weighted order (see Section 6).
- **FR-007**: The CLI MUST provide a `mod diff` command to show a diff between the local module definition and the live resources on the cluster.
- **FR-008**: The CLI MUST provide a `mod status` command to report the readiness and health of a deployed module's Kubernetes resources, following the health evaluation logic in Section 6.3.
- **FR-009**: The CLI MUST provide `mod publish` and `mod get` commands for distributing modules via an OCI registry, leveraging the user's standard `~/.docker/config.json` for authentication.
- **FR-010**: All deployment-related commands (`build`, `apply`, `diff`, `delete`) MUST support multiple `--values` flags accepting CUE, YAML, or JSON files. These inputs MUST be unified with the module's CUE definitions to ensure schema compliance and produce the final configuration.
- **FR-011**: All commands MUST be non-interactive.
- **FR-012**: The CLI MUST use a YAML configuration file at `~/.opm/config.yaml`, validated against an internal CUE schema. The CLI MUST provide `config init` and `config vet` commands for configuration management.
- **FR-013**: The CLI's `bundle` command group MUST mirror the functionality of the `mod` group, operating on bundles instead of modules.
- **FR-014**: The CLI MUST apply and delete resources based on a predefined weighting system to ensure hard dependencies (e.g., CRDs, Namespaces) are managed correctly).
- **FR-015**: The `OPM_REGISTRY` configuration (env var or `config.yaml`) MUST act as a global registry redirect for all CUE module resolution. When set (e.g., `localhost:5000`), all CUE imports (e.g., `opm.dev/core@v0`) MUST resolve from the configured registry. The CLI MUST pass this configuration to the `cue` binary via the `CUE_REGISTRY` environment variable when executing `mod tidy`, `mod vet`, `bundle tidy`, and `bundle vet` commands.
- **FR-016**: When `OPM_REGISTRY` is configured and the registry is unreachable, commands that require module resolution MUST fail fast with a clear error message indicating registry connectivity failure. The CLI MUST NOT silently fall back to alternative registries.
- **FR-017**: The CLI MUST provide structured, human-readable logging to `stderr`. Logs MUST use colors to distinguish categories (Info, Warning, Error, Debug). The `--verbose` flag MUST increase the detail of logs.
- **FR-018**: The CLI MUST provide a global `--output-format` flag (alias `-o`) supporting `text` (default), `yaml`, and `json` values. The `text` format MUST provide the most appropriate human-readable output for the command (e.g., tables for status, YAML for manifests) on `stdout`.

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

- **SC-005**: The `opm mod publish` and `opm mod get` commands successfully complete a round-trip within reasonable time: publishing a module to an OCI registry and retrieving it produces an identical module.
  - *Measurement*: Module published with `opm mod publish`, deleted locally, retrieved with `opm mod get`, and `opm mod vet` passes on retrieved module.
  - *Assumptions*: OCI registry is accessible with valid credentials in `~/.docker/config.json`.

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
