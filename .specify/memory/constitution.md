<!--
SYNC IMPACT REPORT
==================
Version change: 0.1.0 → 0.2.0
Ratified: 2025-01-22
Last Amended: 2025-01-23

Modified principles: None
Added sections:
  - Development Workflow > Validation Gates: Self-deployment requirement
Removed sections: None

Templates requiring updates:
  - .specify/templates/plan-template.md ✅ no changes needed
  - .specify/templates/spec-template.md ✅ no changes needed
  - .specify/templates/tasks-template.md ✅ no changes needed

Follow-up TODOs: None
-->

# Open Platform Model Constitution

## Core Principles

### I. Type Safety First

All definitions MUST be expressed in CUE. Invalid configuration MUST be rejected at definition
time—never in production. CUE's structural typing, constraints, and validation provide compile-time
guarantees that prevent runtime failures.

**Rationale**: Type safety catches mistakes before rollout, reducing production incidents and
enabling confident refactoring. String templating and runtime validation are insufficient for
platform-scale configuration.

### II. Separation of Concerns

The delivery flow MUST maintain clear ownership boundaries:

- **Developers** declare intent via ModuleDefinitions
- **Platform teams** apply policy via Scopes and extend definitions via CUE unification
- **Consumers** receive approved ModuleReleases with concrete values

No single role should own the entire configuration lifecycle. ModuleDefinition → Module →
ModuleRelease is the canonical flow.

**Rationale**: Clear separation prevents "whoever yells loudest owns the config" anti-patterns and
enables independent evolution of application intent and platform governance.

### III. Policy Built-In

Governance MUST NOT be an afterthought. Policies and Scopes are first-class citizens of the model:

- **Policies** encode security, compliance, residency, and organizational standards
- **Scopes** attach Policies to Components and define inter-Component relationships
- Policy enforcement happens at definition time, not deployment time

**Rationale**: Bolting policy on after the fact leads to gaps, drift, and compliance failures.
Built-in policy ensures governance is enforceable and auditable.

### IV. Portability by Design

Definitions MUST be runtime-agnostic. The same ModuleDefinition MUST be deployable to multiple
providers (Kubernetes, Docker Compose, future orchestrators) without rewriting. Provider-specific
concerns belong in ProviderDefinitions, not in application definitions.

**Rationale**: Vendor lock-in increases cost and risk. Portable definitions enable sovereign
deployments and provider migration without application changes.

### V. Semantic Versioning

All artifacts MUST follow [Semantic Versioning 2.0.0](https://semver.org):

- MAJOR: Backward-incompatible changes
- MINOR: Backward-compatible functionality additions
- PATCH: Backward-compatible bug fixes

All commits MUST follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope): description` where type is one of: feat, fix, refactor, docs, test, chore.

**Rationale**: Consistent versioning enables automated tooling, clear upgrade paths, and predictable
breaking change communication.

### VI. Simplicity & YAGNI

Start simple. Complexity MUST be justified with a clear rationale. Avoid abstractions until proven
necessary. Prefer:

- Direct solutions over clever indirection
- Fewer concepts that compose well over many specialized concepts
- Explicit configuration over implicit convention

**Rationale**: Premature abstraction increases cognitive load and maintenance burden. Simplicity
enables faster onboarding and reduces bugs.

## Technology Standards

### Language & Tooling

- **CUE Version**: v0.15.0 or later
- **Go Version**: Standard gofmt, golangci-lint compliance required
- **Taskfile**: Used for build automation (`task fmt`, `task vet`, `task test`)

### CUE Code Style

- Use `#` prefix for definitions (e.g., `#ModuleDefinition`)
- Use `_` prefix for hidden/private fields (e.g., `_internal`)
- Use `!` suffix for required fields (e.g., `name!: string`)
- Follow the function pattern: `#Func: {X1="in": {...}, out: {...}}` with `let` bindings
- Use `error()` builtin for custom validation messages (v0.14.0+)

### Go Code Style

- Accept interfaces, return structs
- Context propagation required for all async operations
- Wrap errors with context; use sentinel errors for known conditions

## Development Workflow

### Validation Gates

Before any merge, the following MUST pass:

1. `cue fmt ./...` — All CUE files formatted
2. `cue vet ./...` — All CUE files validate
3. `task test` — All Go tests pass (in cli/)

### Design Validation

The OPM controller MUST be deployable via OPM Module or Bundle definitions. This self-hosting
requirement validates that the model is sufficiently expressive for platform-level workloads and
prevents special-casing that would undermine portability claims.

### Commit Standards

- Format: `type(scope): description`
- Types: feat, fix, refactor, docs, test, chore
- Keep descriptions concise
- No AI attribution in commit messages

### Code Review

- All changes require review
- Reviewers MUST verify constitution compliance
- Complexity additions MUST include justification

## Governance

This constitution supersedes all other development practices and guidelines. When conflicts arise,
the constitution is authoritative.

### Amendment Process

1. Propose amendment via pull request to this file
2. Document rationale and migration plan for affected code
3. Obtain approval from project maintainers
4. Update version according to semantic versioning:
   - **MAJOR**: Principle removal or incompatible redefinition
   - **MINOR**: New principle or material expansion of existing guidance
   - **PATCH**: Clarification, wording, or non-semantic refinement

### Compliance Verification

- All PRs MUST verify compliance with these principles
- Complexity MUST be justified in PR descriptions
- Runtime development guidance is in `AGENTS.md`

**Version**: 0.2.0 | **Ratified**: 2025-01-22 | **Last Amended**: 2025-01-23
