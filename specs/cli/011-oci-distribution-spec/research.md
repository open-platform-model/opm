# Research: OPM Distribution & Versioning

**Feature Branch**: `011-oci-distribution-spec`
**Created**: 2026-01-24
**Status**: Draft

## Context

The Open Platform Model (OPM) needs a standard way to distribute and version artifacts. These artifacts include:

1. **Core Definitions**: `#Module`, `#Resource`, `#Trait` (owned by OPM maintainers).
2. **User Modules**: Implementations of `#Module` (owned by users/Module Authors).

We evaluated two primary architecture options for handling this distribution.

## Options Analysis

### Option 1: Unified CUE Modules (Selected)

In this model, **everything** is a standard CUE module.

* The OPM Core is a module: `opmodel.dev/core`.
* A User Module is a module: `registry.example.com/my-app`.
* Users import Core using standard CUE syntax: `import "opmodel.dev/core"`.
* Distribution uses the OCI (Open Container Initiative) standard, leveraging CUE's built-in `cue mod publish` logic.

**Pros:**

* **Native Composition:** Users can import other users' modules easily (`import "github.com/other/module"`).
* **Standard Tooling:** Leverages existing CUE ecosystem (VS Code plugins, `cue` CLI, standard dependency resolution).
* **Simplicity:** No need to build a custom package manager or registry protocol.

**Cons:**

* **Strict Versioning:** CUE modules require major versions in the import path (e.g., `.../core:v0`), which couples user code to the Core version.
* **UX Friction:** Managing `module.cue` dependencies manually (editing JSON/CUE structures) can be tedious.

### Option 2: Split Model (Rejected)

In this model, Core definitions are CUE modules, but User Modules are custom OPM artifacts (e.g., a tarball with metadata).

* `opm` would handle the "unpacking" of User Modules.
* `opm` would inject the Core dependencies into the User Module's workspace invisibly.

**Pros:**

* **Abstraction:** Hides `cue.mod` and versioning complexity from the user.
* **Decoupling:** `opm` could potentially map different Core versions dynamically.

**Cons:**

* **Complex Implementation:** Effectively requires writing a new package manager.
* **Broken Imports:** If `my-app` isn't a CUE module, standard CUE tools can't build it without `opm`'s magic intervention.
* **Limited Composition:** Harder for User A to import User B's module if it's in a custom format.

## Decision: Unified CUE Modules with CLI Helpers

We chose **Option 1** because it aligns with the Constitution's principles of **Simplicity** and **Type Safety**. The ecosystem benefits of standard CUE modules outweigh the UX friction.

To mitigate the UX friction (Cons of Option 1), the `opm` CLI will provide "Smart Helpers":

* `opm mod get`: Automatically updates `module.cue` `deps`.
* `opm mod update`: Checks for new versions of dependencies (Core or others) and helps the user upgrade.

## Technical Details

### OCI Structure

We will adhere strictly to the CUE module OCI specification. This ensures `opm` commands are compatible with `cue` commands.

* **Media Type:** `application/vnd.cue.module.v1+json` (conceptually, actual media types determined by CUE implementation).
* **Registry:** Any OCI-compliant registry (GHCR, Docker Hub, Harbor, etc.).

### Versioning Policy

* **SemVer 2.0.0** is strictly enforced.
* **Core Stability:** `opm/core` will maintain `v0` for the initial beta phase, allowing breaking changes with minor version bumps *until* v1.0.0. Post-v1.0.0, breaking changes require `v2`.
* **Dependency Locking:** `module.cue` locks dependencies to exact versions for reproducibility.

### Registry Routing Strategy

We adopt CUE's [standard registry configuration](https://cuelang.org/docs/reference/command/cue-help-registryconfig/) pattern.

* **Prefix-Based Routing**: Users define a map of module prefixes to registry URLs in `~/.opm/config.cue`.
* **Example**:

    ```cue
    package opmconfig
    
    registries: {
        "opmodel.dev": {
            url: "registry.opmodel.dev"
        }
        "company.internal": {
            url: "oci://harbor.internal/modules"
            insecure: true
        }
        "corp.example": {
            url: "registry.corp.example"
        }
    }
    ```

* **Translation**: The CLI translates this user-friendly config into the standard CUE registry protocol (e.g., setting `CUE_REGISTRY` or configuring the module loader) to ensure `opm` and `cue` behavior is identical.
