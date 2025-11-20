# Advanced Template

**Level:** Advanced
**Complexity:** Multi-package organization with local templates
**Use Case:** Complex applications, large teams, platform engineering

## Overview

The Advanced template demonstrates multi-package CUE organization for complex applications. This template uses **three separate packages** with local component and scope templates, providing clear separation of concerns and maximum reusability.

## When to Use

- **Large applications** - 10+ components
- **Multi-package organization** - Separate concerns across distinct packages
- **Reusable local templates** - Define component/scope templates once, use many times
- **Team collaboration** - Different teams own different packages
- **Complex architectures** - Multi-tier systems needing clear structure
- **Platform engineering** - Templates can be extracted and published for reuse

## Structure

```text
advanced/
├── cue.mod/module.cue            # Module: template.opm.dev
├── module_definition.cue          # Package: module (main entry point)
├── components.cue                 # Package: module (references templates)
├── scopes.cue                     # Package: module (references templates)
├── values.cue                     # Package: module (value schema)
├── components/                    # Package: components (local templates)
│   ├── api.cue                   # _api component template
│   ├── db.cue                    # _db component template
│   ├── web.cue                   # _web component template
│   └── worker.cue                # _worker component template
└── scopes/                        # Package: scopes (local templates)
    ├── backend.cue               # _backend scope template
    └── frontend.cue              # _api scope template
```

## Quick Reference

### Package: module (root files)

- **`module_definition.cue`** - Main entry point with metadata
- **`components.cue`** - References component templates from `components/` package
- **`scopes.cue`** - References scope templates from `scopes/` package
- **`values.cue`** - Complex value schema with nested configuration

### Package: components (components/ directory)

- **`web.cue`** - Web component template (`_web`)
- **`api.cue`** - API component template (`_api`)
- **`worker.cue`** - Worker component template (`_worker`)
- **`db.cue`** - Database component template (`_db`)

### Package: scopes (scopes/ directory)

- **`frontend.cue`** - Frontend scope template (`_api`)
- **`backend.cue`** - Backend scope template (`_backend`)

All template files contain working examples with detailed comments.

## Getting Started

1. **Initialize:**

   ```bash
   opm mod init my-platform --template advanced
   cd my-platform
   ```

2. **Understand the structure:**
   - Root files (package `module`) reference templates
   - Templates are defined in `components/` and `scopes/` subdirectories
   - Each template is a hidden field (prefixed with `_`)

3. **Customize:**
   - Edit templates in `components/` and `scopes/` directories
   - Edit template usage in root `components.cue` and `scopes.cue`
   - Edit value constraints in `values.cue`

4. **Validate:**

   ```bash
   cue vet .
   ```

5. **Build (future):**

   ```bash
   opm mod render . --platform kubernetes --output ./k8s
   ```

## Key Concepts

### Multi-Package Architecture

The template uses three packages for clear separation:

```text
┌─────────────────────────────────────────────┐
│  Package: module (root level)               │
│  ├── module_definition.cue                  │
│  ├── components.cue ─────┐                  │
│  ├── scopes.cue ─────┐   │                  │
│  └── values.cue      │   │                  │
└──────────────────────┼───┼──────────────────┘
                       │   │
           imports     │   │  imports
           local pkg   │   │  local pkg
                       │   │
                       ▼   ▼
┌──────────────────────────────────────────────┐
│  Package: components (components/ subdir)    │
│  ├── web.cue (_web template)                 │
│  ├── api.cue (_api template)                 │
│  ├── worker.cue (_worker template)           │
│  └── db.cue (_db template)                   │
└──────────────────────────────────────────────┘
                       ▲
                       │
           imports     │
           local pkg   │
                       │
┌──────────────────────────────────────────────┐
│  Package: scopes (scopes/ subdir)            │
│  ├── frontend.cue (_api template)            │
│  └── backend.cue (_backend template)         │
└──────────────────────────────────────────────┘
```

### Local Cross-Package Imports

Root files import local packages using the module path:

- `import comps "template.opm.dev/components"` imports `components/` package
- `import scopes "template.opm.dev/scopes"` imports `scopes/` package

This works because:

1. Module path is `template.opm.dev` (in `cue.mod/module.cue`)
2. Subdirectories become sub-packages
3. Can import local packages as if they were external

This pattern makes templates easy to extract and publish later.

### Hidden Field Templates

Templates use hidden fields (prefixed with `_`) for reusability:

- Templates defined: `_web`, `_api`, `_worker`, `_db` in `components/`
- Templates used: `web: comps._web & { ... }` in `components.cue`

Hidden fields don't appear in output but can be referenced and extended.

### Two-Layer Pattern

1. **Layer 1: Template Definitions** (in subdirectories)
   - Define reusable component/scope patterns
   - Use hidden fields for templates
   - Keep abstract (no concrete values)

2. **Layer 2: Template Usage** (in root files)
   - Reference templates via imports
   - Extend with concrete values
   - Bind to value schema

This creates clear separation between what you define and how you use it.

### Component Template Pattern

**Step 1:** Define template in `components/web.cue` with abstract fields
**Step 2:** Reference and extend in `components.cue` with value bindings
**Step 3:** Define constraints in `values.cue`

See the actual template files for complete working examples.

## Customization Guide

### Add New Component Template

1. Create `components/cache.cue` with template definition
2. Reference in `components.cue`: `cache: comps._cache & { ... }`
3. Add constraints in `values.cue`

Follow the existing patterns in the template files.

### Add New Scope Template

1. Create `scopes/data.cue` with scope definition
2. Reference in `scopes.cue`: `data: scopes._data`

### Modify Existing Templates

1. Edit template files in `components/` or `scopes/`
2. Changes automatically apply to all usages
3. Validate with `cue vet .`

### Extend Value Schema

Edit `values.cue` to add nested configuration. See the file for patterns like resources, rate limiting, and backup policies.

## Benefits of Multi-Package Organization

### Separation of Concerns

- Template definitions in separate packages (`components`, `scopes`)
- Template usage in main package (`module`)
- Value schemas in dedicated file
- Clear boundaries between definition and usage

### Reusability

- Define templates once, use multiple times
- Easy to extract and publish as external modules
- Platform teams can maintain template libraries
- Templates shared across projects

### Scalability

- Add new template files without modifying existing files
- Each template in its own file
- Clear structure for large applications (10+ components)
- Easy to navigate and understand

### Team Collaboration

- Platform team maintains `components/` and `scopes/` packages
- Application team uses templates in main package
- Clear ownership boundaries
- Reduced merge conflicts
- Different teams work on different packages

### Type Safety

- CUE validates entire composition across packages
- Templates define structure and constraints
- Value schema enforces configuration rules
- Catches errors at build time

### Path to External Templates

The local multi-package pattern mirrors external template usage:

1. **Start local** - Define templates in subdirectories
2. **Test and refine** - Use locally until stable
3. **Extract to external module** - Publish to OCI registry
4. **Import and use** - Same import pattern works

This makes the transition seamless when sharing templates across teams or organizations.

## Migration Path

### From Standard → Advanced

When you have 10+ components:

1. Create `components/` subdirectory with package `components`
2. Move component definitions to separate template files
3. Create `scopes/` subdirectory with package `scopes`
4. Add local cross-package imports in root files
5. Keep `module_definition.cue` simple (just metadata)

### Growing the Advanced Template

As your application grows:

1. **Add template files** - Create new files in `components/` or `scopes/`
2. **Split by domain** - Organize by tier, function, or team ownership
3. **Extract to external modules** - Publish to OCI registry for reuse
4. **Complex value schemas** - Add nested configuration
5. **Additional scopes** - Define fine-grained boundaries

## Best Practices

### 1. Use Hidden Fields for Templates

Templates should use `_` prefix to distinguish from concrete definitions.

### 2. Keep Templates Abstract

Leave configuration fields abstract in templates (e.g., `image: string`). Bind concrete values in usage files.

### 3. Separate Packages by Concern

- Package `components`: Component templates
- Package `scopes`: Scope templates
- Package `module`: Main module and usage

### 4. One Template Per File

Each template gets its own file for clarity and to reduce merge conflicts.

### 5. Leverage Cross-Package Imports

Scopes can import and reference components to define relationships.

### 6. Keep module_definition.cue Simple

Main file should only declare ModuleDefinition and metadata. Let CUE unify everything else.

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/CLI_SPEC.md#directory-structure--templates)
- [OPM Documentation](../../../README.md)
