# ModuleDefinition - Lifecycle

## What is a ModuleDefinition

ModuleDefinitions are the developer-authored blueprints for modules. They define the core module structure including components, developer-controlled scopes, and configurable values that end users can override. This is the primary artifact developers create and maintain, representing the portable module design without platform-specific concerns.

ModuleDefinitions serve as the **source of truth** for module logic and behavior. They contain everything needed to understand, deploy, and configure a module while remaining completely portable across different OPM-compliant platforms.

## Role in the Module Lifecycle

ModuleDefinitions represent the **developer domain** in OPM's separation of concerns:

```mermaid
graph LR
    DEV[Developer] -->|Creates & Maintains| MD[ModuleDefinition]
    MD[ModuleDefinition] -->|Packaged & Distributed| MOD[Module]
    PLT[Platform Team] -->|Curates| MOD
    PLT[Platform Team] -->|Adds Policies| MOD
    PLT[Platform Team] -->|Adds Components| MOD
    USR[End User] -->|Selects from Catalog| MOD
    USR[End User] -->|Deploys with Overrides| MR[ModuleRelease]
    MOD -->|Referenced by| MR[ModuleRelease]
    MR -->|Deployed to| ENV[Environment]

    style MD fill:#e1f5fe
    style DEV fill:#e1f5fe
```

**Developer Ownership**: Developers own the ModuleDefinition and all its contents - components, module scopes, and configurable values.

**Platform Independence**: ModuleDefinitions must work on any OPM-compliant platform without modification.

**User Configurability**: Values provide end users with configuration flexibility without exposing internal complexity.

## ModuleDefinition Structure

### Core Elements

1. **Metadata**: Name, version, description, and labels
2. **Components**: The module's building blocks (workloads and resources)
3. **Module Scopes**: Developer-controlled cross-cutting concerns
4. **Values**: User-configurable parameters with defaults and validation

### Structure in CUE

```cue
#ModuleDefinition: {
    #apiVersion: "core.opm.dev/v1"
    #kind:       "ModuleDefinition"
    #metadata: {
        name!:        #NameType
        version!:     #VersionType
        description?: string

        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    components: [Id=string]: #Component & {
        #metadata: #id: Id
    }

    // Developer-defined module scopes
    scopes?: [Id=string]: #Scope & {
        #metadata: #id: Id
    }

    // User-configurable values (like Helm values)
    // ALL fields MUST be optional to allow override
    // MUST be OpenAPIv3 compliant
    values: {
        // Example structure (all optional with defaults):
        // replicas?:     uint | *3
        // image?: {
        //     repository?: string | *"nginx"
        //     tag?:        string | *"1.0.0"
        // }
        ...
    }

    #status?: {
        componentCount: len(components)
        scopeCount:     len(scopes)
    }
}
```

## ModuleDefinition Rules

### Value Rules

1. **Sane Defaults**: Values SHOULD be set to defaults that create a deployable module without user modification
2. **OpenAPIv3 Compliance**: Values MUST be OpenAPIv3 compliant with proper types, constraints, and descriptions
3. **Value Paths**: Each value MUST have a clear injection path to component fields via CUE unification
4. **No Secret Values**: MUST NOT expose secret data through values (passwords, keys, tokens)

### Portability Rules

1. **Platform Agnostic**: MUST NOT reference platform-specific resources (ServiceAccounts, StorageClasses, node selectors)
2. **No Platform Resources**: ModuleDefinitions MUST NOT reference platform-specific resources
3. **Clear Separation**: Platform concerns belong in PlatformScopes, not in ModuleDefinitions

### Versioning Rules

1. **Semantic Versioning**: Version changes SHOULD follow semver (breaking = major, features = minor)
2. **Backward Compatibility**: Schema changes MUST be backward compatible within major versions

## Value Configuration System

The values system allows end users to configure modules without understanding internal complexity:

### Value Flow

```shell
ModuleDefinition defaults → Module overrides → ModuleRelease overrides → Final Configuration
```

### Value Injection

Values are injected into components through CUE unification:

```cue
// In ModuleDefinition
values: {
    replicas?: uint | *3
    image?: {
        repository?: string | *"nginx"
        tag?:        string | *"latest"
    }
}

// Component uses values
webServer: #WorkloadComponent & {
    traits.#Container
    traits.#Replicas

    container: {
        name: "web"
        image: {
            repository: values.image.repository
            tag:        values.image.tag
        }
    }

    replicas: values.replicas
}
```

### Value Documentation

Every value should be self-documenting through CUE constraints and comments:

```cue
values: {
    // Number of web server replicas (1-10)
    replicas?: uint & >=1 & <=10 | *3

    // Container image configuration
    image?: {
        // Container registry and repository
        repository?: string | *"nginx"
        // Image tag (use 'latest' for development only)
        tag?: string & =~"^[a-zA-Z0-9][a-zA-Z0-9._-]*$" | *"1.21"
    }

    // Database configuration
    database?: {
        // Database name (alphanumeric only)
        name?: string & =~"^[a-zA-Z0-9]+$" | *"myapp"
        // Maximum number of connections (1-1000)
        maxConnections?: uint & >=1 & <=1000 | *100
    }
}
```

## ModuleDefinition Examples

### Simple Web Module

```cue
package webApp

import (
    core "core.opm.dev/v1alpha1"
    traits "traits.opm.dev/v1alpha1"
)

core.#ModuleDefinition

#metadata: {
    name: "simple-web-app"
    version: "1.0.0"
    description: "A simple web module with configurable scaling"
    labels: {
        category: "web"
        tier: "frontend"
    }
}

components: {
    webServer: #WorkloadComponent & {
        #metadata: {
            type: "Workload"
            workloadType: "Stateless"
        }
        traits.#Container
        traits.#Expose
        traits.#Replicas
        traits.#UpdateStrategy

        container: {
            name: "web"
            image: {
                repository: values.image.repository
                tag:        values.image.tag
            }
            ports: [{
                name: "http"
                containerPort: 8080
            }]
            env: [
                {
                    name: "PORT"
                    value: "8080"
                },
                {
                    name: "ENV"
                    value: values.environment
                }
            ]
        }

        expose: {
            type: "ClusterIP"
            ports: [{
                name: "http"
                port: 80
                targetPort: 8080
            }]
        }

        replicas: values.replicas

        updateStrategy: {
            type: "RollingUpdate"
            rollingUpdate: {
                maxSurge: 1
                maxUnavailable: 0
            }
        }
    }
}

values: {
    // Number of web server replicas (1-10)
    replicas?: uint & >=1 & <=10 | *3

    // Container image configuration
    image?: {
        repository?: string | *"nginx"
        tag?:        string | *"1.21"
    }

    // Deployment environment
    environment?: "development" | "staging" | "production" | *"production"
}

```

### Full-Stack Module with Database

```cue
package ecommerce

import (
    core "core.opm.dev/v1alpha1"
    traits "traits.opm.dev/v1alpha1"
)

core.#ModuleDefinition

#metadata: {
    name: "ecommerce-platform"
    version: "2.1.0"
    description: "Full-stack e-commerce module with database"
    labels: {
        category: "ecommerce"
        complexity: "high"
    }
}

components: {
    frontend: #WorkloadComponent & {
        #metadata: {
            type: "Workload"
            workloadType: "Stateless"
        }
        traits.#Container
        traits.#Expose
        traits.#Replicas

        container: {
            name: "frontend"
            image: {
                repository: values.frontend.image.repository
                tag:        values.frontend.image.tag
            }
            ports: [{
                name: "http"
                containerPort: 3000
            }]
            env: [{
                name: "API_URL"
                value: "http://backend"
            }]
        }

        expose: {
            type: "ClusterIP"
            ports: [{
                name: "http"
                port: 80
                targetPort: 3000
            }]
        }

        replicas: values.frontend.replicas
    }

    backend: #WorkloadComponent & {
        #metadata: {
            type: "Workload"
            workloadType: "Stateless"
        }
        traits.#Container
        traits.#Expose
        traits.#Replicas
        traits.#ConfigMap

        container: {
            name: "backend"
            image: {
                repository: values.backend.image.repository
                tag:        values.backend.image.tag
            }
            ports: [{
                name: "http"
                containerPort: 8080
            }]
            env: [
                {
                    name: "DATABASE_URL"
                    value: "postgres://\(values.database.user):\(values.database.password)@database:5432/\(values.database.name)"
                },
                {
                    name: "MAX_CONNECTIONS"
                    valueFrom: configMaps.config.data.maxConnections
                }
            ]
        }

        expose: {
            type: "ClusterIP"
            ports: [{
                name: "http"
                port: 80
                targetPort: 8080
            }]
        }

        replicas: values.backend.replicas

        configMaps: {
            config: {
                data: {
                    maxConnections: "\(values.database.maxConnections)"
                    cacheSize: "\(values.caching.size)"
                }
            }
        }
    }

    database: #WorkloadComponent & {
        #metadata: {
            type: "Workload"
            workloadType: "Stateful"
        }
        traits.#Container
        traits.#Volumes
        traits.#Secret
        traits.#Expose

        container: {
            name: "postgres"
            image: {
                repository: "postgres"
                tag: "14"
            }
            ports: [{
                name: "postgres"
                containerPort: 5432
            }]
            env: [
                {
                    name: "POSTGRES_DB"
                    value: values.database.name
                },
                {
                    name: "POSTGRES_USER"
                    value: values.database.user
                },
                {
                    name: "POSTGRES_PASSWORD"
                    valueFrom: secrets.credentials.data.password
                }
            ]
            volumeMounts: [
                volumes.data & {mountPath: "/var/lib/postgresql/data"}
            ]
        }

        volumes: {
            data: {
                type: "persistentVolume"
                size: values.database.storage.size
                accessMode: "ReadWriteOnce"
            }
        }

        secrets: {
            credentials: {
                data: {
                    password: values.database.password
                }
            }
        }

        expose: {
            type: "ClusterIP"
            ports: [{
                name: "postgres"
                port: 5432
                targetPort: 5432
            }]
        }
    }

    sharedConfig: #ResourceComponent & {
        #metadata: {
            type: "Resource"
        }
        traits.#ConfigMap

        configMaps: {
            appSettings: {
                data: {
                    environment: values.environment
                    logLevel: values.logging.level
                    enableMetrics: "\(values.monitoring.enabled)"
                }
            }
        }
    }
}

scopes: {
    apiRouting: #ModuleScope & {
        #metadata: {
            immutable: false
        }
        traits.#HTTPRoute

        httpRoute: {
            hosts: [values.ingress.host]
            rules: [{
                matches: [{
                    path: {
                        type: "PathPrefix"
                        value: "/api"
                    }
                }]
                backendRefs: [{
                    name: "backend"
                    port: 80
                }]
            }, {
                matches: [{
                    path: {
                        type: "PathPrefix"
                        value: "/"
                    }
                }]
                backendRefs: [{
                    name: "frontend"
                    port: 80
                }]
            }]
        }

        appliesTo: [frontend, backend]
    }
}

values: {
    // Environment configuration
    environment?: "development" | "staging" | "production" | *"production"

    // Frontend configuration
    frontend?: {
        image?: {
            repository?: string | *"ecommerce/frontend"
            tag?:        string | *"v2.1.0"
        }
        replicas?: uint & >=1 & <=10 | *2
    }

    // Backend configuration
    backend?: {
        image?: {
            repository?: string | *"ecommerce/backend"
            tag?:        string | *"v2.1.0"
        }
        replicas?: uint & >=1 & <=20 | *3
    }

    // Database configuration
    database?: {
        name?:     string & =~"^[a-zA-Z0-9]+$" | *"ecommerce"
        user?:     string & =~"^[a-zA-Z0-9]+$" | *"ecommerce_user"
        password?: string & strings.MinRunes(8) | *"changeme123"
        maxConnections?: uint & >=10 & <=500 | *100
        storage?: {
            size?: string | *"20Gi"
        }
    }

    // Caching configuration
    caching?: {
        size?: string | *"512Mi"
    }

    // Ingress configuration
    ingress?: {
        host?: string | *"ecommerce.example.com"
    }

    // Monitoring configuration
    monitoring?: {
        enabled?: bool | *true
    }

    // Logging configuration
    logging?: {
        level?: "debug" | "info" | "warn" | "error" | *"info"
    }
}
```

## Best Practices

### ModuleDefinition Design

1. **Sane Defaults**: Provide defaults that create a working module without user input
2. **Clear Value Names**: Use descriptive, hierarchical value names that reflect their purpose
3. **Appropriate Validation**: Add constraints that prevent invalid configurations
4. **Component Organization**: Group related functionality into logical components
5. **Resource Sharing**: Use resource components for shared configuration and secrets

### Value Configuration

1. **User-Centric**: Design values from the end-user perspective, not internal implementation
2. **Reasonable Constraints**: Add validation that prevents common misconfigurations
3. **Clear Documentation**: Document each value's purpose, impact, and valid ranges
4. **Hierarchical Structure**: Organize values logically to match user mental models
5. **Environment Awareness**: Consider different needs for development vs production

### Portability Considerations

1. **Avoid Platform Resources**: Never reference Kubernetes-specific resources directly
2. **Use Traits**: Express all capabilities through traits to maintain abstraction
3. **No Platform Assumptions**: Don't assume specific platform features or behaviors
4. **Test Across Platforms**: Validate ModuleDefinitions work on different OPM platforms

### Versioning Strategy

1. **Semantic Versioning**: Use semver for predictable upgrade paths
2. **Backward Compatibility**: Maintain compatibility within major versions
3. **Clear Change Logs**: Document what changed between versions
4. **Migration Guides**: Provide guidance for breaking changes

ModuleDefinitions serve as the foundation of portable, configurable modules in OPM. They enable developers to create modules that work across platforms while providing end users with the configuration flexibility they need without exposing unnecessary complexity.
