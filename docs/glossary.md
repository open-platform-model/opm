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
