# Research Findings: CLI Render System

## 1. CUE Go API & Concurrency

### Context Safety & Parallelism

The CUE Go API (`cuelang.org/go/cue`) is **not thread-safe**. `cue.Value` objects are bound to their `cue.Context` and cannot be accessed concurrently or shared across contexts.

To achieve the **Parallel Execution** requirement (`FR-015`), we must use an **Isolated Context Pattern**:

1. **Main Thread**: Uses a single `mainContext` for module loading and matching.
2. **Worker Pool**: Each worker goroutine creates and maintains its own private `workerContext := cuecontext.New()`.

### Safe Data Transport: `ast.Node`

Instead of serializing components to JSON (which incurs parsing overhead) or passing `cue.Value` objects (which causes race conditions), the optimal transport mechanism is the **CUE Abstract Syntax Tree (`cue/ast`)**.

* **Why**: `ast.Node` is a pure Go struct tree, completely independent of any `cue.Context`, making it thread-safe to pass between goroutines.
* **Mechanism**:
    1. **Export (Main Thread)**: `node := componentValue.Syntax(cue.Final(), cue.Concrete(true))` generates a self-contained AST with all references resolved to concrete values.
    2. **Transport**: Pass the `node` pointer to the worker via a channel.
    3. **Import (Worker Thread)**: `val := workerContext.BuildExpr(node)` re-hydrates the component in the worker's isolated context without re-parsing text.

## 2. Input Source: #ModuleRelease

The render pipeline should operate on the `#ModuleRelease` definition (from `@catalog/v0/core/module_release.cue`).

* **Benefit**: `#ModuleRelease` guarantees that all fields in `components` are concrete (closed) and unified with user values.
* **Simplification**: This removes the need for the renderer to manually handle CUE unification or default value application—it simply consumes the fully resolved state.

## 3. Function Execution in CUE

To execute the `#transform` function in a worker:

1. **Re-hydrate Inputs**: Build `componentVal` (from AST) and `transformerVal` (from AST or cache) in the `workerContext`.
2. **Inject Context**: Use `workerContext.Encode(goContextStruct)` to create the `#context` value from a Go struct.
3. **Construct Call**: Create a unified value:

    ```cue
    {
        #component: <re-hydrated component>
        #context:   <encoded context>
    } & <transformer>
    ```

4. **Extract Output**: Lookup the `output` path and `Decode` it into a Go struct.

## 4. Secret Redaction

The CLI output (especially verbose logs) must not leak secrets.

* **Strategy**: Implement a `Redactor` logger wrapper.
* **Mechanism**:
    1. Maintain a list of known sensitive values (e.g., from `os.Environ()` if injected).
    2. Use heuristic matching for keys (e.g., `password`, `token`, `secret`) in structured logs.
    3. Sanitize all output streams (stdout/stderr) during verbose mode.

## 5. Existing Structure & Integration

* **New Package**: `cli/internal/render` will house the pipeline logic.
* **Entry Point**: `cli/internal/cmd/mod/build.go` will invoke the renderer.
* **Pipeline**: The `Render` function will accept a `*ModuleRelease` and return a list of generated resources or errors.
