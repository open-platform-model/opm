# Quickstart: OPM CLI v2

**Spec**: [spec.md](./spec.md) | **Date**: 2026-01-29

This guide walks through the core OPM CLI workflows for module authoring and deployment.

## Prerequisites

- Go 1.25+ installed
- CUE v0.15.x installed (`cue version` must show compatible MAJOR.MINOR with CLI)
- Kubernetes cluster access (for apply/delete/status commands)
- Access to CUE module registry (for provider module resolution)

## Installation

```bash
# From source
cd cli && task build

# Binary will be at ./bin/opm
./bin/opm version
```

## 1. Initialize Configuration

First-time setup creates the CLI configuration at `~/.opm/`:

```bash
# Create default config with kubernetes provider
opm config init

# Verify config is valid
opm config vet
```

**Generated files:**

- `~/.opm/config.cue` - Main configuration
- `~/.opm/cue.mod/module.cue` - CUE module metadata

## 2. Create a Module

Scaffold a new module using built-in templates:

```bash
# Create with standard template (default)
opm mod init my-app

# Or use simple template for minimal projects
opm mod init my-app --template simple

# Or use advanced template for complex deployments
opm mod init my-app --template advanced
```

**Output:**

```text
my-app/                    Module directory
  cue.mod/module.cue       CUE module metadata
  module.cue               Module definition
  values.cue               Default values
  components.cue           Component definitions (standard/advanced only)
```

## 3. Validate the Module

```bash
cd my-app

# Validate CUE syntax and schema
opm mod vet

# Validate with concrete values required
opm mod vet --concrete

# Update dependencies
opm mod tidy
```

## 4. Build Manifests

Render the module to Kubernetes manifests:

```bash
# Output YAML to stdout (default)
opm mod build

# With values file
opm mod build -f production.cue

# Output as JSON
opm mod build -o json

# Write to directory
opm mod build -o dir --out-dir ./manifests
```

## 5. Deploy to Cluster

```bash
# Preview changes (dry-run)
opm mod apply --dry-run

# Show diff before applying
opm mod apply --diff

# Apply and wait for readiness
opm mod apply --wait

# Apply with specific values
opm mod apply -f production.cue --namespace prod
```

## 6. Monitor Status

```bash
# Show status table
opm mod status

# Watch continuously
opm mod status --watch

# Output as JSON (for scripting)
opm mod status -o json
```

## 7. View Differences

```bash
# Compare local definition with cluster state
opm mod diff

# With specific values
opm mod diff -f production.cue
```

## 8. Delete Resources

```bash
# Preview deletion
opm mod delete --dry-run

# Delete with confirmation
opm mod delete

# Force delete (no confirmation, removes finalizers)
opm mod delete --force
```

## Configuration Reference

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPM_REGISTRY` | Registry for CUE module resolution | - |
| `OPM_KUBECONFIG` | Path to kubeconfig | `~/.kube/config` |
| `OPM_CONTEXT` | Kubernetes context | current-context |
| `OPM_NAMESPACE` | Default namespace | `default` |
| `OPM_CONFIG` | Path to config file | `~/.opm/config.cue` |
| `OPM_CACHE_DIR` | Cache directory | `~/.opm/cache` |

### Configuration Precedence

1. Command-line flags (highest)
2. Environment variables
3. Config file (`~/.opm/config.cue`)
4. Built-in defaults (lowest)

### Example config.cue

```cue
package config

import (
    providers "opmodel.dev/providers@v0"
)

config: {
    // Registry for CUE module resolution (providers, core, etc.)
    registry: "registry.opmodel.dev"
    
    kubernetes: {
        kubeconfig: "~/.kube/config"
        namespace:  "default"
    }
    
    cacheDir: "~/.opm/cache"
    
    providers: {
        kubernetes: providers.#Registry["kubernetes"]
    }
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Validation error |
| 3 | Connectivity error |
| 4 | Permission denied |
| 5 | Not found |
| 6 | CUE version mismatch |

## Next Steps

- See [commands.md](./reference/commands.md) for full CLI reference
- See [project-structure.md](./reference/project-structure.md) for module layout details
- See [exit-codes.md](./contracts/exit-codes.md) for error handling
