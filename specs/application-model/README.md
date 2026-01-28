# Application Model Specifications

This directory contains specifications for the **Application Model** of the Open Platform Model (OPM).

## What is the Application Model?

The application model describes **deployable units** and models the complete lifecycle of an application—from definition through compilation to release.

It enables developers and platform teams to **describe applications once and deploy anywhere**, separating:

- **What** an application is (resources, traits, policies)
- **How** it gets configured (values)
- **Where** it gets deployed (releases)

The application model is complemented by the [CLI](../cli/README.md) as the primary authoring and deployment tool.

## Core Concepts

### Definitions

- **`#Resource`**: Deployable components or services that can be instantiated independently
- **`#Trait`**: Additional behavior attached to components (e.g., replicas, health checks)
- **`#Blueprint`**: Reusable composition patterns combining resources and traits
- **`#Policy`**: Governance rules and guardrails *(draft)*
- **`#Scope`**: Cross-cutting concerns spanning multiple components *(draft)*

### Composition

- **`#Component`**: A grouping of resources, traits, and blueprints forming a deployable unit
- **`#Module`**: The portable application blueprint with components, value schema, and default values
- **`#ModuleCompiled`**: Compiled intermediate representation with blueprints expanded
- **`#ModuleRelease`**: Concrete deployment instance with closed values and target namespace

### Distribution

- **`#Bundle`**: Collection of modules for distribution *(draft)*
- **`#BundleCompiled`**: Compiled bundle with expanded blueprints *(draft)*
- **`#BundleRelease`**: Concrete bundle deployment instance *(draft)*

## Specifications in this Directory

| Spec | Description |
|------|-------------|
| [001-application-definitions-spec](./001-application-definitions-spec/spec.md) | Core application definitions (Resource, Trait, Component, Module, etc.) |
| [009-definition-interface-spec](./009-definition-interface-spec/spec.md) | Module interface contracts *(archived)* |
| [010-definition-lifecycle-spec](./010-definition-lifecycle-spec/spec.md) | Lifecycle management for components and modules *(archived)* |
| [017-bundle-spec](./017-bundle-spec/spec.md) | Bundle definitions for module collections *(draft)* |

For CLI-related specifications, see [CLI Specifications](../cli/README.md).

## Relationship to Other Models

### Platform Model

The application model is **platform-agnostic**. Applications defined here can be deployed to any platform that implements the [Platform Model](../platform-model/README.md).

The platform model provides:

- **`#Provider`**: Platform adapters (e.g., Kubernetes)
- **`#Transformer`**: Conversion logic from OPM components to platform resources
- **`#PlatformRegistry`**: Curated module catalogs

See [016-platform-definitions-spec](../platform-model/016-platform-definitions-spec/spec.md) for platform-side definitions.

### CLI

The [CLI](../cli/README.md) operates on application model definitions, providing commands for validation, rendering, distribution, and deployment.

## Key Principles

1. **Separation of Concerns**: Module (Developer) → ModuleCompiled (Platform) → ModuleRelease (Consumer)
2. **Type Safety First**: All definitions in CUE with validation at definition time
3. **Portability by Design**: Definitions are runtime-agnostic
4. **Policy Built-In**: Policies and scopes are first-class citizens
5. **Semantic Versioning**: All modules follow SemVer v2.0.0

## Getting Started

To create a new application-model spec:

```bash
cd opm/.specify/scripts/bash
./create-new-feature.sh "Your spec description" --category application
```
