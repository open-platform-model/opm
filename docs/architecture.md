# OPM Architecture

Open Platform Model (OPM) is a way to define, compose, and deploy applications using simple building blocks. Instead of writing platform-specific configuration, you describe what your application needs and OPM handles the rest.

## How It Works

OPM uses three types of building blocks to describe your application:

| Building Block | What It Does | Example |
|----------------|--------------|---------|
| **Resource** | Defines what gets deployed | Container, Volume, ConfigMap |
| **Trait** | Configures how it behaves | Replicas, HealthCheck, Expose |
| **Policy** | Enforces rules it must follow | Encryption, NetworkRules, ResourceQuota |

You combine these blocks into **Components**, group components into **Modules**, and deploy modules as **Releases**.

```
Resources + Traits + Policies → Component → Module → Release → Running App
```

## Building Blocks

### Resources: What Gets Deployed

A **Resource** is something that must exist in your environment. Every component needs at least one Resource.

```cue
// Define a container workload
#components: {
    api: {
        #Container  // This is a Resource

        spec: container: {
            image: "myapp:v1.0"
            ports: [{containerPort: 8080}]
        }
    }
}
```

Common Resources:

- `#Container` - A containerized application
- `#Volume` - Persistent storage
- `#ConfigMap` - Configuration data
- `#Secret` - Sensitive configuration

### Traits: How It Behaves

A **Trait** modifies how a Resource operates. Traits are optional and can be mixed and matched.

```cue
#components: {
    api: {
        #Container
        #Replicas    // Scale to multiple instances
        #HealthCheck // Monitor application health
        #Expose      // Make it accessible

        spec: {
            container: {image: "myapp:v1.0"}
            replicas: 3
            healthCheck: {
                liveness: {httpGet: {path: "/health", port: 8080}}
            }
            expose: {type: "LoadBalancer"}
        }
    }
}
```

Common Traits:

- `#Replicas` - Number of instances to run
- `#HealthCheck` - Liveness and readiness probes
- `#Expose` - Network exposure (ClusterIP, LoadBalancer, etc.)
- `#RestartPolicy` - What happens when containers fail
- `#ResourceLimit` - CPU and memory allocation

### Policies: Rules It Must Follow

A **Policy** enforces constraints that your application must comply with. Unlike Traits (which configure), Policies enforce.

```cue
#components: {
    api: {
        #Container
        #Replicas
        #SecurityContext  // Policy: security requirements

        spec: {
            container: {image: "myapp:v1.0"}
            replicas: 3
            securityContext: {
                runAsNonRoot: true
                allowPrivilegeEscalation: false
            }
        }
    }
}
```

Policies have enforcement rules:

- **When**: `deployment` (before deploy), `runtime` (while running), or `both`
- **Action**: `block` (reject), `warn` (log warning), or `audit` (record for review)

Common Policies:

- `#SecurityContext` - Container security requirements
- `#Encryption` - Data encryption requirements
- `#ResourceQuota` - Maximum resource consumption
- `#NetworkRules` - Network traffic rules

### The Difference: Trait vs Policy

Both add configuration to your component, but they serve different purposes:

| | Trait | Policy |
|---|-------|--------|
| **Purpose** | Configure behavior | Enforce rules |
| **Required?** | Optional | Depends on platform |
| **Failure** | Misconfiguration | Violation (blocked/warned) |
| **Example** | "Run 3 replicas" | "Must not run as root" |

Think of it this way:

- **Trait**: "I want my app to scale to 3 instances" (your preference)
- **Policy**: "Your app must enable encryption" (platform requirement)

## Blueprints: Pre-Built Patterns

**Blueprints** bundle Resources and Traits into reusable patterns. Instead of assembling blocks yourself, use a Blueprint that encodes best practices.

```cue
// Without Blueprint - manual assembly
api: {
    #Container
    #Replicas
    #HealthCheck
    #RestartPolicy

    spec: {
        container: {image: "myapp:v1.0"}
        replicas: 3
        // ... more config
    }
}

// With Blueprint - use a proven pattern
api: {
    #StatelessWorkload  // Bundles Container + Replicas + HealthCheck + RestartPolicy

    spec: statelessWorkload: {
        container: {image: "myapp:v1.0"}
        replicas: 3
    }
}
```

Common Blueprints:

- `#StatelessWorkload` - Scalable apps without persistent state
- `#StatefulWorkload` - Apps needing stable identity and storage
- `#DaemonWorkload` - One instance per node
- `#TaskWorkload` - Run-to-completion jobs
- `#ScheduledTaskWorkload` - Cron-style scheduled jobs

## Components, Modules, and Releases

### Component

A **Component** is a logical part of your application built from Resources, Traits, and Policies.

```cue
#components: {
    frontend: {...}
    api: {...}
    database: {...}
}
```

### Module

A **Module** packages your components together with configurable values.

```cue
#Module: {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "MyApp"
        version:    "1.0.0"
    }

    #components: {
        frontend: {...}
        api: {...}
        database: {...}
    }

    // Values users can configure
    #values: {
        replicas: int | *3
        image: {
            tag: string | *"latest"
        }
    }
}
```

### Release

A **Release** deploys a Module with specific values to a target environment.

```cue
#ModuleRelease: {
    metadata: {
        name: "my-app-production"
        namespace: "production"
    }

    module: "my-app@1.0.0"

    values: {
        replicas: 5
        image: tag: "v1.2.3"
    }
}
```

## Scopes: Cross-Cutting Concerns

**Scopes** apply Policies across multiple components. Instead of adding a Policy to each component, define it once in a Scope.

```cue
#scopes: {
    "production-security": {
        #NetworkRules
        #Encryption

        // Apply to all components with this label
        appliesTo: componentLabels: {
            "env": "production"
        }

        spec: {
            networkRules: {
                "deny-external": {
                    action: "deny"
                    from: [{component: "external"}]
                }
            }
            encryption: {
                atRest: true
                inTransit: true
            }
        }
    }
}
```

## Policy Levels

Policies can apply at three levels:

| Level | Applies To | Example Use Case |
|-------|------------|------------------|
| **Component** | Single component | "This database must have backups enabled" |
| **Scope** | Group of components | "All production services must use mTLS" |
| **Module** | Entire module at runtime | "Enable audit logging for this module" |

Component and Scope policies are validated when you define your module. Module-level policies describe runtime requirements that the platform enforces after deployment.

## Putting It Together

Here's a complete example:

```cue
package myapp

import (
    opm "opmodel.dev/core@v0"
    workload "opmodel.dev/blueprints/workload@v0"
    security "opmodel.dev/policies/security@v0"
    network "opmodel.dev/policies/network@v0"
)

#MyApp: opm.#Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "MyApp"
        version:    "1.0.0"
    }

    // Components
    #components: {
        api: workload.#StatelessWorkload & {
            security.#SecurityContext

            spec: {
                statelessWorkload: {
                    container: {
                        image: "myapp/api:\(#values.image.tag)"
                        ports: [{containerPort: 8080}]
                    }
                    replicas: #values.replicas
                }
                securityContext: {
                    runAsNonRoot: true
                }
            }
        }

        worker: workload.#StatelessWorkload & {
            spec: statelessWorkload: {
                container: {
                    image: "myapp/worker:\(#values.image.tag)"
                }
                replicas: #values.workerReplicas
            }
        }
    }

    // Cross-cutting policies
    #scopes: {
        "internal-network": network.#NetworkRules & {
            appliesTo: all: true
            spec: networkRules: {
                "allow-internal": {
                    action: "allow"
                    from: [{component: "api"}, {component: "worker"}]
                }
            }
        }
    }

    // Configurable values
    #values: {
        replicas:       int | *3
        workerReplicas: int | *2
        image: {
            tag: string | *"latest"
        }
    }
}
```

## Quick Reference

### Mental Model

```
Resource  = What exists (Container, Volume)
Trait     = How it behaves (Replicas, HealthCheck)
Policy    = Rules to follow (Encryption, SecurityContext)
Blueprint = Pre-built pattern (StatelessWorkload)
Component = Part of your app (api, database)
Scope     = Where policies apply (production, public-facing)
Module    = Complete application package
Release   = Deployed instance
```

### Definition Flow

```
┌─────────────────────────────────────────────────────────┐
│                        Module                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Components                                       │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐         │   │
│  │  │Resource │  │ Trait   │  │ Policy  │         │   │
│  │  │Container│ +│Replicas │ +│Security │ = api   │   │
│  │  └─────────┘  └─────────┘  └─────────┘         │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Scopes (cross-cutting policies)                 │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Values (configurable parameters)                │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    ModuleRelease                        │
│  module: "my-app@1.0.0"                                │
│  namespace: "production"                                │
│  values: {replicas: 5, image: {tag: "v1.2.3"}}        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
                    Running Application
```

## Next Steps

- See [Definition Types](../../core/docs/definition-types.md) for detailed schema documentation
- Browse the [Catalog](../../catalog/) for available Resources, Traits, and Policies
- Check [Examples](../examples/) for complete module examples
