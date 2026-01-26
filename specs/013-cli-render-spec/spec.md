# Feature Specification: CLI Render System

**Feature Branch**: `013-cli-render-spec`  
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

- Q: How are providers resolved? → A: CLI resolves provider names to CUE modules (e.g., `kubernetes` -> `opm.dev/providers/kubernetes`) fetched via `OPM_REGISTRY`.
- Q: How are render errors handled during parallel processing? → A: Fail on End. The CLI renders all components, collecting errors (unmatched components, transformation failures), and exits with a non-zero status and full error list only after all components are processed.
- Q: What formats does verbose output support? → A: Both human-readable (default `--verbose`) and structured JSON (`--verbose=json`) for machine parsing.
- Q: What fields are in the TransformerContext? → A: Extended context: `name`, `namespace`, `version`, `provider`, `timestamp` (RFC3339), `strict` (bool), and `labels` (module metadata labels).
- Q: How are files named with `--split`? → A: Using the pattern `<lowercase-kind>-<resource-name>.yaml` (e.g., `deployment-api.yaml`).
- Q: How should the render pipeline handle sensitive data (e.g., secrets from environment variables) to prevent exposure in logs or verbose output? → A: Redact Secrets in Logs. The CLI should not write logs that could even contain secrets to begin with, but if that happens we should redact it.
- Q: What are the expected scalability limits for the render pipeline? (e.g., how many components/transformers) → A: No Defined Limits

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

### Edge Cases

- What happens when two transformers have identical requirements and both match the same component? **Error with "multiple exact transformer matches".**
- How does the system handle a transformer that produces zero resources? **Empty output is valid; no error.**
- What happens when a transformer's output fails Kubernetes schema validation? **Warning logged; apply will fail server-side.**
- How are namespace and labels propagated from module metadata to generated resources? **Via TransformerContext and post-transform labeling.**

---

## 3. Detailed Render Pipeline

The render pipeline is the core execution flow of the `opm mod build` command. It is designed to be deterministic, parallelizable, and error-aggregating (fail-on-end).

```text
+-----------------+      +-----------------+      +-----------------+
|  Module Source  |----->|   CUE Unify     |----->|   Provider      |
|  (User Input)   |      | (Deps + Values) |      | (Load & Index)  |
+-----------------+      +--------+--------+      +--------+--------+
                                  |                        |
                                  v                        v
                         +------------------------------------------+
                         |      Component Analysis & Matching       |
                         |   (Map Transformers -> List[Component])  |
                         +--------------------+---------------------+
                                              |
                                              v
                         +------------------------------------------+
                         |    Parallel Transformer Execution        |
                         |   (Iterate Map -> Transform + Labels)    |
                         +--------------------+---------------------+
                                              |
                                              v
                         +------------------------------------------+
                         |       Aggregation & Output               |
                         |     (Collect Single Resources)           |
                         +------------------------------------------+
```

### Phase 1: Module Loading & Validation

- **Initialization**: Load CLI config, set up context.
- **Resolution**: Resolve CUE dependencies (via `OPM_REGISTRY`).
- **Unification**: Unify `module.cue` and user values into a single instance.
- **Validation**: Verify schema against `ModuleDefinition`. Ensure the module is ready for processing.

### Phase 2: Provider Loading

- **Load Provider**: Resolve and load the configured provider (e.g., `kubernetes`).
- **Index Transformers**: Build an in-memory registry of available transformers from the provider.

### Phase 3: Component Matching (The "Matched" Map)

- **Loop**: Iterate through all components in the unified module.
- **Match**: For each component, identify **ALL** matching transformers (see Section 4). Multiple transformers can match the same component (e.g., a stateless workload with `Expose` trait matches both `DeploymentTransformer` and `ServiceTransformer`).
- **Group**: Construct a `matched` data structure that groups components by their matched transformer.

    ```cue
    matched: {
        "transformer.opm.dev/workload@v1#DeploymentTransformer": {
            transformer: DeploymentTransformer
            components: [comp1, comp2]
        }
        "opm.dev/providers/kubernetes/transformers@v1#ServiceTransformer": {
            transformer: ServiceTransformer
            components: [comp1]
        }
    }
    ```

### Phase 4: Parallel Transformer Execution

- **Parallel Loop**: Iterate through the keys (transformers) of the `matched` map in parallel.
- **Context Injection**: Create a `TransformerContext` for each execution. **Crucially**, OPM tracking labels (e.g., `app.kubernetes.io/managed-by`, `module.opmodel.dev/name`) are injected into the context here, rather than post-processing.
- **Execution**: Run the `#transform` function for each component in the transformer's list.
- **Output**: Each execution produces exactly **one** resource.

### Phase 5: Aggregation & Output

- **Aggregation**: Collect all generated resources from the parallel workers.
- **Error Handling**: Aggregate all errors (unmatched components, transform failures) and report them together.
- **Formatting**: Serialize and output to YAML/JSON or files (`--split`).

---

## 4. Transformer Matching Logic

This logic determines which transformers run for a given component. It creates the execution plan (the `matched` map) before any transformation occurs.

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
+-------------------------+      No
|   Required Labels Met?  |------------> (Continue to next Transformer)
+-------------+-----------+
              | Yes
              v
+---------------------------------------------+
| Add Component to `matched[Transformer].components` |
+---------------------------------------------+
```

### 4.1. Effective Labels

`EffectiveLabels` are the result of CUE unification (Component labels + Resource labels + Trait labels).

### 4.2. Matching Criteria

A transformer matches if and only if **ALL** conditions are met:

1. **Required Labels**: Present in Effective Labels.
2. **Required Resources**: Present in component resources.
3. **Required Traits**: Present in component traits.
4. **Required Policies**: Present in component policies.

### 4.3. Conflict Resolution

- **Multiple Matches**: It is valid and expected for multiple transformers to match a single component. They will be executed independently in Phase 4.
- **No Match**: If a component matches NO transformers, it is recorded as an error.

---

## Requirements

### Functional Requirements

#### Provider System

- **FR-001**: Provider MUST contain a `transformers` map registry.
- **FR-002**: Provider MUST aggregate declared resources/traits/policies.
- **FR-003**: Provider MUST include metadata.
- **FR-004**: Support `--provider` flag.

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

- **FR-015**: The render pipeline MUST execute transformers in parallel (iterating the `matched` map).
- **FR-016**: Generated resources MUST include OPM tracking labels, injected via **TransformerContext**:
  - `app.kubernetes.io/managed-by: open-platform-model`
  - `module.opmodel.dev/name`
  - `module.opmodel.dev/version`
  - `component.opmodel.dev/name`
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

### Non-Functional Requirements

- **NFR-001**: The render pipeline MUST NOT have predefined limits on the number of components or transformers it can process. Performance should scale linearly with the size of the input module.

### Key Entities

- **Provider**: Platform adapter.
- **Transformer**: Converts OPM component to **one** platform resource.
- **TransformerContext**:
  - `name`, `namespace`, `version`, `provider`, `timestamp`
  - `strict` (bool)
  - `labels` (map[string]string): **Includes OPM tracking labels.**
- **Component**: OPM component with resources, traits, policies, and computed labels.
- **MatchedMap**: internal structure grouping components by transformer.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: A module with 5 components renders to Kubernetes manifests in under 2 seconds (excluding network operations).
- **SC-002**: Transformer matching is deterministic - the same module always produces identical output.
- **SC-003**: 100% of components with matching transformers produce valid Kubernetes resources that pass `kubectl apply --dry-run=client` validation.
- **SC-004**: Error messages for unmatched components include actionable guidance (list transformers, their requirements, and what's missing).
- **SC-005**: Verbose output mode shows transformer matching decisions for every component.

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
        apiVersion:  "transformer.opm.dev/workload@v1"
        name:        "DeploymentTransformer"
        description: "Converts stateless workload components to Kubernetes Deployments"
    }

    // Matching criteria
    requiredLabels: {
        "core.opm.dev/workload-type": "stateless"
    }
    requiredResources: {
        "opm.dev/resources/workload@v1#Container": _
    }
    optionalLabels: {
        "opm.dev/debug": "true"
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
