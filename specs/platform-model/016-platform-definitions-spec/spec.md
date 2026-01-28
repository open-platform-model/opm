# Feature Specification: OPM Platform Definitions

**Feature Branch**: `016-platform-definitions-spec`  
**Created**: 2026-01-28  
**Updated**: 2026-01-28  
**Status**: Draft

## Overview

This specification defines the platform-side definitions for Open Platform Model (OPM). These definitions enable the transformation of portable application components (defined in [001-application-definitions-spec](../../application-model/001-application-definitions-spec/spec.md)) into concrete, platform-specific resources.

The platform model bridges the application model to target platforms by defining:
- **Providers**: Platform adapters (e.g., Kubernetes) with transformer registries
- **Transformers**: Conversion logic from OPM components to platform resources
- **PlatformRegistry**: Curated module catalogs for end-user consumption

## Design Principles

### Separation of Concerns

The platform model is intentionally separated from the application model to enable:
- **Portability**: Applications remain platform-agnostic
- **Extensibility**: New platforms can be added without changing application definitions
- **Governance**: Platform operators control how applications are rendered and deployed

### Transformer-Based Architecture

Platform-specific rendering is delegated to transformers that:
- Use label-based matching to identify compatible components
- Transform abstract components into concrete platform resources
- Execute in parallel for performance
- Are registered in platform providers

## Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Provider` | Platform adapter with transformer registry | `transformers`, `#declaredResources`, `#declaredTraits`, `#declaredDefinitions` |
| `#Transformer` | Converts components to platform resources | `requiredLabels`, `requiredResources`, `optionalResources`, `requiredTraits`, `optionalTraits`, `#transform` |
| `#TransformerContext` | Context passed to transformers | `name`, `namespace`, `version`, `provider`, `timestamp`, `labels` |
| `#PlatformRegistry` | Curated module catalog for end-users | Modules, Bundles, curation policies |

## Relationship to Application Model

The platform model **consumes** definitions from the application model:
- `#Resource`, `#Trait`, `#Policy` (from 001-application-definitions-spec)
- `#Component` (from 001-application-definitions-spec)
- `#Module`, `#ModuleRelease` (from 001-application-definitions-spec)

Transformers match against these application-level abstractions and produce platform-specific resources.

## Subspec Index

| Index | Subspec | Document | Description |
|---|---|---|---|
| 13 | Platform Provider | [platform-provider.md](./subspecs/platform-provider.md) | Provider and Transformer structure |
| 14 | Transformer | [transformer.md](./subspecs/transformer.md) | Label-based matching algorithm for transformers |

## Related Specifications

- [001-application-definitions-spec](../../application-model/001-application-definitions-spec/spec.md) - Core OPM application definitions
- [013-cli-render-spec](../../cli/013-cli-render-spec/spec.md) - CLI render pipeline using these definitions
- [015-platform-runtime-spec](./015-platform-runtime-spec/spec.md) - Platform runtime and module catalog
