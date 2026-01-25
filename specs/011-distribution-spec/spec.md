# Feature Specification: OPM Distribution & Versioning

**Feature Branch**: `011-distribution-spec`
**Created**: 2026-01-24
**Status**: Draft
**Input**: User description: "Based on the discussion we have had and the decision we have made create the new spec called "009-distribution-spec""

## Clarifications

### Session 2026-01-24

- Q: How should the CLI handle registry authentication? → A: Strictly rely on `~/.docker/config.json` managed by external tools (e.g., `docker login` or `oras login`), keeping the CLI simple and compliant with the "Simplicity" principle.
- Q: Should `opm mod get` support `@latest`? → A: No. CUE modules require strict versioning. To ensure compatibility and reproducibility, `opm` will enforce specific SemVer tags, mirroring CUE's behavior.
- Q: How should `opm` interact with CUE logic? → A: Embed the `cuelang.org/go` libraries directly. This ensures the `opm` binary is standalone and does not require a separate `cue` installation, while guaranteeing behavior parity.
- Q: How should dependency conflicts be resolved? → A: Use CUE's MVS to select a compatible version, and only error when no compatible version exists.
- Q: Should `opm mod update` include major version upgrades by default? → A: No. Default to patch/minor updates only; include majors only when `--major` is provided.
- Q: Where should the CLI store the module cache by default? → A: Use the CUE cache directory.
- Q: What availability target should we state for registry interactions? → A: Best-effort; no uptime SLA, but clear error reporting.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publishing a Module (Priority: P1)

A Module Author wants to publish their module to an OCI registry so that others can consume it. They need a simple command that validates the module and pushes it to their registry of choice.

**Why this priority**: This is the fundamental action for sharing content in the ecosystem. Without publishing, there is no distribution.

**Independent Test**: Can be tested by running a local registry (e.g., `zot` or `docker-registry`), publishing a module, and verifying the artifact exists in the registry.

**Acceptance Scenarios**:

1. **Given** a valid local OPM module, **When** the user runs `opm mod publish registry.example.com/my-module v1.0.0`, **Then** the module is validated (vet), packed, and pushed to the registry.
2. **Given** a module with validation errors, **When** the user runs `opm mod publish ...`, **Then** the process fails with clear error messages and nothing is pushed.
3. **Given** an unauthenticated registry, **When** the user runs `opm mod publish ...`, **Then** the CLI uses credentials from `~/.docker/config.json` to authenticate.

---

### User Story 2 - Consuming a Module (Priority: P2)

A Module Author wants to use a published module (e.g., `registry.example.com/simple-blog@v1`) in their own project. They need to download the dependency and have their project configuration (`module.cue`) updated automatically.

**Why this priority**: Consuming dependencies is the primary way users build upon the platform. Manual editing of `module.cue` dependency maps is error-prone and lowers adoption.

**Independent Test**: Can be tested by publishing a "provider" module, then in a separate "consumer" project, running `opm mod get` and verifying the dependency is usable in CUE.

**Acceptance Scenarios**:

1. **Given** an initialized OPM project, **When** the user runs `registry.example.com/simple-blog@v1`, **Then** the module is downloaded to the local cache AND the `module.cue` `deps` field is updated with the new dependency. It can be imported in the package.
2. **Given** a project with existing dependencies, **When** the user runs `opm mod get`, **Then** it respects existing versions unless a specific version is requested.
3. **Given** a dependency that imports other modules, **When** `opm mod get` is run, **Then** transitive dependencies are resolved and fetched.

---

### User Story 3 - Updating Dependencies (Priority: P3)

A Module Author wants to check if newer versions of their dependencies (e.g., `opmodel.dev/resources/workload` or `opmodel.dev/traits/storage`) are available and upgrade them easily.

**Why this priority**: Keeps the ecosystem healthy and up-to-date. Reduces the friction of "strict versioning" by automating the upgrade path.

**Independent Test**: Can be tested by publishing `v1.0.0` and `v1.1.0` of a module, consuming `v1.0.0`, and then running `opm mod update` to see the prompt for `v1.1.0`.

**Acceptance Scenarios**:

1. **Given** a project using `v1.0.0` of a dependency, **When** a `v1.1.0` is available and the user runs `opm mod update`, **Then** the CLI displays the available update and asks for confirmation.
2. **Given** a user confirms an update, **When** the process completes, **Then** `module.cue` reflects the new version and the artifacts are cached.
3. **Given** `opm mod update --check`, **When** updates are available, **Then** the command exits with a non-zero code (useful for CI).

---

### User Story 4 - Platform Composition & Extension (Priority: P2)

A Platform Operator wants to curate a catalog by consuming generic upstream modules (e.g., `registry.opm.dev/postgres@v2`) and extending them with organizational specifics (e.g., adding a mandatory `#Policy`, injecting a logging sidecar, or setting default labels) without forking the upstream code.

**Why this priority**: This enables the "Platform as Product" model where operators deliver value-added services on top of raw infrastructure modules. It validates that the distribution system preserves CUE's unification capabilities.

**Independent Test**: Create a module `internal-db` that imports `registry.opm.dev/postgres@v2`, adds a `#Policy`, and runs `opm mod build`. Verify the output YAML contains the postgres resources *plus* the policy enforcement results.

**Acceptance Scenarios**:

1. **Given** a local module importing an upstream OCI module (via `opm mod get`), **When** the user defines a new component or policy that unifies with the imported definitions, **Then** `opm mod build` successfully generates the combined configuration.
2. **Given** an upstream module, **When** the operator adds a mandatory `#Policy` (e.g., Security Context constraints), **Then** consumers of the operator's module cannot override this policy (validating the "Policy Built-In" principle).
3. **Given** a dependency on a specific version of a module, **When** `opm mod build` is run, **Then** the system uses the exact version specified in `module.cue` to ensure reproducible builds.

---

### Edge Cases

- **Network Failure**: If the registry is unreachable during `publish` or `get`, the CLI must fail gracefully with a descriptive error (not a stack trace).
- **Version Conflict**: If two dependencies require incompatible versions of a third dependency (Diamond Dependency), OPM uses CUE's MVS to pick a compatible version when possible and only errors when no compatible version exists.
- **Corrupt Cache**: If local cache is corrupt, `opm mod get` should allow a `--force` flag to re-download.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST provide `opm mod publish <oci-ref>` which validates (`vet`), packs, and pushes the current module to an OCI registry.
- **FR-002**: The artifact format in the OCI registry MUST be compatible with the standard CUE module specification. The CLI MUST use the `cuelang.org/go` libraries to handle module logic internally, ensuring a standalone binary without external `cue` CLI dependencies.
- **FR-003**: The CLI MUST provide `opm mod get <oci-ref>@<version>` which downloads the specified module and adds/updates the dependency in the `module.cue` file's `deps` map.
- **FR-004**: The CLI MUST provide `opm mod update [dependency]` which checks for newer SemVer versions of dependencies.
- **FR-005**: `opm mod update` MUST support an interactive mode (prompt user) and a non-interactive `--check` mode (exit code signal).
- **FR-010**: `opm mod update` MUST default to patch/minor updates only; major updates are included only when `--major` is provided.
- **FR-006**: The CLI MUST provide `opm mod tidy` to remove unused dependencies from `module.cue` and the local cache.
- **FR-007**: All registry interactions MUST support authentication using standard Docker credentials (`~/.docker/config.json`) managed by external tools (e.g., `docker login`). The CLI SHOULD NOT implement its own login command or environment variable logic.
- **FR-008**: The CLI MUST enforce Semantic Versioning (SemVer 2.0.0) for all module interactions. `opm mod get` MUST require an explicit version tag (e.g., `@v1.2.3`). The use of `@latest` or mutable tags is PROHIBITED to ensure reproducibility and CUE compatibility.
- **FR-009**: The CLI MUST correctly handle the mapping between CUE import paths (containing Major version, e.g., `path/to/mod:v1`) and specific registry tags (e.g., `v1.2.3`).
- **FR-011**: The CLI MUST store downloaded modules in the CUE cache directory.
- **FR-012**: The CLI MUST support a `registries` field in `~/.opm/config.yaml` that defines a map of module prefixes to registry URLs (e.g., `"opmodel.dev": "registry.example.com"`). The CLI MUST translate this user-friendly map into standard CUE registry routing configuration (prefix-based routing) to correctly resolve module imports across multiple registries. Or in the config:

    ```yaml
    registries:
        "opmodel.dev": 
            url: "registry.opm.dev"
        "company.internal":
            url: "harbor.internal/modules"
            insecure: true
        "registry.cue.works":
            url: "registry.cue.works"
    ```

### Key Entities

- **CUE Module**: A directory containing a `cue.mod/module.cue` file and CUE source files.
- **OCI Artifact**: The packaged representation of the CUE module stored in a registry.
- **Dependency Map**: The `deps` field in `module.cue` mapping import paths to registry versions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can publish a valid module to a standard OCI registry (e.g., GHCR, Docker Hub) and consume it in another project without manual JSON editing in `module.cue` 100% of the time.
- **SC-002**: `opm mod get` successfully updates the `module.cue` `deps` field with the correct version string within 2 seconds for a cached registry response.
- **SC-003**: The OPM module format remains 100% compatible with standard `cue` CLI commands (i.e., a user can run `cue eval` in an OPM project if they have the dependencies).
- **SC-004**: `opm mod update` correctly identifies available SemVer updates (Patch, Minor, Major) for all listed dependencies.
- **SC-005**: Registry operations are best-effort with clear, actionable error reporting (no uptime SLA).
