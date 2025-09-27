# Scopes - Core Concepts

## What are Scopes

Scopes are specialized element compositions that apply cross-cutting concerns to groups of components. Like components, scopes are themselves elements (specifically, composite traits) but with a different purpose - they establish operational boundaries and shared policies rather than defining individual workloads or resources.

While components use elements to define WHAT runs (containers, volumes, configs), scopes use elements to define HOW things run together (network policies, resource quotas, observability settings). Each scope applies exactly one element across its member components, maintaining focus and clarity.

## Scopes as Elements

Scopes are first-class citizens in the OPM system with their own structure:

```cue
#Scope: {
    #kind:       "Scope"
    #apiVersion: "core.opm.dev/v1alpha1"
    #metadata: {
        #id!: string

        name!: string | *#id

        // Scope specific labels and annotations
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
        ...
    }

    #elements: [elementName=string]: #Element & {#name!: elementName}

    // Helper: Extract ALL primitive elements (recursively traverses composite elements)
    #primitiveElements: [...string]
    #primitiveElements: {
        // Collect all primitive elements
        let allElements = [
            for _, e in #elements if e != _|_ {
                // Primitive traits contribute themselves
                if e.kind == "primitive" {
                    e.#fullyQualifiedName
                }
            },
        ]

        // Deduplicate and sort
        let set = {for cap in allElements {(cap): _}}
        list.SortStrings([for k, _ in set {k}])
    }

    appliesTo!: [...#Component] | "*"
    ...
}
```

This element-based architecture means:

- **Scopes are focused**: Each scope applies exactly one element for clarity
- **Scopes are composable**: Multiple scopes can affect the same components
- **Scopes are type-safe**: CUE validates element application
- **Scopes establish boundaries**: Define operational contexts for component groups

## The Single Element Rule

Unlike components which compose multiple elements, scopes follow a strict single-element rule. This design principle ensures:

### Clear Purpose

Each scope has one well-defined responsibility:

```cue
// Good: Single-purpose scope with one element
networkBoundary: #Scope & {
    #NetworkPolicy
    networkPolicy: {...}
    appliesTo: [frontend, backend]
}

// Bad: Multi-purpose scope trying to do too much
// This would fail validation
overloadedScope: #Scope & {
    #NetworkPolicy
    #ResourceQuota  // Error: Multiple elements not allowed
    #Metrics        // Error: Multiple elements not allowed
}
```

### Composable Policies

Multiple focused scopes work together:

```cue
// Each scope applies one element
securityScope: #Scope & {
    #PodSecurity
    podSecurity: {
        runAsNonRoot: true
    }
    appliesTo: "*"
}

resourceScope: #Scope & {
    #ResourceQuota
    resourceQuota: {
        limits: {cpu: "100"}
    }
    appliesTo: "*"
}

networkScope: #Scope & {
    #NetworkPolicy
    networkPolicy: {
        ingress: [...]
    }
    appliesTo: [api, database]
}
```

## Scope Types Based on Mutability

Scopes are classified by who controls them:

### PlatformScope (Immutable)

Platform-controlled element applications that enforce organizational policies:

```cue
#PlatformScope: #Scope & {
    #metadata: {
        immutable: true  // Cannot be modified by developers
    }
}
```

**Characteristics**:

- Defined and managed by platform teams
- Enforce non-negotiable requirements
- Apply security, compliance, and governance elements
- Cannot be overridden by module developers

**Common Elements Applied**:

- `#NetworkPolicy`: Network segmentation and security
- `#ResourceQuota`: Resource consumption limits
- `#PodSecurity`: Security standards and constraints
- `#CompliancePolicy`: Regulatory requirements

### ModuleScope (Mutable)

Developer-controlled element applications for module-specific needs:

```cue
#ModuleScope: #Scope & {
    #metadata: {
        immutable: false  // Can be modified by developers
    }
}
```

**Characteristics**:

- Created and managed by module developers
- Implement module-specific optimizations
- Must work within platform constraints
- Can be adjusted as module evolves

**Common Elements Applied**:

- `#HTTPRoute`: Traffic routing and management
- `#CachePolicy`: Caching strategies
- `#OTelMetrics`: Custom observability
- `#ServiceMesh`: Advanced networking features

## Scope Targeting Strategies

Scopes define which components they affect through the `appliesTo` field:

### Explicit Component List

Target specific components by reference:

```cue
apiRateLimit: #Scope & {
    #RateLimiting
    rateLimiting: {
        requestsPerSecond: 100
        burstSize: 200
    }
    appliesTo: [publicAPI, webhookHandler]  // Only these components
}
```

### Universal Application

Apply to all components in the module:

```cue
globalSecurity: #Scope & {
    #SecurityBaseline
    securityBaseline: {
        level: "restricted"
        auditLogging: true
    }
    appliesTo: "*"  // Affects every component
}
```

### Dynamic Selection

Use CUE expressions for conditional targeting:

```cue
publicServices: #Scope & {
    #TLSPolicy
    tlsPolicy: {
        minVersion: "1.3"
        cipherSuites: ["TLS_AES_256_GCM_SHA384"]
    }

    // Apply to components with public exposure
    appliesTo: [
        for comp in components if comp.#metadata.labels.exposure == "public" {
            comp
        }
    ]
}
```

## Element Application Through Scopes

Scopes serve as the vehicle for applying elements at scale:

### Network Segmentation Example

```cue
// Define the network element
#NetworkSegment: #ElementBase & {
    #metadata: #elements: NetworkSegment: #PrimitiveTrait & {
        description: "Network isolation and segmentation"
        target: ["scope"]  // This element targets scopes
        labels: {"core.opm.dev/category": "connectivity"}
        #schema: #NetworkSegmentSpec
    }

    networkSegment: #NetworkSegmentSpec
}

// Apply through a PlatformScope
internalZone: #PlatformScope & {
    #metadata: {
        #id: "internal-network-zone"
        immutable: true
    }

    #NetworkSegment
    networkSegment: {
        name: "internal"
        allowedSources: ["10.0.0.0/8"]
        deniedSources: ["0.0.0.0/0"]
        protocols: ["TCP", "UDP"]
    }

    appliesTo: [database, cache, messageQueue]
}
```

### Resource Governance Example

```cue
// Resource quota element
#ResourceQuota: #ElementBase & {
    #metadata: #elements: ResourceQuota: #PrimitiveTrait & {
        description: "Resource consumption limits"
        target: ["scope"]
        labels: {"core.opm.dev/category": "governance"}
        #schema: #ResourceQuotaSpec
    }

    resourceQuota: #ResourceQuotaSpec
}

// Apply through a PlatformScope
teamQuota: #PlatformScope & {
    #metadata: {
        #id: "team-alpha-quota"
        immutable: true
    }

    #ResourceQuota
    resourceQuota: {
        limits: {
            "requests.cpu": "100"
            "requests.memory": "200Gi"
            "persistentvolumeclaims": 10
        }
        scopes: ["NotTerminating"]
    }

    appliesTo: "*"  // All components share the quota
}
```

### Observability Configuration Example

```cue
// Metrics collection element
#MetricsCollection: #ElementBase & {
    #metadata: #elements: MetricsCollection: #PrimitiveTrait & {
        description: "Metrics collection configuration"
        target: ["scope"]
        labels: {"core.opm.dev/category": "observability"}
        #schema: #MetricsSpec
    }

    metricsCollection: #MetricsSpec
}

// Apply through a ModuleScope
appMetrics: #ModuleScope & {
    #metadata: {
        #id: "application-metrics"
        immutable: false
    }

    #MetricsCollection
    metricsCollection: {
        provider: "prometheus"
        interval: "30s"
        customMetrics: {
            "app_requests_total": {
                type: "counter"
                help: "Total number of requests"
            }
            "app_request_duration": {
                type: "histogram"
                help: "Request duration in seconds"
                buckets: [0.1, 0.5, 1, 2, 5]
            }
        }
    }

    appliesTo: [webAPI, worker, scheduler]
}
```

## Scope Composition Patterns

While each scope contains only one element, multiple scopes work together:

### Layered Security

```cue
// Base security for all components
baselineSecurity: #PlatformScope & {
    #PodSecurity
    podSecurity: {
        runAsNonRoot: true
        readOnlyRootFilesystem: true
    }
    appliesTo: "*"
}

// Additional security for sensitive components
enhancedSecurity: #PlatformScope & {
    #SeccompProfile
    seccompProfile: {
        type: "RuntimeDefault"
        localhostProfile: "profiles/strict.json"
    }
    appliesTo: [paymentProcessor, authService]
}

// Network isolation for sensitive data
dataIsolation: #PlatformScope & {
    #NetworkPolicy
    networkPolicy: {
        policyTypes: ["Ingress", "Egress"]
        ingress: [{from: [{podSelector: {tier: "secure"}}]}]
    }
    appliesTo: [database, secretsManager]
}
```

### Progressive Traffic Management

```cue
// Global load balancing
loadBalancing: #ModuleScope & {
    #LoadBalancer
    loadbalancer: {
        strategy: "round-robin"
        healthCheck: {
            interval: "10s"
            timeout: "5s"
        }
    }
    appliesTo: "*"
}

// Canary deployment for specific services
canaryRouting: #ModuleScope & {
    #TrafficSplit
    trafficSplit: {
        splits: {
            stable: 90
            canary: 10
        }
    }
    appliesTo: [apiV2, newFeatureService]
}

// Circuit breaking for external calls
circuitBreaker: #ModuleScope & {
    #CircuitBreaker
    circutBreaker: {
        threshold: 5
        timeout: "30s"
        halfOpenRequests: 3
    }
    appliesTo: [externalAPIClient, webhookCaller]
}
```

## Scope Validation

The element model provides comprehensive validation for scopes:

### Single Element Enforcement

```cue
#Scope: {
    #metadata: {
        // Automatic validation that exactly one element is present
        #validateSingleElement: len(#elements) == 1 |
            error("Scope must have exactly one element. Current count: \(len(#elements))")
    }
}
```

## Real-World Scope Examples

### Platform-Enforced Compliance

```cue
complianceScope: #PlatformScope & {
    #metadata: {
        #id: "pci-compliance"
        name: "PCI DSS Compliance Requirements"
        immutable: true
    }

    #CompliancePolicy
    compliancePolicy: {
        framework: "PCI-DSS"
        version: "4.0"
        controls: {
            encryption: {
                atRest: true
                inTransit: true
                algorithm: "AES-256"
            }
            auditLogging: {
                enabled: true
                retention: "365d"
                events: ["access", "modification", "deletion"]
            }
            accessControl: {
                mfa: true
                sessionTimeout: "15m"
                passwordPolicy: "strong"
            }
        }
    }

    appliesTo: [paymentAPI, cardProcessor, transactionDB]
}
```

### Multi-Region Deployment

```cue
regionScope: #ModuleScope & {
    #metadata: {
        #id: "multi-region"
        name: "Multi-Region Configuration"
        immutable: false
    }

    #RegionAffinity
    regions: {
        primary: "us-east-1"
        replicas: ["us-west-2", "eu-west-1"]
        failover: {
            strategy: "automatic"
            healthCheckInterval: "30s"
        }
        dataReplication: {
            mode: "async"
            lagThreshold: "5s"
        }
    }

    appliesTo: [webService, apiGateway, cdn]
}
```

### Cost Optimization

```cue
costScope: #ModuleScope & {
    #metadata: {
        #id: "cost-optimization"
        name: "Cost Optimization Policies"
        immutable: false
    }

    #CostOptimization
    costOptimization: {
        spotInstances: {
            enabled: true
            maxPrice: "0.05"
            fallbackToOnDemand: true
        }
        autoScaling: {
            scaleDownDelay: "10m"
            targetUtilization: 70
            schedules: {
                overnight: {
                    cron: "0 22 * * *"
                    minReplicas: 1
                }
                weekend: {
                    cron: "0 0 * * SAT,SUN"
                    minReplicas: 0
                }
            }
        }
    }

    appliesTo: [batchProcessor, reportGenerator, analyticsWorker]
}
```

## Best Practices

### Scope Design Principles

1. **Single Element Rule**: Always apply exactly one element per scope
2. **Clear Naming**: Use descriptive names that indicate the scope's purpose
3. **Appropriate Granularity**: Don't create too many narrow scopes
4. **Document Purpose**: Clearly explain why the scope exists
5. **Validate Targets**: Ensure components can receive the scope's element

### Platform vs Module Scope Selection

1. **Use PlatformScope for**:
   - Security requirements
   - Compliance policies
   - Resource governance
   - Organizational standards

2. **Use ModuleScope for**:
   - Application-specific optimization
   - Traffic management
   - Custom observability
   - Performance tuning

### Scope Composition Strategies

1. **Layer Incrementally**: Build complex policies from simple scopes
2. **Avoid Conflicts**: Ensure scopes don't apply conflicting elements
3. **Consider Order**: Some elements may depend on others
4. **Test Combinations**: Validate that scope combinations work correctly

### Targeting Best Practices

1. **Explicit over Implicit**: Prefer explicit component lists when possible
2. **Validate References**: Ensure targeted components exist
3. **Document Targeting Logic**: Explain complex selection criteria
4. **Avoid Over-Broad Scopes**: Don't use "*" unless truly universal

## Scope Anti-Patterns

### Multiple Elements in One Scope

```cue
// Bad: Trying to apply multiple elements
overloadedScope: #Scope & {
    #NetworkPolicy
    #ResourceQuota  // Error: violates single element rule
    appliesTo: "*"
}

// Good: Separate scopes for each concern
networkScope: #Scope & {
    #NetworkPolicy
    networkPolicy: {...}
    appliesTo: "*"
}

quotaScope: #Scope & {
    #ResourceQuota
    resourceQuota: {...}
    appliesTo: "*"
}
```

### Overly Specific Scopes

```cue
// Bad: Too many narrow scopes
frontendPort8080Scope: #Scope & {...}
frontendPort8081Scope: #Scope & {...}
backendPort9090Scope: #Scope & {...}

// Good: Logical grouping
servicePortScope: #Scope & {
    #PortConfiguration
    portConfiguration: {
        frontend: [8080, 8081]
        backend: [9090]
    }
    appliesTo: [frontend, backend]
}
```

### Conflicting Scopes

```cue
// Bad: Conflicting network policies
allowAllScope: #Scope & {
    #NetworkPolicy
    networkPolicy: {allowAll: true}

    appliesTo: [api]
}

denyAllScope: #Scope & {
    #NetworkPolicy
    networkPolicy: {denyAll: true}

    appliesTo: [api]  // Same component, conflicting policies
}

// Good: Coherent policy set
defaultDenyScope: #Scope & {
    #NetworkPolicy
    networkPolicy: {
        defaultAction: "deny"
        allowedSources: ["10.0.0.0/8"]
    }

    appliesTo: [api]
}
```

## Integration with Components

Scopes and components work together through the element system:

```cue
// Components define what runs
webService: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    #Container
    container: {
        name: "web"
        image: "app:latest"
    }

    #Expose
    expose: {
        port: 8080
    }
}

// Scopes define how things run together
productionScope: #PlatformScope & {
    #ProductionReadiness & {
        requirements: {
            minReplicas: 3
            antiAffinity: "required"
            podDisruptionBudget: {
                minAvailable: 2
            }
        }
    }

    appliesTo: [webService]  // Applies production requirements
}

// The platform combines both to create the final deployment
```

## Scope Lifecycle

Understanding how scopes are processed:

### 1. Definition Phase

Scopes are defined with their single element and targeting strategy

### 2. Validation Phase

CUE validates the single element rule and target validity

### 3. Application Phase

Scopes are applied to their target components

### 4. Composition Phase

Multiple scopes affecting the same components are composed

### 5. Platform Transformation

The platform transforms the combined scope elements to platform resources

## Advanced Scope Patterns

### Conditional Application

```cue
// Apply different elements based on environment
envScope: #ModuleScope & {
    if environment == "production" {
        #ProductionOptimization & {...}
    }
    if environment == "development" {
        #DevelopmentTools & {...}
    }

    appliesTo: "*"
}
```

### Dynamic Scope Generation

```cue
// Generate scopes based on team structure
for team in teams {
    "\(team.name)Quota": #PlatformScope & {
        #ResourceQuota & {
            quota: {
                limits: team.resourceLimits
            }
        }
        appliesTo: team.components
    }
}
```

Scopes are the mechanism through which OPM applies cross-cutting concerns while maintaining the element model's consistency. By enforcing the single-element rule, scopes remain focused and composable, allowing platform teams to enforce policies and developers to optimize their applications, all within a type-safe, validated framework. The element-based design ensures that scopes, like components, are portable, predictable, and powerful tools for managing complex deployments.
