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
3. **Existing transformer matching**: Documents the current label-based matching algorithm without changes.

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

## Requirements

### Functional Requirements

#### Provider System

- **FR-001**: Provider MUST contain a `transformers` map registry that maps unique keys to Transformer definitions.
- **FR-002**: Provider MUST compute `#declaredResources`, `#declaredTraits`, and `#declaredPolicies` by aggregating from all registered transformers.
- **FR-003**: Provider MUST include metadata with name, version, and description.
- **FR-004**: The CLI MUST support specifying which provider to use via `--provider` flag (default: `kubernetes`).

#### Transformer System

- **FR-005**: Transformer MUST declare matching criteria: `requiredLabels`, `requiredResources`, `requiredTraits`, `requiredPolicies`.
- **FR-006**: Transformer MAY declare optional inputs: `optionalResources`, `optionalTraits`, `optionalPolicies`.
- **FR-007**: Transformer MUST implement a `#transform` function that receives `#component` and `#context` and produces `output: [...]`.
- **FR-008**: Transformer output MUST be a list of resources, even for single-resource transformers.
- **FR-009**: A transformer matches a component when ALL of:
  - ALL `requiredLabels` are present on component with matching values
  - ALL `requiredResources` FQNs exist in `component.#resources`
  - ALL `requiredTraits` FQNs exist in `component.#traits`
  - ALL `requiredPolicies` FQNs exist in `component.#policies`

#### Matching & Conflict Resolution

- **FR-010**: Component labels MUST be the union of labels from `metadata.labels` plus all attached `#resources`, `#traits`, and `#policies`.
- **FR-011**: When multiple transformers match with **identical requirements**, the system MUST error with "multiple exact transformer matches".
- **FR-012**: Transformers with **different requirements** are complementary and MUST both execute when matched.
- **FR-013**: Outputs from multiple matched transformers MUST be concatenated into a single resource list.
- **FR-014**: Each matched transformer receives the full component (components are not partitioned).

#### Render Pipeline

- **FR-015**: The render pipeline MUST process in the following order:
  1. Load and validate module definition
  2. Unify values (module defaults + user values)
  3. For each component: match transformers, execute transforms
  4. Concatenate all transformer outputs
  5. Format output (YAML/JSON, single/split)
- **FR-016**: Generated resources MUST include OPM tracking labels:
  - `app.kubernetes.io/managed-by: opm-platform-model`
  - `module.opmodel.dev/name: <module-name>`
  - `module.opmodel.dev/namespace: <namespace>`
  - `module.opmodel.dev/version: <version>`
  - `component.opmodel.dev/name: <component-name>`
- **FR-017**: The CLI MUST support output formats: `yaml` (default), `json`.
- **FR-018**: The CLI MUST support `--split` flag to output each resource as a separate file.

#### Error Handling

- **FR-019**: When no transformers match a component, the CLI MUST error with component details and list of available transformers with their requirements.
- **FR-020**: In `--strict` mode, unhandled traits MUST cause an error with the list of unhandled traits.
- **FR-021**: In normal mode, unhandled traits SHOULD produce a warning.

### Key Entities

- **Provider**: Platform adapter containing transformer registry and metadata. Maps transformer keys to transformer definitions.
- **Transformer**: Declares matching criteria and transform function. Converts OPM components to platform-specific resources.
- **TransformerContext**: Minimal context passed to transforms (module name, namespace).
- **Component**: OPM component with resources, traits, policies, and computed labels.

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

```text
+-----------------+
|  Module.cue     |
|  + values.yaml  |
+--------+--------+
         |
         v
+-----------------+
|  CUE Unify      |  Merge module definition with user values
+--------+--------+
         |
         v
+-----------------+
|  For each       |
|  Component      |-------------------+
+--------+--------+                   |
         |                            |
         v                            |
+-----------------+                   |
|  Match          |  Find transformers|
|  Transformers   |  matching this    |
+--------+--------+  component        |
         |                            |
         v                            |
+-----------------+                   |
|  Execute        |  Run #transform   |
|  Transforms     |  for each match   |
+--------+--------+                   |
         |                            |
         v                            |
+-----------------+                   |
|  Collect Output |  Concatenate all  |
|  Resources      |<------------------+
+--------+--------+
         |
         v
+-----------------+
|  Add Labels     |  OPM tracking labels
+--------+--------+
         |
         v
+-----------------+
|  Format Output  |  YAML/JSON, single/split
+--------+--------+
         |
         v
+-----------------+
|  Kubernetes     |
|  Manifests      |
+-----------------+
```

---

## Appendix C: Transformer Matching Algorithm

```text
function matches(transformer, component) -> bool:
    // Check labels
    for key, value in transformer.requiredLabels:
        if component.metadata.labels[key] != value:
            return false
    
    // Check resources
    for fqn in keys(transformer.requiredResources):
        if fqn not in component.#resources:
            return false
    
    // Check traits
    for fqn in keys(transformer.requiredTraits):
        if fqn not in component.#traits:
            return false
    
    // Check policies
    for fqn in keys(transformer.requiredPolicies):
        if fqn not in component.#policies:
            return false
    
    return true
```

---

## Appendix D: Example Transformer Implementation

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

    // Transform function
    #transform: {
        #component: core.#Component
        #context:   core.#TransformerContext

        output: [{
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
        }]
    }
}
```
