# Feature Specification: OPM Bundle

**Feature Branch**: `017-bundle-spec`  
**Created**: 2026-01-28  
**Status**: Draft  
**Input**: User description: "Create a new specification for bundle. place it in opm/specs/application-model. Remove bundle from 002"

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create and Deploy Bundle (Priority: P1)

A platform team wants to deploy a complete platform stack consisting of multiple modules as a single coordinated unit, ensuring consistent versions and proper dependency ordering across all modules.

**Why this priority**: This is the core value proposition of bundles - enabling multi-module deployments as a single atomic operation. Without this, bundles have no purpose.

**Independent Test**: Create a bundle with 2-3 modules, apply it to a cluster, and verify all modules deploy correctly with proper resource ordering.

**Acceptance Scenarios**:

1. **Given** a platform operator has the OPM CLI installed, **When** they run `opm bundle init my-platform`, **Then** a new bundle project is created with `bundle.cue`, `values.cue`, and `cue.mod/module.cue`.
2. **Given** a bundle definition with multiple modules, **When** the user runs `opm bundle apply`, **Then** all modules are deployed in correct weighted order with proper labeling (`bundle.opmodel.dev/name`).
3. **Given** a bundle definition references 3 modules, **When** the user runs `opm bundle apply`, **Then** resources across all modules are applied in weighted order (CRDs before Namespaces before Deployments).
4. **Given** a bundle with invalid CUE syntax, **When** the user runs `opm bundle vet`, **Then** they see clear error messages with file locations and line numbers.

---

### User Story 2 - Update Bundle (Priority: P2)

A platform operator needs to update an existing bundle (e.g., update a module reference or change bundle-level values) and wants to safely preview and apply these changes to the cluster.

**Why this priority**: This represents the day-to-day workflow of platform operators managing bundles. The ability to safely diff and apply bundle changes is essential for production operations.

**Independent Test**: Deploy a bundle, modify `bundle.cue` or `values.cue`, run `opm bundle diff` to see pending changes, then apply with `opm bundle apply`.

**Acceptance Scenarios**:

1. **Given** a bundle is deployed and the local `bundle.cue` has been modified, **When** the user runs `opm bundle diff`, **Then** they see a clear, colorized diff of pending changes across all affected modules.
2. **Given** `opm bundle diff` shows pending changes, **When** the user runs `opm bundle apply`, **Then** the changes are applied to the cluster and `opm bundle diff` subsequently shows no differences.
3. **Given** a developer wants to render the bundle manifests locally, **When** they run `opm bundle build -o yaml`, **Then** the full Kubernetes manifests from all modules are printed to standard output.

---

### User Story 3 - Bundle Status and Deletion (Priority: P3)

A platform operator needs to monitor the health of a deployed bundle and remove it when no longer needed.

**Why this priority**: Essential for operational visibility and lifecycle management, but builds on the foundation of bundle deployment (US1).

**Independent Test**: Deploy a bundle, run `opm bundle status` to see aggregate health, then run `opm bundle delete` to remove all resources.

**Acceptance Scenarios**:

1. **Given** a deployed bundle, **When** the user runs `opm bundle status`, **Then** they see the aggregate health status of all modules in the bundle, including resource readiness.
2. **Given** a deployed bundle, **When** the user runs `opm bundle delete`, **Then** all resources from all modules are removed in reverse weighted order (Deployments before Namespaces before CRDs).
3. **Given** a deployed bundle with failing resources, **When** the user runs `opm bundle status --output-format json`, **Then** they receive structured JSON output with detailed health information for each resource.

---

### Edge Cases

- **Missing Module References**: What happens when a bundle references a module that cannot be loaded (not in cache, not in registry)? The CLI should fail with a clear error indicating which module reference failed to resolve.
- **Circular Dependencies**: How does the system handle a bundle that references modules with circular dependencies? The CLI should detect and report circular dependencies during `bundle vet`.
- **Partial Apply Failures**: What happens if `bundle apply` succeeds for some modules but fails for others? The CLI should report which resources succeeded and which failed, allowing users to troubleshoot.
- **Conflicting Resources**: How does the system handle a bundle where two modules define resources with the same name and namespace? The CLI should detect conflicts during `bundle build` and report which modules have conflicting resources.
- **Bundle Values Override**: When `--values` files are provided to bundle commands, do they override individual module values or only bundle-level values? Bundle-level values are merged with each module's values during rendering.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST provide a `bundle init` command to create a new bundle from a template containing `bundle.cue`, `values.cue`, and `cue.mod/module.cue`.
- **FR-002**: The CLI MUST provide `bundle vet` and `bundle tidy` commands for bundle validation and dependency management, delegating to CUE binary with `CUE_REGISTRY` environment variable set when `OPM_REGISTRY` is configured.
- **FR-003**: The CLI MUST provide a `bundle build` command that renders all modules in the bundle into Kubernetes manifests in YAML, JSON, or a directory structure.
- **FR-004**: The CLI MUST provide a `bundle apply` command to idempotently create or update all bundle resources on a Kubernetes cluster, applying them in weighted order across all modules.
- **FR-005**: The `bundle apply` command MUST support `--dry-run`, `--diff`, `--wait`, and `--timeout` flags to allow users to preview changes and control deployment behavior.
- **FR-006**: The CLI MUST provide a `bundle delete` command to remove all Kubernetes resources discovered via the `bundle.opmodel.dev/name` label, deleting them in reverse weighted order.
- **FR-007**: The CLI MUST provide a `bundle diff` command to show a diff between the local bundle definition and the live cluster resources across all modules.
- **FR-008**: The CLI MUST provide a `bundle status` command to report the aggregate readiness and health of all resources in the bundle, supporting `--output-format` for text, JSON, and YAML output.
- **FR-009**: All bundle commands MUST support multiple `--values` flags accepting CUE, YAML, or JSON files. Bundle-level values MUST be unified with each module's values during rendering.
- **FR-010**: Bundle resources MUST be labeled with `bundle.opmodel.dev/name` in addition to standard OPM labels (`app.kubernetes.io/managed-by`, `module.opmodel.dev/name`, `component.opmodel.dev/name`) for lifecycle tracking.
- **FR-011**: The CLI MUST validate that all module references in `bundle.cue` can be resolved before proceeding with `build`, `apply`, or `diff` operations.
- **FR-012**: The CLI MUST detect and report conflicting resources (same name, namespace, kind) across modules during `bundle build` operations.
- **FR-013**: The weighted ordering system defined in 002-cli-spec Section 6.2 MUST be applied across all modules in a bundle, not per-module.

### Key Entities

- **Bundle**: A collection of multiple modules deployed as a coordinated unit. Defined in `bundle.cue` containing `#Bundle` definition.
- **BundleMetadata**: Identification information for a bundle including `apiVersion`, `name`, and optional `version`.
- **Bundle Project Structure**: A strictly defined directory layout with `bundle.cue` (entry point), `values.cue` (bundle defaults), and `modules.cue` (module registry).
- **Module Reference**: A reference to a module within a bundle, specifying how to locate and configure the module.
- **Weighted Ordering**: The system for determining apply/delete order of resources based on Kubernetes resource kinds, applied globally across all modules in a bundle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A platform operator can successfully initialize, build, and apply a bundle with 3 modules to a local Kubernetes cluster in under 5 minutes.
  - *Measurement*: Timed from `opm bundle init` to successful `opm bundle apply` completion with all module resources visible in cluster.
  - *Assumptions*: Warm local cache for CUE dependencies and module references, local cluster (kind/k3d), network latency < 100ms.

- **SC-002**: The `opm bundle diff` command accurately reflects the delta between a local bundle configuration change and the live cluster state 100% of the time across all modules.
  - *Measurement*: Diff output MUST show all field changes in supported Kubernetes resources across all modules.
  - *Exclusions*: Server-managed fields (metadata.generation, metadata.resourceVersion, status.*) are excluded.

- **SC-003**: The `opm bundle apply` command is fully idempotent; running it multiple times with the same inputs results in no changes after the first successful application.
  - *Measurement*: Second consecutive `opm bundle apply` with identical inputs MUST result in zero server-side changes across all modules.

- **SC-004**: The `opm bundle status` command correctly reports the aggregate `Ready` or `NotReady` status for all managed workloads across all modules within 60 seconds of a change.
  - *Measurement*: Time from `opm bundle apply` completion to `opm bundle status` reporting all workloads as Ready.
  - *Assumptions*: Standard workloads with readiness probes responding within 30s.

- **SC-005**: Resource ordering is correctly enforced across all modules - CRDs are fully applied before any dependent custom resources from any module.
  - *Measurement*: All resources with weight < 0 complete before any resources with weight ≥ 0 begin, regardless of which module they belong to.
  - *Verification*: Apply bundle with CRD in module A and custom resource in module B; custom resource must not be attempted until CRD is ready.
