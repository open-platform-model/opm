# OPM V1 Examples

This directory contains examples demonstrating the Open Platform Model V1 architecture. Each example is in its own file for easy reference and reuse.

## Directory Structure

```text
examples/
├── components/     # Individual component examples (8 files)
├── modules/        # Module workflow examples (2 files)
├── bundles/        # Bundle workflow examples (1 file)
└── README.md       # This file
```

## Component Examples

**Location**: `components/`

Individual component examples showing different workload patterns using Units and Traits.

### Basic Components

- **[basic_component.cue](components/basic_component.cue)** - Simple nginx component
  - Units: Container, Volumes
  - Traits: Replicas
  - Shows basic composition with persistent storage

### Workload Patterns

- **[stateful_workload.cue](components/stateful_workload.cue)** - PostgreSQL stateful workload
  - Units: Container
  - Traits: Replicas, RestartPolicy, UpdateStrategy, HealthCheck, InitContainers
  - 3 replicas with rolling updates and health probes

- **[daemon_workload.cue](components/daemon_workload.cue)** - Node exporter daemon
  - Units: Container
  - Traits: RestartPolicy, UpdateStrategy, HealthCheck
  - Runs on all nodes (no replicas trait)

- **[task_workload.cue](components/task_workload.cue)** - Data migration job
  - Units: Container
  - Traits: RestartPolicy (OnFailure), JobConfig, InitContainers
  - One-time execution with backoff limits and TTL

- **[scheduled_task_workload.cue](components/scheduled_task_workload.cue)** - Database backup cron job
  - Units: Container
  - Traits: RestartPolicy (OnFailure), CronJobConfig, InitContainers
  - Daily 2 AM schedule with concurrency control

### Database Examples

- **[simple_database_mongodb.cue](components/simple_database_mongodb.cue)** - MongoDB with persistence
  - Units: Container, Volumes
  - Traits: Replicas, RestartPolicy, HealthCheck
  - 50Gi persistent storage with health checks

- **[simple_database_postgres.cue](components/simple_database_postgres.cue)** - PostgreSQL database
  - Units: Container, Volumes
  - Traits: Replicas, RestartPolicy, HealthCheck
  - 100Gi persistent storage

- **[simple_database_redis.cue](components/simple_database_redis.cue)** - Redis cache
  - Units: Container
  - Traits: Replicas, RestartPolicy, HealthCheck
  - In-memory cache without persistence

## Module Examples

**Location**: `modules/`

Complete module workflow examples demonstrating the three-layer architecture: ModuleDefinition → Module → ModuleRelease.

- **[basic_module.cue](modules/basic_module.cue)** - Basic module workflow
  - Shows ModuleDefinition with value schema (constraints only)
  - Shows Module (flattened/optimized form)
  - Shows ModuleRelease with concrete values
  - Simple web + database application

- **[multi_tier_module.cue](modules/multi_tier_module.cue)** - Multi-tier application
  - 4 components: database, log agent, setup job, backup job
  - Demonstrates all new workload traits
  - Production and staging deployments
  - Full parameterization with value schema

## Bundle Examples

**Location**: `bundles/`

Bundle packaging and distribution examples.

- **[bundle_workflow.cue](bundles/bundle_workflow.cue)** - Bundle lifecycle
  - Bundle creation and composition
  - Multi-module bundles
  - Distribution patterns

## Usage

### Validate Examples

```bash
# Validate all examples
cd /path/to/opm/v1/examples
cue vet ./...

# Validate specific category
cue vet ./components/
cue vet ./modules/
cue vet ./bundles/

# Validate specific file
cue vet ./components/stateful_workload.cue
```

### Format Examples

```bash
# Format all examples
cue fmt ./...

# Format specific file
cue fmt ./components/daemon_workload.cue
```

### Evaluate Examples

```bash
# Evaluate a component
cue eval ./components/stateful_workload.cue -e exampleStatefulWorkload

# Evaluate a module release
cue eval ./modules/multi_tier_module.cue -e exampleNewTraitsModuleReleaseProduction

# Export as JSON
cue export ./components/basic_component.cue -e exampleComponent

# Export as YAML
cue export ./components/task_workload.cue -e exampleTaskWorkload --out yaml
```

## Key Patterns

### Component Composition

Components are composed by including Units (what exists) and Traits (how it behaves):

```cue
myComponent: core.#ComponentDefinition & {
    metadata: name: "my-component"

    // Include units and traits
    workload_units.#Container
    workload_traits.#Replicas
    workload_traits.#HealthCheck

    // Define concrete spec
    spec: {
        container: {
            name:  "app"
            image: "myapp:latest"
        }
        replicas: 3
        healthCheck: {
            readinessProbe: { ... }
        }
    }
}
```

### Module Three-Layer Pattern

1. **ModuleDefinition** - Portable blueprint with constraints (no concrete values)
2. **Module** - Flattened optimized form ready for binding
3. **ModuleRelease** - Deployed instance with concrete values

```cue
// 1. Definition (constraints)
definition: core.#ModuleDefinition & {
    #components: { web: { ... } }
    #values: { image!: string }  // Required, no default
}

// 2. Module (flattened)
module: core.#Module & {
    #components: { web: { spec: { image: #values.image } } }
    #values: { image!: string }
}

// 3. Release (concrete values)
release: core.#ModuleRelease & {
    module: module
    values: { image: "nginx:1.21" }  // Concrete value provided
}
```

### Trait Categories

**Workload Traits**:

- `Replicas` - Number of instances
- `RestartPolicy` - Always/OnFailure/Never
- `UpdateStrategy` - RollingUpdate/Recreate/OnDelete
- `HealthCheck` - Liveness and readiness probes
- `JobConfig` - Job-specific settings (completions, parallelism, etc.)
- `CronJobConfig` - Scheduled job settings (schedule, concurrency, etc.)
- `InitContainers` - Initialization containers
- `SidecarContainers` - Sidecar containers

**Storage Traits**:

- `Volumes` - Persistent and ephemeral volumes

## File Organization

Each example is self-contained in its own file:

- One example per file for easy reference
- All files use `package examples`
- Clear naming convention: `{pattern}_{detail}.cue`
- Focused examples demonstrating specific patterns

## Related Documentation

- [V1 Core Documentation](../core/)
- [V1 Blueprints](../blueprints/)
- [V1 Units](../units/)
- [V1 Traits](../traits/)
- [V1 Schemas](../schemas/)
