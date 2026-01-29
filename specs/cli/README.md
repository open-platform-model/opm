# CLI Specifications

This directory contains specifications for the **CLI** of the Open Platform Model (OPM).

## What is the CLI?

The CLI is the primary authoring and deployment tool for OPM. It enables developers to:

- Initialize and scaffold new modules
- Validate and render modules for target platforms
- Publish modules to OCI registries
- Deploy modules to target environments

The CLI bridges the **Application Model** and **Platform Model**, orchestrating the transformation from portable definitions to platform-specific resources.

## Core Concepts

### Commands & Operations

- **`opm mod init`**: Initialize new modules from templates
- **`opm mod validate`**: Validate module definitions
- **`opm mod build`**: Render modules to platform-specific resources
- **`opm mod publish`**: Publish modules to OCI registries
- **`opm mod release`**: Deploy module releases to target environments

### Configuration

- **`.opm/config.cue`**: Project-level configuration for CLI behavior
- **Values overlay system**: Tiered values (defaults, platform, namespace, release)

### Rendering & Distribution

- **Transformer pipeline**: Converts OPM components to platform resources
- **OCI-based distribution**: Semantic versioning and registry management
- **Template system**: Scaffolding for new modules

## Specifications in this Directory

| Spec | Description |
|------|-------------|
| [002-cli-spec](./002-cli-spec/spec.md) | CLI v2 implementation (commands, UX, architecture, configuration) |
| [011-oci-distribution-spec](./011-oci-distribution-spec/spec.md) | OCI-based module distribution and versioning |
| [012-template-oci-spec](./012-template-oci-spec/spec.md) | CLI module templates for initialization |
| [004-render-and-lifecycle-spec](./004-render-and-lifecycle-spec/spec.md) | CLI render system for transforming modules to platform resources |

## Relationship to Application Model

The CLI **operates on** definitions from the [Application Model](../application-model/README.md):

- `#Resource`, `#Trait`, `#Policy` - Component building blocks
- `#Component` - Logical application parts
- `#Module`, `#ModuleRelease` - Deployable units

The CLI validates these definitions, manages their distribution, and orchestrates their deployment.

## Relationship to Platform Model

The CLI **integrates with** the [Platform Model](../platform-model/README.md):

- Uses `#Provider` and `#Transformer` definitions for rendering
- Queries `#ModuleCatalog` for curated modules
- Applies platform-specific values overlays

See [004-render-and-lifecycle-spec](./004-render-and-lifecycle-spec/spec.md) for the render pipeline implementation.

## Key Principles

1. **Developer Experience First**: Clear commands, helpful errors, beautiful output
2. **Type Safety**: CUE validation at every step
3. **Portability**: Works with any platform that implements the Platform Model
4. **Semantic Versioning**: All modules follow SemVer v2.0.0
5. **OCI-Native**: Distribution via OCI registries (e.g., ghcr.io, Docker Hub)

## Tech Stack

- **CLI Framework**: spf13/cobra
- **Config**: spf13/viper, CUE-based `.opm/config.cue`
- **CUE**: cuelang.org/go v0.11+
- **Kubernetes**: k8s.io/client-go (server-side apply)
- **OCI**: oras.land/oras-go/v2
- **Diff**: homeport/dyff
- **Terminal UX**: charmbracelet/{lipgloss, log, glamour, huh}

## Getting Started

To create a new CLI spec:

```bash
cd opm/.specify/scripts/bash
./create-new-feature.sh "Your spec description" --category cli
```
