# OPM Lifecycle Specification

**Status**: Draft  
**Last Updated**: 2026-01-22

> **Moved**: This specification has been migrated into the application definitions spec as subspecs. See [Lifecycle System](../001-application-definitions-spec/subspecs/lifecycle.md).

## 1. Overview

This specification defines the lifecycle management subsystem for the Open Platform Model (OPM). It details how operations are executed during key transition points in a module's or component's existence, such as installation, upgrades, and deletion.

The lifecycle system is designed to be safe, consistent, and auditable by enforcing the use of pre-built, reusable blocks for all lifecycle actions. This approach prevents arbitrary code execution and ensures that all operations are tested, validated, and understood.

## 2. Core Concepts

- **Lifecycle**: A set of ordered steps that execute at specific transition points (install, upgrade, delete).
- **Lifecycle Step**: A single, pre-built, and configurable action from a catalog, identified by a Fully Qualified Name (FQN).
- **Component Lifecycle**: Actions scoped to an individual component (e.g., database schema migrations).
- **Module Lifecycle**: Actions scoped to an entire module, typically for cross-component coordination (e.g., integration tests).

## 3. Subsystems

This specification is divided into the following sub-specifications:

- **[Component Lifecycle](./subspecs/component.md)**: Defines the lifecycle for individual components.
- **[Module Lifecycle](./subspecs/module.md)**: Defines the lifecycle for entire modules and the execution order relative to component lifecycles.
