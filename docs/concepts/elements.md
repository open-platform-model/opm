# Elements - Core Concepts

## What are Elements

Elements are the fundamental building blocks of the Open Platform Model (OPM). They represent every capability, behavior, and resource that can be expressed in a module. Like LEGO blocks, primitive elements combine into composite elements, which compose into complete modules. This creates a unified mental model where everything - from simple containers to complex policy frameworks - is an element.

Elements provide a consistent abstraction layer that enables portability across platforms while maintaining type safety through CUE. Every element is self-documenting with metadata describing its purpose, schema, and usage constraints.

## The Element Philosophy

**Everything is an Element** - This foundational principle means that whether you're defining a container, a network policy, a volume, or a compliance requirement, you're working with elements. This consistency provides:

- **Unified Mental Model**: One pattern to understand all capabilities
- **Composability**: Elements naturally combine to create higher-level abstractions
- **Type Safety**: CUE enforces correct element usage and composition
- **Self-Documentation**: Every element carries its own documentation
- **Extensibility**: New capabilities are added as new elements

## Element Anatomy

Every element in OPM has a consistent structure defined by the `#Element` schema:

```cue
#Element: {
    #name!:              string                    // Element identifier
    #apiVersion:         string | *"core.opm.dev/v1alpha1"
    #fullyQualifiedName: "\(#apiVersion).\(#name)" // Unique element reference

    description?: string  // Human-readable description
    labels?:      {...}   // Metadata for categorization

    type!:   "trait" | "resource" | "policy"       // Element type
    kind!:   "primitive" | "composite" | "modifier" | "custom"  // Element kind
    target!: ["component"] | ["scope"] | ["component", "scope"]  // Where it applies

    #schema!: _  // OpenAPIv3 compatible schema defining the element's structure
}
```

## Element Types

Elements are classified into three types based on their purpose:

### Traits

Behavioral capabilities that define how components behave. Traits represent actions, configurations, or policies that affect runtime behavior.

**Examples**: Container execution, scaling behavior, update strategies, health checks

### Resources

Infrastructure primitives that components need. Resources represent tangible assets that are created, managed, and consumed.

**Examples**: Volumes, ConfigMaps, Secrets, Networks

### Policies

Governance and compliance rules that enforce organizational requirements. Policies represent constraints and rules that must be followed.

**Examples**: Security policies, resource quotas, compliance frameworks

## Element Kinds

Elements are further classified by their implementation complexity:

### Primitive

Single-purpose, fundamental capabilities implemented directly by the platform. These are the atomic building blocks that cannot be decomposed further.

**Characteristics**:

- Directly mapped to platform capabilities
- Cannot be broken down into smaller elements
- Platform must provide implementation
- Form the foundation for all other elements

**Examples**:

- `#Container`: Maps directly to container runtime
- `#Volume`: Maps to storage primitives
- `#NetworkPolicy`: Maps to network security rules

### Composite

Combinations of multiple primitive elements that represent common patterns. Composites provide higher-level abstractions while maintaining transparency about their composition.

**Characteristics**:

- Built from 2+ primitive elements
- Provide convenient abstractions for common use cases
- Can be decomposed to understand their primitives
- Reduce boilerplate for standard patterns

**Examples**:

- `#WebService`: Combines Container + Expose + Replicas
- `#Database`: Combines Container + Volume + Secret + ConfigMap
- `#CronJob`: Combines Task + Schedule + RetryPolicy

### Modifier

Elements that augment or transform the behavior of other elements. Modifiers cannot stand alone but enhance existing elements with additional capabilities.

**Characteristics**:

- Cannot be used independently
- Must target specific element types
- Transform or enhance element behavior
- Often implement cross-cutting concerns

**Note**: Modifier elements are defined in the OPM architecture but not yet implemented. They represent future capabilities for transforming or enhancing other elements without duplication.

### Custom

Platform-specific extensions for capabilities not covered by standard elements. Custom elements are a last resort when no standard element fits.

**Characteristics**:

- Platform-specific implementation required
- Must provide transformer to platform resources
- Should follow standard element patterns
- Used sparingly to maintain portability

**Requirements for Custom Elements**:

- MUST declare as `kind: "custom"`
- MUST provide transformation logic to platform resources
- MUST follow standard element structure
- SHOULD document platform dependencies

## Element Targeting

Elements declare where they can be applied through the `target` field:

### Component-Level

Elements that configure individual components:

```cue
target: ["component"]
```

These elements affect single components in isolation. They define component-specific behavior without requiring coordination with other components.

**Use Cases**: Container configuration, component networking, individual resource limits

### Scope-Level

Elements that apply cross-cutting concerns:

```cue
target: ["scope"]
```

These elements affect groups of components through scopes. They establish shared policies and coordinated behavior across multiple components.

**Use Cases**: Network policies, shared observability, group resource quotas

### Dual-Target

Elements that work at either level:

```cue
target: ["component", "scope"]
```

These flexible elements can be applied to individual components or groups, depending on requirements.

**Use Cases**: Security policies, monitoring configuration, resource constraints

## Element Categories

Elements use labels for categorization, with the standard label `core.opm.dev/category`:

- **workload**: Container orchestration, scaling, lifecycle management
- **data**: Storage, configuration, secrets management
- **connectivity**: Networking, service discovery, API management
- **security**: Access control, encryption, compliance
- **observability**: Logging, metrics, tracing, alerting
- **governance**: Resource management, policies, quotas

## Platform Provider Integration

Elements abstract over multiple deployment platforms through the transformer system:

### Element Definition (Platform-Agnostic)

```cue
// Developer defines elements without platform specifics
myComp: #Component & {
    #Container
    container: {
        name: "app"
        image: "myapp:v1"
    }
    #Expose
    expose: {
        port: 8080
        type: "LoadBalancer"
    }
}
```

### Platform Transformation

Platform providers implement transformers that convert elements to platform-specific resources:

- **Kubernetes**: Transforms to Deployments, Services, PVCs
- **Docker Compose**: Transforms to services, volumes, networks
- **Cloud Platforms**: Transforms to cloud-native resources

This separation ensures modules remain portable while platforms optimize implementation.

## Element Validation

Elements leverage CUE's type system for comprehensive validation:

### Schema Validation

```cue
#ContainerSpec: {
    name: string & =~"^[a-z0-9-]+$"  // DNS-compliant name
    image: string & =~".+:.+"        // Must include tag
    ports?: [...{
        containerPort: int & >=1 & <=65535
        protocol?: "TCP" | "UDP"
    }]
    resources?: {
        limits?: {
            cpu?: string & =~"^[0-9]+m?$"      // Millicores or cores
            memory?: string & =~"^[0-9]+[KMG]i?$"  // Memory units
        }
    }
}
```

## Best Practices

### Element Design

1. **Single Responsibility**: Each element should have one clear purpose
2. **Minimal Interface**: Expose only necessary configuration options
3. **Unique field name**: The element specific field name MUST be uique
4. **Sensible Defaults**: Provide good defaults for optional fields
5. **Clear Documentation**: Include descriptions for the element and its fields
6. **Type Safety**: Use CUE constraints to prevent invalid configurations

### Element Selection

1. **Prefer Primitives** for simple, single-purpose needs
2. **Use Composites** for common patterns to reduce boilerplate
3. **Apply Modifiers** to enhance existing elements without duplication
4. **Create Custom Elements** only when standard elements don't suffice

### Element Composition

1. **Layer Incrementally**: Build complex elements from simple ones
2. **Maintain Transparency**: Make composition visible and understandable
3. **Avoid Deep Nesting**: Keep composition hierarchies shallow
4. **Document Dependencies**: Clearly state element relationships

### Platform Portability

1. **Use Standard Elements**: Stick to core elements when possible
2. **Abstract Platform Details**: Avoid platform-specific configurations
3. **Document Requirements**: Clearly state any platform dependencies
4. **Test Across Platforms**: Validate elements work on target platforms

## Element Extensibility

The element system is designed for extensibility at multiple levels:

### Developer Extensions

Developers can create application-specific composites:

```cue
#MyAppStack: #CompositeTrait & {
    composes: [#WebService, #Database, #Cache]
    // Application-specific orchestration
}
```

### Platform Extensions

Platform teams can add platform-specific elements:

```cue
#CloudLoadBalancer: #Custom & {
    description: "Cloud-specific load balancer"
    // Platform-specific configuration
}
```

### Ecosystem Extensions

Third parties can provide element packages:

```cue
import "crossplane.io/elements/v1"
import "istio.io/elements/v1"

// Use third-party elements
#CrossplaneResource: crossplane.#CompositeResource
#IstioServiceMesh: istio.#ServiceMesh
```

Elements form the foundation of OPM's composable architecture, providing a consistent, type-safe, and extensible way to express any capability across any platform. Through the element system, OPM achieves its goal of portable module definitions while maintaining platform flexibility and developer productivity.
