# Feature Specification: OPM Template Distribution

**Feature Branch**: `012-template-oci-spec`  
**Created**: 2026-01-23  
**Updated**: 2026-01-29  
**Status**: Draft  
**Input**: OCI-based template distribution system for creating, publishing, discovering, and consuming module templates

## Command Structure

This specification adds the `opm template` command group to the OPM CLI:

```text
opm template list                         # List templates from registry
opm template get <ref> [--dir <path>]     # Download template for editing
opm template show <ref>                   # Show template details
opm template validate                     # Validate template structure
opm template publish <oci-ref>            # Publish template to registry

opm mod init <name> --template <ref>      # Initialize module from template
```

| Command | Description |
|---------|-------------|
| `opm template list` | List available templates from `OPM_REGISTRY` or `config.registry` |
| `opm template get` | Download template to local path for editing/customization |
| `opm template show` | Display template metadata, description, and file structure |
| `opm template validate` | Validate template manifest and file structure |
| `opm template publish` | Publish template to OCI registry |
| `opm mod init --template` | Initialize a new module from a template |

## Relationship to Other Specs

- **002-cli-spec**: Defines `opm mod init --template` command; this spec extends template resolution
- **011-oci-distribution-spec**: Reuses OCI distribution patterns, registry routing, authentication

## Template Reference Resolution

Templates support multiple reference formats with automatic resolution:

| Input Format | Resolved To | Example |
|--------------|-------------|---------|
| Shorthand name | `oci://${REGISTRY}/templates/${name}:latest` | `standard` |
| OCI reference | As-is | `oci://registry.example.com/my-template:v1` |
| OCI (no scheme) | Prepend `oci://` | `registry.example.com/template:v1` |
| Local file | Local filesystem | `file://./my-template` |

**Resolution precedence for registry:**

1. `--registry` flag (if provided)
2. `OPM_REGISTRY` environment variable
3. `config.registry` from `~/.opm/config.cue`
4. Default: `registry.opmodel.dev`

## Official Templates

Three official templates are published to `registry.opmodel.dev/templates/`:

| Template | OCI Reference | Description |
|----------|---------------|-------------|
| `simple` | `registry.opmodel.dev/templates/simple:v1` | Single-file module for learning and prototypes |
| `standard` | `registry.opmodel.dev/templates/standard:v1` | Separated files for team projects |
| `advanced` | `registry.opmodel.dev/templates/advanced:v1` | Multi-package structure for complex applications |

These are resolved via shorthand: `opm mod init app --template standard`

## Template Structure

A template is a directory containing a manifest and template files:

```text
my-template/
├── template.cue              # Template manifest (required)
├── module.cue.tmpl           # Template files with placeholders
├── values.cue.tmpl
├── cue.mod/
│   └── module.cue.tmpl
└── components/               # Subdirectories supported
    └── web.cue.tmpl
```

### Template Manifest (`template.cue`)

```cue
package template

name:        "standard"
version:     "1.0.0"
description: "Standard OPM module template for team projects"

// Supported placeholders for substitution
placeholders: ["ModuleName", "ModulePath", "Version"]

// files: auto-derived from *.tmpl files in the template directory
```

### Template Files (`.tmpl`)

Template files use Go's `text/template` syntax for placeholder substitution:

| Placeholder | Source | Default |
|-------------|--------|---------|
| `{{.ModuleName}}` | `--name` flag or directory name | Directory name |
| `{{.ModulePath}}` | `--module` flag or derived | `example.com/<dirname>` |
| `{{.Version}}` | Hardcoded | `0.1.0` |

**Example `module.cue.tmpl`:**

```cue
package main

import "opmodel.dev/core@v0"

core.#Module

metadata: {
    apiVersion:  "{{.ModulePath}}@v0"
    name:        "{{.ModuleName}}"
    version:     "{{.Version}}"
    description: string | *"An OPM module"
}

#spec: {
    // Configuration schema
}
```

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initialize Module from Official Template (Priority: P1)

A developer wants to create a new OPM module using an official template. They run a single command and get a valid, ready-to-use module structure.

**Why this priority**: This is the primary entry point for new users and the most common template operation.

**Independent Test**: User runs `opm mod init my-app --template standard`, the module is created, and `opm mod vet` passes.

**Acceptance Scenarios**:

1. **Given** OPM CLI installed with default registry, **When** user runs `opm mod init my-app --template standard`, **Then** template is fetched from `registry.opmodel.dev/templates/standard:latest`, rendered with placeholders substituted, and written to `./my-app/`.
2. **Given** a module initialized from template, **When** user runs `opm mod vet` in that directory, **Then** validation passes with no errors.
3. **Given** template fetch succeeds, **When** user examines generated files, **Then** all `{{.ModuleName}}` placeholders are replaced with `my-app`.
4. **Given** `--name` flag provided, **When** user runs `opm mod init my-app --template standard --name custom-name`, **Then** `metadata.name` in generated `module.cue` is `custom-name`.

---

### User Story 2 - Discover Available Templates (Priority: P1)

A user wants to see what templates are available before initializing a module.

**Why this priority**: Template discovery is essential for users to make informed choices.

**Independent Test**: User runs `opm template list` and sees a formatted list of available templates.

**Acceptance Scenarios**:

1. **Given** OPM CLI with registry configured, **When** user runs `opm template list`, **Then** they see a table with template names, versions, and descriptions from the registry.
2. **Given** `OPM_REGISTRY` is set to a custom registry, **When** user runs `opm template list`, **Then** templates from that registry are listed.
3. **Given** registry is unreachable, **When** user runs `opm template list`, **Then** CLI exits with error code 3 (Connectivity Error) and clear message.

---

### User Story 3 - Inspect Template Details (Priority: P2)

A user wants to see detailed information about a specific template including its file structure and description.

**Why this priority**: Helps users understand what they're getting before using a template.

**Independent Test**: User runs `opm template show standard` and sees template metadata and file list.

**Acceptance Scenarios**:

1. **Given** a valid template reference, **When** user runs `opm template show standard`, **Then** they see: name, version, description, placeholders, and file tree.
2. **Given** a template with subdirectories, **When** user runs `opm template show advanced`, **Then** the file tree shows nested structure.
3. **Given** an invalid template reference, **When** user runs `opm template show unknown`, **Then** CLI exits with error code 5 (Not Found).

---

### User Story 4 - Download Template for Editing (Priority: P2)

A template author wants to download an existing template to customize it and publish their own version.

**Why this priority**: Enables template ecosystem growth by allowing users to build on existing templates.

**Independent Test**: User runs `opm template get standard --dir ./my-template`, edits files, and publishes.

**Acceptance Scenarios**:

1. **Given** a valid template reference, **When** user runs `opm template get standard`, **Then** template files are downloaded to `./standard/` directory.
2. **Given** `--dir` flag provided, **When** user runs `opm template get standard --dir ./my-template`, **Then** files are downloaded to `./my-template/`.
3. **Given** target directory exists and is non-empty, **When** user runs `opm template get`, **Then** CLI exits with error unless `--force` is provided.
4. **Given** template downloaded, **When** user examines files, **Then** they see `template.cue` manifest and `.tmpl` files (not rendered).

---

### User Story 5 - Publish Custom Template (Priority: P3)

A template author has created or customized a template and wants to publish it to an OCI registry for others to use.

**Why this priority**: Enables template sharing and ecosystem growth.

**Independent Test**: User creates a template, runs `opm template validate`, then `opm template publish`.

**Acceptance Scenarios**:

1. **Given** a valid template directory, **When** user runs `opm template publish registry.example.com/my-template:v1`, **Then** template is validated and pushed to the registry.
2. **Given** template with invalid manifest, **When** user runs `opm template publish`, **Then** CLI exits with error code 2 (Validation Error) and describes the issue.
3. **Given** registry authentication required, **When** user runs `opm template publish`, **Then** CLI uses credentials from `~/.docker/config.json`.
4. **Given** successful publish, **When** another user runs `opm template show registry.example.com/my-template:v1`, **Then** they see the template metadata.

---

### User Story 6 - Use Local Template (Priority: P3)

A developer is creating a custom template and wants to test it locally before publishing.

**Why this priority**: Enables template development workflow without requiring registry access.

**Independent Test**: User runs `opm mod init app --template file://./my-template` and module is created.

**Acceptance Scenarios**:

1. **Given** a local template directory, **When** user runs `opm mod init app --template file://./my-template`, **Then** module is initialized from local template.
2. **Given** local path does not exist, **When** user runs `opm mod init app --template file://./nonexistent`, **Then** CLI exits with error code 5 (Not Found).
3. **Given** local template with invalid manifest, **When** user runs `opm mod init`, **Then** CLI exits with error code 2 (Validation Error).

---

### Edge Cases

- **Template caching**: Downloaded templates are cached locally. Cache location follows 011-oci-distribution-spec patterns.
- **Version resolution**: Shorthand names resolve to `:latest`. Explicit versions (`:v1`, `:v1.2.3`) are respected.
- **Network failure**: If registry is unreachable during `list`, `get`, `show`, or `mod init`, CLI fails with exit code 3 and descriptive error.
- **Invalid template reference**: Malformed OCI references or unknown shorthand names result in exit code 2 or 5.
- **Directory name normalization**: When deriving `ModulePath` from directory name, hyphens are replaced with underscores for CUE compatibility.
- **Force overwrite**: `opm template get --force` and `opm mod init --force` overwrite existing directories.

## Requirements *(mandatory)*

### Functional Requirements

#### Template Discovery & Inspection

- **FR-001**: The CLI MUST provide `opm template list` to list available templates from the configured registry.
- **FR-002**: The CLI MUST provide `opm template show <ref>` to display template metadata including name, version, description, placeholders, and file structure.
- **FR-003**: Template references MUST support shorthand names (e.g., `standard`), OCI URLs (`oci://...`), and local paths (`file://...`).
- **FR-004**: When scheme is omitted from a reference containing `/`, CLI MUST default to `oci://`.
- **FR-005**: Shorthand names MUST resolve to `oci://${REGISTRY}/templates/${name}:latest` using the registry precedence chain.

#### Template Download

- **FR-006**: The CLI MUST provide `opm template get <ref>` to download template files to a local directory.
- **FR-007**: `opm template get` MUST default to a directory named after the template if `--dir` is not specified.
- **FR-008**: `opm template get` MUST fail if target directory exists and is non-empty, unless `--force` is provided.

#### Template Validation

- **FR-009**: The CLI MUST provide `opm template validate` to validate the current directory as a valid template.
- **FR-010**: Validation MUST verify: presence of `template.cue`, valid manifest schema, at least one `.tmpl` file.
- **FR-011**: Validation MUST verify all declared placeholders are valid identifiers.

#### Template Publishing

- **FR-012**: The CLI MUST provide `opm template publish <oci-ref>` to publish a template to an OCI registry.
- **FR-013**: `opm template publish` MUST validate the template before publishing.
- **FR-014**: `opm template publish` MUST use credentials from `~/.docker/config.json` for registry authentication.
- **FR-015**: Templates MUST be published as OCI artifacts compatible with standard OCI registries.

#### Module Initialization

- **FR-016**: `opm mod init <name> --template <ref>` MUST fetch template, substitute placeholders, and write rendered files.
- **FR-017**: Placeholder substitution MUST use Go `text/template` syntax.
- **FR-018**: Rendered files MUST have `.tmpl` suffix removed (e.g., `module.cue.tmpl` → `module.cue`).
- **FR-019**: `opm mod init` MUST support `--name` flag to override `{{.ModuleName}}` placeholder.
- **FR-020**: `opm mod init` MUST support `--module` flag to override `{{.ModulePath}}` placeholder.
- **FR-021**: Generated modules MUST pass `opm mod vet` without modification.

#### Official Templates

- **FR-022**: Official templates (`simple`, `standard`, `advanced`) MUST be published to `registry.opmodel.dev/templates/`.
- **FR-023**: Official templates MUST be resolvable via shorthand names.

### Key Entities

- **Template**: An OCI artifact containing a manifest and template files that produce an OPM module when rendered.
- **Template Manifest**: A `template.cue` file defining template metadata (name, version, description, placeholders).
- **Template File**: A file with `.tmpl` suffix containing Go template placeholders for substitution.
- **Template Reference**: A string identifying a template: shorthand name, OCI URL, or local file path.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: User can initialize a module from an official template in under 10 seconds (warm cache).
  - *Measurement*: Time from `opm mod init` command to directory creation.
  - *Assumptions*: Template cached locally, low-latency filesystem.

- **SC-002**: 100% of modules generated from official templates pass `opm mod vet` without modification.
  - *Measurement*: Automated testing of all three official templates.

- **SC-003**: User can discover available templates via `opm template list` within 5 seconds.
  - *Measurement*: Time from command to output display.
  - *Assumptions*: Registry responsive, network latency < 100ms.

- **SC-004**: User can publish a custom template and use it in under 60 seconds.
  - *Measurement*: Time from `opm template publish` to successful `opm mod init` using published template.
  - *Assumptions*: Local or low-latency registry.

- **SC-005**: Template system is compatible with standard OCI registries (GHCR, Docker Hub, Harbor, Zot).
  - *Measurement*: Integration tests against each registry type.

## Clarifications

### Session 2026-01-29

- Q: Should builtin templates remain CLI-embedded? → A: No. Publish as OCI artifacts to `registry.opmodel.dev/templates/`.
- Q: Should templates have a manifest file? → A: Yes. `template.cue` with name, version, description, placeholders.
- Q: Should templates support custom parameters beyond placeholders? → A: No. Only `ModuleName`, `ModulePath`, `Version`.
- Q: What command structure for template operations? → A: `opm template list/get/show/validate/publish` (separate from `opm mod`).
- Q: Should local templates be supported? → A: Yes. Use `file://` prefix. Default scheme is `oci://`.
- Q: Should shorthand names resolve to `:latest`? → A: Yes. Templates allow `:latest` unlike modules.
- Q: What file extension for template files? → A: `.tmpl` suffix (e.g., `module.cue.tmpl`).
- Q: What does `opm template get` do? → A: Downloads template to local path for editing/customization.

## Assumptions

- Templates are distributed as OCI artifacts using the same registry infrastructure as modules.
- Template authors manage versioning via OCI tags (SemVer recommended but not enforced).
- Template caching follows the same patterns as module caching (CUE cache directory).
- The `text/template` package provides sufficient functionality for placeholder substitution.
- Users have registry credentials configured via `~/.docker/config.json` for publishing.

## Out of Scope

- Interactive template wizards or prompts
- Template parameters beyond the three standard placeholders
- Converting existing modules to templates
- Template inheritance or composition
- Template marketplace or search beyond `opm template list`
