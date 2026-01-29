# Research Report: Timoni's `mod vet` Implementation

**Feature**: CLI Module Validation  
**Research Date**: 2026-01-29  
**Source**: Timoni v0.x codebase  
**Purpose**: Understand Timoni's validation implementation to inform OPM's `mod vet` design

## Executive Summary

Timoni's `timoni mod vet` command validates CUE modules by building them with default/custom values and validating the resulting Kubernetes objects. The implementation uses CUE's native validation capabilities (`cuelang.org/go`) combined with Kubernetes resource schema validation through unstructured objects.

**Key Findings**:

- Uses Go CUE SDK directly (not shelling out to `cue` binary)
- Four-phase validation pipeline: structure → load → build → extract
- Supports debug values, custom packages, and multiple values files
- Validates both CUE schema and generated Kubernetes resources
- Provides detailed error messages with file locations

## Architecture Overview

### File Structure

```text
timoni/
├── cmd/timoni/
│   ├── mod_vet.go         # Command implementation
│   └── mod_vet_test.go    # Test suite
├── internal/engine/
│   ├── module_builder.go  # Core validation logic
│   ├── resourceset.go     # K8s resource extraction
│   ├── values_builder.go  # Values merging
│   └── utils.go           # Helper functions
├── api/v1alpha1/
│   └── instance.go        # Schema definitions
└── internal/engine/fetcher/
    └── fetcher.go         # Module loading (local/OCI)
```

### Component Responsibilities

| Component | Responsibility | Key Methods |
|-----------|---------------|-------------|
| `mod_vet.go` | CLI interface, flag parsing | `runVetModCmd()` |
| `module_builder.go` | CUE loading, validation | `NewModuleBuilder()`, `Build()`, `WriteSchemaFile()` |
| `resourceset.go` | K8s resource extraction | `GetResources()` |
| `values_builder.go` | Values file merging | `MergeValues()` |
| `fetcher/fetcher.go` | Module source resolution | `New()`, `Fetch()` |

## Command Structure

### CLI Flags

Timoni's `mod vet` command structure (`cmd/timoni/mod_vet.go:40-72`):

```go
type vetModFlags struct {
    path        string
    pkg         flags.Package
    debug       bool
    valuesFiles []string
    name        string
}

var vetModCmd = &cobra.Command{
    Use:     "vet [MODULE PATH]",
    Aliases: []string{"lint"},
    Short:   "Validate a local module",
    Long:    `The vet command builds the local module and validates the resulting Kubernetes objects.`,
    RunE:    runVetModCmd,
}

func init() {
    vetModCmd.Flags().StringVar(&vetModArgs.name, "name", "default", "Name of the instance used to build the module")
    vetModCmd.Flags().VarP(&vetModArgs.pkg, vetModArgs.pkg.Type(), vetModArgs.pkg.Shorthand(), vetModArgs.pkg.Description())
    vetModCmd.Flags().BoolVar(&vetModArgs.debug, "debug", false,
        "Use debug_values.cue if found in the module root instead of the default values.")
    vetModCmd.Flags().StringSliceVarP(&vetModArgs.valuesFiles, "values", "f", nil,
        "The local path to values files (cue, yaml or json format).")
    modCmd.AddCommand(vetModCmd)
}
```

**Flags Breakdown**:

- `--name`: Instance name for building (default: "default")
- `--package (-p)`: CUE package to validate (custom flag type)
- `--debug`: Use `debug_values.cue` instead of default values
- `--values (-f)`: Additional values files (supports CUE, YAML, JSON)
- `--namespace`: Kubernetes namespace (inherited from global kubeconfig flags)

### Validation Flow

The `runVetModCmd` function (`mod_vet.go:74-210`) implements a four-phase pipeline:

```text
┌─────────────────────────────────────────────────────────────┐
│                   Timoni Validation Pipeline                │
├─────────────────────────────────────────────────────────────┤
│  Phase 1: Setup & Module Fetching                           │
│           ├─ Create temp directory                          │
│           ├─ Initialize fetcher (local/OCI)                 │
│           └─ Fetch module to temp dir                       │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: Debug Values Handling                             │
│           ├─ Check if --debug flag set                      │
│           ├─ Copy debug_values.cue if exists                │
│           └─ Set CUE tags for debug mode                    │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: Module Building                                   │
│           ├─ Create ModuleBuilder                           │
│           ├─ Write schema file (timoni.schema.cue)          │
│           ├─ Merge custom values if provided                │
│           └─ Build module with tags                         │
├─────────────────────────────────────────────────────────────┤
│  Phase 4: Resource Extraction & Validation                  │
│           ├─ Extract apply sets (K8s resources)             │
│           ├─ Extract container images                       │
│           ├─ Validate image references                      │
│           └─ Display success summary                        │
└─────────────────────────────────────────────────────────────┘
```

### Phase Implementation Details

#### Phase 1: Setup & Module Fetching

```go
func runVetModCmd(cmd *cobra.Command, args []string) error {
    // Parse module path
    if len(args) < 1 {
        vetModArgs.path = "."
    } else {
        vetModArgs.path = args[0]
    }

    // Create temp directory
    tmpDir, err := os.MkdirTemp("", apiv1.FieldManager)
    if err != nil {
        return err
    }
    defer os.RemoveAll(tmpDir)

    // Initialize fetcher (local or OCI)
    f, err := fetcher.New(ctxPull, fetcher.Options{
        Source:       vetModArgs.path,
        Version:      apiv1.LatestVersion,
        Destination:  tmpDir,
        CacheDir:     rootArgs.cacheDir,
        Insecure:     rootArgs.registryInsecure,
        DefaultLocal: true,
    })
    if err != nil {
        return err
    }

    // Fetch module
    mod, err := f.Fetch()
    if err != nil {
        return err
    }
    // ...
}
```

**Key Insights**:

- Uses temp directory to isolate build artifacts
- Fetcher abstraction supports both local paths and OCI registries
- `DefaultLocal: true` makes local paths the default without `file://` prefix

#### Phase 2: Debug Values Handling

```go
var tags []string
if vetModArgs.debug {
    dv := path.Join(vetModArgs.path, "debug_values.cue")
    if _, err := os.Stat(dv); err == nil {
        if cpErr := cp.Copy(dv, path.Join(tmpDir, "module", "debug_values.cue")); cpErr != nil {
            return cpErr
        }
        tags = append(tags, "debug")
        log.Info("vetting with debug values")
    } else {
        log.Info("vetting with default values (debug values not found)")
    }
} else {
    log.Info("vetting with default values")
}
```

**Key Insights**:

- Copies `debug_values.cue` to temp dir rather than loading directly
- Uses CUE tags (`@tag(debug)`) to conditionally activate debug values
- Falls back gracefully with informative logging

#### Phase 3: Module Building

```go
builder := engine.NewModuleBuilder(
    cuectx,
    vetModArgs.name,
    *kubeconfigArgs.Namespace,
    f.GetModuleRoot(),
    vetModArgs.pkg.String(),
)

// Write schema file (injects Timoni instance schema)
if err := builder.WriteSchemaFile(); err != nil {
    return err
}

// Get module name from cue.mod/module.cue
mod.Name, err = builder.GetModuleName()
if err != nil {
    return fmt.Errorf("build failed: %w", err)
}

// Merge custom values files
if len(vetModArgs.valuesFiles) > 0 {
    valuesCue, err := convertToCue(cmd, vetModArgs.valuesFiles)
    if err != nil {
        return err
    }
    err = builder.MergeValuesFile(valuesCue)
    if err != nil {
        return err
    }
}

// Build the module
buildResult, err := builder.Build(tags...)
if err != nil {
    return describeErr(f.GetModuleRoot(), "validation failed", err)
}
```

**Key Insights**:

- `ModuleBuilder` encapsulates CUE loading and evaluation
- `WriteSchemaFile()` generates runtime schema constraints
- `MergeValuesFile()` unifies custom values with module defaults
- `Build()` accepts tags for conditional compilation

#### Phase 4: Resource Extraction & Validation

```go
// Extract apply sets (Kubernetes resources)
applySets, err := builder.GetApplySets(buildResult)
if err != nil {
    return fmt.Errorf("build failed: %w", err)
}

if len(applySets) == 0 {
    return fmt.Errorf("%s contains no objects", apiv1.ApplySelector)
}

var objects []*unstructured.Unstructured
for _, set := range applySets {
    objects = append(objects, set.Objects...)
}

if len(objects) == 0 {
    return fmt.Errorf("build failed, no objects to apply")
}

// Validate and display resources
for _, object := range objects {
    log.Info(fmt.Sprintf("%s %s",
        logger.ColorizeSubject(ssautil.FmtUnstructured(object)), logger.ColorizeInfo("valid resource")))
}

// Extract and validate container images
images, err := builder.GetContainerImages(buildResult)
if err != nil {
    return fmt.Errorf("failed to extract images: %w", err)
}

for _, image := range images {
    if _, err := name.ParseReference(image); err != nil {
        log.Error(err, "invalid image")
        continue
    }

    if !strings.Contains(image, "@sha") {
        log.Info(fmt.Sprintf("%s %s",
            logger.ColorizeSubject(image), logger.ColorizeWarning("valid image (digest missing)")))
    } else {
        log.Info(fmt.Sprintf("%s %s",
            logger.ColorizeSubject(image), logger.ColorizeInfo("valid image")))
    }
}

log.Info(fmt.Sprintf("%s %s",
    logger.ColorizeSubject(mod.Name), logger.ColorizeInfo("valid module")))

return nil
```

**Key Insights**:

- Extracts Kubernetes resources from CUE build result
- Validates image references using `go-containerregistry`
- Warns on missing image digests (not pinned)
- Displays entity summary on success

## Core Components Deep Dive

### 1. ModuleBuilder (`internal/engine/module_builder.go`)

The `ModuleBuilder` is the heart of Timoni's validation system.

#### Constructor

```go
func NewModuleBuilder(ctx *cue.Context, name, namespace, moduleRoot, pkgName string) *ModuleBuilder {
    if ctx == nil {
        ctx = cuecontext.New()
    }
    b := &ModuleBuilder{
        ctx:           ctx,
        moduleRoot:    moduleRoot,
        pkgName:       pkgName,
        pkgPath:       moduleRoot,
        name:          name,
        namespace:     namespace,
        moduleVersion: DefaultDevelVersion,
        kubeVersion:   defaultKubeVersion,
    }

    if kv := os.Getenv("TIMONI_KUBE_VERSION"); kv != "" {
        b.kubeVersion = kv
    }

    if pkgName != defaultPackage {
        b.pkgPath = filepath.Join(moduleRoot, pkgName)
    }
    return b
}
```

**Key Insights**:

- Accepts CUE context for dependency injection
- Supports multi-package modules (via `pkgPath`)
- Injects version info for CUE tags

#### Build Method

```go
func (b *ModuleBuilder) Build(tags ...string) (cue.Value, error) {
    var value cue.Value
    cfg := &load.Config{
        AcceptLegacyModules: true,
        ModuleRoot:          b.moduleRoot,
        Package:             b.pkgName,
        Dir:                 b.pkgPath,
        DataFiles:           true,
        Tags: []string{
            "name=" + b.name,
            "namespace=" + b.namespace,
        },
        TagVars: map[string]load.TagVar{
            "moduleVersion": {
                Func: func() (ast.Expr, error) {
                    return ast.NewString(b.moduleVersion), nil
                },
            },
            "kubeVersion": {
                Func: func() (ast.Expr, error) {
                    return ast.NewString(b.kubeVersion), nil
                },
            },
        },
    }

    if len(tags) > 0 {
        cfg.Tags = append(cfg.Tags, tags...)
    }

    modInstances := load.Instances([]string{}, cfg)
    if len(modInstances) == 0 {
        return value, errors.New("no instances found")
    }

    modInstance := modInstances[0]
    if modInstance.Err != nil {
        return value, fmt.Errorf("instance error: %w", modInstance.Err)
    }

    modValue := b.ctx.BuildInstance(modInstance)
    if modValue.Err() != nil {
        return value, modValue.Err()
    }

    // Extract the Timoni instance from the build value
    instance := modValue.LookupPath(cue.ParsePath(apiv1.InstanceSelector.String()))
    if instance.Err() != nil {
        return modValue, fmt.Errorf("lookup %s failed: %w", apiv1.InstanceSelector, instance.Err())
    }

    // Validate the Timoni instance which should be concrete and final
    if err := instance.Validate(cue.Concrete(true), cue.Final()); err != nil {
        return modValue, err
    }

    return modValue, nil
}
```

**Key Insights**:

- Uses `load.Config` for CUE package loading
- Injects runtime values via `Tags` (name, namespace) and `TagVars` (versions)
- Validates using `cue.Concrete(true)` and `cue.Final()` - requires all values to be resolved
- Extracts specific CUE path (`timoni.instance`) for validation

#### Values Merging

```go
func (b *ModuleBuilder) MergeValuesFile(overlays [][]byte) error {
    vb := NewValuesBuilder(b.ctx)
    defaultFile := filepath.Join(b.pkgPath, defaultValuesFile)

    finalVal, err := vb.MergeValues(overlays, defaultFile)
    if err != nil {
        return err
    }

    if err := finalVal.Err(); err != nil {
        return err
    }

    cueGen := fmt.Sprintf("package %s\n%s: %v", b.pkgName, apiv1.ValuesSelector, finalVal)

    // Overwrite the values.cue file with the merged values
    if err := os.MkdirAll(b.moduleRoot, os.ModePerm); err != nil {
        return err
    }
    return os.WriteFile(defaultFile, []byte(cueGen), 0644)
}
```

**Key Insights**:

- Merges values using `ValuesBuilder` helper
- Overwrites `values.cue` with merged result (in temp dir)
- Validates merged values before writing

### 2. ResourceSet Extraction (`internal/engine/resourceset.go`)

Converts CUE values to Kubernetes unstructured objects:

```go
type ResourceSet struct {
    Name    string
    Objects []*unstructured.Unstructured
}

func GetResources(value cue.Value) ([]ResourceSet, error) {
    var sets []ResourceSet

    // Validate concrete and final
    if err := value.Validate(cue.Concrete(true), cue.Final()); err != nil {
        return nil, err
    }

    iter, err := value.Fields(cue.Concrete(true), cue.Final())
    if err != nil {
        return nil, fmt.Errorf("getting resources failed: %w", err)
    }
    
    for iter.Next() {
        name := iter.Selector().String()
        expr := iter.Value()
        if expr.Err() != nil {
            return nil, fmt.Errorf("getting value of resource list %q failed: %w", name, expr.Err())
        }

        items, err := expr.List()
        if err != nil {
            return nil, fmt.Errorf("listing objects in resource list %q failed: %w", name, err)
        }

        // Convert CUE to YAML
        data, err := yaml.EncodeStream(items)
        if err != nil {
            return nil, fmt.Errorf("converting objects for resource list %q failed: %w", name, err)
        }

        // Parse as Kubernetes objects
        objects, err := ssautil.ReadObjects(bytes.NewReader(data))
        if err != nil {
            return nil, fmt.Errorf("loading objects for resource list %q failed: %w", name, err)
        }

        sets = append(sets, ResourceSet{
            Name:    name,
            Objects: objects,
        })
    }
    return sets, nil
}
```

**Key Insights**:

- Requires concrete and final values (no open fields)
- Converts CUE to YAML stream using `cuelang.org/go/encoding/yaml`
- Uses Flux SSA utils (`github.com/fluxcd/pkg/ssa/utils`) for K8s parsing
- Groups resources into named sets (e.g., `timoni.apply.all`)

### 3. Fetcher Abstraction (`internal/engine/fetcher/fetcher.go`)

Supports both local and OCI module sources:

```go
type Fetcher interface {
    Fetch() (*apiv1.ModuleReference, error)
    GetModuleRoot() string
}

type Options struct {
    Source       string  // Location of the module
    Version      string  // Version to fetch
    Destination  string  // Where to store fetched module
    CacheDir     string  // Cache directory
    Creds        string  // Credentials
    Insecure     bool    // Allow insecure connections
    DefaultLocal bool    // Default to local fetcher
}

func New(ctx context.Context, opts Options) (Fetcher, error) {
    switch {
    case strings.HasPrefix(opts.Source, apiv1.ArtifactPrefix):
        return NewOCI(ctx, opts.Source, opts.Version, opts.Destination, opts.CacheDir, opts.Creds, opts.Insecure), nil
    case strings.HasPrefix(opts.Source, apiv1.LocalPrefix):
        return NewLocal(opts.Source, opts.Destination), nil
    default:
        if opts.DefaultLocal {
            return NewLocal(opts.Source, opts.Destination), nil
        }
        return nil, fmt.Errorf("unsupported module source %s", opts.Source)
    }
}
```

**Key Insights**:

- Factory pattern based on source prefix (`oci://` or `file://`)
- `DefaultLocal: true` treats paths without prefix as local
- Returns `ModuleReference` with metadata (name, version, digest)

## Validation Checks Performed

Timoni's `mod vet` performs the following checks:

### 1. Project Structure

- `cue.mod/module.cue` exists (CUE module metadata)
- Package directory exists at specified path
- Module can be loaded without file system errors

### 2. CUE Syntax & Imports

- All CUE files have valid syntax
- All imports can be resolved
- No circular dependencies

### 3. Instance Validation

- `timoni.instance` path exists in built value
- Instance validates as concrete (all values resolved)
- Instance validates as final (no open unifications)
- API version matches expected format

### 4. Resource Extraction

- `timoni.apply` contains resource sets
- At least one apply set exists
- At least one resource object exists
- Resources can be converted to YAML
- Resources parse as valid Kubernetes unstructured objects

### 5. Image Validation

- All container images can be parsed by `go-containerregistry`
- Images with digests are highlighted as secure
- Images without digests receive warnings

## Error Handling Patterns

### Custom Error Messages

```go
func describeErr(moduleRoot, msg string, err error) error {
    // Enhanced error with file location and context
    // Implementation details vary by error type
}
```

Timoni provides enhanced errors with:

- File location (when available)
- Context about what was being validated
- Suggested fixes (for common errors)

### Example Errors

**Missing package**:

```
Error: cannot find package components
  Module path: /path/to/module
  
Ensure the package exists at /path/to/module/components
```

**CUE validation error**:

```
Error: validation failed
  File: module.cue:24:5
  
metadata.name: conflicting values "foo" and "bar"
```

**Unresolved import**:

```
Error: cannot resolve import "example.com/my-module"
  
Check that the module is published to your configured registry.
Run 'timoni mod tidy' to resolve dependencies.
```

## Testing Patterns

Timoni uses table-driven tests with test fixtures (`mod_vet_test.go`):

```go
func TestModVet(t *testing.T) {
    modPath := "testdata/module"

    t.Run("vets module with default values", func(t *testing.T) {
        g := NewWithT(t)
        output, err := executeCommand(fmt.Sprintf(
            "mod vet %s -p main",
            modPath,
        ))
        g.Expect(err).ToNot(HaveOccurred())
        g.Expect(output).To(ContainSubstring("timoni:latest-dev@sha256:"))
        g.Expect(output).To(ContainSubstring("timoni.sh/test valid"))
    })

    t.Run("fails to vet with undefined package", func(t *testing.T) {
        g := NewWithT(t)
        _, err := executeCommand(fmt.Sprintf(
            "mod vet %s -p test",
            modPath,
        ))
        g.Expect(err).To(HaveOccurred())
        g.Expect(err.Error()).To(ContainSubstring("cannot find package"))
    })
}
```

**Test Coverage**:

- Valid modules with default values
- Invalid packages
- Custom values files
- Conflicting values
- Name and namespace overrides

## Module Structure Expectations

Timoni modules have this structure:

```text
my-module/
├── cue.mod/
│   ├── module.cue           # CUE module metadata
│   └── pkg/                 # Imported dependencies
│       └── timoni.sh/
│           └── core/v1alpha1/
├── templates/
│   ├── config.cue           # #Config schema
│   ├── deployment.cue       # K8s Deployment template
│   └── service.cue          # K8s Service template
├── timoni.cue               # Main instance definition
├── values.cue               # Default values
└── debug_values.cue         # Debug values (optional)
```

### Key Files

**`timoni.cue`** - Defines the Timoni instance:

```cue
package main

import (
    templates "timoni.sh/test/templates"
)

values: templates.#Config

timoni: {
    apiVersion: "v1alpha1"
    
    instance: templates.#Instance & {
        config: values
        config: {
            metadata: {
                name: string @tag(name)
                namespace: string @tag(namespace)
            }
            moduleVersion: string @tag(mv, var=moduleVersion)
            kubeVersion: string @tag(kv, var=kubeVersion)
        }
    }
    
    apply: all: [for obj in instance.objects {obj}]
}
```

**`values.cue`** - Concrete default values:

```cue
package main

values: {
    team: "test"
    replicas: 1
}
```

### Instance Schema

Injected by `WriteSchemaFile()`:

```cue
package main

#Timoni: {
    apiVersion: string & =~"^v1alpha1$"
    instance: {...}
    apply: [string]: [...]
}

timoni: #Timoni
```

## Similarities OPM Can Adopt

1. **Module Builder Pattern**: Reusable builder encapsulating CUE loading, validation, and rendering
2. **CUE Tag Injection**: Use `load.Config` with `Tags` and `TagVars` for runtime values (name, namespace, versions)
3. **Two-Phase Validation**:
   - Phase 1: CUE schema validation (structure, syntax, imports)
   - Phase 2: Concrete validation (all values resolved)
4. **Fetcher Abstraction**: Support local and OCI module sources via interface
5. **Temporary Build Directory**: Use temp dir to avoid polluting module source
6. **Error Aggregation**: Collect multiple errors and report together (fail-on-end)
7. **Entity Summary Output**: Show validated entities on success for user confidence

## Key Differences for OPM

1. **Definition Types**: OPM has `#Module`, `#Component`, `#Scope` - need separate validation
2. **No Kubernetes Resources**: OPM validates CUE definitions, not K8s objects (that's for `mod build`)
3. **Optional Concrete Mode**: OPM schema validation doesn't require concrete values by default
4. **Multi-Package Support**: OPM's advanced template uses subdirectories (`components/`, `scopes/`)
5. **No Instance Wrapper**: OPM validates `#Module` directly, not wrapped in `timoni.instance`

## Recommended Implementation Strategy for OPM

Based on Timoni's patterns, here's the recommended approach for `opm mod vet`:

```go
// opm/cli/internal/vet/module_vet.go
type ModuleVet struct {
    ctx        *cue.Context
    moduleRoot string
    pkgName    string
}

func NewModuleVet(ctx *cue.Context, moduleRoot, pkgName string) *ModuleVet {
    if ctx == nil {
        ctx = cuecontext.New()
    }
    return &ModuleVet{
        ctx:        ctx,
        moduleRoot: moduleRoot,
        pkgName:    pkgName,
    }
}

func (v *ModuleVet) Validate(concrete bool) error {
    // Phase 1: Project structure validation
    if err := v.validateStructure(); err != nil {
        return err
    }
    
    // Phase 2: Load CUE instances
    cfg := &load.Config{
        ModuleRoot: v.moduleRoot,
        Package:    v.pkgName,
        Dir:        v.moduleRoot,
    }
    
    instances := load.Instances([]string{}, cfg)
    if len(instances) == 0 {
        return fmt.Errorf("no CUE instances found")
    }
    
    inst := instances[0]
    if inst.Err != nil {
        return fmt.Errorf("load error: %w", inst.Err)
    }
    
    value := v.ctx.BuildInstance(inst)
    if value.Err() != nil {
        return value.Err()
    }
    
    // Phase 3: Schema validation
    if err := v.validateSchema(value); err != nil {
        return err
    }
    
    // Phase 4: Concrete validation (optional)
    if concrete {
        if err := value.Validate(cue.Concrete(true), cue.Final()); err != nil {
            return err
        }
    }
    
    return nil
}

func (v *ModuleVet) validateStructure() error {
    // Check for cue.mod/module.cue
    // Check for module.cue
    // Check for values.cue
}

func (v *ModuleVet) validateSchema(value cue.Value) error {
    // Validate against #Module schema
    // Extract and validate components
    // Extract and validate scopes
}
```

## Technology Stack

| Dependency | Purpose | Version |
|------------|---------|---------|
| `cuelang.org/go` | CUE SDK | v0.11+ |
| `github.com/spf13/cobra` | CLI framework | Latest |
| `github.com/fluxcd/pkg/ssa/utils` | K8s resource parsing | Latest |
| `k8s.io/apimachinery` | Unstructured objects | Latest |
| `github.com/google/go-containerregistry` | Image validation | Latest |
| `github.com/otiai10/copy` | File copying | Latest |

## References

**Key Files to Study**:

- `cmd/timoni/mod_vet.go` - Command implementation
- `internal/engine/module_builder.go` - Core validation logic
- `internal/engine/resourceset.go` - Resource extraction
- `internal/engine/values_builder.go` - Values merging
- `api/v1alpha1/instance.go` - Instance schema

**Documentation**:

- [Timoni Module Documentation](https://timoni.sh/cue/module/)
- [CUE Language Specification](https://cuelang.org/docs/)
- [CUE Go API](https://pkg.go.dev/cuelang.org/go/cue)

## Conclusion

Timoni's `mod vet` provides a solid foundation for OPM's validation command. The key takeaways are:

1. Use Go CUE SDK directly for better control and error formatting
2. Implement a multi-phase validation pipeline
3. Support debug values and custom packages
4. Provide detailed, actionable error messages
5. Show entity summary on success

OPM should adapt these patterns while accounting for differences in definition types (Module vs. Timoni Instance) and validation scope (schema-first vs. always-concrete).
