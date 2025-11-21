# Standard Template

**Level:** Intermediate
**Complexity:** Three files (module + components + values)
**Use Case:** Most applications, team projects

## Overview

The Standard template separates ModuleDefinition, components, and value schema into three files. This separation provides better organization and is ideal for team projects where components and values may have different owners or update frequencies.

## When to Use

- **Medium applications** - 3-10 components
- **Team projects** - Clear separation of concerns
- **Shared values** - When values need to be reused across modules
- **Frequent updates** - When components and values change independently

## Structure

```text
standard/
├── cue.mod/module.cue           # CUE module definition
├── module_definition.cue         # ModuleDefinition (main entry point)
├── components.cue                # Component definitions
├── values.cue                    # Value schema
└── releases/                     # Deployment releases
    └── module_release.cue        # Default release with concrete values
```

## Quick Reference

- **`module_definition.cue`** - Main entry point with module metadata
- **`components.cue`** - Component definitions using Units and Traits
- **`values.cue`** - Value schema with constraints and defaults
- **`releases/module_release.cue`** - ModuleRelease with concrete values for deployment

All definition files are in the same package—CUE automatically unifies them. No imports needed between these files. The releases/ directory uses imports to reference the parent module.

## Getting Started

1. **Initialize:**

   ```bash
   opm mod init my-app --template standard
   cd my-app
   ```

2. **Customize:** Edit the three files:
   - `components.cue` - Define your components
   - `values.cue` - Set value constraints
   - `module_definition.cue` - Update metadata if needed

3. **Validate:**

   ```bash
   cue vet .
   ```

4. **Build (future):**

   ```bash
   opm mod render . --platform kubernetes --output ./k8s
   ```

## Key Concepts

### Automatic File Unification

CUE automatically unifies all `.cue` files in the same package:

- No imports needed between `module_definition.cue`, `components.cue`, and `values.cue`
- Fields defined in one file are accessible in others
- `#components` from `components.cue` is automatically available in `module_definition.cue`
- `#values` from `values.cue` is automatically available in `components.cue`

This creates a clean separation while maintaining type safety.

### Component Organization

The `components.cue` file contains all component definitions, making it easy to:

- See all components in one place
- Group related components together
- Compare and standardize component patterns
- Review component changes independently

### Value Schema Separation

The `values.cue` file defines constraints separately from components:

- Platform teams define components
- DevOps teams manage value constraints
- Changes to constraints don't affect component definitions
- Value schema serves as configuration documentation

### ModuleRelease for Deployment

The `releases/module_release.cue` file provides concrete values for deployment:

```cue
core.#ModuleRelease & {
    metadata: {
        name:      "standard-app-local"
        namespace: "default"  // Required: target namespace
    }

    module: {
        // Reference to the module definition
        // Imports parent package using: import module ".."
    }

    values: {
        // Concrete values for ALL components
        web: {
            image:    "nginx:latest"
            replicas: 3
        }
        db: {
            image:      "postgres:14"
            volumeSize: "10Gi"
        }
    }
}
```

**Key characteristics:**
- ModuleRelease is the deployable artifact that binds definition with values
- Must provide concrete values for all required fields (marked with `!`)
- Can override defaults for optional fields or use schema defaults
- Target namespace is required (defines where to deploy)

**Multiple environment releases:**

Create additional release files for different environments:

```text
releases/
├── module_release.cue      # Default (local/test)
├── dev.release.cue         # Development
├── staging.release.cue     # Staging
└── prod.release.cue        # Production
```

Each environment can have different:
- Container image tags (`v1.0.0` vs `v1.1.0`)
- Replica counts (3 in dev, 10 in prod)
- Resource allocations (smaller in dev, larger in prod)
- Volume sizes (10Gi in dev, 100Gi in prod)

## File Responsibilities

### module_definition.cue

**Purpose:** Main entry point and module metadata

Edit this file to:

- Change module name and version
- Update description and labels
- Modify module-level configuration

See the file for the exact structure.

### components.cue

**Purpose:** Component definitions and specifications

Edit this file to:

- Add or remove components
- Change component Units and Traits
- Update component specifications
- Organize components by tier or function

See the file for working examples with web and database components.

### values.cue

**Purpose:** Value schema with constraints

Edit this file to:

- Add value constraints for new components
- Set defaults for optional fields
- Add validation rules
- Document configuration options

See the file for constraint patterns (required fields, defaults, validation).

### releases/module_release.cue

**Purpose:** Bind module definition with concrete values for deployment

Edit this file to:

- Provide concrete values for all components
- Set target namespace for deployment
- Configure environment-specific settings
- Override defaults from value schema

Create additional release files (`prod.release.cue`, `staging.release.cue`) for different environments with different configurations.

## Customization Guide

### Add a New Component

1. In `components.cue`, add a new component block
2. In `values.cue`, add corresponding value constraints
3. Follow the existing patterns in both files

### Modify Existing Components

1. Edit the component in `components.cue`
2. Update value constraints in `values.cue` if needed
3. Validate with `cue vet .`

### Change Value Constraints

1. Edit `values.cue` to adjust constraints
2. No changes to `components.cue` needed (same value references)

## Benefits of Separation

### Clear Ownership

- Platform team manages `module_definition.cue` and `components.cue`
- DevOps team manages `values.cue`
- Different teams can own different files

### Better Version Control

- Component changes in separate commits from value schema changes
- Easier to track what changed and why
- Reduced merge conflicts

### Team Collaboration

- Multiple team members work on different files simultaneously
- Each file has a single, clear responsibility
- Easier code reviews and approvals

### Reusability

- Value schemas can be shared across multiple modules
- Clear boundaries between definition and configuration
- Components can be copied to other modules

## Migration Paths

### From Simple → Standard

You're already here! The Standard template separates the Simple template's single file into three files.

### Standard → Advanced

When you have 10+ components, consider the Advanced template:

1. Create `components/` subdirectory for component templates
2. Create `scopes/` subdirectory for scope definitions
3. Use multi-package organization with local imports
4. Separate concerns into distinct packages

The Standard template prepares you for this—the file separation pattern is similar, just adds more structure.

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/cli/MODULE_STRUCTURE_GUIDE.md)
- [OPM Documentation](../../../README.md)
