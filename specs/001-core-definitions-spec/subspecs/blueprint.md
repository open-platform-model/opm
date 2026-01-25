# Blueprint Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Superseded  
**Last Updated**: 2026-01-25

> **Note**: This subspec has been superseded by the unified Definition Status System specification.
>
> See: [007-definition-blueprint-spec](../../007-definition-blueprint-spec/spec.md)

## Overview

This document defines the schema and behavior of Blueprints. A **Blueprint** represents a reusable pattern that composes Resources and Traits into a higher-level abstraction. Blueprints act as "templates" for components, allowing developers to standardize architectural patterns (e.g., "StatelessWorkload", "DatabaseCluster") and hide complexity.

### Core Principle: Composition

Blueprints enable composition by bundling:

1. **Resources**: The fundamental deployable units (e.g., Container, Service).
2. **Traits**: The behavioral modifiers (e.g., Replicas, Ingress).

When a component uses a blueprint, it inherits all the resources and traits defined in that blueprint.
