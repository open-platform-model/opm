# Provider Definition Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-08

## Overview

Providers are the bridge between platform-agnostic OPM modules and concrete platform implementations (Kubernetes, Docker, cloud providers, etc.). A Provider contains a registry of **Transformers** that convert OPM components (Units + Traits) into platform-specific resources.

### Core Principles

- **Platform-specific**: Each Provider targets a specific deployment platform
- **Registry pattern**: Providers are collections of Transformers, not implementations
- **Declarative matching**: Transformers declare which Resources, Traits, and Policies they handle
- **Stateless transformations**: Transformers are pure functions without side effects
- **Versioned**: Providers and Transformers have independent versioning for compatibility
- **Extensible**: Platform teams can add custom transformers to existing providers

### What Providers Represent

Providers can target:

- **Container Orchestrators**: Kubernetes, Docker Swarm, Nomad
- **Cloud Platforms**: AWS, GCP, Azure (via Terraform, Crossplane, etc.)
- **Configuration Management**: Ansible, Chef, Puppet
- **Infrastructure as Code**: Terraform, Pulumi, CloudFormation
- **Custom Platforms**: Internal deployment systems, edge computing platforms

### Provider vs Transformer vs Renderer

| Aspect | Provider | Transformer | Renderer |
|--------|----------|-------------|----------|
| **Purpose** | Registry of transformers | Convert components to resources | Format output manifests |
| **Contains** | Map of transformers | Transform function | Render function |
| **Versioning** | Provider version | Transformer version | Renderer version |
| **Examples** | Kubernetes Provider | DeploymentTransformer | Kubernetes List Renderer |

---

## Provider Definition Structure

Every Provider follows this structure:

```cue
#Provider: {
    kind:       "Provider"
    apiVersion: "core.opm.dev/v1"

    metadata: {
        name:        string  // Provider name (e.g., "kubernetes")
        description: string  // Brief description
        version:     string  // Provider version
        minVersion:  string  // Minimum OPM version required

        // Labels for provider categorization
        // Example: {"core.opm.dev/format": "kubernetes"}
        labels?: #LabelsAnnotationsType
    }

    // Transformer registry - maps platform resources to transformers
    transformers: #TransformerMap

    // Computed: All resources, traits, and policies declared by transformers
    #declaredResources: #ResourceStringArray
    #declaredTraits:    #TraitStringArray
    #declaredPolicies:  #PolicyStringArray
    #allDefinitions:    list.Concat([...])
}
```

### Metadata Fields

**name** (`string`, required)

- Provider name, typically matches the target platform
- Examples: `"kubernetes"`, `"docker-compose"`, `"terraform-aws"`
- Convention: lowercase with hyphens

**description** (`string`, required)

- Human-readable description of what platform this provider targets
- Example: `"Transforms OPM components to Kubernetes native resources"`

**version** (`string`, required)

- Provider version following semantic versioning
- Example: `"1.2.3"`
- Version applies to the provider's transformer set, not the target platform

**minVersion** (`string`, required)

- Minimum OPM core version required
- Example: `"1.0.0"`
- Ensures compatibility with OPM features used by transformers

**labels** (`#LabelsAnnotationsType`, optional)

- Key-value pairs for provider categorization
- Useful for provider discovery and selection
- Common labels:
  - `"core.opm.dev/format"` - Target format (e.g., `"kubernetes"`)
  - `"core.opm.dev/platform"` - Platform type (e.g., `"container-orchestrator"`)

### Transformers Field

The `transformers` field is a map where:

- **Key**: Transformer fully qualified name (FQN)
- **Value**: Transformer definition

Example:

```cue
transformers: {
    "transformer.opm.dev/workload@v1#DeploymentTransformer": #DeploymentTransformer
    "transformer.opm.dev/workload@v1#StatefulSetTransformer": #StatefulSetTransformer
    // ... more transformers
}
```

### Computed Fields

Providers automatically compute which definitions they support:

- `#declaredResources` - All Resources declared by all transformers
- `#declaredTraits` - All Traits declared by all transformers
- `#declaredPolicies` - All Policies declared by all transformers
- `#allDefinitions` - Concatenation of all the above

These computed fields enable:

- Provider capability discovery
- Validation that components can be transformed
- Automated documentation generation

---

## Transformer Definition Structure

Transformers are the core logic of a Provider. Each Transformer defines how to convert OPM components into platform-specific resources.

```cue
#Transformer: {
    kind:       "Transformer"
    apiVersion: "core.opm.dev/v1"

    metadata: {
        apiVersion!: #NameType   // Example: "transformer.opm.dev/workload@v1"
        name!:       #NameType   // Example: "DeploymentTransformer"
        fqn:         #FQNType    // Computed: "\(apiVersion)#\(name)"
        description: string      // Brief description

        // Labels for categorizing transformers
        // Used for DRY matching in transformer selection
        labels?: #LabelsAnnotationsType
    }

    // Resources required by this transformer - component MUST include these
    // Map key is the FQN, value is the full ResourceDefinition (provides access to #defaults)
    requiredResources: [string]: _

    // Resources optionally used by this transformer - component MAY include these
    // If not provided, defaults from the definition can be used
    optionalResources: [string]: _

    // Traits required by this transformer - component MUST include these
    // Map key is the FQN, value is the full TraitDefinition (provides access to #defaults)
    requiredTraits: [string]: _

    // Traits optionally used by this transformer - component MAY include these
    // If not provided, defaults from the definition can be used
    optionalTraits: [string]: _

    // Policies required by this transformer - component MUST include these
    // Map key is the FQN, value is the full PolicyDefinition (provides access to #defaults)
    requiredPolicies: [string]: _

    // Policies optionally used by this transformer - component MAY include these
    // If not provided, defaults from the definition can be used
    optionalPolicies: [string]: _

    // Transform function
    transform: {
        #component: #ComponentDefinition      // Input component
        #context:   #TransformerContext       // Context (module, version)
        output:     [...]                     // Output MUST be a list
    }
}
```

### Transformer Metadata

**apiVersion** (`#NameType`, required)

- Transformer-specific version path
- Example: `"transformer.opm.dev/workload@v1"`
- Allows transformers to version independently

**name** (`#NameType`, required)

- Transformer name in PascalCase
- Example: `"DeploymentTransformer"`
- Should clearly indicate what it transforms to

**fqn** (`#FQNType`, computed)

- Fully qualified name: `"\(apiVersion)#\(name)"`
- Example: `"transformer.opm.dev/workload@v1#DeploymentTransformer"`
- Used as key in provider's transformers map

**labels** (`#LabelsAnnotationsType`, optional)

- Categorization labels for pattern matching
- Common labels:
  - `"core.opm.dev/workload-type"` - Workload category (e.g., `"stateless"`, `"stateful"`)
  - `"core.opm.dev/resource-type"` - Platform resource (e.g., `"deployment"`, `"statefulset"`)
  - `"core.opm.dev/priority"` - Selection priority for overlapping transformers

### Declaration Fields

Transformers declare which OPM definitions they handle using maps of FQN → Definition. This pattern provides two key benefits:

1. **Clear required vs optional semantics**: Explicitly distinguish mandatory from optional elements
2. **Access to defaults**: Map values contain full definitions, enabling access to `#defaults` for fallback values

**requiredResources** (`[string]: _`, required)

- Map of Resource FQN → ResourceDefinition for resources this transformer REQUIRES
- Component MUST include all required resources or matching fails
- Example: `{"opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource}`
- Map key is used for matching, value provides access to defaults

**optionalResources** (`[string]: _`, optional)

- Map of Resource FQN → ResourceDefinition for resources this transformer CAN USE
- Component MAY include these, transformer can use defaults if not present
- Example: `{"opm.dev/resources/storage@v1#Volume": storage_resources.#VolumeResource}`

**requiredTraits** (`[string]: _`, optional)

- Map of Trait FQN → TraitDefinition for traits this transformer REQUIRES
- Component MUST include all required traits or matching fails
- Can be empty map `{}` if no traits are required

**optionalTraits** (`[string]: _`, optional)

- Map of Trait FQN → TraitDefinition for traits this transformer CAN USE
- Component MAY include these, transformer can use defaults if not present
- Example: `{"opm.dev/traits/scaling@v1#Replicas": scaling_traits.#ReplicasTrait}`

**requiredPolicies** (`[string]: _`, optional)

- Map of Policy FQN → PolicyDefinition for policies this transformer REQUIRES
- Component MUST include all required policies or matching fails
- Can be empty map `{}` if no policies are required

**optionalPolicies** (`[string]: _`, optional)

- Map of Policy FQN → PolicyDefinition for policies this transformer CAN USE
- Component MAY include these
- Can be empty map `{}` if no policies are handled

### Transform Function

The heart of a transformer is its `transform` function:

**Inputs:**

- `#component`: The OPM component to transform (after flattening, only Resources + Traits)
- `#context`: Transformer context (module name, version, environment, etc.)

**Output:**

- MUST be a list `[...]` even for single resources
- Contains platform-specific resource objects
- Example for Kubernetes: `[{apiVersion: "apps/v1", kind: "Deployment", ...}]`

**Important Rules:**

1. **Always return a list** - Enables consistent concatenation and processing
2. **Stateless** - No side effects, pure transformation
3. **Idempotent** - Same input always produces same output
4. **Fail fast** - Validate inputs and return errors early

---

## Transformer Context

The `#TransformerContext` provides environmental information to transformers:

```cue
#TransformerContext: close({
    // Module information
    name:    string              // Module name
    version: string | *"latest"  // Module version
})
```

Future extensions may include:

- `environment` - Target environment (production, staging, etc.)
- `namespace` - Target namespace for multi-tenant platforms
- `region` - Cloud region or datacenter
- `values` - User-provided configuration values

---

## Transformer Matching and Selection

When rendering a module, the OPM CLI must select appropriate transformers for each component. The matching algorithm follows these steps:

### 1. Exact FQN Matching

**Primary matching**: Transformers declare exactly which Resources, Traits, and Policies they handle by FQN using required/optional maps.

```cue
// Transformer declares
requiredResources: {
    "opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
}
optionalTraits: {
    "opm.dev/traits/scaling@v1#Replicas": scaling_traits.#ReplicasTrait
}

// Component has (after flattening)
spec: {
    container: {...}  // Matches required resource
    replicas: {...}   // Matches optional trait
}
```

**Matching Rules:**

- Component MUST include ALL resources in transformer's `requiredResources`
- Component MUST include ALL traits in transformer's `requiredTraits`
- Component MAY include resources from transformer's `optionalResources`
- Component MAY include traits from transformer's `optionalTraits`
- If component lacks required elements, transformer is excluded from candidates
- Multiple transformers can handle the same Resource+Trait combination

### 2. Label-Based Pattern Matching

**Secondary matching**: Use transformer labels for flexible pattern matching when FQNs aren't specific enough.

```cue
// Transformer metadata
#metadata: {
    name: "DeploymentTransformer"
    labels: {
        "core.opm.dev/workload-type": "stateless"
        "core.opm.dev/priority":      "10"
    }
}

// Component metadata (from Blueprint provenance)
metadata: {
    labels: {
        "core.opm.dev/workload-type": "stateless"
    }
}
```

**Label Matching:**

- Transformers can be selected by label patterns
- Higher priority value wins if multiple transformers match
- Useful for Blueprint-based selection (provenance tracking)

### 3. Transformer Selection Algorithm

```
For each component in module:
  1. Flatten component (Blueprints → Resources + Traits)
  2. Extract component's Resources and Traits FQNs
  3. Find candidate transformers where:
     - ALL transformer.requiredResources are present in component
     - ALL transformer.requiredTraits are present in component
     - Component MAY have additional resources/traits from optional maps
  4. Score each candidate:
     - Base score for meeting all requirements
     - Additional points for optional resources/traits coverage
     - Label match bonuses
     - Priority label values
  5. Select transformer(s) based on strategy:
     - "best": Single highest-scoring transformer
     - "all": All matching transformers (default)
     - "threshold": All above minimum score
  6. Execute transformer.transform(component, context) for each
  7. Collect and concatenate output resources
```

### 4. Validation Rules

**Before transformation:**

- ✅ Component must have at least one Resource
- ✅ Component MUST have all `requiredResources` from matched transformer
- ✅ Component MUST have all `requiredTraits` from matched transformer
- ✅ At least one transformer must match the component
- ⚠️ Traits not in any transformer's required/optional maps generate warnings
- ⚠️ Resources not in any transformer's required/optional maps generate warnings
- ❌ Components with no matching transformer fail
- ❌ Components missing required resources/traits fail

**After transformation:**

- ✅ Transformer output must be a list
- ✅ Each output resource must have required platform fields
- ✅ No duplicate resources (by platform-specific identity)

---

## Examples

### Example 1: Kubernetes Provider

```cue
package kubernetes

import (
    opm "opm.dev/core/v1"
)

#KubernetesProvider: opm.#Provider & {
    #metadata: {
        name:        "kubernetes"
        description: "Transforms OPM components to Kubernetes native resources"
        version:     "1.0.0"
        minVersion:  "1.0.0"
        labels: {
            "core.opm.dev/format":   "kubernetes"
            "core.opm.dev/platform": "container-orchestrator"
        }
    }

    transformers: {
        "transformer.opm.dev/workload@v1#DeploymentTransformer":   #DeploymentTransformer
        "transformer.opm.dev/workload@v1#StatefulSetTransformer":  #StatefulSetTransformer
        "transformer.opm.dev/workload@v1#DaemonSetTransformer":    #DaemonSetTransformer
        "transformer.opm.dev/storage@v1#PVCTransformer":           #PVCTransformer
        "transformer.opm.dev/network@v1#ServiceTransformer":       #ServiceTransformer
    }
}
```

### Example 2: Deployment Transformer

```cue
#DeploymentTransformer: opm.#Transformer & {
    metadata: {
        apiVersion: "transformer.opm.dev/workload@v1"
        name:       "DeploymentTransformer"
        description: "Converts stateless workload components to Kubernetes Deployments"
        labels: {
            "core.opm.dev/workload-type": "stateless"
            "core.opm.dev/resource-type": "deployment"
            "core.opm.dev/priority":      "10"
        }
    }

    // Required: Container resource MUST be present
    requiredResources: {
        "opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
    }

    // No optional resources
    optionalResources: {}

    // No required traits
    requiredTraits: {}

    // Optional: Various traits that enhance deployment behavior
    optionalTraits: {
        "opm.dev/traits/scaling@v1#Replicas":                scaling_traits.#ReplicasTrait
        "opm.dev/traits/workload@v1#RestartPolicy":          workload_traits.#RestartPolicyTrait
        "opm.dev/traits/workload@v1#UpdateStrategy":         workload_traits.#UpdateStrategyTrait
        "opm.dev/traits/workload@v1#HealthCheck":            workload_traits.#HealthCheckTrait
        "opm.dev/traits/workload@v1#SidecarContainers":      workload_traits.#SidecarContainersTrait
        "opm.dev/traits/workload@v1#InitContainers":         workload_traits.#InitContainersTrait
    }

    // No required policies
    requiredPolicies: {}

    // No optional policies
    optionalPolicies: {}

    transform: {
        #component: _
        #context:   _

        // VALIDATION: Ensure required Container resource is present
        _container: #component.spec.container | error("DeploymentTransformer requires Container resource")

        // Apply defaults for optional traits
        _replicas: *optionalTraits["opm.dev/traits/scaling@v1#Replicas"].#defaults | int
        if #component.spec.replicas != _|_ {
            _replicas: #component.spec.replicas
        }

        // Build container list (main + optional sidecars)
        _sidecarContainers: *optionalTraits["opm.dev/traits/workload@v1#SidecarContainers"].#defaults | [...]
        if #component.spec.sidecarContainers != _|_ {
            _sidecarContainers: #component.spec.sidecarContainers
        }

        _containers: list.Concat([
            [_container],
            _sidecarContainers,
        ])

        // Extract init containers with defaults
        _initContainers: *optionalTraits["opm.dev/traits/workload@v1#InitContainers"].#defaults | [...]
        if #component.spec.initContainers != _|_ {
            _initContainers: #component.spec.initContainers
        }

        output: [{
            apiVersion: "apps/v1"
            kind:       "Deployment"
            metadata: {
                name:      #component.metadata.name
                namespace: #context.namespace | *"default"
                labels:    #component.metadata.labels | {}
            }
            spec: {
                replicas: _replicas

                selector: matchLabels: app: #component.metadata.name

                template: {
                    metadata: labels: app: #component.metadata.name

                    spec: {
                        containers: _containers

                        if len(_initContainers) > 0 {
                            initContainers: _initContainers
                        }

                        if #component.spec.restartPolicy != _|_ {
                            restartPolicy: #component.spec.restartPolicy.policy
                        }
                    }
                }

                if #component.spec.updateStrategy != _|_ {
                    strategy: {
                        type: #component.spec.updateStrategy.type
                        if #component.spec.updateStrategy.type == "RollingUpdate" {
                            rollingUpdate: #component.spec.updateStrategy.rollingUpdate
                        }
                    }
                }
            }
        }]
    }
}
```

### Example 3: Service Transformer (Expose Trait)

```cue
#ServiceTransformer: opm.#Transformer & {
    metadata: {
        apiVersion: "transformer.opm.dev/network@v1"
        name:       "ServiceTransformer"
        description: "Creates Kubernetes Services from Expose trait"
        labels: {
            "core.opm.dev/trait-type":    "network"
            "core.opm.dev/resource-type": "service"
        }
    }

    // Works with any resource that has Container
    requiredResources: {
        "opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
    }

    optionalResources: {}

    // Requires Expose trait - service only makes sense with this trait
    requiredTraits: {
        "opm.dev/traits/network@v1#Expose": network_traits.#ExposeTrait
    }

    optionalTraits: {}

    requiredPolicies: {}

    optionalPolicies: {}

    transform: {
        #component: _
        #context:   _

        output: [{
            apiVersion: "v1"
            kind:       "Service"
            metadata: {
                name:      #component.metadata.name
                namespace: #context.namespace | *"default"
            }
            spec: {
                selector: app: #component.metadata.name

                type: #component.spec.expose.type

                ports: [
                    for port in #component.spec.container.ports {
                        {
                            port:       port.containerPort
                            targetPort: port.containerPort
                            protocol:   port.protocol | *"TCP"
                        }
                    }
                ]
            }
        }]
    }
}
```

---

## Best Practices

### Provider Design

1. **Clear Scope**: One provider per target platform
2. **Complete Coverage**: Include transformers for all common use cases
3. **Extensibility**: Allow users to add custom transformers
4. **Documentation**: Document transformer capabilities and limitations
5. **Versioning**: Use semantic versioning for provider releases

### Transformer Design

1. **Single Responsibility**: Each transformer handles one platform resource type
2. **Explicit Declarations**: Clearly declare all Resources, Traits, Policies handled
3. **Defensive Coding**: Validate inputs, provide defaults, handle edge cases
4. **List Output**: Always return a list, even for single resources
5. **Stateless**: No side effects, no external state
6. **Composability**: Transformers should compose well (e.g., Service + Deployment)

### Matching Strategy

1. **Prefer FQN Matching**: Most reliable and explicit
2. **Use Labels Sparingly**: For pattern matching when FQNs aren't sufficient
3. **Document Priority**: If using priority labels, document the rationale
4. **Fail Early**: Validate component compatibility before transformation
5. **Clear Errors**: Provide helpful error messages when matching fails

### Testing

1. **Unit Tests**: Test each transformer in isolation
2. **Integration Tests**: Test full provider with realistic modules
3. **Validation**: Validate output against platform schemas (e.g., K8s OpenAPI)
4. **Edge Cases**: Test with minimal components, maximal components, mixed traits
5. **Regression**: Test against previous transformer versions

---

## Versioning and Compatibility

### Provider Versioning

Providers follow semantic versioning:

- **MAJOR**: Breaking changes to transformer interfaces or removed transformers
- **MINOR**: New transformers added, backward-compatible enhancements
- **PATCH**: Bug fixes in existing transformers

### Transformer Versioning

Transformers version independently in their `metadata.apiVersion`:

```cue
metadata: {
    apiVersion: "transformer.opm.dev/workload@v2"  // Major version bump
    name:       "DeploymentTransformer"
}
```

Version bumps when:

- **Major**: Incompatible changes to declarations or output format
- **Minor**: New traits/policies supported, backward-compatible
- **Patch**: Bug fixes, no API changes

### Compatibility Matrix

Providers declare minimum OPM version:

```cue
#metadata: {
    version:    "2.1.0"   // Provider version
    minVersion: "1.5.0"   // Requires OPM >= 1.5.0
}
```

---

## Related Specifications

- [Resource Definition](RESOURCE_DEFINITION.md) - Units that transformers process
- [Trait Definition](TRAIT_DEFINITION.md) - Behavioral modifiers
- [Component Definition](COMPONENT_DEFINITION.md) - Unit + Trait compositions
- [Module Definition](MODULE_DEFINITION.md) - Collections of components
- [CLI Commands - Provider](cli/COMMANDS_PROVIDER.md) - CLI for provider management

---

## Future Enhancements

Potential future additions to Provider/Transformer architecture:

1. **Multi-Platform Transformers**: Single component transforms to multiple platforms
2. **Conditional Transformation**: Transform based on environment, feature flags
3. **Transformer Composition**: Chain transformers together
4. **Resource Merging**: Merge outputs from multiple transformers
5. **Validation Hooks**: Pre/post transformation validation
6. **Transformation Metadata**: Provenance tracking in transformed resources
7. **Dry-Run Mode**: Validate transformations without executing
8. **Diff Mode**: Compare transformed output across versions

---

**Status**: This specification is in draft status and subject to change based on implementation feedback and community input.
