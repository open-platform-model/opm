# Status Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Superseded  
**Last Updated**: 2026-01-24

> **Note**: This subspec has been superseded by the unified Definition Status System specification.
>
> See: [008-definition-status-spec](../../008-definition-status-spec/spec.md)

## Overview

The status system for OPM Modules is now defined in the **Definition Status System** specification, which provides a unified `#Status` definition usable by Components, Modules, and Bundles.

Key features of the new specification:

- **Unified #Status**: Single definition for all entity types
- **#Condition**: Kubernetes-style conditions for interoperability
- **#StatusProbe**: Composable runtime health probes
- **Flexible details**: Key-value map for entity-specific metrics

For the complete specification including schemas, requirements, and examples, refer to the [Definition Status System spec](../../008-definition-status-spec/spec.md).
