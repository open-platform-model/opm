# Simple Template

**Level:** Beginner
**Complexity:** Single file
**Use Case:** Learning, quick prototypes, demos

## Overview

The Simple template provides everything in a single `module_definition.cue` file—perfect for getting started with OPM. This template includes the ModuleDefinition, components with concrete specifications, and value schema all inline.

## When to Use

- **Learning OPM** - Easiest way to understand OPM concepts
- **Simple applications** - 1-3 components
- **Quick prototypes** - Fast iteration during development
- **Demos and examples** - Clear, self-contained examples

## Structure

```text
simple/
├── cue.mod/module.cue        # CUE module definition
└── module_definition.cue      # Everything in one file
```

## Quick Reference

- **`module_definition.cue`** - Main file containing:
  - ModuleDefinition with metadata
  - Component definitions using Units and Traits
  - Value schema with constraints

Open this file to see working examples with detailed comments.

## Getting Started

1. **Initialize:**

   ```bash
   opm mod init my-app --template simple
   cd my-app
   ```

2. **Customize:** Edit `module_definition.cue` to:
   - Modify component images and ports
   - Add or remove components
   - Adjust value constraints

3. **Validate:**

   ```bash
   cue vet .
   ```

4. **Build (future):**

   ```bash
   opm mod render . --platform kubernetes --output ./k8s
   ```

## Key Concepts

### Component Composition

Components are composed from **Units** (what exists) and **Traits** (how it behaves):

- **Units**: `#Container`, `#Volumes`, `#ConfigMap`, `#Secret`
- **Traits**: `#Replicas`, `#HealthCheck`, `#Expose`, `#RestartPolicy`

The template demonstrates this pattern—see the actual file for examples.

### Spec Block

The `spec:` block provides concrete configuration. You can use:

- Concrete values: `image: "nginx:latest"`
- Value references: `replicas: #values.web.replicas`

This binds your component to the value schema.

### Value Schema

The `#values` field defines **constraints**, not concrete values:

- Use `!` for required fields: `image!: string`
- Use `?` for optional fields with defaults: `replicas?: int | *3`
- Add validation: `replicas?: int & >=1 & <=10 | *3`

Concrete values are provided later (at ModuleRelease deployment).

## Customization Guide

All customization happens in `module_definition.cue`:

1. **Change images** - Update the `image:` field in component specs
2. **Add components** - Copy a component block and modify
3. **Adjust resources** - Add `resources:` to container specs
4. **Update values** - Modify the `#values` schema constraints

Refer to the template file for the exact syntax and structure.

## Migration Path

As your application grows:

### Simple → Standard (separate files)

When you have 3+ components, separate concerns into multiple files:

1. Move components to `components.cue`
2. Move values to `values.cue`
3. Keep `module_definition.cue` for metadata only

CUE automatically unifies files in the same package.

### Standard → Advanced (multi-package)

When you have 10+ components, use multi-package organization:

1. Create `components/` subdirectory for component templates
2. Create `scopes/` subdirectory for scope definitions
3. Use local cross-package imports

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/CLI_SPEC.md#directory-structure--templates)
- [OPM Documentation](../../../README.md)
