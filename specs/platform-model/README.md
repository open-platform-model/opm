# Platform Model Specifications

This directory contains specifications for the **Platform Model** of the Open Platform Model (OPM).

## What is the Platform Model?

The platform model bridges the **Application Model** to target platforms by defining how abstract components are transformed into concrete, platform-specific resources.

It enables platform operators to:

- Define how applications are **rendered** for specific infrastructure
- Curate which modules are **accessible** to deploy
- Provide **platform-specific** transformations and policies

The platform model contains the **control-plane** and platform runtime components.

## Core Concepts

### Platform Transformation

- **`#Provider`**: Platform adapter (e.g., Kubernetes) with metadata and transformer registry
- **`#Transformer`**: Declares conversion of OPM components into platform-specific resources via label matching
- **`#TransformerContext`**: Context passed to transformers (name, namespace, version, provider, timestamp, labels)

### Module Curation

- **`#PlatformRegistry`**: Central registry bridging the application model to target platforms
- **`#ModuleCatalog`**: Curated collection of approved modules and bundles exposed to end-users

## Specifications in this Directory

| Spec | Description |
|------|-------------|
| [016-platform-definitions-spec](./016-platform-definitions-spec/spec.md) | Platform definitions (Provider, Transformer, TransformerContext) |
| [015-platform-runtime-spec](./015-platform-runtime-spec/spec.md) | Platform runtime system, module catalog, and tiered values |

## Relationship to Application Model

The platform model **consumes** definitions from the [Application Model](../application-model/README.md):

- `#Resource`, `#Trait`, `#Policy` - Component building blocks
- `#Component` - Logical application parts
- `#Module`, `#ModuleRelease` - Deployable units

Transformers match against these application-level abstractions and produce platform-specific resources (e.g., Kubernetes Deployments, Services).

## Key Principles

1. **Separation of Concerns**: Applications remain platform-agnostic
2. **Extensibility**: New platforms can be added without changing application definitions
3. **Governance**: Platform operators control rendering and deployment policies
4. **Label-Based Matching**: Transformers use labels to identify compatible components
5. **Registry-Centric**: End users can only deploy modules from the curated catalog

## Transformation Flow

```text
Application Model (portable)
    ↓
Provider + Transformers (platform-specific)
    ↓
Platform Resources (e.g., K8s YAML)
```

The CLI (`opm mod build`) orchestrates this transformation using:

1. **Module**: Portable application definition
2. **Provider**: Platform adapter with transformer registry
3. **Transformers**: Label-based matching and conversion functions
4. **Output**: Platform-specific manifests

See [004-render-and-lifecycle-spec](../cli/004-render-and-lifecycle-spec/spec.md) for the render pipeline implementation.

## Getting Started

To create a new platform-model spec:

```bash
cd opm/.specify/scripts/bash
./create-new-feature.sh "Your spec description" --category platform
```
