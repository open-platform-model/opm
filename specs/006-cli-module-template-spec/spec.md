# Feature Specification: OPM Module Template System

**Feature Branch**: `006-cli-module-template-spec`  
**Created**: 2026-01-23  
**Status**: Draft  
**Input**: Create specification for `opm mod init --template` command with three hardcoded templates (simple, standard, advanced) as initial implementation before OCI-based templates

## Command Structure

This specification adds the following commands to the OPM CLI:

```text
opm mod init <name> [--template <name>] [--name <module-name>] [--module <path>] [--force]
opm mod template list
opm mod template show <name>
```

| Command | Description |
|---------|-------------|
| `opm mod init` | Initialize a new module from a template |
| `opm mod template list` | List available templates with descriptions |
| `opm mod template show` | Show detailed information about a template |

## Relationship to 004-cli-spec

This specification extends the OPM CLI v2 specification (004-cli-spec), specifically:

- **FR-001**: "The CLI MUST provide a `mod init` command to create a new module from a template"
- **User Story 1**: References `opm mod init my-app --template oci://registry.opm.dev/templates/standard:latest`

This spec defines the interim hardcoded template implementation. A future specification will cover OCI-based template distribution.

## Template Overview

Three hardcoded templates provide progressive complexity levels:

| Template | Complexity | Target User | Component Count |
|----------|------------|-------------|-----------------|
| **simple** | Single-file inline | Learning OPM, prototypes | 1-3 |
| **standard** | Separated files | Team projects | 3-10 |
| **advanced** | Multi-package | Platform engineering, large apps | 10+ |

### Project Structure Alignment

Templates follow the new project structure conventions from 004-cli-spec:

| Generated File | Purpose | simple | standard | advanced |
|----------------|---------|--------|----------|----------|
| `module.cue` | Main #Module definition | Y | Y | Y |
| `values.cue` | Concrete default values | Y | Y | Y |
| `cue.mod/module.cue` | CUE module definition | Y | Y | Y |
| `components.cue` | Component extraction | - | Y | Y |
| `scopes.cue` | Scope definitions | - | - | Y |
| `policies.cue` | Policy definitions | - | - | Y |
| `debug_values.cue` | Extended values for validation | - | - | Y |
| `components/` | Component templates (subpackage) | - | - | Y |
| `scopes/` | Scope templates (subpackage) | - | - | Y |

### Generated Project Structures

#### Simple Template

```text
my-app/
├── cue.mod/
│   └── module.cue         # CUE module definition (module path)
├── module.cue              # Main #Module with inline components and #spec
└── values.cue              # Concrete default values
```

**3 files** - Everything in one place for learning and prototypes.

#### Standard Template

```text
my-app/
├── cue.mod/
│   └── module.cue         # CUE module definition
├── module.cue              # Main #Module with metadata
├── values.cue              # Concrete default values
└── components.cue          # Component definitions (extracted)
```

**4 files** - Separated concerns for team collaboration.

#### Advanced Template

```text
my-platform/
├── cue.mod/
│   └── module.cue         # CUE module definition
├── module.cue              # Main #Module with metadata
├── values.cue              # Concrete default values
├── components.cue          # Component composition (imports from components/)
├── scopes.cue              # Scope composition (imports from scopes/)
├── policies.cue            # Policy definitions
├── debug_values.cue        # Extended values for validation
├── components/             # Component templates (separate package)
│   ├── web.cue            # _web component template
│   ├── api.cue            # _api component template
│   ├── worker.cue         # _worker component template
│   └── db.cue             # _db component template
└── scopes/                 # Scope templates (separate package)
    ├── frontend.cue       # _frontend scope template
    └── backend.cue        # _backend scope template
```

**13 files** - Multi-package organization showcasing CUE's flexibility.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initialize Simple Module (Priority: P1)

A new OPM user wants to create their first module with minimal files to learn the platform basics. The simple template provides everything in a single `module.cue` file with inline components and value schema.

**Why this priority**: First-time user experience is critical for adoption. The simple template provides the gentlest onboarding with the least cognitive overhead.

**Independent Test**: User runs `opm mod init my-app --template simple`, examines the single-file structure, and successfully validates with `opm mod vet`.

**Acceptance Scenarios**:

1. **Given** a user with OPM CLI installed, **When** they run `opm mod init my-app --template simple`, **Then** a directory `my-app/` is created containing `module.cue`, `values.cue`, and `cue.mod/module.cue`.
2. **Given** a simple module was initialized, **When** the user runs `opm mod vet` in that directory, **Then** validation passes with no errors.
3. **Given** a simple module, **When** the user runs `opm mod build -o yaml`, **Then** valid Kubernetes manifests are rendered to stdout.
4. **Given** a simple module, **When** the user opens `module.cue`, **Then** they see inline component definitions with explanatory comments demonstrating OPM concepts.

---

### User Story 2 - Initialize Standard Module (Priority: P2)

A developer starting a team project wants a conventional structure with clear separation of components and values. The standard template separates concerns into multiple files while remaining approachable.

**Why this priority**: Most real-world applications will use this template. It balances simplicity with organizational best practices for team collaboration.

**Independent Test**: User runs `opm mod init my-app --template standard`, verifies the separated file structure, and successfully validates with `opm mod vet`.

**Acceptance Scenarios**:

1. **Given** a user, **When** they run `opm mod init my-app --template standard`, **Then** a directory is created with `module.cue`, `values.cue`, `components.cue`, and `cue.mod/module.cue`.
2. **Given** a standard module, **When** the user opens `module.cue`, **Then** it contains metadata and references to `#components` defined in `components.cue` (not inline definitions).
3. **Given** a standard module, **When** the user runs `opm mod vet`, **Then** CUE correctly unifies all root-level `.cue` files and validation passes.
4. **Given** a standard module, **When** the user modifies `components.cue` to add a new component, **Then** the change is reflected without modifying `module.cue`.

---

### User Story 3 - Initialize Advanced Module (Priority: P3)

A platform engineer building a complex application wants full organizational structure with multi-package templates, scopes, policies, and debug utilities. The advanced template demonstrates CUE's multi-package capabilities.

**Why this priority**: Advanced template targets experienced users building production-grade modules. Lower priority because it requires OPM familiarity.

**Independent Test**: User runs `opm mod init my-platform --template advanced`, all conventional files and subdirectory packages are created, and `opm mod vet` passes.

**Acceptance Scenarios**:

1. **Given** a user, **When** they run `opm mod init my-platform --template advanced`, **Then** a directory is created with: `module.cue`, `values.cue`, `components.cue`, `scopes.cue`, `policies.cue`, `debug_values.cue`, `cue.mod/module.cue`, `components/` subdirectory, and `scopes/` subdirectory.
2. **Given** an advanced module, **When** the user examines `components/`, **Then** they find separate `.cue` files defining reusable component templates as hidden fields (e.g., `_web`, `_api`).
3. **Given** an advanced module, **When** the user examines `components.cue`, **Then** it imports from the local `components` package and composes final components by extending templates.
4. **Given** an advanced module, **When** the user runs `opm mod vet --concrete` with `debug_values.cue`, **Then** the module validates completely with all fields resolved.

---

### User Story 4 - Initialize with Default Template (Priority: P4)

A user initializes a module without specifying a template and receives the standard template as a sensible default.

**Why this priority**: Improves ergonomics but not critical since `--template` can always be specified.

**Independent Test**: User runs `opm mod init my-app` (no `--template` flag) and receives standard template output.

**Acceptance Scenarios**:

1. **Given** a user, **When** they run `opm mod init my-app` without `--template`, **Then** the standard template is used by default.
2. **Given** a user, **When** they run `opm mod init my-app` without `--template`, **Then** the CLI outputs a message indicating which template was used.

---

### User Story 5 - List Available Templates (Priority: P5)

A user wants to discover what templates are available before initializing.

**Why this priority**: Discoverability is important but not blocking for initialization.

**Independent Test**: User runs `opm mod template list` and sees the available options with descriptions.

**Acceptance Scenarios**:

1. **Given** a user, **When** they run `opm mod template list`, **Then** they see a formatted list showing `simple`, `standard`, `advanced` with brief descriptions.
2. **Given** a user, **When** they run `opm mod template list`, **Then** the output indicates which template is the default.

---

### User Story 6 - Inspect Template Details (Priority: P6)

A user wants to see detailed information about a specific template before deciding to use it, including what files will be generated and the template's purpose.

**Why this priority**: Helps users make informed decisions but not required for basic usage.

**Independent Test**: User runs `opm mod template show advanced` and sees comprehensive template details.

**Acceptance Scenarios**:

1. **Given** a user, **When** they run `opm mod template show simple`, **Then** they see the template description, target use case, and list of files that will be generated.
2. **Given** a user, **When** they run `opm mod template show advanced`, **Then** they see the multi-package structure including subdirectories.
3. **Given** a user, **When** they run `opm mod template show unknown`, **Then** the CLI exits with error code 2 and displays valid template names.

---

### Edge Cases

- **Invalid template name**: When a user specifies `--template unknown`, the CLI exits with error code 2 (Validation Error) and displays valid template options.
- **Directory already exists (non-empty)**: When the target directory exists and is non-empty, the CLI fails with an error unless `--force` flag is provided.
- **Directory already exists (empty)**: When the target directory exists but is empty, the CLI proceeds with initialization.
- **Force overwrite behavior**: When `--force` is provided, the CLI overwrites only conflicting template files while preserving unrelated existing files. No confirmation prompt is shown (flag implies user consent).
- **Custom module name**: When `--name` flag is provided, it sets `metadata.name` in the generated `module.cue`, independent of directory name.
- **Invalid `--name` value**: When `--name` contains invalid CUE identifier characters (spaces, hyphens, etc.), the CLI rejects with exit code 2 and displays allowed characters (letters, digits, underscores; must start with letter or underscore).
- **CUE module path**: The CUE module path in `cue.mod/module.cue` is derived as `example.com/<dirname>` where `<dirname>` has hyphens replaced with underscores for CUE compatibility. The `--module` flag overrides this derivation.
- **Nested directory creation**: When the target path includes non-existent parent directories (e.g., `apps/my-app`), the CLI creates the full path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `mod init` command MUST accept a `--template` flag with valid values: `simple`, `standard`, `advanced`.
- **FR-002**: The `mod init` command MUST default to the `standard` template when `--template` is not specified.
- **FR-003**: The `mod init` command MUST create a valid CUE module structure with `cue.mod/module.cue` containing the module path.
- **FR-004**: All generated templates MUST pass `opm mod vet` without errors immediately after initialization.
- **FR-005**: The CLI MUST provide `opm mod template list` command to display available templates with descriptions.
- **FR-005a**: The CLI MUST provide `opm mod template show <name>` command to display detailed information about a specific template.
- **FR-006**: The `mod init` command MUST fail with exit code 2 when the target directory exists and is non-empty, unless `--force` is provided.
- **FR-007**: Generated `module.cue` MUST use package `main` and follow the project structure conventions from 004-cli-spec.
- **FR-008**: Generated `values.cue` MUST provide concrete default values that satisfy the module's `#spec` schema.
- **FR-009**: The **simple** template MUST generate only mandatory files: `module.cue`, `values.cue`, `cue.mod/module.cue`.
- **FR-010**: The **standard** template MUST additionally generate `components.cue` with extracted component definitions.
- **FR-011**: The **advanced** template MUST additionally generate: `scopes.cue`, `policies.cue`, `debug_values.cue`, and subdirectories `components/` and `scopes/` with separate CUE packages.
- **FR-012**: The `mod init` command MUST support `--name` flag to override `metadata.name` in generated files.
- **FR-013**: The `mod init` command MUST support `--module` flag to override the CUE module path in `cue.mod/module.cue`.
- **FR-014**: All templates MUST be embedded in the CLI binary (no network access required).
- **FR-015**: Generated files MUST include explanatory comments appropriate to the template complexity level.
- **FR-016**: The CUE module path MUST be derived as `example.com/<dirname>` where hyphens in `<dirname>` are replaced with underscores for CUE compatibility.
- **FR-017**: The `mod init` command MUST reject `--name` values containing invalid CUE identifier characters with exit code 2 and list allowed characters.
- **FR-018**: The `mod init` command MUST emit debug-level logs via charmbracelet/log (visible with `--debug` flag).
- **FR-019**: When `--force` is provided, the CLI MUST overwrite only conflicting template files while preserving unrelated existing files, without prompting for confirmation.

### Key Entities

- **Template**: A predefined set of CUE file scaffolds embedded in the CLI that create a valid OPM module structure when applied.
- **Template Identifier**: A string name (`simple`, `standard`, `advanced`) used with the `--template` flag to select a template.
- **Generated Module**: The output directory containing all scaffolded CUE files ready for customization and use with other `opm mod` commands.
- **Template Package**: For the advanced template, a subdirectory containing a separate CUE package with reusable template definitions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can initialize and validate a module using any template in under 30 seconds.
  - *Measurement*: Time from `opm mod init` command to successful `opm mod vet` completion.
  - *Assumptions*: Local filesystem, no network operations.

- **SC-002**: 100% of generated modules from any template pass `opm mod vet` without user modification.
  - *Measurement*: Automated testing of all three templates with `opm mod vet` returning exit code 0.

- **SC-003**: Users can identify the appropriate template for their use case within 10 seconds using `opm mod template list`.
  - *Measurement*: Template descriptions clearly indicate complexity level and use case.

- **SC-006**: Users can view detailed template information including generated file structure via `opm mod template show`.
  - *Measurement*: Output includes template name, description, use case, and complete file listing.

- **SC-004**: Generated modules from standard and advanced templates produce valid Kubernetes manifests via `opm mod build -o yaml`.
  - *Measurement*: Output is valid YAML that can be parsed and contains expected Kubernetes resource kinds.

- **SC-005**: Advanced template demonstrates multi-package CUE organization with working cross-package imports.
  - *Measurement*: `components.cue` successfully imports from local `components` package and `opm mod vet` passes.

## Clarifications

### Session 2026-01-23

- Q: When `--force` is provided and the target directory exists with files, what should happen to existing files? → A: Overwrite conflicting files only; preserve unrelated files.
- Q: What CUE module path format should be used when deriving from the directory name? → A: Prefixed with placeholder domain (e.g., `example.com/my_app`), MUST replace `-` with `_` for CUE naming compatibility.
- Q: Should the CLI emit structured logging/telemetry for template operations? → A: Debug-level logs via charmbracelet/log (visible with `--debug`).
- Q: For the `--force` flag behavior, should the CLI prompt for confirmation or proceed silently? → A: Proceed silently (flag implies user consent).
- Q: What should happen when `--name` contains invalid CUE identifier characters? → A: Reject with validation error listing allowed characters.

## Assumptions

- Templates are embedded in the CLI binary using Go's `embed` package.
- Template identifiers (`simple`, `standard`, `advanced`) are stable; future OCI-based templates will use URI syntax.
- The `--template` flag syntax is forward-compatible with future OCI template URIs (e.g., `--template oci://registry/template:tag`).
- Generated example components use generic workload patterns (web server, database) that are universally applicable.
- Users have basic familiarity with CUE syntax or will learn from the generated comments.
- CUE module paths and identifiers require underscores instead of hyphens; directory names with hyphens are auto-normalized in module path derivation.

## Out of Scope

- OCI-based template distribution (covered by a future specification).
- Template customization or parameterization beyond `--name` and `--module` flags.
- Interactive template selection or wizard-style initialization.
- Template versioning (hardcoded templates are tied to CLI version).
