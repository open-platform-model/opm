# Research: OPM CLI v2

**Plan**: [plan.md](./plan.md) | **Date**: 2026-01-22

This document captures research findings for technology decisions made during planning.

## 1. CLI Framework: spf13/cobra

### Decision

Use `github.com/spf13/cobra` v1.8+ as the CLI framework.

### Rationale

- **Industry standard**: Used by kubectl, docker, gh, helm, and most major Go CLIs
- **Rich feature set**: Subcommands, persistent flags, flag inheritance, shell completion
- **Excellent documentation**: Well-documented with extensive examples
- **Active maintenance**: Regular releases, responsive to issues
- **Ecosystem**: Works seamlessly with viper for configuration

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| urfave/cli | Simpler API but less ecosystem support, fewer features for complex CLIs |
| kong | Modern type-safe design but smaller community, less tooling support |
| No framework | Too much boilerplate for a CLI of this complexity |

### Integration Notes

```go
// Root command pattern
var rootCmd = &cobra.Command{
    Use:   "opm",
    Short: "Open Platform Model CLI",
    PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
        // Initialize logging, load config, resolve settings (FR-019)
        return initializeGlobals(cmd)
    },
}

// Subcommand group pattern
var modCmd = &cobra.Command{
    Use:   "mod",
    Short: "Module operations",
}

func init() {
    rootCmd.AddCommand(modCmd)
    modCmd.AddCommand(modApplyCmd, modBuildCmd, modDeleteCmd, ...)
}

// Configuration resolution with viper (FR-019)
// Precedence: flags > env > config file > defaults
func initializeConfig(cmd *cobra.Command) (*config.Config, error) {
    viper.SetConfigFile(configPath)
    viper.SetEnvPrefix("OPM")
    viper.AutomaticEnv()
    
    // Bind flags (highest precedence)
    viper.BindPFlag("kubeconfig", cmd.Flags().Lookup("kubeconfig"))
    viper.BindPFlag("namespace", cmd.Flags().Lookup("namespace"))
    // ... bind other flags
    
    // Load config file
    if err := viper.ReadInConfig(); err != nil {
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return nil, err
        }
    }
    
    // Resolve each key with logging (if --verbose)
    resolver := config.NewResolver(viper.GetViper(), cmd.Flags())
    cfg := &config.Config{}
    
    for _, key := range []string{"kubeconfig", "namespace", "registry", "cacheDir"} {
        resolved := resolver.Resolve(key)
        resolver.LogResolution(resolved) // DEBUG level
        // Set cfg field from resolved.Value
    }
    
    return cfg, nil
}
```

---

## 2. Diff Library: homeport/dyff

### Decision

Use `github.com/homeport/dyff` v1.9+ for YAML/JSON diff output.

### Rationale

- **YAML-aware**: Understands YAML structure, not just text diff
- **Semantic comparison**: Handles reordering, type coercion, multi-document YAML
- **Beautiful output**: Colorized, human-readable diff format
- **Used by Helm**: Proven in production for K8s manifest diffing
- **Programmatic API**: Can be used as library, not just CLI

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| sergi/go-diff | Raw text diff, no YAML awareness |
| pmezard/go-difflib | Standard unified diff, less visual |
| Custom with lipgloss | Significant effort, dyff already does this well |

### Integration Notes

```go
import (
    "github.com/homeport/dyff/pkg/dyff"
)

func diffManifests(live, desired []byte) (string, error) {
    from, _ := ytbx.LoadYAMLDocuments(live)
    to, _ := ytbx.LoadYAMLDocuments(desired)
    
    report, err := dyff.CompareInputFiles(from, to)
    if err != nil {
        return "", err
    }
    
    // Use human-readable report writer
    var buf bytes.Buffer
    reportWriter := dyff.HumanReport{
        Report:     report,
        ShowBanner: false,
    }
    reportWriter.WriteReport(&buf)
    return buf.String(), nil
}
```

---

## 3. OCI Library: oras-go v2

### Decision

Use `oras.land/oras-go/v2` v2.5+ for OCI registry operations.

### Rationale

- **CNCF project**: Well-maintained, vendor-neutral
- **Purpose-built**: Designed specifically for OCI artifacts (not just container images)
- **Used by Helm/Flux**: Proven for distributing Helm charts and Flux artifacts
- **Clean API**: v2 has improved ergonomics over v1
- **Auth integration**: Supports docker config.json credentials

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| google/go-containerregistry | More focused on container images, less artifact-friendly |
| fluxcd/pkg/oci | Built on go-containerregistry, adds unnecessary dependency |
| containerd | Too low-level for our needs |

### Integration Notes

```go
import (
    "oras.land/oras-go/v2"
    "oras.land/oras-go/v2/registry/remote"
    "oras.land/oras-go/v2/registry/remote/auth"
)

func pushModule(ctx context.Context, ref string, moduleDir string) error {
    // Create repository reference
    repo, err := remote.NewRepository(ref)
    if err != nil {
        return err
    }
    
    // Configure auth from docker config
    repo.Client = &auth.Client{
        Client: http.DefaultClient,
        Credential: auth.CredentialFunc(func(ctx context.Context, hostport string) (auth.Credential, error) {
            return auth.Credential{}, nil // Load from ~/.docker/config.json
        }),
    }
    
    // Pack and push
    // ... artifact packaging logic
    return oras.Copy(ctx, store, ref, repo, ref, oras.DefaultCopyOptions)
}
```

### Artifact Format

OPM modules will be packaged as OCI artifacts with:
- **Media type**: `application/vnd.opm.module.v1+tar+gzip`
- **Layers**: Single layer containing tar.gz of module directory
- **Annotations**: Module name, version, description

---

## 4. Kubernetes Server-Side Apply

### Decision

Use Kubernetes server-side apply (SSA) with field manager "opm".

### Rationale

- **Declarative**: Server computes diff, handles conflicts
- **Field ownership**: Tracks which controller owns which fields
- **Conflict detection**: Prevents overwriting changes from other sources
- **Recommended approach**: K8s upstream recommends SSA over client-side apply
- **Simpler code**: No need to compute 3-way merge client-side

### Implementation Pattern

```go
import (
    "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
    "k8s.io/apimachinery/pkg/types"
    "k8s.io/client-go/dynamic"
)

func applyResource(ctx context.Context, client dynamic.Interface, obj *unstructured.Unstructured) error {
    gvr := schema.GroupVersionResource{...} // Derive from obj
    
    data, err := json.Marshal(obj)
    if err != nil {
        return err
    }
    
    _, err = client.Resource(gvr).
        Namespace(obj.GetNamespace()).
        Patch(ctx, obj.GetName(), types.ApplyPatchType, data, metav1.PatchOptions{
            FieldManager: "opm",
            Force:        ptr.To(true), // Force ownership transfer
        })
    return err
}
```

### Conflict Handling

- Use `Force: true` to take ownership of fields managed by other controllers
- This matches kubectl behavior with `--force-conflicts`
- Users can opt-out with `--server-side=false` if needed (future enhancement)

---

## 5. Charm Libraries Integration

### Decision

Use Charm ecosystem for terminal UX: lipgloss, log, glamour, huh (spinner only).

### Library Purposes

| Library | Purpose | Key Features Used |
|---------|---------|-------------------|
| lipgloss | Styling | Colors, borders, padding, table rendering |
| lipgloss/table | Tables | Status output, resource lists |
| charmbracelet/log | Logging | Leveled logging, structured fields, colors |
| glamour | Markdown | Help text rendering |
| huh/spinner | Progress | Spinner during `apply --wait` |

### Integration Notes

**Logging Setup**:
```go
import "github.com/charmbracelet/log"

func setupLogging(verbose bool) {
    level := log.InfoLevel
    if verbose {
        level = log.DebugLevel
    }
    
    log.SetLevel(level)
    log.SetReportTimestamp(true)
    log.SetReportCaller(verbose)
}
```

**Table Output**:
```go
import (
    "github.com/charmbracelet/lipgloss"
    "github.com/charmbracelet/lipgloss/table"
)

func renderStatusTable(resources []ResourceStatus) string {
    t := table.New().
        Border(lipgloss.NormalBorder()).
        BorderStyle(lipgloss.NewStyle().Foreground(lipgloss.Color("240"))).
        Headers("KIND", "NAME", "STATUS", "AGE", "MESSAGE")
    
    for _, r := range resources {
        t.Row(r.Kind, r.Name, r.Status, r.Age, r.Message)
    }
    
    return t.String()
}
```

**Spinner for Wait**:
```go
import "github.com/charmbracelet/huh/spinner"

func waitWithSpinner(ctx context.Context, action func() error) error {
    return spinner.New().
        Title("Waiting for resources to become ready...").
        Action(action).
        Run()
}
```

---

## 6. CUE SDK Integration

### Decision

Use `cuelang.org/go` v0.11+ for CUE operations, delegate `vet`/`tidy` to binary.

### Rationale

- **SDK for rendering**: Full control over module loading and manifest generation
- **Binary for tooling**: `cue vet` and `cue mod tidy` are complex, better to delegate
- **Version alignment**: SDK and binary versions must match (MAJOR.MINOR)

### Module Loading Pattern

```go
import (
    "cuelang.org/go/cue"
    "cuelang.org/go/cue/cuecontext"
    "cuelang.org/go/cue/load"
)

func loadModule(dir string, valuesFiles []string) (cue.Value, error) {
    ctx := cuecontext.New()
    
    // Load the module
    instances := load.Instances([]string{"."}, &load.Config{
        Dir: dir,
    })
    
    if len(instances) == 0 {
        return cue.Value{}, errors.New("no instances loaded")
    }
    
    value := ctx.BuildInstance(instances[0])
    if value.Err() != nil {
        return cue.Value{}, value.Err()
    }
    
    // Unify with values files
    for _, vf := range valuesFiles {
        valuesValue, err := loadValuesFile(ctx, vf)
        if err != nil {
            return cue.Value{}, err
        }
        value = value.Unify(valuesValue)
    }
    
    return value, value.Err()
}
```

### Binary Delegation Pattern

```go
func runCueVet(dir string, concrete bool) error {
    // Check version compatibility first
    if err := checkCueVersion(); err != nil {
        return err
    }
    
    args := []string{"vet", "./..."}
    if concrete {
        args = append(args, "--concrete")
    }
    
    cmd := exec.Command("cue", args...)
    cmd.Dir = dir
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    
    return cmd.Run()
}

func checkCueVersion() error {
    // Compare binary version with embedded SDK version
    // Return error with exit code 6 if mismatch
}
```

---

## 7. Testing Strategy

### Decision

Use testify for assertions, envtest for K8s integration tests.

### Test Layers

| Layer | Tool | Purpose |
|-------|------|---------|
| Unit | testify | Pure Go logic, mocked dependencies |
| Integration | envtest | Real K8s API server, test apply/delete/status |
| E2E | testify + exec | Full CLI binary execution |

### envtest Setup

```go
import (
    "sigs.k8s.io/controller-runtime/pkg/envtest"
)

func TestApply(t *testing.T) {
    testEnv := &envtest.Environment{}
    cfg, err := testEnv.Start()
    require.NoError(t, err)
    defer testEnv.Stop()
    
    client, err := dynamic.NewForConfig(cfg)
    require.NoError(t, err)
    
    // Test apply logic
    err = applyResource(context.Background(), client, testDeployment)
    assert.NoError(t, err)
}
```

---

## Summary of Research Findings

All technology decisions have been validated through research:

| Decision | Status | Confidence |
|----------|--------|------------|
| spf13/cobra for CLI | Validated | High |
| homeport/dyff for diff | Validated | High |
| oras-go v2 for OCI | Validated | High |
| Server-side apply | Validated | High |
| Charm libs for UX | Validated | High |
| CUE SDK + binary delegation | Validated | High |
| testify + envtest | Validated | High |

No NEEDS CLARIFICATION items remain.
