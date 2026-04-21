# Open Platform Model — OPM Meta Repository Constitution

## Purpose

This document is the reader-friendly reference for the principles that shape documentation, specifications, benchmarks, and Taskfile automation in the OPM meta repository. The OPM repo is the landing project for the Open Platform Model — it holds specs, architectural docs, benchmarks, and the tooling automation that ties the model together.

## Design Principles

| # | Principle | Summary |
|---|-----------|---------|
| **I** | [Type Safety First](#i-type-safety-first) | All definitions expressed in CUE; validation at definition time |
| **II** | [Separation of Concerns](#ii-separation-of-concerns) | Developer, platform, and consumer layers have distinct ownership |
| **III** | [Composability](#iii-composability) | Definitions compose without implicit coupling |
| **IV** | [Declarative Intent](#iv-declarative-intent) | Express WHAT, not HOW |
| **V** | [Portability by Design](#v-portability-by-design) | Definitions stay runtime-agnostic |
| **VI** | [Semantic Versioning](#vi-semantic-versioning) | SemVer 2.0.0 for artifacts; Conventional Commits for all commits |
| **VII** | [Simplicity & YAGNI](#vii-simplicity--yagni) | Complexity must be justified; prefer explicit over implicit |
| **VIII** | [Small Batch Sizes](#viii-small-batch-sizes-iterative--incremental-delivery) | Changes must stay tiny, incremental, and independently verifiable |

---

### I. Type Safety First

All definitions MUST be expressed in CUE. Invalid configuration MUST be rejected at definition time, never in production.

- Specs that produce CUE definitions must validate before merge
- Benchmarks and test data must use typed structures where possible
- Taskfile automation should fail fast on bad input rather than silently producing wrong output

---

### II. Separation of Concerns

The delivery flow MUST maintain clear ownership boundaries:

- Developers declare intent via Modules
- Platform teams extend definitions via CUE unification
- Consumers receive approved ModuleReleases with concrete values

Module → ModuleRelease is the canonical flow. Specs in this repo describe and govern that boundary without blurring it.

```text
Developer: Module            What the application needs
Platform:  Policy/Provider   How it is governed and deployed
Consumer:  ModuleRelease     Concrete values for a real environment
```

---

### III. Composability

Definitions MUST compose without implicit coupling:

- Resources describe what exists independently
- Traits modify behavior without knowing Resource internals
- Blueprints compose Resources and Traits without requiring modification
- Specs in this repo must not introduce cross-spec dependencies that cannot be resolved by reading the spec alone

---

### IV. Declarative Intent

Specs and documentation MUST express intent, not implementation. Declare WHAT, not HOW.

- Specs define required behaviors, not step-by-step procedures
- Taskfile tasks declare targets and dependencies, not ad hoc shell scripts embedded in prose
- Benchmarks measure behavior; they do not dictate implementation strategy

---

### V. Portability by Design

All specifications and definitions MUST remain runtime-agnostic. The same Module MUST be deployable to multiple providers without rewriting.

- Specs must not assume a specific cloud provider or Kubernetes distribution
- Platform-specific details belong in ProviderDefinitions, not in core specs
- Documentation that covers platform-specific behavior must label it clearly as such

---

### VI. Semantic Versioning

All artifacts MUST follow SemVer 2.0.0. All commits MUST follow Conventional Commits v1: `type(scope): description`.

Allowed commit types:

- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

Commit scopes: `vision`, `architecture`, `resource`, `trait`, `cli`, `module`.

Versioning communicates compatibility, change risk, and upgrade expectations across specs and published artifacts.

---

### VII. Simplicity & YAGNI

Start simple. Complexity MUST be justified with clear rationale. Prefer:

- Direct solutions over clever indirection
- Fewer concepts that compose well over many specialized concepts
- Explicit configuration over implicit convention

If a spec introduces a new concept, it must justify why existing primitives are insufficient.

---

### VIII. Small Batch Sizes (Iterative & Incremental Delivery)

All changes MUST be kept tiny. Small, incremental, independently verifiable steps are required.

- If a request is too large, it must be split into smaller sequential tasks
- Tiny changes produce focused, atomic commits
- A single commit should ideally address one specific concern

This applies to both spec work and Taskfile automation. Large bundled changes hide risk, slow review, and weaken validation.

#### Execution Gate

Before beginning any implementation, the scope of the request MUST be evaluated against the small-batch principle.

If the request is too large, the required response is:

> "🛑 **Scope Warning**: This request is too large for a single safe iteration. I suggest we split it into the following smaller steps: [list 2-3 logical, tiny steps]. Should we start with step 1?"

---

## Quality Gates

Before merge, the expected validation gates are:

1. `task fmt` — CUE files formatted
2. `task vet` — CUE files validate
3. Spec documents reviewed for heading consistency and internal link integrity

## How Principles Work Together

These principles reinforce each other:

- Type safety and declarative intent keep specs implementable and testable
- Separation of concerns prevents specs from leaking implementation details across ownership boundaries
- Composability enables smaller, targeted specs rather than monolithic documents
- Portability keeps the model broadly applicable rather than narrowly coupled
- Small batch sizes keep spec quality high and make review practical

When principles appear to conflict, treat that as a design smell and document the trade-off explicitly.

## Further Reading

- `AGENTS.md` — repository mechanics, commands, and coding guidance
- `docs/concepts/overview.md` — user-facing overview of the model
- `docs/glossary.md` — canonical term definitions
- `specs/` — all active and deferred specifications
