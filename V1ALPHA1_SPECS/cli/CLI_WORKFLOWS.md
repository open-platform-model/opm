# OPM CLI Common Workflows

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

---

## Overview

This guide demonstrates common workflows and usage patterns for the OPM CLI. Each workflow includes step-by-step commands with explanations.

---

## Initialize and Build a Module

### Development Workflow

```bash
# 1. Initialize new module
opm mod init my-app --template oci://registry.opm.dev/templates/webapp

# 2. Edit module definition
vim module.cue

# 3. Validate module
opm mod vet ./module.cue

# 4. Option A: Render directly to platform resources (development)
opm mod render ./module.cue --platform kubernetes --output ./k8s --verbose

# 4. Option B: Build to Module IR then render (production)
opm mod build ./module.cue --output ./dist/my-app.module.cue
opm mod render ./dist/my-app.module.cue --platform kubernetes --output ./k8s

# 5. Apply to platform
opm mod apply ./module.cue --platform kubernetes
```

### Explanation

- **Step 1**: Initialize creates a new module directory with the specified template
- **Step 2**: Edit the generated `module.cue` to define your components and values
- **Step 3**: Validate ensures your module definition is correct before rendering
- **Step 4A**: Direct rendering is faster for development iterations
- **Step 4B**: Pre-building creates an optimized intermediate representation for production
- **Step 5**: Apply renders and deploys resources to the target platform

### When to Use Each Approach

**Direct Rendering (Option A):**
- Rapid development and testing
- Frequent changes to module definition
- Single platform target

**Pre-Build + Render (Option B):**
- Production deployments
- Multiple platform targets
- CI/CD pipelines
- Performance-critical scenarios (50-80% faster)

---

## Work with Registry Definitions

### Discovering and Using Definitions

```bash
# 1. List available Blueprints
opm blueprint list

# 2. List available Units
opm unit list

# 3. Describe a specific Blueprint
opm registry describe opm.dev/blueprints@v1#StatelessWorkload --examples

# 4. Describe a specific Unit
opm registry describe opm.dev/units/workload@v1#Container --schema

# 5. Search across all Definition types
opm registry search database

# 6. Clear cache if needed
opm registry cache clear
```

### Explanation

- **Steps 1-2**: List available building blocks for your modules
- **Step 3**: View detailed information about a Blueprint including usage examples
- **Step 4**: View the schema definition for a Unit to understand its fields
- **Step 5**: Search for definitions by keyword across all types
- **Step 6**: Clear cache to fetch latest definitions from registry

### Use Cases

**For Module Authors:**
- Discover available components before writing module definitions
- Understand the schema and constraints of Units and Traits
- Find examples of how to use specific Blueprints

**For Platform Teams:**
- Document available building blocks for developers
- Validate custom definitions against standard schemas

---

## Develop with Local Registry

### Local Development Setup

```bash
# 1. Start local registry (see Makefile.registry)
make -f Makefile.registry start

# 2. Configure CLI to use local registry
export OPM_REGISTRY=localhost:5000

# 3. Login to local registry
opm registry login localhost:5000

# 4. Push module to local registry
opm registry push ./my-module oci://localhost:5000/opm/my-module --version v0.1.0

# 5. List modules in registry
opm registry list localhost:5000/opm

# 6. Pull module
opm registry pull oci://localhost:5000/opm/my-module@v0.1.0
```

### Explanation

- **Step 1**: Start a local OCI registry container for testing
- **Step 2**: Configure CLI to use local registry instead of remote
- **Step 3**: Authenticate to local registry
- **Step 4**: Publish your module to local registry for testing
- **Step 5**: Verify module was published successfully
- **Step 6**: Pull module back from registry to test distribution

### Use Cases

**Testing Module Publishing:**
- Validate module packaging before publishing to production registry
- Test module versioning and tagging

**Offline Development:**
- Work without internet connection
- Test registry integration locally

**CI/CD Integration:**
- Set up ephemeral registries for testing
- Validate pull/push workflows in pipelines

---

## Debug Module Transformation

### Inspection and Debugging

```bash
# 1. Inspect transformation pipeline
opm dev inspect ./module.cue --verbose

# 2. Focus on specific component
opm dev inspect ./module.cue --component web-server --stage transformers

# 3. Compare two module versions
opm dev diff ./module-v1.cue ./module-v2.cue

# 4. Generate dependency graph
opm dev graph ./module.cue --format mermaid > diagram.md

# 5. Watch for changes and auto-render during development
opm dev watch ./module.cue --platform kubernetes --output ./k8s
```

### Explanation

- **Step 1**: View the complete transformation pipeline to understand processing stages
- **Step 2**: Focus debugging on a specific component and stage
- **Step 3**: Compare outputs to see what changed between versions
- **Step 4**: Visualize module dependencies as a graph
- **Step 5**: Enable live reload for faster development iterations

### Debugging Scenarios

**Transform Not Working:**
```bash
# Inspect which transformers matched
opm dev inspect ./module.cue --stage transformers

# Expected output:
# Component: web-server
# Matched Transformers:
#   - kubernetes/stateless-workload (priority: 100)
#   - kubernetes/container (priority: 50)
```

**Unexpected Resource Output:**
```bash
# Compare before and after changes
opm dev diff ./module-old.cue ./module-new.cue

# View specific component transformation
opm dev inspect ./module.cue --component database --stage resources
```

**Understanding Module Structure:**
```bash
# Generate visual dependency graph
opm dev graph ./module.cue --format mermaid > module-graph.md

# View in browser or markdown viewer
```

---

## Bundle Management

### Creating and Deploying Bundles

```bash
# 1. Initialize a new bundle
opm bundle init my-platform --template platform-bundle

# 2. Edit bundle definition
vim bundle.cue

# 3. Validate bundle
opm bundle vet ./bundle.cue

# 4. Build bundle (flatten all modules)
opm bundle build ./bundle.cue --output ./dist/platform.bundle.cue

# 5. Render all modules in bundle
opm bundle render ./dist/platform.bundle.cue --platform kubernetes --output ./k8s

# 6. Apply entire bundle
opm bundle apply ./bundle.cue --platform kubernetes
```

### Explanation

- **Step 1**: Initialize bundle with multiple modules
- **Step 2**: Edit to define modules and values
- **Step 3**: Validate all modules in bundle
- **Step 4**: Pre-flatten all modules for faster rendering
- **Step 5**: Generate platform resources for all modules
- **Step 6**: Deploy entire bundle to platform

### Use Cases

**Platform Teams:**
- Distribute complete platform stacks (observability, security, networking)
- Version entire platforms as single unit
- Provide opinionated defaults for application teams

**Multi-Module Applications:**
- Deploy related services together
- Share common configuration across modules
- Manage dependencies between modules

---

## CI/CD Integration

### Continuous Deployment Pipeline

```bash
#!/bin/bash
# Example CI/CD script

set -e

# Environment configuration
export OPM_REGISTRY=${CI_REGISTRY:-registry.opm.dev}
export OPM_LOG_LEVEL=info

# 1. Validate module
echo "Validating module..."
opm mod vet ./module.cue --all-errors

# 2. Build optimized module
echo "Building module..."
opm mod build ./module.cue --output ./dist/app.module.cue --timings

# 3. Render platform resources
echo "Rendering resources..."
opm mod render ./dist/app.module.cue \
  --platform kubernetes \
  --output ./manifests \
  --format yaml

# 4. Dry-run apply (validation)
echo "Validating deployment..."
opm mod apply ./dist/app.module.cue \
  --platform kubernetes \
  --dry-run

# 5. Apply to target environment
if [ "$CI_COMMIT_BRANCH" = "main" ]; then
  echo "Deploying to production..."
  opm mod apply ./dist/app.module.cue \
    --platform kubernetes \
    --wait \
    --timeout 10m
fi
```

### GitHub Actions Example

```yaml
name: OPM Module Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPM CLI
        run: |
          curl -L https://github.com/opm/cli/releases/latest/download/opm-linux-amd64 -o /usr/local/bin/opm
          chmod +x /usr/local/bin/opm

      - name: Validate Module
        run: opm mod vet ./module.cue --all-errors

      - name: Build Module
        run: opm mod build ./module.cue --output ./dist/app.module.cue

      - name: Render Manifests
        run: opm mod render ./dist/app.module.cue --platform kubernetes --output ./k8s

      - name: Apply (Production Only)
        if: github.ref == 'refs/heads/main'
        env:
          OPM_REGISTRY: ${{ secrets.OPM_REGISTRY }}
        run: |
          echo "${{ secrets.KUBECONFIG }}" > /tmp/kubeconfig
          export KUBECONFIG=/tmp/kubeconfig
          opm mod apply ./dist/app.module.cue --platform kubernetes --wait
```

---

## Multi-Environment Deployment

### Managing Multiple Environments

```bash
# Directory structure:
# my-app/
# ├── module.cue (ModuleDefinition)
# ├── values/
# │   ├── dev.cue
# │   ├── staging.cue
# │   └── prod.cue
# └── releases/
#     ├── dev.release.cue
#     ├── staging.release.cue
#     └── prod.release.cue

# 1. Build module once
opm mod build ./module.cue --output ./dist/app.module.cue

# 2. Deploy to dev
opm mod render ./dist/app.module.cue \
  --platform kubernetes \
  --output ./k8s/dev \
  --values ./values/dev.cue

# 3. Deploy to staging
opm mod render ./dist/app.module.cue \
  --platform kubernetes \
  --output ./k8s/staging \
  --values ./values/staging.cue

# 4. Deploy to production
opm mod render ./dist/app.module.cue \
  --platform kubernetes \
  --output ./k8s/prod \
  --values ./values/prod.cue
```

### Environment-Specific Values

**values/dev.cue:**
```cue
package app

values: {
    replicas: 1
    resources: {
        cpu:    "100m"
        memory: "128Mi"
    }
    image: "myapp:dev"
}
```

**values/prod.cue:**
```cue
package app

values: {
    replicas: 5
    resources: {
        cpu:    "1000m"
        memory: "2Gi"
    }
    image: "myapp:v1.2.3"
}
```

---

## Module Development Iteration

### Fast Development Loop

```bash
# Terminal 1: Watch and auto-render
opm dev watch ./module.cue --platform kubernetes --output ./k8s

# Terminal 2: Edit module
vim module.cue

# Terminal 3: Apply changes automatically
kubectl apply -f ./k8s/
```

### Explanation

- **Terminal 1**: Watches for file changes and automatically re-renders
- **Terminal 2**: Edit module definition as needed
- **Terminal 3**: Apply rendered manifests (can be scripted with `kubectl apply -f ./k8s/ --watch`)

### Benefits

- Instant feedback on changes
- No manual rebuild steps
- Faster development iterations

---

## Testing and Validation

### Comprehensive Validation Workflow

```bash
# 1. Syntax validation
opm mod vet ./module.cue

# 2. Strict validation with all errors
opm mod vet ./module.cue --strict --all-errors

# 3. Render to check output
opm mod render ./module.cue --platform kubernetes --output ./test-output

# 4. Dry-run apply to validate against cluster
opm mod apply ./module.cue --platform kubernetes --dry-run

# 5. Diff against current deployment
opm dev diff ./current.cue ./updated.cue --context 5
```

---

## Module Publishing

### Publishing to Registry

```bash
# 1. Build and validate module
opm mod vet ./module.cue --strict
opm mod build ./module.cue --output ./dist/app.module.cue

# 2. Login to registry
opm registry login registry.opm.dev --username myuser

# 3. Push module with version tag
opm registry push ./my-app oci://registry.opm.dev/org/my-app --version v1.0.0

# 4. Tag as latest
opm registry push ./my-app oci://registry.opm.dev/org/my-app --version v1.0.0 --latest

# 5. Verify publication
opm registry list registry.opm.dev/org --tags
```

### Versioning Best Practices

- Use semantic versioning: `v1.0.0`, `v1.2.3`, etc.
- Tag stable releases as `latest`
- Use pre-release tags for testing: `v1.0.0-alpha`, `v1.0.0-beta.1`

---

## Related Documentation

- [CLI Specification](../CLI_SPEC.md) - Full CLI command reference
- [Module Structure Guide](MODULE_STRUCTURE_GUIDE.md) - Directory organization patterns
- [CLI Configuration](CLI_CONFIGURATION.md) - Configuration management

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
