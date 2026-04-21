# Glossary

This glossary defines the core concepts, personas, and terminology used throughout Open Platform Model.

## Personas

### Infrastructure Operator

Person or team operating the underlying infrastructure (Kubernetes clusters, cloud accounts, networking, etc.). Responsible for providing the foundational platform on which OPM runs.

### Module Author

Developer who creates and maintains OPM modules. Responsible for defining the Module, setting sane default values, and publishing updates. Module authors design for reusability and configurability.

```cue
// Module authors define the structure and defaults
#Module: {
    metadata: name: "my-service"
    #values: {
        replicas: int | *3  // Sane default
    }
}
```

### Platform Operator

Person or team operating a platform and its catalog of Modules and Bundles. Consumes modules from authors, curates them for organizational use, and may apply additional constraints via CUE unification. Bridges infrastructure and end-users.

### End-user

Person who consumes modules via ModuleRelease. Responsible for providing concrete configuration values for deployment. Interacts primarily with the `#values` interface exposed by modules.

```cue
// End-users provide concrete values
#ModuleRelease: {
    module: "my-service@1.0.0"
    values: replicas: 5  // Concrete value for production
}
```

## Core Concepts

These are the building blocks of every OPM module. See [Concepts Overview](concepts/overview.md) for a walkthrough.

### Resource

A thing that physically exists at runtime. Resources are the fundamental "what exists" primitive — a container, a volume, a config map. Every Component contains at least one Resource.

```cue
// A container workload
#Container
spec: container: image: "nginx:1.25"
```

### Trait

An optional modifier that adjusts how a Component behaves. Where Resources say *what exists*, Traits say *how it behaves* — scaling, network exposure, health probes, restart policy.

```cue
// Scale to three instances
#Replicas
spec: replicas: 3
```

### Blueprint

A pre-bundled combination of Resources and Traits that captures a common pattern. Most authors use Blueprints instead of wiring Resources and Traits manually. Platform teams ship Blueprints as "golden paths."

```cue
// Stateless web workload in one line
#StatelessWorkload
```

### Component

A logical part of an application, built by composing Resources + Traits, or by using a Blueprint. A Module contains one or more Components.

### Policy

A rule a Component (or group of Components) must follow. Unlike Traits, which express preferences, Policies express requirements that can block, warn, or audit on violation. Examples: network rules, encryption, resource quotas.

### Provider

An implementation of OPM for a specific runtime (for example, Kubernetes). A Provider ships a set of Transformers that turn OPM definitions into runtime-specific resources.

### Transformer

A CUE function that converts an OPM definition into a provider-specific resource. The Kubernetes provider ships transformers for Deployments, StatefulSets, Services, Ingresses, PVCs, and more.

### Module

The portable, reusable definition of an application. A Module contains Components, a `#config` schema declaring which values are tunable, and sane defaults. Authored once and deployed many times. See [Module and ModuleRelease](concepts/module-and-release.md).

### ModuleRelease

The concrete deployment of a Module. Supplies final values for a specific environment and targets a namespace. Consumers write ModuleReleases; they do not need to understand the Module's internals.

## Terms and Definitions

### CUE-specific Terms

| Term | Definition |
|------|------------|
| **Definition** | CUE schema prefixed with `#` (e.g., `#Container`, `#Module`). Definitions are templates that constrain values. |
| **Hidden Field** | Field prefixed with `_`, computed internally and not exported in final output. Used for intermediate calculations. |
| **Required Field** | Field with `!` suffix that must be provided by the user (e.g., `name!: string`). Validation fails if missing. |
| **Optional Field** | Field with `?` suffix that may be omitted (e.g., `description?: string`). No error if absent. |
| **Default Value** | Value with `*` syntax providing a fallback (e.g., `replicas: *3 \| int`). Used when no explicit value is given. |
| **Unification** | CUE's core merge operation that combines schema, constraints, and data into one. Conflicts result in errors. |
| **Closed Struct** | Struct using `close()` that rejects any fields not explicitly defined. Prevents typos and unexpected fields. |

### OPM Workflow Terms

| Term | Definition |
|------|------------|
| **Rendering** | Process of evaluating a Module with concrete values to produce platform-specific resources (e.g., Kubernetes manifests). |
| **Flattening** | Process of converting a Module to a CompiledModule by pre-evaluating CUE expressions. Improves runtime performance. |
| **Validation (`vet`)** | Checking CUE definitions for type errors, constraint violations, and structural correctness. Run via `opm mod vet` or `cue vet`. |
| **Publishing** | Releasing a module or definition to a registry (CUE registry for definitions, OCI registry for Modules/Bundles/Providers). |
| **Tidy** | Resolving and updating module dependencies to ensure consistency. Run via `cue mod tidy`. |
