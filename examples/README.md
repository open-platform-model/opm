# OPM Examples

This directory contains example OPM module definitions, modules, and provider implementations demonstrating real-world usage patterns.

---

## Quick Start

### Using the Examples Tool

The easiest way to work with examples:

```bash
# List all available examples
cue cmd list

# Show a module structure
cue cmd show -t name=myApp

# Export a module as YAML
cue cmd export -t name=myApp -t format=yaml

# Export a module as JSON
cue cmd export -t name=myApp -t format=json

# Show module values
cue cmd values -t name=myApp

# Show module components
cue cmd components -t name=myApp

# Validate all examples
cue cmd validate

# Export to file
cue cmd export:file -t name=myApp -t format=yaml -t output=myapp.yaml

# Export all modules
cue cmd export:all
```

### Manual CUE Commands

You can also use CUE directly:

```bash
# Validate examples
cue vet -c=false .

# Export specific module
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp --out yaml

# Export just components
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.components --out yaml

# Evaluate (shows structure with incomplete values)
cue eval ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp
```

---

## Available Examples

### 1. Simple Application (`myAppDefinition` → `myApp`)

**Location**: [example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue](example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue) (lines 12-160)

A simple web application with database:

- **Frontend**: StatelessWorkload with volume
- **Database**: SimpleDatabase composite (PostgreSQL)
- **Platform Extension**: Audit logging component added by platform

**Features Demonstrated**:

- Basic component composition
- Volume management
- Value parameterization
- Platform-added components

**Try it**:

```bash
# View the module
cue cmd show -t name=myApp

# See values
cue cmd values -t name=myApp

# Export components
cue cmd components -t name=myApp

# Export full module
cue cmd export -t name=myApp -t format=yaml > myapp.yaml
```

**Key Concepts**:

- ModuleDefinition with constraints-only values
- Module with concrete values
- Component using StatelessWorkload + Volume
- Component using SimpleDatabase composite

---

### 2. E-commerce Application (`ecommerceAppDefinition` → `ecommerceApp`)

**Location**: [example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue](example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue) (lines 162-398)

Complete e-commerce platform with multiple tiers:

- **Frontend**: Stateless web app with replicas and health checks
- **Database**: Stateful PostgreSQL with persistent storage
- **Order Processor**: Task-based batch processing
- **Monitoring**: Platform-added observability with sidecars

**Features Demonstrated**:

- Multi-component application
- Health checks (liveness, readiness)
- Replica configuration
- Stateful workloads with volumes
- Task workloads
- Sidecar containers
- Value override flow (dev → prod)

**Try it**:

```bash
# View frontend component
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e ecommerceApp.components.frontend --out yaml

# View database component
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e ecommerceApp.components.database --out yaml

# See production overrides
cue cmd values -t name=ecommerceApp
```

**Key Concepts**:

- StatelessWorkload with HealthCheck and Replicas
- StatefulWorkload with Volume
- TaskWorkload with RestartPolicy
- SidecarContainers modifier
- Platform value overrides (replicas: 3 → 5, storage: 50Gi → 100Gi)

---

### 3. Monitoring Stack (`monitoringStackDefinition` → `monitoringStack`)

**Location**: [example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue](example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue) (lines 400-573)

Observability stack with metrics and logging:

- **Metrics Server**: Prometheus with persistent storage
- **Log Collector**: Fluentd as DaemonWorkload
- **Alert Manager**: Stateless alerting service

**Features Demonstrated**:

- DaemonWorkload (runs on every node)
- ConfigMap volumes
- Multiple volume types (PersistentClaim + ConfigMap)
- Production scaling (replicas, storage)

**Try it**:

```bash
# View metrics server
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e monitoringStack.components.metricsServer --out yaml

# View log collector (daemon)
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e monitoringStack.components.logCollector --out yaml

# See production configuration
cue cmd values -t name=monitoringStack
```

**Key Concepts**:

- DaemonWorkload element
- Multiple volume types in single component
- ConfigMap as volume
- High availability configuration

---

### 4. Kubernetes Provider (`#KubernetesProvider`)

**Location**: [example_provider.cue](example_provider.cue)

Example provider implementation showing:

- Provider metadata and capabilities
- Transformer registration
- Component-to-resource transformation
- Compatibility validation

**Features Demonstrated**:

- Provider definition structure
- Transformer requirements (required/optional elements)
- Platform capability declaration
- Module compatibility checking

**Try it**:

```bash
# View provider structure
cue eval ./example_provider.cue -e '#KubernetesProvider'

# View deployment transformer
cue eval ./example_provider.cue -e '#DeploymentTransformer'
```

**Key Concepts**:

- Provider transformers
- Element requirement matching
- Platform capability detection

---

### 5. Catalog Validation

**Location**: [example_catalog_validation.cue](example_catalog_validation.cue)

Examples of element catalog validation:

- Element registry structure
- Compatibility checks
- Element discovery

**Try it**:

```bash
cue vet -c=false ./example_catalog_validation.cue
```

---

## Understanding Example Structure

### ModuleDefinition vs Module

**ModuleDefinition** (Template):

```cue
myAppDefinition: opm.#ModuleDefinition & {
    #metadata: {...}
    components: {...}

    // CONSTRAINTS ONLY (no defaults)
    values: {
        image!: string      // Required
        replicas: int       // Type constraint
    }
}
```

**Module** (Instance):

```cue
myApp: opm.#Module & {
    #metadata: {...}
    moduleDefinition: myAppDefinition

    // Platform can add components
    components: {
        monitoring: {...}
    }

    // CONCRETE VALUES
    values: {
        image: "nginx:1.25"  // Satisfies required
        replicas: 5          // Satisfies int constraint
    }
}
```

**ModuleRelease** (Deployment):

```cue
myAppRelease: opm.#ModuleRelease & {
    module: myApp
    provider: #KubernetesProvider

    // User can override values
    values: {
        replicas: 10  // Production override
    }
}
```

---

## Common Workflows

### 1. Viewing Module Structure

```bash
# See all components in a module
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.components --out yaml

# See specific component
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.components.web --out yaml

# See component metadata
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.components.web.#metadata --out yaml

# See primitive elements used
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.#allPrimitiveElements
```

### 2. Understanding Value Flow

```bash
# Definition values (constraints only)
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myAppDefinition.values --out yaml

# Module values (concrete)
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.values --out yaml

# Compare definition vs module
diff <(cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myAppDefinition.values --out yaml) \
     <(cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp.values --out yaml)
```

### 3. Exporting for Deployment

```bash
# Export module to YAML manifest
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp --out yaml > deploy/myapp.yaml

# Export all components separately
for comp in web db auditLogging; do
  cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e "myApp.components.$comp" --out yaml > "deploy/$comp.yaml"
done

# Export as JSON for API consumption
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp --out json > myapp.json
```

### 4. Validation and Testing

```bash
# Validate all examples
cue cmd validate

# Validate specific example (allow incomplete definitions)
cue vet -c=false ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue

# Check for errors
cue vet --all-errors ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue

# Format examples
cue fmt .
```

---

## Creating Your Own Examples

### 1. Create a ModuleDefinition

```cue
package examples

import (
    opm "github.com/open-platform-model/core"
    elements "github.com/open-platform-model/elements/core"
)

myNewAppDefinition: opm.#ModuleDefinition & {
    #metadata: {
        name:    "my-new-app"
        version: "1.0.0"
    }

    components: {
        api: {
            elements.#StatelessWorkload

            statelessWorkload: container: {
                image: values.image  // Reference value
                ports: http: {targetPort: 8080}
            }
        }
    }

    // Constraints only (no defaults)
    values: {
        image!: string  // Required
    }
}
```

### 2. Create a Module Instance

```cue
myNewApp: opm.#Module & {
    #metadata: {
        name:    "my-new-app-prod"
        version: "1.0.0"
    }

    moduleDefinition: myNewAppDefinition

    // Provide concrete values
    values: {
        image: "myregistry.io/api:v1.2.3"
    }
}
```

### 3. Test Your Example

```bash
# Validate
cue vet -c=false ./my_example.cue

# View result
cue export ./my_example.cue -e myNewApp --out yaml

# Use the examples tool
cue cmd show -t name=myNewApp
```

---

## Best Practices

### 1. **Value Strategy**

**ModuleDefinition** (DO):

- ✅ Use constraints only: `replicas: int`
- ✅ Mark required fields: `image!: string`
- ✅ Use type constraints: `port: >0 & <65536`
- ✅ Use enums: `env: "dev" | "staging" | "prod"`

**ModuleDefinition** (DON'T):

- ❌ Don't add defaults: `replicas: int | *3`
- ❌ Don't provide concrete values: `image: "nginx:latest"`

**Module** (DO):

- ✅ Provide all required fields
- ✅ Add defaults: `replicas: int | *3`
- ✅ Refine constraints: `domain: string & =~".*\\.platform\\.com$"`
- ✅ Provide concrete values

### 2. **Component Patterns**

```cue
// Good: Specific and complete
components: {
    web: {
        elements.#StatelessWorkload
        elements.#Replicas
        elements.#HealthCheck

        statelessWorkload: container: {
            image: "nginx:latest"
            ports: http: {targetPort: 80}
        }
        replicas: count: 3
        healthCheck: liveness: {
            httpGet: {path: "/health", port: 80}
        }
    }
}

// Bad: Incomplete or ambiguous
components: {
    web: {
        elements.#StatelessWorkload
        // Missing required fields
    }
}
```

### 3. **Validation**

Always test your examples:

```bash
# 1. Validate structure
cue vet -c=false ./my_example.cue

# 2. Check export works
cue export ./my_example.cue -e myModule --out yaml

# 3. Verify components
cue cmd components -t name=myModule

# 4. Check values
cue cmd values -t name=myModule
```

---

## Troubleshooting

### "incomplete value" errors

**Problem**: `cue export` shows incomplete values

**Solution**:

- ModuleDefinitions are meant to be incomplete (templates)
- Export the Module instance, not the Definition
- Use `-c=false` for validation: `cue vet -c=false`

```bash
# Wrong: Definition is incomplete
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myAppDefinition --out yaml

# Right: Module has concrete values
cue export ./example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue -e myApp --out yaml
```

### "field is required but not present"

**Problem**: Module doesn't provide all required fields

**Solution**: Check Definition's required fields (marked with `!`) and provide them in Module:

```cue
// Definition
values: {
    image!: string  // Required
}

// Module MUST provide
values: {
    image: "nginx:latest"  // Concrete value
}
```

### "reference not found"

**Problem**: Files not loaded together

**Solution**: Ensure all files are in same package and loaded together:

```bash
# Wrong: Single file
cue export ./example_provider.cue -e exampleCatalog

# Right: All files together
cue export . -e exampleCatalog
```

---

## File Organization

```
examples/
├── README.md                           # This file
├── run_examples_tool.cue               # Examples tool commands
├── example_simple_app.cue, example_ecommerce_app.cue, example_monitoring_stack.cue                 # Module examples
├── example_provider.cue                # Provider implementation
├── example_catalog_validation.cue      # Catalog validation
└── output/                             # Generated exports (gitignored)
    ├── myApp.yaml
    ├── ecommerceApp.yaml
    └── monitoringStack.yaml
```

---

## Related Documentation

- **[../CLAUDE.md](../CLAUDE.md)**: Project overview and value inheritance strategy
- **[../tests/README.md](../tests/README.md)**: Test framework documentation
- **[../tests/TEST_FRAMEWORK.md](../tests/TEST_FRAMEWORK.md)**: Detailed test patterns
- **[CUE Documentation](https://cuelang.org/docs/)**: Official CUE language docs

---

## Contributing Examples

When adding new examples:

1. Follow the value strategy (constraints in Definition, concrete in Module)
2. Use descriptive names and comments
3. Demonstrate a specific pattern or use case
4. Test with `cue cmd validate`
5. Add documentation to this README
6. Format with `cue fmt`

Example checklist:

- [ ] Definition has constraints-only values
- [ ] Module provides concrete values
- [ ] All required fields are satisfied
- [ ] Example validates with `-c=false`
- [ ] Can export with `cue export`
- [ ] Added to examples tool list
- [ ] Documented in README
