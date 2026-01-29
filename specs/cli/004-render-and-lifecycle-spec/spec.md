# Feature Specification: CLI Render System and Lifecycle

**Feature Branch**: `004-render-and-lifecycle-spec`  
**Created**: 2026-01-24  
**Status**: Draft  
**Input**: User description: "Specification for CLI rendering system - provider definition, transformer definition, and render pipeline with Kubernetes focus"

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## Overview

This specification defines how the OPM CLI renders OPM modules into platform-specific manifests. The render system transforms abstract OPM components into concrete Kubernetes resources through a provider/transformer architecture.

The rendering pipeline consists of three key concepts:

- **Provider**: Platform adapter containing transformer registry
- **Transformer**: Converts OPM components to platform resources  
- **Render Pipeline**: CLI orchestration from Module to output manifests

### Design Decisions

1. **CLI-only rendering**: Rendering logic resides in the CLI, not in CUE schemas. This simplifies the model and avoids complexity of CUE-based output formatting.
2. **Kubernetes-first**: The specification focuses on Kubernetes as the primary target platform, with hooks for future platform extensibility.
3. **Parallel Execution**: Component rendering occurs in parallel goroutines to minimize render time for large modules.
4. **CUE-First Unification**: The CLI relies on CUE's unification engine for initial validation and label conflict resolution.

## Clarifications

### Session 2026-01-25

- Q: How are providers resolved? → A: Providers are defined in `~/.opm/config.cue` by importing provider modules (e.g., `import k8s "opmodel.dev/providers/kubernetes@v0"`). The `--provider` flag selects which configured provider to use for rendering. Modules MUST NOT declare or reference providers.
- Q: How are render errors handled during parallel processing? → A: Fail on End. The CLI renders all components, collecting errors (unmatched components, transformation failures), and exits with a non-zero status and full error list only after all components are processed.
- Q: What formats does verbose output support? → A: Both human-readable (default `--verbose`) and structured JSON (`--verbose=json`) for machine parsing.
- Q: What fields are in the TransformerContext? → A: Extended context: `name`, `namespace`, `version`, `provider`, `timestamp` (RFC3339), `strict` (bool), and `labels` (module metadata labels).
- Q: How are files named with `--split`? → A: Using the pattern `<lowercase-kind>-<resource-name>.yaml` (e.g., `deployment-api.yaml`).
- Q: How should the render pipeline handle sensitive data (e.g., secrets from environment variables) to prevent exposure in logs or verbose output? → A: Redact Secrets in Logs. The CLI should not write logs that could even contain secrets to begin with, but if that happens we should redact it.
- Q: What are the expected scalability limits for the render pipeline? (e.g., how many components/transformers) → A: No Defined Limits

### Session 2026-01-28 (Experiment 004 Findings)

- Q: Where are providers configured and how are they loaded? → A: Providers are ONLY configured in `~/.opm/config.cue` via CUE imports. The config is a valid CUE module that imports provider modules (e.g., `opmodel.dev/providers/kubernetes@v0`). Modules never declare providers.
- Q: How does provider validation work? → A: Provider validation is shallow - only structural validation (metadata exists, transformers map exists). Abstract transformer definitions are not validated until render time when unified with actual components.
- Q: Can users extend providers? → A: Yes, via CUE unification. Users can add custom transformers to providers in their config.cue by unifying with the imported provider definition.
- Q: How many providers can be used per render? → A: Only one provider per render operation. The `--provider` flag selects from configured providers.

### Session 2026-01-29

- Q: How does `opm mod build/apply` relate to ModuleRelease? → A: The CLI creates a `#ModuleRelease` internally (on the fly) from the local module path. This simplifies workflow logic by ensuring all rendering operates on the same `#ModuleRelease` type regardless of input source.
- Q: How are values resolved when `--values` is not provided? → A: The CLI looks for `values.cue` at the module root. Since `values.cue` is required per 002-cli-spec, the operation fails if not found.
- Q: How are multiple values files handled? → A: All values files (including default `values.cue`) are unified using CUE. If the same field has conflicting values, CUE's native unification error is raised.
- Q: How is the release namespace determined? → A: From `--namespace` flag, or falls back to `#Module.metadata.defaultNamespace`. If neither is provided, the operation fails with an error.
- Q: How is the release name determined? → A: From `--name` flag, or falls back to `#Module.metadata.name`.

---

## User Scenarios & Testing

### User Story 1 - Render Module to Kubernetes Manifests (Priority: P1)

A developer wants to convert their OPM module into Kubernetes manifests that can be applied to a cluster or reviewed locally.

**Why this priority**: This is the core value proposition of the render system - transforming portable OPM definitions into deployable Kubernetes resources.

**Independent Test**: Given a valid OPM module with components, running `opm mod build` produces valid Kubernetes YAML that can be applied with `kubectl apply`.

**Acceptance Scenarios**:

1. **Given** a module with a Container resource and stateless workload-type label, **When** the CLI renders, **Then** a Kubernetes Deployment is generated.
2. **Given** a module with a Container resource and Expose trait, **When** the CLI renders, **Then** both a Deployment and Service are generated.
3. **Given** a module with multiple components, **When** the CLI renders, **Then** all components are transformed and output in a single manifest.

---

### User Story 2 - Understand Why Resources Were Generated (Priority: P2)

A developer wants to understand which transformers matched their components and why specific Kubernetes resources were generated.

**Why this priority**: Debugging transformer matching is essential for troubleshooting unexpected output or missing resources.

**Independent Test**: Running `opm mod build --verbose` shows which transformers matched each component and why.

**Acceptance Scenarios**:

1. **Given** a component with Container and Expose, **When** the CLI renders with verbose output, **Then** it shows "DeploymentTransformer matched: requiredResources=Container, requiredLabels=stateless" and "ServiceTransformer matched: requiredTraits=Expose".
2. **Given** a component missing a required label, **When** the CLI renders with verbose output, **Then** it explains why certain transformers didn't match.

---

### User Story 3 - Handle Unmatched Components (Priority: P2)

A developer has a component that doesn't match any transformer and needs clear feedback on what's missing.

**Why this priority**: Clear error messages prevent confusion and guide users to fix configuration issues.

**Independent Test**: A component with no matching transformers produces an error listing available transformers and their requirements.

**Acceptance Scenarios**:

1. **Given** a component with no matching transformers, **When** the CLI renders, **Then** it errors with "No transformers matched component 'api'. Available transformers: [list with requirements]".
2. **Given** `--strict` mode enabled, **When** a component has unhandled traits, **Then** the CLI errors with the list of unhandled traits.

---

### User Story 4 - Output Format Control (Priority: P3)

A developer wants to control how rendered manifests are output - as a single file, multiple files, or streamed to stdout.

**Why this priority**: Different deployment workflows require different output formats (GitOps single file vs. Helm-style directories).

**Independent Test**: `opm mod build -o yaml`, `opm mod build -o json`, and `opm mod build --split` produce expected output formats.

**Acceptance Scenarios**:

1. **Given** a module, **When** running `opm mod build -o yaml`, **Then** output is a single YAML document (Kubernetes List or multi-doc YAML).
2. **Given** a module, **When** running `opm mod build --split --out-dir ./manifests`, **Then** each resource is written to a separate file.

---

### User Story 5 - Deploy Module to Kubernetes Cluster (Priority: P1)

A developer wants to deploy their rendered module to a Kubernetes cluster and verify it's running correctly.

**Why this priority**: This is the core deployment workflow - getting from rendered manifests to running resources.

**Independent Test**: Given rendered manifests, `opm mod apply` deploys them to a cluster and `opm mod status` shows healthy resources.

**Acceptance Scenarios**:

1. **Given** a developer has a valid module and kubeconfig, **When** they run `opm mod apply`, **Then** the resources are deployed to the cluster.
2. **Given** a module has been deployed, **When** the user runs `opm mod status`, **Then** they see a status summary of the Kubernetes resources.
3. **Given** a module has been deployed, **When** the user runs `opm mod delete`, **Then** all resources associated with that module are removed from the cluster.
4. **Given** a module with CRDs and custom resources, **When** the user runs `opm mod apply`, **Then** CRDs are created before custom resources (weighted ordering).

---

### User Story 6 - Preview Changes Before Deployment (Priority: P2)

A module author needs to preview changes to an existing deployment before applying them.

**Why this priority**: Safe deployment practices require ability to see what will change.

**Independent Test**: Deploy a module, modify it locally, run `opm mod diff` to see changes before applying.

**Acceptance Scenarios**:

1. **Given** a module is deployed and the local definition has been modified, **When** the user runs `opm mod diff`, **Then** they see a clear, colorized diff of the pending changes.
2. **Given** `opm mod diff` shows pending changes, **When** the user runs `opm mod apply`, **Then** the changes are applied and `opm mod diff` subsequently shows no differences.
3. **Given** a developer wants to preview without applying, **When** they run `opm mod apply --dry-run`, **Then** they see what would be applied without making changes.

---

### Edge Cases

#### Render Edge Cases

- What happens when two transformers have identical requirements and both match the same component? **Error with "multiple exact transformer matches".**
- How does the system handle a transformer that produces zero resources? **Empty output is valid; no error.**
- What happens when a transformer's output fails Kubernetes schema validation? **Warning logged; apply will fail server-side.**
- How are namespace and labels propagated from module metadata to generated resources? **Via TransformerContext and post-transform labeling.**

#### Deployment Edge Cases

- **Secret Management**: When secrets are provided via `--values` files, they are unified into the CUE definition. It is the user's responsibility to manage the security of these files (e.g., using SOPS to decrypt before passing to OPM). Manifests rendered via `build` will contain these secrets in plaintext unless the module definition targets resources like `ExternalSecret`.
- **Cluster Connectivity**: What happens when a user runs `apply`, `delete`, `diff`, or `status` without a valid or reachable Kubernetes cluster? The CLI should fail gracefully with a clear error message about cluster connectivity.
- **Invalid Values**: How does the system handle an `apply` or `build` when the user provides a `--values` file that does not satisfy the module's schema? The operation should fail with a clear CUE validation error.
- **Permissions**: What happens if the user tries to `apply` or `delete` resources in a namespace where they don't have sufficient RBAC permissions? The CLI should output the server-side error from the Kubernetes API.
- **Server-Side Apply Field Conflicts**: When another controller (e.g., HPA) owns a field that the module also specifies, the CLI warns to stderr and proceeds with the apply, taking ownership of the conflicting field. This matches kubectl's default SSA behavior.
- **API Rate Limiting**: The CLI uses client-go's built-in rate limiter with defaults. When the Kubernetes API returns 429 (Too Many Requests), client-go handles exponential backoff automatically.
- **Missing Namespace**: If neither `--namespace` flag nor `#Module.metadata.defaultNamespace` is provided, the CLI fails with: "Error: namespace required. Provide --namespace flag or set metadata.defaultNamespace in module."
- **Values File Conflict**: When multiple values files define the same field with different values, CUE's native unification error is returned (e.g., "port: conflicting values 8080 and 9090").

---

## 3. Detailed Render Pipeline

The render pipeline is the core execution flow of the `opm mod build` command. It is designed to be deterministic, parallelizable, and error-aggregating (fail-on-end).

```text
┌─────────────────────────────────────────────────────────────────┐
│                       Hybrid Render Pipeline                    │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: Module Loading & Validation                     [Go]  │
│           ├─ Load CUE via cue/load                              │
│           ├─ Extract release metadata                           │
│           └─ Build base TransformerContext                      │
├─────────────────────────────────────────────────────────────────┤
│  Phase 2: Provider Loading                                [Go]  │
│           └─ Access provider.transformers from CUE              │
├─────────────────────────────────────────────────────────────────┤
│  Phase 3: Component Matching                             [CUE]  │
│           ├─ CUE evaluates #Matches predicate                   │
│           ├─ CUE computes #matchedTransformers map              │
│           └─ Go reads back the computed matching plan           │
├─────────────────────────────────────────────────────────────────┤
│  Phase 4: Parallel Transformer Execution                  [Go]  │
│           ├─ Iterate CUE-computed matches                       │
│           ├─ For each (transformer, component):                 │
│           │   ├─ Unify transformer.#transform + inputs          │
│           │   ├─ Export unified AST (thread-safe)               │
│           │   └─ Send Job to worker goroutine                   │
│           └─ Workers: isolated cue.Context → Decode output      │
├─────────────────────────────────────────────────────────────────┤
│  Phase 5: Aggregation & Output                            [Go]  │
│           ├─ Collect results from workers                       │
│           ├─ Aggregate errors (fail-on-end)                     │
│           └─ Output YAML manifests                              │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 1: Module Loading & ModuleRelease Construction

- **Initialization**: Load CLI config from `~/.opm/config.cue`. This includes:
  - Extracting `config.registry` via simple parsing (without resolving imports)
  - Resolving final registry URL: `--registry` flag > `OPM_REGISTRY` env > `config.registry`
  - Loading full config with provider imports using the resolved registry
  - Validating provider structure (shallow validation)
- **Module Loading**: Load the `#Module` from the local path, resolving CUE dependencies using the resolved registry URL.
- **Values Resolution**:
  1. Start with `values.cue` at module root (required, fail if missing)
  2. If `--values` flags provided, unify all specified files with CUE
  3. Unification errors (conflicting values) fail with CUE's native error
- **ModuleRelease Construction**: Create `#ModuleRelease` on the fly:
  - `metadata.name`: From `--name` flag, or `#module.metadata.name`
  - `metadata.namespace`: From `--namespace` flag, or `#module.metadata.defaultNamespace` (fail if neither provided)
  - `#module`: The loaded `#Module`
  - `values`: The unified values from resolution step
- **Validation**: Verify the constructed `#ModuleRelease` against schema. Ensure the module release is ready for processing.

### Phase 2: Provider Loading

- **Determine Provider Source**:
  - Check `--provider` flag for explicit provider selection
  - Otherwise use the default provider from config.providers (typically `kubernetes`)
- **Load Provider from Config**: Access the provider definition from the loaded config.cue. The provider is already loaded as part of config loading (imported via `import k8s "opmodel.dev/providers/kubernetes@v0"`).
- **Validate Provider Structure**: Verify the provider has required fields:
  - `metadata` (name, version, description)
  - `transformers` map (registry of transformer definitions)
  - Note: Validation is shallow - only checks existence, not concrete values
- **Index Transformers**: Build an in-memory registry mapping transformer IDs to their CUE definitions. Each transformer in the `provider.transformers` map becomes available for matching.
- **Error Handling**: If provider is not found in config, if validation fails, or if transformers map is empty, exit with a clear error message including:
  - Which provider was requested
  - Available providers in config
  - Validation failure details (if applicable)

### Phase 3: Component Matching (The "Matched" Map)

- **Loop**: Iterate through all components in the unified module.
- **Match**: For each component, identify **ALL** matching transformers (see Section 4). Multiple transformers can match the same component (e.g., a stateless workload with `Expose` trait matches both `DeploymentTransformer` and `ServiceTransformer`).
- **Group**: Construct a `matchedTransformers` data structure that groups components by their matched transformer.

    ```cue
    #MatchedTransformersMap: [string]: {
        transformer: #Transformer
        components: [...#Component]
    }

    matchedTransformers: #MatchedTransformersMap {
        "transformer.opmodel.dev/workload@v1#DeploymentTransformer": {
            transformer: #DeploymentTransformer
            components: [comp1, comp2]
        }
        "opmodel.dev/providers/kubernetes/transformers@v1#ServiceTransformer": {
            transformer: #ServiceTransformer
            components: [comp1]
        }
    }
    ```

### Phase 4: Parallel Transformer Execution

- **Parallel Loop**: Iterate through the keys (transformers) of the `matchedTransformers` map in parallel.
- **Context Injection**: Create a `TransformerContext` for each execution. **Crucially**, OPM tracking labels (e.g., `app.kubernetes.io/managed-by`, `module.opmodel.dev/name`) are injected into the context here, rather than post-processing.
- **Execution**: Run the `#transform` function for each component in the transformer's list.
- **Output**: Each execution produces exactly **one** resource.

### Phase 5: Aggregation & Output

- **Aggregation**: Collect all generated resources from the parallel workers.
- **Error Handling**: Aggregate all errors (unmatched components, transform failures) and report them together.
- **Formatting**: Serialize and output to YAML/JSON or files (`--split`).

---

## 4. Transformer Matching Logic

This logic determines which transformers run for a given component. It creates the execution plan (the `matchedTransformers` map) before any transformation occurs.

**Concept: Capability vs. Intent**
Matching happens in two logical stages:

1. **Capability (Resources & Traits)**: Does the component have the necessary data to support this transformer? (e.g., "I have a Container, so I *could* be a Deployment or StatefulSet").
2. **Intent (Labels)**: Does the component have the specific label to disambiguate its type? (e.g., "I have `workload-type: stateless`, so I *am* a Deployment").

**Guidance for Authors**: Transformers targeting common resources (like `Container`) **MUST** use `requiredLabels` to prevent ambiguous matches.

```text
+-----------------------------+
| For each Component in Module |
+-------------+---------------+
              |
              v
+---------------------------------+
| For each Transformer in Provider |
+-------------+-------------------+
              |
              v
+-------------------------+      No
|   Required Labels Met?  |------------> (Continue to next Transformer)
+-------------+-----------+
              | Yes
              v
+---------------------------+    No
| Required Resources Met? |------------> (Continue to next Transformer)
+-------------+-------------+
              | Yes
              v
+-------------------------+      No
|   Required Traits Met?  |------------> (Continue to next Transformer)
+-------------+-----------+
              | Yes
              v
+---------------------------------------------+
| Add Component to `matchedTransformers[Transformer].components` |
+---------------------------------------------+
```

### 4.1. Effective Labels

`EffectiveLabels` are the result of CUE unification (Component labels + Resource labels + Trait labels).

### 4.2. Matching Criteria

A transformer matches if and only if **ALL** conditions are met:

1. **Required Labels**: Present in Effective Labels.
2. **Required Resources**: Present in component resources.
3. **Required Traits**: Present in component traits.

### 4.3. Conflict Resolution

- **Multiple Matches**: It is valid and expected for multiple transformers to match a single component. They will be executed independently in Phase 4.
- **No Match**: If a component matches NO transformers, it is recorded as an error.

---

## 5. Deployment Lifecycle & Resource Ordering

To ensure reliable and predictable deployments, the OPM CLI uses a weighted system to determine the order in which Kubernetes resources are applied and deleted. This approach correctly handles "hard dependencies" where applying a resource would fail if another resource (like a CRD or Namespace) does not yet exist.

### 5.1. Resource Weighting System

The core mechanic is a predefined weight assigned to each Kubernetes resource Kind.

- **Apply Order**: Resources are applied in **ascending** order of their weights (lower weights first).
- **Delete Order**: Resources are deleted in **descending** order of their weights (higher weights first).

This ensures that foundational resources are created before the workloads that depend on them, and that workloads are terminated before their foundational resources are removed.

### 5.2. Resource Weights

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

### 5.3. Resource Health & Readiness

The `mod status` command evaluates resource health based on the following rules:

1. **Workloads**: Resources of kind `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, and `CronJob` are considered healthy only when their standard Kubernetes `Ready` or `Complete` conditions are met.
2. **Passive Resources**: Resources like `ConfigMap`, `Secret`, `Service`, `Namespace`, and `RBAC` entities are considered healthy immediately upon successful creation or update in the cluster.
3. **Custom Resources**: If a custom resource defines a `Ready` condition in its status, it is used; otherwise, it is treated as a passive resource.

### 5.4. Resource Labeling

All resources generated or managed by the OPM CLI MUST include the following labels for identification and lifecycle management:

| Label | Purpose |
| :--- | :--- |
| `app.kubernetes.io/managed-by` | Set to `open-platform-model`. |
| `module.opmodel.dev/name` | The name of the module. |
| `module.opmodel.dev/namespace` | The target namespace for the module. |
| `module.opmodel.dev/version` | The version of the module being deployed. |
| `component.opmodel.dev/name` | The name of the specific component within the module. |

---

## Requirements

### Functional Requirements

#### Provider System

- **FR-001**: Provider MUST contain a `transformers` map registry. Provider validation MUST verify structural correctness (metadata exists, transformers map exists, transformer entries have required fields) but MUST NOT require concrete values for all fields. Abstract transformer definitions (e.g., `#transform` functions) are validated at render time when unified with actual components.
- **FR-002**: Provider MUST aggregate declared resources/traits.
- **FR-003**: Provider MUST include metadata (name, version, description).
- **FR-004**: Support `--provider` flag to select from providers configured in `~/.opm/config.cue`.
- **FR-028**: Providers MUST be configured in `~/.opm/config.cue` by importing provider modules. Modules MUST NOT declare or reference providers. The config file imports providers (e.g., `import k8s "opmodel.dev/providers/kubernetes@v0"`) and registers them in `config.providers` map.

#### Transformer System

- **FR-005**: Transformer MUST declare matching criteria.
- **FR-006**: Transformer MAY declare optional inputs: `optionalLabels`, `optionalResources`, `optionalTraits`.
- **FR-007**: Transformer MUST implement `#transform` accepting `#component` and `#context`.
- **FR-008**: Transformer output MUST be a **single resource** (`output: {...}`).
- **FR-009**: Matching requires ALL criteria to be met.

#### Matching & Execution

- **FR-010**: Use unified effective labels.
- **FR-011**: Allow multiple transformers to match a single component.
- **FR-012**: (Replaced by FR-011)
- **FR-013**: Outputs from all matched transformers MUST be aggregated.
- **FR-014**: Each matched transformer receives the full component.
- **FR-022**: Rely on CUE unification for label conflicts.

#### Render Pipeline

- **FR-015**: The render pipeline MUST execute transformers in parallel (iterating the `matchedTransformers` map).
- **FR-016**: Generated resources MUST include OPM tracking labels, injected via **TransformerContext**:
  - `app.kubernetes.io/managed-by: open-platform-model`
- **FR-017**: Support `yaml`, `json` output.
- **FR-018**: Support `--split`.
- **FR-023**: Aggregate outputs deterministically.
- **FR-024**: Aggregate errors (fail-on-end).
- **FR-025**: Support verbose logging (human/json).
- **FR-026**: File naming for `--split`.

#### Error Handling

- **FR-019**: Error on unmatched components (aggregated).
- **FR-020**: Error on unhandled traits in `--strict` mode.
- **FR-021**: Warning on unhandled traits in normal mode.
- **FR-027**: The render pipeline MUST redact sensitive values (e.g., from environment variables) in all verbose or debug logging output.

#### Deployment Operations

- **FR-029**: The `mod build` command MUST render a module's CUE definition into Kubernetes manifests in YAML, JSON, or a directory structure.
- **FR-030**: The `mod apply` command MUST idempotently create or update a module's resources on a Kubernetes cluster, applying them in weighted order to respect hard dependencies (see Section 5).
- **FR-031**: The `mod apply` command MUST support `--dry-run` and `--diff` flags to allow users to preview changes before they are made.
- **FR-032**: The `mod delete` command MUST remove all Kubernetes resources discovered via the `module.opmodel.dev/name` and `module.opmodel.dev/namespace` labels, deleting them in the reverse weighted order (see Section 5).
- **FR-033**: The `mod diff` command MUST show a diff between the local module definition and the live resources on the cluster.
- **FR-034**: The `mod status` command MUST report the readiness and health of a deployed module's Kubernetes resources, following the health evaluation logic in Section 5.3.
- **FR-035**: All deployment-related commands (`build`, `apply`, `diff`, `delete`) MUST support multiple `--values` flags accepting CUE, YAML, or JSON files. These inputs MUST be unified with the module's CUE definitions to ensure schema compliance and produce the final configuration.
- **FR-036**: The CLI MUST use client-go's built-in rate limiter with default settings for all Kubernetes API operations. The CLI MUST NOT implement custom rate limiting or backoff logic.
- **FR-037**: When server-side apply encounters field ownership conflicts, the CLI MUST log a warning to stderr identifying the conflicting fields and their current owners, then proceed with the apply (taking ownership). The CLI MUST NOT fail on field conflicts by default.
- **FR-038**: Long-running operations (`apply --wait`, `delete`, `status --watch`) MUST NOT display progress indicators. Output is silent until completion, timeout, or error.
- **FR-039**: The CLI MUST NOT enforce limits on module complexity (resource count, CUE evaluation depth). Natural limits are provided by operation timeouts and system resources.
- **FR-040**: The `mod build` and `mod apply` commands MUST construct a `#ModuleRelease` internally from the local module path before rendering. This ensures all rendering operates on the same schema regardless of input source.
- **FR-041**: If `--values` flag is not provided, the CLI MUST look for `values.cue` at the module root. The operation MUST fail if `values.cue` is not found.
- **FR-042**: When multiple values files are provided (via `--values` or combined with default `values.cue`), all files MUST be unified using CUE. The operation MUST fail with CUE's native error if unification fails due to conflicting values.
- **FR-043**: The `--namespace` flag MUST take precedence over `#Module.metadata.defaultNamespace`. The operation MUST fail if neither is provided.
- **FR-044**: The `--name` flag MUST take precedence over `#Module.metadata.name` for the release name.

### Non-Functional Requirements

- **NFR-001**: The render pipeline MUST NOT have predefined limits on the number of components or transformers it can process. Performance should scale linearly with the size of the input module.

### Key Entities

- **Provider**: Platform adapter.
- **Transformer**: Converts OPM component to **one** platform resource.
- **TransformerContext**:
  - `name`, `namespace`, `version`, `provider`, `timestamp`
  - `strict` (bool)
  - `labels` (map[string]string): **Includes OPM tracking labels.**
- **Component**: OPM component with resources, traits, and computed labels.
- **MatchedMap**: internal structure grouping components by transformer.

---

## Success Criteria

### Measurable Outcomes

#### Render Pipeline

- **SC-001**: A module with 5 components renders to Kubernetes manifests in under 2 seconds (excluding network operations).
- **SC-002**: Transformer matching is deterministic - the same module always produces identical output.
- **SC-003**: 100% of components with matching transformers produce valid Kubernetes resources that pass `kubectl apply --dry-run=client` validation.
- **SC-004**: Error messages for unmatched components include actionable guidance (list transformers, their requirements, and what's missing).
- **SC-005**: Verbose output mode shows transformer matching decisions for every component.

#### Deployment Operations

- **SC-006**: A new user can successfully initialize, build, and apply a default "hello-world" module to a local Kubernetes cluster in under 3 minutes.
  - *Measurement*: Timed from `opm mod init` to successful `opm mod apply` completion with resources visible in cluster.
  - *Assumptions*: Warm local cache for CUE dependencies, local cluster (kind/k3d), network latency < 100ms.
  - *Exclusions*: CUE dependency download time on first run, cluster provisioning time.

- **SC-007**: The `opm mod diff` command accurately reflects the delta between a local configuration change and the live cluster state 100% of the time for supported Kubernetes resources.
  - *Measurement*: Diff output MUST show all field changes in supported Kubernetes resource kinds.
  - *Exclusions*: Server-managed fields (metadata.generation, metadata.resourceVersion, status.*) are excluded from diff comparison.

- **SC-008**: The `opm mod apply` command's server-side apply operation is fully idempotent; running it multiple times with the same inputs results in no changes after the first successful application.
  - *Measurement*: Second consecutive `opm mod apply` with identical inputs MUST result in zero server-side changes.
  - *Exclusions*: Server-managed timestamp fields (metadata.managedFields timestamps) are excluded from idempotency comparison.

- **SC-009**: The `opm mod status` command correctly reports the `Ready` or `NotReady` status for all managed Kubernetes workloads (Deployments, StatefulSets) within 60 seconds of a change.
  - *Measurement*: Time from `opm mod apply` completion to `opm mod status` reporting all workloads as Ready.
  - *Assumptions*: Standard workloads (Deployment, StatefulSet) with readiness probes responding within 30s.

---

## Appendix A: Kubernetes Provider Transformers

The default Kubernetes provider includes these transformers:

| Transformer | Required Labels | Required Resources | Required Traits | Output Kind |
|-------------|-----------------|-------------------|-----------------|-------------|
| DeploymentTransformer | `workload-type: stateless` | Container | - | Deployment |
| StatefulSetTransformer | `workload-type: stateful` | Container | - | StatefulSet |
| DaemonSetTransformer | `workload-type: daemon` | Container | - | DaemonSet |
| JobTransformer | `workload-type: job` | Container | - | Job |
| CronJobTransformer | `workload-type: cronjob` | Container | - | CronJob |
| ServiceTransformer | - | Container | Expose | Service |
| PVCTransformer | - | - | PersistentStorage | PersistentVolumeClaim |

---

## Appendix B: Render Pipeline Flow

*(See Section 3 for detailed ASCII diagram)*

---

## Appendix C: Example Transformer Implementation

```cue
#DeploymentTransformer: core.#Transformer & {
    metadata: {
        apiVersion:  "transformer.opmodel.dev/workload@v1"
        name:        "DeploymentTransformer"
        description: "Converts stateless workload components to Kubernetes Deployments"
    }

    // Matching criteria
    requiredLabels: {
        "core.opmodel.dev/workload-type": "stateless"
    }
    requiredResources: {
        "opmodel.dev/resources/workload@v1#Container": _
    }
    optionalLabels: {
        "opmodel.dev/debug": "true"
    }

    // Transform function
    #transform: {
        #component: core.#Component
        #context:   core.#TransformerContext

        output: {
            apiVersion: "apps/v1"
            kind:       "Deployment"
            metadata: {
                name:      #component.metadata.name
                namespace: #context.name
            }
            spec: {
                replicas: #component.spec.replicas
                selector: matchLabels: app: #component.metadata.name
                template: {
                    metadata: labels: app: #component.metadata.name
                    spec: containers: [#component.spec.container]
                }
            }
        }
    }
}
```
