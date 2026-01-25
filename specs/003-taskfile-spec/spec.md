# Feature Specification: OPM Development Taskfile

**Feature Branch**: `003-taskfile-spec`  
**Created**: 2026-01-23  
**Status**: Draft  
**Input**: User description: "I want a specification about the tasks that need to exist for the development of this project."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Environment Setup (Priority: P1)

A new contributor clones the OPM repository and needs to quickly set up their local development environment with all necessary tools and dependencies to start contributing.

**Why this priority**: First-time setup is the critical entry point for all contributors. A frustrating setup experience leads to contributor drop-off.

**Independent Test**: A developer with only basic tools installed (Go, CUE, Task) can run `task setup` and have a fully functional development environment within 5 minutes.

**Acceptance Scenarios**:

1. **Given** a fresh clone of the repository, **When** the developer runs `task setup`, **Then** all dependencies are installed, configurations are validated, and the environment is ready for development.
2. **Given** a developer has completed setup, **When** they run `task env`, **Then** they see a summary of their configured environment including tool versions and paths.
3. **Given** a developer wants to reset their environment, **When** they run `task clean`, **Then** all generated artifacts are removed and the environment returns to a clean state.

---

### User Story 2 - CUE Module Development Workflow (Priority: P1)

A developer is working on CUE definitions in the `core/` or `catalog/` repositories and needs to format, validate, and test their changes efficiently.

**Why this priority**: CUE module development is the primary activity in this project. Fast feedback loops on CUE validation are essential for productivity.

**Independent Test**: A developer can modify a CUE file, run `task fmt` and `task vet`, and receive clear feedback on any issues within seconds.

**Acceptance Scenarios**:

1. **Given** modified CUE files exist, **When** the developer runs `task fmt`, **Then** all CUE files are formatted consistently according to project standards.
2. **Given** CUE files exist in a module, **When** the developer runs `task vet`, **Then** all CUE files are validated and any schema errors are reported with clear file locations and messages.
3. **Given** a developer wants to focus on a specific module, **When** they run `task module:vet MODULE=core`, **Then** only the specified module is validated.
4. **Given** a developer wants continuous feedback, **When** they run `task watch:vet`, **Then** validation runs automatically on each file save.

---

### User Story 3 - CLI Development Workflow (Priority: P2)

A developer is working on the Go-based CLI in the `cli/` repository and needs to build, test, and lint their changes.

**Why this priority**: The CLI is the primary user-facing tool. However, it depends on stable CUE definitions, making this secondary to CUE development tasks.

**Independent Test**: A developer can modify Go code, run `task build` and `task test`, and receive feedback on compilation and test results.

**Acceptance Scenarios**:

1. **Given** Go source code exists in `cli/`, **When** the developer runs `task build`, **Then** the CLI binary is compiled successfully.
2. **Given** test files exist in `cli/`, **When** the developer runs `task test`, **Then** all tests (unit and integration) are executed and results are reported.
3. **Given** a developer wants to run only unit tests, **When** they run `task test:unit`, **Then** only unit tests are executed (fast, no external dependencies).
4. **Given** a developer wants to run only integration tests, **When** they run `task test:integration`, **Then** only integration tests are executed (may require external dependencies like Kubernetes).
5. **Given** a developer wants verbose test output, **When** they run `task test:verbose`, **Then** detailed test execution is shown including individual test names.
6. **Given** a developer wants to run a specific test, **When** they run `task test:run TEST=TestModuleLoad`, **Then** only the matching test is executed.

---

### User Story 4 - Cross-Repository Orchestration (Priority: P2)

A developer or CI system needs to run operations across all repositories in the monorepo, such as formatting all code, running all tests, or validating all modules.

**Why this priority**: Consistency across the monorepo requires coordinated operations. Essential for CI/CD and release processes.

**Independent Test**: A developer can run `task all:vet` and have all CUE and Go code validated across all repositories.

**Acceptance Scenarios**:

1. **Given** the monorepo contains multiple sub-repositories, **When** the developer runs `task all:fmt`, **Then** formatting is applied to all repositories (CUE in core/catalog, Go in cli).
2. **Given** the monorepo contains multiple sub-repositories, **When** the developer runs `task all:vet`, **Then** validation runs across all repositories and reports aggregated results.
3. **Given** a CI pipeline is running, **When** it runs `task ci`, **Then** all formatting checks, validations, and tests are executed in the correct order.

---

### User Story 5 - Module Publishing Workflow (Priority: P3)

A maintainer needs to publish CUE modules to an OCI registry for distribution to users.

**Why this priority**: Publishing is less frequent than development but critical for releases and distribution.

**Independent Test**: A maintainer can run `task module:publish MODULE=core` and have the module pushed to the configured registry.

**Acceptance Scenarios**:

1. **Given** a validated module exists, **When** the maintainer runs `task module:publish MODULE=core`, **Then** the module is pushed to the OCI registry with correct versioning.
2. **Given** the maintainer wants to test publishing locally, **When** they run `task registry:start`, **Then** a local OCI registry is started for testing.
3. **Given** a local registry is running, **When** the maintainer runs `task module:publish:local MODULE=core`, **Then** the module is pushed to the local registry.

---

### User Story 6 - Release & Versioning Workflow (Priority: P3)

A maintainer needs to manage versions, generate changelogs, and create releases following Semantic Versioning and Conventional Commits.

**Why this priority**: Release management is infrequent but critical for distribution. Proper automation ensures consistency.

**Independent Test**: A maintainer can run `task version:bump TYPE=minor` and have all version references updated and a changelog entry generated.

**Acceptance Scenarios**:

1. **Given** commits follow Conventional Commits format, **When** the maintainer runs `task changelog`, **Then** a changelog is generated or updated from commit history.
2. **Given** a version bump is needed, **When** the maintainer runs `task version:bump TYPE=patch|minor|major`, **Then** version files are updated following SemVer.
3. **Given** a release is ready, **When** the maintainer runs `task release`, **Then** the version is tagged, changelog is updated, and artifacts are prepared.
4. **Given** the maintainer wants to preview a release, **When** they run `task release:dry-run`, **Then** the release process is simulated without making changes.

---

### Edge Cases

- What happens when CUE validation fails? Tasks MUST report clear error messages with file paths and line numbers.
- What happens when a required tool is missing (Go, CUE, Task)? Setup tasks MUST detect missing tools and provide installation instructions.
- What happens when running tasks in a sub-repository directly? Tasks MUST work correctly whether run from root or from within a sub-repository.
- What happens when the OCI registry is unreachable? Publishing tasks MUST fail gracefully with clear connectivity error messages.
- What happens when watch mode detects rapid file changes? Watch tasks MUST debounce file change events to avoid excessive resource usage.
- What happens when version bump is attempted with uncommitted changes? Release tasks MUST abort and warn about dirty working directory.

## Requirements *(mandatory)*

### Functional Requirements

#### Root-Level Tasks

- **FR-001**: The root Taskfile MUST provide a `setup` task to initialize the complete development environment.
- **FR-002**: The root Taskfile MUST provide a `clean` task to remove all generated artifacts across all repositories.
- **FR-003**: The root Taskfile MUST provide an `env` task to display environment configuration and tool versions.
- **FR-004**: The root Taskfile MUST provide `all:fmt` and `all:vet` tasks to run formatting and validation across all repositories.
- **FR-005**: The root Taskfile MUST provide a `ci` task that runs all validation and testing required for continuous integration.
- **FR-006**: The root Taskfile MUST provide shortcut tasks (`fmt`, `vet`) that default to operating on all CUE modules.

#### CUE Module Tasks (core/, catalog/)

- **FR-007**: CUE repositories MUST provide a `fmt` task to format all CUE files using `cue fmt`.
- **FR-008**: CUE repositories MUST provide a `vet` task to validate all CUE files using `cue vet`.
- **FR-009**: CUE repositories MUST provide a `tidy` task to manage module dependencies using `cue mod tidy`.
- **FR-010**: CUE repositories MUST provide `watch:fmt` and `watch:vet` tasks for continuous formatting and validation on file changes.
- **FR-011**: CUE repositories MUST provide a `module:publish` task to publish the module to the configured OCI registry.
- **FR-012**: CUE repositories MUST provide a `module:publish:local` task to publish to a local development registry.
- **FR-013**: CUE repositories MUST provide a `module:version` task to display the current module version.
- **FR-014**: CUE repositories MUST provide a `module:version:bump` task accepting TYPE parameter (patch, minor, major) following SemVer.

#### CLI Tasks (cli/)

- **FR-015**: The CLI Taskfile MUST provide a `build` task to compile the CLI binary.
- **FR-016**: The CLI Taskfile MUST provide a `test` task to run all tests (unit and integration).
- **FR-017**: The CLI Taskfile MUST provide a `test:unit` task to run only unit tests (fast, no external dependencies).
- **FR-018**: The CLI Taskfile MUST provide a `test:integration` task to run only integration tests (may require external dependencies).
- **FR-019**: The CLI Taskfile MUST provide a `test:verbose` task for detailed test output.
- **FR-020**: The CLI Taskfile MUST provide a `test:run` task accepting a TEST parameter to run specific tests.
- **FR-021**: The CLI Taskfile MUST provide a `lint` task to run Go linters.
- **FR-022**: The CLI Taskfile MUST provide a `clean` task to remove build artifacts.

#### Registry Tasks

- **FR-023**: The root Taskfile MUST provide `registry:start` and `registry:stop` tasks for local OCI registry management.
- **FR-024**: The root Taskfile MUST provide `module:publish` tasks for pushing modules to OCI registries (orchestrating across all sub-repos).
- **FR-025**: Publishing tasks MUST support both local (development) and remote (production) registry targets.

#### Release & Versioning Tasks

- **FR-026**: The root Taskfile MUST provide a `version` task to display current versions of all components.
- **FR-027**: The root Taskfile MUST provide a `version:bump` task accepting TYPE parameter (patch, minor, major) following SemVer.
- **FR-028**: The root Taskfile MUST provide a `changelog` task to generate or update changelog from Conventional Commits.
- **FR-029**: The root Taskfile MUST provide a `release` task that orchestrates version bump, changelog, and tagging.
- **FR-030**: The root Taskfile MUST provide a `release:dry-run` task to preview release changes without committing.
- **FR-031**: Version tasks MUST support per-repository versioning (core, cli, catalog can have independent versions).

#### Cross-Cutting Requirements

- **FR-032**: All tasks MUST be non-interactive and suitable for CI/CD execution.
- **FR-033**: Tasks MUST support a `--verbose` flag or `TASK_VERBOSE=1` environment variable for detailed output.
- **FR-034**: Tasks MUST exit with non-zero status codes on failure.
- **FR-035**: Each sub-repository (core/, cli/, catalog/) MUST be fully self-contained with its own Taskfile that can execute all relevant tasks independently.
- **FR-036**: Root-level tasks MUST orchestrate sub-repository tasks, not duplicate their logic.

### Key Entities

- **Taskfile**: The configuration file (`Taskfile.yml`) that defines available tasks, their dependencies, and execution.
- **Module**: A CUE module directory containing CUE definitions and a `cue.mod/` directory.
- **Repository**: A sub-directory in the monorepo that may contain its own Taskfile (`core/`, `cli/`, `catalog/`).
- **Registry**: An OCI-compliant container registry for distributing CUE modules.
- **Version Registry**: A file tracking versions of each module independently.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new contributor can complete environment setup in under 5 minutes using documented tasks.
- **SC-002**: The `task fmt` command completes across all CUE modules in under 10 seconds for typical module sizes.
- **SC-003**: The `task vet` command provides actionable error messages including file path and line number for 100% of validation failures.
- **SC-004**: The CI task (`task ci`) executes all required checks in under 5 minutes for the complete monorepo.
- **SC-005**: All tasks can run successfully in a CI environment without manual intervention or interactive prompts.
- **SC-006**: 90% of common developer workflows (format, validate, test, build) can be accomplished with a single task command.
- **SC-007**: A maintainer can complete a release (version bump, changelog, tag) in under 2 minutes using documented tasks.
