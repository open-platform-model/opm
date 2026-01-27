# Implementation Plan: CLI Render System

**Branch**: `013-cli-render-spec` | **Date**: 2026-01-26 | **Spec**: [./spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-cli-render-spec/spec.md`

## Summary

This plan outlines the implementation of a new render system within the OPM CLI. The system will transform abstract OPM modules into concrete Kubernetes manifests using a provider/transformer architecture. The core logic will reside entirely within the CLI, utilizing a parallel execution pipeline designed around CUE's concurrency constraints.

## Technical Context

**Language/Version**: Go 1.25.0
**Primary Dependencies**:

- cuelang.org/go v0.15.3 (Core engine)
- github.com/spf13/cobra v1.10.2 (CLI)
- github.com/spf13/viper v1.21.0 (Config)
- k8s.io/client-go v0.35.0 (Types)
- github.com/homeport/dyff v1.10.3 (Diffing)
- github.com/charmbracelet/log v0.4.2 (Logging)

**Architecture Decision - Parallelism**:

- **Pattern**: Isolated Context Worker Pool.
- **Problem**: `cue.Context` is not thread-safe.
- **Solution**: The pipeline will use a worker pool where each worker maintains its own isolated `cue.Context`.
- **Transport**: Data will be passed from the main thread to workers as `cue/ast.Node` objects (via `Value.Syntax(cue.Final(), cue.Concrete(true))`). This avoids the overhead of JSON serialization while maintaining thread safety.

**Input Strategy**:

- The renderer will operate on the `#ModuleRelease` definition. This ensures all component values are concrete/closed before rendering begins, simplifying the pipeline logic.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Type Safety First**: PASS. The design relies on CUE for all definitions.
- **II. Separation of Concerns**: PASS. Rendering is decoupled from definition.
- **III. Policy Built-In**: PASS. Policies are part of the matching criteria.
- **IV. Portability by Design**: PASS. Provider-based architecture.
- **V. Semantic Versioning**: PASS.
- **VI. Simplicity & YAGNI**: PASS. Complexity of parallel workers is justified by performance requirements for large modules.

## Project Structure

### Documentation (this feature)

```text
specs/013-cli-render-spec/
├── plan.md              # This file
├── research.md          # Research findings (Architecture & CUE SDK)
├── data-model.md        # Data model details
├── quickstart.md        # User guide
├── contracts/           # CUE contracts
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
cli/
├── internal/
│   ├── cmd/
│   │   └── mod/
│   │       └── build.go      # Primary command logic (Entry point)
│   ├── render/               # NEW: Core render logic
│   │   ├── pipeline.go       # Orchestrator (Serial matching phase)
│   │   ├── worker.go         # Worker logic (Parallel execution phase)
│   │   ├── types.go          # Go structs (TransformerContext, Job, Result)
│   │   └── provider.go       # Provider loading & transformer indexing
│   ├── cue/                  
│   │   └── loader.go         # Existing CUE loader (used to load ModuleRelease)
│   ├── kubernetes/           
│   │   └── client.go         # K8s helpers
│   └── output/               
│       └── writer.go         # Output formatting (YAML/JSON/Split)
└── tests/
    └── integration/
        └── render_test.go    # End-to-end tests
```

**Structure Decision**: A new package `cli/internal/render` is created to encapsulate the complex rendering logic, keeping it separate from generic CUE utilities in `cli/internal/cue`.

## Implementation Steps

1. **Scaffold Package**: Create `cli/internal/render` and defined types in `types.go`.
2. **Provider Logic**: Implement `provider.go` to load providers and index transformers from the registry.
3. **Worker Implementation**: Implement `worker.go` with the isolated `cue.Context` logic and AST re-hydration.
4. **Pipeline Orchestration**: Implement `pipeline.go` to handle module loading, component matching, and worker dispatch.
5. **Command Integration**: Update `cli/internal/cmd/mod/build.go` to use the new `render` package.
6. **Output & Redaction**: Implement output formatting and secret redaction.
7. **Testing**: Add integration tests covering parallel execution and error handling.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Parallel Worker Pool | Performance (FR-015) | Serial execution is too slow for large modules; Single-context concurrency is unsafe in CUE. |
