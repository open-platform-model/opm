# Components - Core Concepts

## What are Components

Components are specialized element compositions that serve as the primary organizational unit within OPM modules. They are themselves elements (specifically, composite traits) that combine multiple primitive elements to represent either deployable workloads or shared resource collections. This makes components both consumers and providers within the element system.

Think of components as pre-configured element bundles that establish common patterns. A web service component isn't just a container - it's a thoughtful composition of Container, Expose, Replicas, and HealthCheck elements. A database component combines Container, Volume, Secret, and ConfigMap elements. These compositions make complex configurations manageable and reusable.

## Components as Elements

Components are first-class citizens in the OPM system with their own structure:

```cue
#Component: {
    #kind:       "Component"
    #apiVersion: "core.opm.dev/v1alpha1"
    #metadata: {
        #id!: string

        name!: string | *#id

        type!:         #ComponentType
        workloadType?: string
        if type == "workload" {
            workloadType!: #WorkloadTypes
        }
        if type == "resource" {
            if workloadType != _|_ {error("Resource components cannot have workloadType")}
        }

        // Component specific labels and annotations
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

    // TODO add validation to ensure only traits/resources are added based on componentType
    ...
}

#ComponentType: "resource" | "workload"

#WorkloadTypes: "stateless" | "stateful" | "daemon" | "task" | "scheduled-task"
```

This element-based architecture means:

- **Components are composable**: Can be extended with additional elements
- **Components are type-safe**: CUE validates element composition
- **Components are self-documenting**: Metadata describes their purpose and contents
- **Components are portable**: Element abstraction ensures platform independence

## The Two Component Types

Components serve two distinct but complementary roles:

### Workload Components

Deployable units that run containers and provide services:

```cue
webService: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    // Compose workload elements
    #Container
    #Expose
    #Replicas
}
```

**Purpose**: Define runnable services that execute business logic

**Key Elements**: Always include Container trait, plus supporting elements

**Workload Types**:

- `stateless`: Horizontally scalable services without persistent state
- `stateful`: Services requiring stable identity and persistent storage
- `daemon`: Node-level services running on every (selected) node
- `task`: Run-to-completion jobs
- `scheduled-task`: Recurring jobs on a schedule

### Resource Components

Non-deployable element collections that provide shared resources:

```cue
sharedConfig: #Component & {
    #metadata: {
        type: "resource"
        // Note: no workloadType for resource components
    }

    // Compose resource elements only
    #ConfigMap
    #Secret
    #Volume
}
```

**Purpose**: Organize and share resources across multiple workload components

**Key Elements**: Only resource elements (ConfigMap, Secret, Volume) - no Container trait

**Use Cases**: Configuration bundles, credential collections, shared storage definitions

## Component Element Composition

Components compose elements following clear patterns:

### Element Selection

Choose elements based on component needs:

```cue
// Stateless service needs networking and scaling
apiService: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    #Container      // Core workload element
    #Expose         // Networking element
    #Replicas       // Scaling element
    #HealthCheck    // Reliability element
}

// Stateful service needs persistence
database: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateful"
    }

    #Container      // Core workload element
    #Volume         // Storage element
    #Secret         // Credentials element
    #ConfigMap      // Configuration element
}
```

### Element Interaction

Elements within a component can reference each other:

```cue
dataProcessor: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "task"
    }

    // Define volume element
    #Volume
    volumes: {
        workspace: {
            emptyDir: {sizeLimit: "1Gi"}
        }
    }


    // Container element references the volume
    #Container
    container: {
        name: "processor"
        image: "processor:latest"
        volumeMounts: {
            data: volumes.workspace & {mountPath: "/data"}
        }
    }

}
```

## Resource Sharing Between Components

The element model enables flexible resource sharing:

### Direct Element Reference

Components can reference elements from other components:

```cue
// Component A defines configuration
configProvider: #Component & {
    #metadata: {
        type: "resource"
    }

    #ConfigMap
    configMaps: {
        appConfig: {
            data: {
                apiUrl: "https://api.example.com"
                timeout: "30s"
            }
        }
    }
}

// Component B uses Component A's configuration
apiClient: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    #Container
    container: {
        env: {
            API_URL: {
                valueFrom: configProvider.configMaps.appConfig.data.apiUrl
            }
        }
    }
}
```

### Shared Element Patterns

Common patterns for element sharing:

```cue
// Shared volume element
sharedStorage: #Component & {
    #metadata: type: "resource"

    #Volume
    volumes: {
        shared: {
            persistentClaim: {
                size: "10Gi"
                accessMode: "ReadWriteMany"
            }
        }
    }
}

// Multiple components mount the same volume
writer: #Component & {
    #metadata: type: "workload"
    #Container
    container: {
        volumeMounts: {
            data: sharedStorage.volumes.shared & {
                mountPath: "/data"
                readOnly: false
            }
        }
    }
}

reader: #Component & {
    #metadata: type: "workload"
    #Container
    container: {
        volumeMounts: {
            data: sharedStorage.volumes.shared & {
                mountPath: "/data"
                readOnly: true
            }
        }
    }
}
```

## Workload Type Patterns

Each workload type implies specific element compositions:

### Stateless Pattern

```cue
#StatelessPattern: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    // Required elements
    #Container

    // Recommended elements
    #Replicas        // Horizontal scaling
    #Expose          // Service exposure
    #HealthCheck     // Health monitoring
    #UpdateStrategy  // Rolling updates

    // Optional elements
    #ConfigMap       // Configuration
    #Metrics         // Observability
}
```

### Stateful Pattern

```cue
#StatefulPattern: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateful"
    }

    // Required elements
    #Container
    #Volume          // Persistent storage

    // Recommended elements
    #Secret          // Credentials
    #ConfigMap       // Configuration
    #Expose          // Service exposure
    #BackupPolicy    // Data protection

    // Careful with these
    #Replicas             // Ordered scaling only
    replicas: {...}
}
```

### Task Pattern

```cue
#TaskPattern: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "task"
    }

    // Required elements
    #Container

    // Common elements
    #Volume          // Working directory
    #ConfigMap       // Job configuration
    #RetryPolicy     // Failure handling

    // Usually avoid
    // #Expose - Tasks don't serve traffic
    // #Replicas - Tasks run once
}
```

## Component Validation

The element model provides multiple validation layers:

### Type Validation

```cue
#Component: {
    #metadata: {
        // Workload components must have workloadType
        if type == "workload" {
            workloadType!: #WorkloadTypes
        }

        // Resource components cannot have workloadType
        if type == "resource" {
            if workloadType != _|_ {
                error("Resource components cannot have workloadType")
            }
        }
    }
}
```

### Element Compatibility

```cue
#StatefulValidation: #Component & {
    #metadata: {
        if workloadType == "stateful" {
            // Stateful components should have volumes
            #requireVolumes: len(volumes) > 0 |
                error("Stateful components typically require volumes")
        }

        if workloadType == "task" {
            // Tasks shouldn't expose services
            #noExpose: expose == _|_ |
                error("Task components should not expose services")
        }
    }
}
```

### Element Dependency

```cue
#ComponentWithDependencies: #Component & {
    // If using environment from ConfigMap, ConfigMap must exist
    if container.env != _|_ {
        for envVar in container.env {
            if envVar.valueFrom.configMapKeyRef != _|_ {
                #validateConfigMap: configMaps[envVar.valueFrom.configMapKeyRef.name] != _|_ |
                    error("Referenced ConfigMap must be defined in component")
            }
        }
    }
}
```

## Component Examples

### Complete Stateless Web Service

```cue
webApi: #Component & {
    #metadata: {
        #id: "web-api"
        name: "Web API Service"
        type: "workload"
        workloadType: "stateless"

        labels: {
            "app": "web-api"
            "tier": "frontend"
        }
    }

    // Core container element
    #Container
    container: {
        name: "api"
        image: "myapp/api:v2.0"
        ports: {
            http: {
                containerPort: 8080
                protocol: "TCP"
            }
        }
        env: {
            PORT: {value: "8080"}
            LOG_LEVEL: {value: "info"}
        }
        resources: {
            requests: {
                cpu: "100m"
                memory: "128Mi"
            }
            limits: {
                cpu: "500m"
                memory: "512Mi"
            }
        }
    }

    // Networking element
    #Expose
    expose: {
        type: "ClusterIP"
        ports: {
            http: {
                port: 80
                targetPort: 8080
            }
        }
    }

    // Scaling element
    #Replicas
    replicas: {
        replicas: 3
        minReplicas: 2
        maxReplicas: 10
        targetCPUUtilization: 75
    }

    // Health monitoring element
    #HealthCheck
    healthCheck: {
        liveness: {
            httpGet: {
                path: "/health/live"
                port: 8080
            }
            initialDelaySeconds: 30
            periodSeconds: 10
        }
        readiness: {
            httpGet: {
                path: "/health/ready"
                port: 8080
            }
            initialDelaySeconds: 5
            periodSeconds: 5
        }
    }
}
```

### Stateful Database with Elements

```cue
postgres: #Component & {
    #metadata: {
        #id: "postgres-db"
        name: "PostgreSQL Database"
        type: "workload"
        workloadType: "stateful"

        labels: {
            "app": "postgres"
            "tier": "database"
        }
    }

    // Storage element
    #Volume
    volumes: {
        data: {
            persistentClaim: {
                size: "20Gi"
                accessMode: "ReadWriteOnce"
                storageClass: "fast-ssd"
            }
        }
        backups: {
            persistentClaim: {
                size: "50Gi"
                accessMode: "ReadWriteOnce"
                storageClass: "standard"
            }
        }
    }

    // Configuration element
    #ConfigMap
    configMaps: {
        pgConfig: {
            data: {
                "postgresql.conf": """
                    max_connections = 100
                    shared_buffers = 256MB
                    work_mem = 4MB
                    """
                "pg_hba.conf": """
                    host all all 0.0.0.0/0 md5
                    """
            }
        }
    }

    // Credentials element
    #Secret
    secrets: {
        pgCredentials: {
            data: {
                POSTGRES_USER: "dbadmin"
                POSTGRES_PASSWORD: "secure-password"
                POSTGRES_DB: "myapp"
            }
        }
    }

    // Container element with references
    #Container
    container: {
        name: "postgres"
        image: "postgres:14-alpine"

        ports: {
            postgres: {
                containerPort: 5432
            }
        }

        env: {
            POSTGRES_USER: {
                valueFrom: secrets.pgCredentials.data.POSTGRES_USER
            }
            POSTGRES_PASSWORD: {
                valueFrom: secrets.pgCredentials.data.POSTGRES_PASSWORD
            }
            POSTGRES_DB: {
                valueFrom: secrets.pgCredentials.data.POSTGRES_DB
            }
        }

        volumeMounts: {
            data: volumes.data & {
                mountPath: "/var/lib/postgresql/data"
            }
            backups: volumes.backups & {
                mountPath: "/backups"
            }
            config: configMaps.pgConfig & {
                mountPath: "/etc/postgresql"
            }
        }
    }

    // Service element
    #Expose
    expose: {
        type: "ClusterIP"
        ports: {
            postgres: {
                port: 5432
                targetPort: 5432
            }
        }
    }
}
```

### Resource Component for Shared Configuration

```cue
sharedResources: #Component & {
    #metadata: {
        #id: "shared-config"
        name: "Shared Application Resources"
        type: "resource"
        // No workloadType for resource components
    }

    // Configuration element
    #ConfigMap
    configMaps: {
        appConfig: {
            data: {
                API_ENDPOINT: "https://api.example.com"
                FEATURE_FLAGS: "new-ui,dark-mode"
                CACHE_TTL: "3600"
            }
        }

        tlsConfig: {
            data: {
                "ca.crt": "-----BEGIN CERTIFICATE-----..."
                "tls.crt": "-----BEGIN CERTIFICATE-----..."
            }
        }
    }

    // Secrets element
    #Secret
    secrets: {
        apiKeys: {
            data: {
                STRIPE_KEY: "sk_live_..."
                SENDGRID_KEY: "SG...."
                JWT_SECRET: "super-secret-key"
            }
        }
    }

    // Shared volumes element
    #Volume
    volumes: {
        cache: {
            emptyDir: {
                sizeLimit: "2Gi"
                medium: "memory"
            }
        }

        uploads: {
            persistentClaim: {
                size: "100Gi"
                accessMode: "ReadWriteMany"
                storageClass: "nfs"
            }
        }
    }
}
```

## Best Practices

### Component Design

1. **Element-First Thinking**: Design components as element compositions
2. **Single Responsibility**: Each component should have one primary purpose
3. **Explicit Dependencies**: Make element dependencies clear and validated
4. **Appropriate Granularity**: Balance between too many small components and monoliths

### Selection of Elements

1. **Start Minimal**: Begin with essential elements, add others as needed
2. **Follow Patterns**: Use established patterns for each workload type
3. **Validate Compatibility**: Ensure elements work well together
4. **Document Choices**: Explain why specific elements were included

### Resource Organization

1. **Logical Grouping**: Group related resources in resource components
2. **Clear Naming**: Use descriptive names for resource elements
3. **Sharing Strategy**: Plan how resources will be shared between components
4. **Version Carefully**: Consider impact when updating shared resources

### Workload Type Selection

1. **Stateless by Default**: Choose stateless unless state is required
2. **Stateful with Care**: Understand implications of persistent state
3. **Tasks for Jobs**: Use tasks for batch processing and one-time operations
4. **Daemons for System**: Reserve daemons for node-level services

## Component Anti-Patterns

### Avoid Element Sprawl

```cue
// Bad: Too many unrelated elements
kitchenSink: #Component & {
    #Container}
    #Volume
    #ConfigMap
    #Secret
    #Expose
    #NetworkPolicy
    #ResourceQuota
    #PodDisruptionBudget
    // ... 20 more elements
}

// Good: Only necessary elements
focused: #Component & {
    #Container
    #Expose
    #HealthCheck
}
```

### Avoid Circular Dependencies

```cue
// Bad: Components depending on each other
componentA: #Component & {
    #Container
    container: {
        env: {
            B_URL: {valueFrom: componentB.expose.url}
        }
    }
}

componentB: #Component & {
    #Container
    container: {
        env: {
            A_URL: {valueFrom: componentA.expose.url}
        }
    }
}

// Good: Shared configuration
config: #Component & {
    #metadata: type: "resource"
    #ConfigMap
    configMaps: endpoints: {
        data: {
            A_URL: "http://a-service"
            B_URL: "http://b-service"
        }
    }
}
```

### Avoid Type Confusion

```cue
// Bad: Workload component without Container
brokenWorkload: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }
    #ConfigMap  // No Container element!
}

// Bad: Resource component with Container
brokenResource: #Component & {
    #metadata: {
        type: "resource"
    }
    #Container  // Resource components don't run containers!
}
```

## Integration with Scopes

Components interact with scopes through shared elements:

```cue
// Scope defines network policy element
internalNetwork: #Scope & {
    #NetworkPolicy & {
        policy: {
            allowInternal: true
            denyExternal: true
        }
    }

    appliesTo: [frontend, backend, database]
}

// Components are affected by scope elements
frontend: #Component & {
    #metadata: {
        type: "workload"
        workloadType: "stateless"
    }

    #Container
    #Expose
    // Automatically constrained by internalNetwork scope
}
```

Components are the building blocks of OPM applications, but they achieve their power through element composition. By understanding components as element collections rather than monolithic units, developers can create flexible, reusable, and maintainable module architectures. The element model ensures that whether a component represents a simple stateless service or a complex stateful system, it remains portable, type-safe, and platform-independent.
