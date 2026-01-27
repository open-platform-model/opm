# OPM Rendering Benchmarks

## Overview

This benchmark suite compares the performance difference between rendering **ModuleDefinition** (with blueprint references) and **Module** (pre-compiled with blueprints expanded).

## Purpose

The goal is to quantify the performance overhead of blueprint expansion during module processing. This helps us understand:

1. **Blueprint expansion cost**: How much overhead does blueprint unification add?
2. **Scaling behavior**: How does performance degrade as component count increases?
3. **Optimization opportunities**: Which stages dominate processing time?
4. **Memory impact**: Memory allocation differences between approaches

## Architecture

### ModuleDefinition (Blueprint-based)

Components reference blueprints:

```cue
frontend: workload_blueprints.#StatelessWorkload & {
    spec: statelessWorkload: {
        container: {...}
        replicas: 2
    }
}
```

CUE must:

1. Load the blueprint definition
2. Unify blueprint schema with component spec
3. Resolve all blueprint-composed resources and traits
4. Validate the result

### Module (Pre-compiled)

Blueprints manually expanded to resources + traits:

```cue
frontend: core.#Component & {
    workload_resources.#Container
    workload_traits.#Replicas

    spec: {
        container: {...}
        replicas: 2
    }
}
```

CUE only needs to:

1. Load the component definition
2. Unify resources and traits directly
3. Validate the result

## Test Modules

### Simple (2 components)

- **Frontend**: StatelessWorkload blueprint (web UI)
- **API**: StatelessWorkload blueprint (backend API)

### Moderate (4 components)

- **Frontend**: StatelessWorkload blueprint (web UI)
- **API**: StatelessWorkload blueprint (backend API)
- **Database**: StatefulWorkload blueprint (PostgreSQL)
- **Worker**: StatelessWorkload blueprint (background jobs)

### Large (12 components)

Complete e-commerce platform with microservices architecture:

**Frontend Tier:**

- **Frontend**: StatelessWorkload blueprint (React SPA)

**Gateway Tier:**

- **API Gateway**: StatelessWorkload blueprint (routing & aggregation)

**Backend Services (6 microservices):**

- **Auth Service**: StatelessWorkload blueprint (authentication/JWT)
- **User Service**: StatelessWorkload blueprint (user management)
- **Product Service**: StatelessWorkload blueprint (product catalog)
- **Order Service**: StatelessWorkload blueprint (order processing)
- **Payment Service**: StatelessWorkload blueprint (payment processing)
- **Notification Service**: StatelessWorkload blueprint (email/SMS)

**Data Tier:**

- **PostgreSQL Database**: StatefulWorkload blueprint (relational data)
- **Redis Cache**: StatefulWorkload blueprint (caching layer)
- **MongoDB**: StatefulWorkload blueprint (product catalog NoSQL)

**Worker Tier:**

- **Message Queue Worker**: StatelessWorkload blueprint (background jobs)

## Benchmark Structure

### Full Pipeline Benchmarks

- `BenchmarkRenderModuleDefinition_Simple` - Load + process ModuleDefinition (2 components)
- `BenchmarkRenderModule_Simple` - Load + process Module (2 components)
- `BenchmarkRenderModuleDefinition_Moderate` - Load + process ModuleDefinition (4 components)
- `BenchmarkRenderModule_Moderate` - Load + process Module (4 components)

### Stage Breakdown Benchmarks

**Load Stage:**

- `BenchmarkStage_Load_Simple_ModuleDefinition`
- `BenchmarkStage_Load_Simple_Module`
- `BenchmarkStage_Load_Moderate_ModuleDefinition`
- `BenchmarkStage_Load_Moderate_Module`

**Extract Stage:**

- `BenchmarkStage_Extract_Simple_ModuleDefinition`
- `BenchmarkStage_Extract_Simple_Module`
- `BenchmarkStage_Extract_Moderate_ModuleDefinition`
- `BenchmarkStage_Extract_Moderate_Module`

## Running Benchmarks

### Basic Run

```bash
cd benchmarks/rendering
go test -bench=. -benchmem
```

### Detailed Run (10 seconds per benchmark)

```bash
go test -bench=. -benchmem -benchtime=10s
```

### With CPU and Memory Profiling

```bash
# Generate profiles
go test -bench=. -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof

# Analyze CPU profile
go tool pprof -http=:8080 cpu.prof

# Analyze memory profile
go tool pprof -http=:8081 mem.prof
```

### Run Specific Benchmarks

```bash
# Only simple module benchmarks
go test -bench=Simple -benchmem

# Only stage breakdown benchmarks
go test -bench=Stage -benchmem

# Only ModuleDefinition (blueprint) benchmarks
go test -bench=ModuleDefinition -benchmem

# Only Module (compiled) benchmarks
go test -bench="Module_" -benchmem
```

### Compare Results

```bash
# Run baseline
go test -bench=. -benchmem > baseline.txt

# Make changes...

# Run comparison
go test -bench=. -benchmem > new.txt

# Compare using benchstat (install: go install golang.org/x/perf/cmd/benchstat@latest)
benchstat baseline.txt new.txt
```

## Interpreting Results

### Example Output

```text
BenchmarkRenderModuleDefinition_Simple-8      1000    1234567 ns/op    123456 B/op    1234 allocs/op
BenchmarkRenderModule_Simple-8                2000     987654 ns/op     98765 B/op     987 allocs/op
```

**Fields:**

- `1000` / `2000` - Number of iterations run
- `1234567 ns/op` - Nanoseconds per operation (lower is better)
- `123456 B/op` - Bytes allocated per operation (lower is better)
- `1234 allocs/op` - Number of allocations per operation (lower is better)

### Key Metrics

1. **Time Overhead**

   ```text
   Overhead = (ModuleDefinition_time - Module_time) / Module_time * 100%
   ```

2. **Memory Overhead**

   ```text
   Overhead = (ModuleDefinition_mem - Module_mem) / Module_mem * 100%
   ```

3. **Scaling Factor**

   ```text
   Factor = Moderate_time / Simple_time
   ```

   - Linear scaling: Factor ≈ 2.0 (expected for 4 vs 2 components)
   - Sub-linear scaling: Factor < 2.0 (good caching)
   - Super-linear scaling: Factor > 2.0 (performance degradation)

## Actual Results

### Performance Comparison

**Simple Module (2 components):**

- **ModuleDefinition**: 37.7ms, 11.6 MB, 93K allocs
- **Module (compiled)**: 6.6ms, 4.5 MB, 41.6K allocs
- **Overhead: 5.7x slower, 2.6x more memory, 2.2x more allocations**

**Moderate Module (4 components):**

- **ModuleDefinition**: 129.4ms, 23.1 MB, 177.5K allocs
- **Module (compiled)**: 10.0ms, 5.9 MB, 55.2K allocs
- **Overhead: 13.0x slower, 3.9x more memory, 3.2x more allocations**

**Large Module (12 components):**

- **ModuleDefinition**: 340.1ms, 47.6 MB, 362.7K allocs
- **Module (compiled)**: 16.0ms, 7.9 MB, 78.4K allocs
- **Overhead: 21.3x slower, 6.0x more memory, 4.6x more allocations**

### Key Findings

1. **Blueprint overhead is massive and grows with scale**
   - Small: 5.7x slower
   - Moderate: 13.0x slower
   - Large: 21.3x slower
   - **Overhead is NOT constant - it grows super-linearly!**

2. **Compiled modules scale beautifully**
   - Time increases sub-linearly (2.4x for 6x more components)
   - Memory increases sub-linearly (1.8x for 6x more components)
   - CUE evaluation caching is working very well

3. **Load stage dominates completely**
   - 99%+ of time spent in CUE loading/unification
   - Extract stage is negligible (5-20µs regardless of size)

4. **Super-linear degradation is concerning**
   - Blueprint path doesn't scale well to larger applications
   - Each additional component adds disproportionate overhead
   - Pre-compilation/flattening is essential for production workloads

### Scaling Analysis

**Time Scaling (ModuleDefinition):**

- 2→4 components: 3.4x slower (super-linear degradation)
- 4→12 components: 2.6x slower (super-linear degradation)
- 2→12 components: 9.0x slower overall

**Time Scaling (Module - compiled):**

- 2→4 components: 1.5x slower (sub-linear, excellent caching)
- 4→12 components: 1.6x slower (sub-linear, excellent caching)
- 2→12 components: 2.4x slower overall (excellent scaling!)

### Recommendations

1. **For production deployments**: Always use pre-compiled Module format
2. **For development**: ModuleDefinition is acceptable for small apps (<5 components)
3. **For large applications**: Blueprint overhead becomes prohibitive (>10 components)
4. **Optimization opportunity**: Implement efficient blueprint flattening/caching

## Directory Structure

```text
benchmarks/rendering/
├── README.md                        # This file
├── go.mod                           # Go module definition
├── go.sum                           # Dependency checksums
├── helpers.go                       # Benchmark helper functions
├── benchmark_test.go                # Benchmark suite
├── benchmark_results.txt            # Initial benchmark results
├── benchmark_results_with_large.txt # Full results with large module
└── modules/                         # Test modules
    ├── simple/                      # 2 components
    │   ├── cue.mod/module.cue       # CUE module metadata
    │   ├── module_definition.cue    # ModuleDefinition (blueprints)
    │   └── module_compiled.cue      # Module (compiled)
    ├── moderate/                    # 4 components
    │   ├── cue.mod/module.cue
    │   ├── module_definition.cue
    │   └── module_compiled.cue
    └── large/                       # 12 components
        ├── cue.mod/module.cue
        ├── module_definition.cue    # E-commerce platform
        └── module_compiled.cue      # E-commerce platform (compiled)
```

## Validation Tests

The benchmark suite includes validation tests to ensure modules load correctly:

```bash
# Run validation tests
go test -v -run=TestModuleLoading
```

These tests verify:

- Modules load without errors
- Expected component counts match
- All components validate successfully
- Timing information is logged

## Continuous Benchmarking

To track performance over time:

1. Run benchmarks regularly (e.g., on each commit to main)
2. Store results in version control
3. Use benchstat to compare against baseline
4. Alert on significant regressions (>10% slowdown)

Example workflow:

```bash
# Baseline (commit abc123)
git checkout abc123
go test -bench=. -benchmem > benchmarks/baseline.txt
git add benchmarks/baseline.txt
git commit -m "bench: add baseline for commit abc123"

# New commit (def456)
git checkout def456
go test -bench=. -benchmem > benchmarks/new.txt

# Compare
benchstat benchmarks/baseline.txt benchmarks/new.txt
```

## Future Enhancements

Potential additions to this benchmark suite:

1. **Larger scales**: 8, 16, 32, 64 component modules
2. **Complex blueprints**: Nested blueprint compositions
3. **Provider transformers**: Include transformer matching and execution
4. **Full rendering**: Measure complete pipeline including YAML generation
5. **Parallel loading**: Benchmark parallel module loading
6. **Cache effectiveness**: Measure CUE evaluation caching

## Related Documentation

- [OPM Architecture](../../docs/architecture.md)
- [Blueprint Definition Spec](../../V1ALPHA1_SPECS/BLUEPRINT_DEFINITION.md)
- [Module Architecture](../../V1ALPHA1_SPECS/module_redesign/)
- [CLI Loader Documentation](../../cli/pkg/loader/)

---

**Last Updated**: 2025-11-21
