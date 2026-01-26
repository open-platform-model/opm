# Data Model: OPM CLI v2

**Plan**: [plan.md](./plan.md) | **Date**: 2026-01-22

This document defines the key Go types and data structures for the OPM CLI.

## Core Types

### Config

Configuration loaded from `~/.opm/config.yaml` and environment variables. The YAML config is validated against an embedded CUE schema.

```go
// Package: internal/config

// Config represents the OPM CLI configuration
// Loaded from ~/.opm/config.yaml, validated against embedded CUE schema
type Config struct {
    // Kubeconfig is the path to the kubeconfig file
    // Env: OPM_KUBECONFIG, Default: ~/.kube/config
    Kubeconfig string `yaml:"kubeconfig,omitempty" json:"kubeconfig,omitempty"`
    
    // Context is the Kubernetes context to use
    // Env: OPM_CONTEXT, Default: current-context from kubeconfig
    Context string `yaml:"context,omitempty" json:"context,omitempty"`
    
    // Namespace is the default namespace for operations
    // Env: OPM_NAMESPACE, Default: "default"
    Namespace string `yaml:"namespace,omitempty" json:"namespace,omitempty"`
    
    // Registry is the default registry for all CUE module resolution and OCI operations.
    // When set, all CUE imports resolve from this registry (passed to CUE via CUE_REGISTRY).
    // Also used as default for publish/get commands.
    // Env: OPM_REGISTRY
    Registry string `yaml:"registry,omitempty" json:"registry,omitempty"`
    
    // CacheDir is the local cache directory
    // Env: OPM_CACHE_DIR, Default: ~/.opm/cache
    CacheDir string `yaml:"cacheDir,omitempty" json:"cacheDir,omitempty"`
}

// Paths contains standard filesystem paths
type Paths struct {
    ConfigFile string // ~/.opm/config.yaml
    CacheDir   string // ~/.opm/cache
    HomeDir    string // ~/.opm
}

// DefaultConfig returns a Config with all default values populated
// Used by `opm config init` to generate initial config file
func DefaultConfig() *Config {
    return &Config{
        Kubeconfig: "~/.kube/config",
        Namespace:  "default",
        CacheDir:   "~/.opm/cache",
    }
}
```

### Config Schema (CUE)

Embedded CUE schema for validating the YAML config file.

```cue
// File: internal/config/schema.cue
package config

#Config: {
    // kubeconfig is the path to the kubeconfig file
    kubeconfig?: string
    
    // context is the Kubernetes context to use
    context?: string
    
    // namespace must be a valid Kubernetes namespace name
    namespace?: string & =~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
    
    // registry is the default registry for all CUE module resolution and OCI operations.
    // When set, all CUE imports resolve from this registry.
    registry?: string
    
    // cacheDir is the local cache directory path
    cacheDir?: string
}
```

### Module

Represents a loaded OPM module.

```go
// Package: internal/cue

// Module represents a loaded OPM module
type Module struct {
    // Metadata from the module definition
    Metadata ModuleMetadata
    
    // Root CUE value after loading and unification
    Value cue.Value
    
    // Directory containing the module
    Dir string
    
    // Values files that were unified
    ValuesFiles []string
}

// ModuleMetadata contains module identification information
type ModuleMetadata struct {
    // APIVersion is the module API version (e.g., "example.com/modules@v0")
    APIVersion string `json:"apiVersion"`
    
    // Name is the module name
    Name string `json:"name"`
    
    // Version is the module version (semver)
    Version string `json:"version"`
    
    // Description is an optional human-readable description
    Description string `json:"description,omitempty"`
}

// Bundle represents a loaded OPM bundle
type Bundle struct {
    // Metadata from the bundle definition
    Metadata BundleMetadata
    
    // Modules contained in the bundle
    Modules map[string]*Module
    
    // Root CUE value
    Value cue.Value
    
    // Directory containing the bundle
    Dir string
}

// BundleMetadata contains bundle identification information
type BundleMetadata struct {
    APIVersion string `json:"apiVersion"`
    Name       string `json:"name"`
    Version    string `json:"version,omitempty"`
}
```

### Manifest

Rendered Kubernetes manifests.

```go
// Package: internal/cue

// Manifest represents a rendered Kubernetes manifest
type Manifest struct {
    // Object is the unstructured Kubernetes object
    Object *unstructured.Unstructured
    
    // ComponentName is the OPM component this manifest belongs to
    ComponentName string
    
    // Weight determines apply/delete order (lower = earlier apply)
    Weight int
}

// ManifestSet is an ordered collection of manifests
type ManifestSet struct {
    // Manifests sorted by weight (ascending for apply)
    Manifests []*Manifest
    
    // Module metadata for labeling
    Module ModuleMetadata
    
    // Namespace override (from --namespace flag)
    NamespaceOverride string
}

// SortForApply sorts manifests in ascending weight order
func (ms *ManifestSet) SortForApply()

// SortForDelete sorts manifests in descending weight order
func (ms *ManifestSet) SortForDelete()
```

### Kubernetes Resources

Types for Kubernetes operations.

```go
// Package: internal/kubernetes

// ResourceWeight maps Kubernetes kinds to their apply/delete weights
// See spec Section 6.2
var ResourceWeight = map[string]int{
    "CustomResourceDefinition":          -100,
    "Namespace":                          0,
    "ClusterRole":                        5,
    "ClusterRoleBinding":                 5,
    "ResourceQuota":                      5,
    "LimitRange":                         5,
    "ServiceAccount":                     10,
    "Role":                               10,
    "RoleBinding":                        10,
    "Secret":                             15,
    "ConfigMap":                          15,
    "StorageClass":                       20,
    "PersistentVolume":                   20,
    "PersistentVolumeClaim":              20,
    "Service":                            50,
    "DaemonSet":                          100,
    "Deployment":                         100,
    "StatefulSet":                        100,
    "ReplicaSet":                         100,
    "Job":                                110,
    "CronJob":                            110,
    "Ingress":                            150,
    "NetworkPolicy":                      150,
    "HorizontalPodAutoscaler":            200,
    "ValidatingWebhookConfiguration":     500,
    "MutatingWebhookConfiguration":       500,
}

// DefaultWeight is used for unknown resource kinds
const DefaultWeight = 100

// Labels used to identify OPM-managed resources
const (
    LabelManagedBy       = "app.kubernetes.io/managed-by"
    LabelManagedByValue  = "open-platform-model"
    LabelModuleName      = "module.opmodel.dev/name"
    LabelModuleNamespace = "module.opmodel.dev/namespace"
    LabelModuleVersion   = "module.opmodel.dev/version"
    LabelComponentName   = "component.opmodel.dev/name"
)

// ApplyOptions configures the apply operation
type ApplyOptions struct {
    // DryRun performs server-side dry run without changes
    DryRun bool
    
    // ShowDiff displays diff before applying
    ShowDiff bool
    
    // Wait blocks until resources are ready
    Wait bool
    
    // Timeout for the operation
    Timeout time.Duration
    
    // Namespace override
    Namespace string
}

// DeleteOptions configures the delete operation
type DeleteOptions struct {
    // DryRun shows what would be deleted without deleting
    DryRun bool
    
    // Force skips confirmation and removes finalizers
    Force bool
    
    // Timeout for the operation
    Timeout time.Duration
}
```

### Health Status

Types for resource health evaluation.

```go
// Package: internal/kubernetes

// HealthStatus represents the health state of a resource
type HealthStatus string

const (
    HealthReady       HealthStatus = "Ready"
    HealthNotReady    HealthStatus = "NotReady"
    HealthProgressing HealthStatus = "Progressing"
    HealthFailed      HealthStatus = "Failed"
    HealthUnknown     HealthStatus = "Unknown"
)

// ResourceStatus represents the status of a single resource
type ResourceStatus struct {
    // Kind is the Kubernetes resource kind
    Kind string
    
    // Name is the resource name
    Name string
    
    // Namespace is the resource namespace (empty for cluster-scoped)
    Namespace string
    
    // Health is the evaluated health status
    Health HealthStatus
    
    // Message provides additional status information
    Message string
    
    // Age is the time since creation
    Age time.Duration
    
    // Component is the OPM component name
    Component string
}

// ModuleStatus represents the aggregate status of a module
type ModuleStatus struct {
    // Module metadata
    Module ModuleMetadata
    
    // Namespace the module is deployed to
    Namespace string
    
    // Resources is the list of resource statuses
    Resources []ResourceStatus
    
    // Summary counts by health status
    Summary StatusSummary
}

// StatusSummary provides aggregate counts
type StatusSummary struct {
    Total       int
    Ready       int
    NotReady    int
    Progressing int
    Failed      int
}

// IsHealthy returns true if all resources are ready
func (ms *ModuleStatus) IsHealthy() bool {
    return ms.Summary.Ready == ms.Summary.Total
}
```

### OCI

Types for OCI registry operations.

```go
// Package: internal/oci

// ArtifactMediaType is the OCI media type for OPM artifacts
const (
    ModuleMediaType = "application/vnd.opm.module.v1+tar+gzip"
    BundleMediaType = "application/vnd.opm.bundle.v1+tar+gzip"
)

// Artifact represents an OCI artifact
type Artifact struct {
    // Reference is the full OCI reference (registry/repo:tag)
    Reference string
    
    // Digest is the artifact digest
    Digest string
    
    // MediaType is the artifact media type
    MediaType string
    
    // Annotations are OCI annotations
    Annotations map[string]string
}

// PublishOptions configures the publish operation
type PublishOptions struct {
    // Tag is the artifact tag (default: "latest")
    Tag string
    
    // Force overwrites existing tag
    Force bool
}

// FetchOptions configures the fetch operation
type FetchOptions struct {
    // Version is the tag/version to fetch (default: "latest")
    Version string
    
    // OutputDir is the directory to extract to
    OutputDir string
}

// Annotations used for OPM artifacts
const (
    AnnotationModuleName    = "dev.opmodel.module.name"
    AnnotationModuleVersion = "dev.opmodel.module.version"
    AnnotationCreated       = "org.opencontainers.image.created"
)
```

### Version

Types for version information.

```go
// Package: internal/version

// Info contains version information
type Info struct {
    // Version is the CLI version (set via ldflags)
    Version string
    
    // GitCommit is the git commit hash
    GitCommit string
    
    // BuildDate is the build timestamp
    BuildDate string
    
    // GoVersion is the Go version used to build
    GoVersion string
    
    // CUESDKVersion is the CUE SDK version (embedded at build time)
    CUESDKVersion string
}

// CUEBinaryInfo contains CUE binary version information
type CUEBinaryInfo struct {
    // Version is the CUE binary version
    Version string
    
    // Path is the path to the CUE binary
    Path string
    
    // Compatible indicates if version matches SDK
    Compatible bool
    
    // Found indicates if CUE binary was found
    Found bool
}

// CUEVersionCompatible checks if binary version is compatible with SDK
func CUEVersionCompatible(sdkVersion, binaryVersion string) bool {
    // Compare MAJOR.MINOR only
    sdkParts := strings.Split(sdkVersion, ".")
    binParts := strings.Split(binaryVersion, ".")
    
    if len(sdkParts) < 2 || len(binParts) < 2 {
        return false
    }
    
    return sdkParts[0] == binParts[0] && sdkParts[1] == binParts[1]
}
```

### Output

Types for terminal output.

```go
// Package: internal/output

// OutputFormat specifies the output format
type OutputFormat string

const (
    FormatYAML  OutputFormat = "yaml"
    FormatJSON  OutputFormat = "json"
    FormatTable OutputFormat = "table"
    FormatDir   OutputFormat = "dir"
)

// DiffResult represents a diff between local and live resources
type DiffResult struct {
    // HasChanges indicates if there are differences
    HasChanges bool
    
    // Added resources (in local, not in cluster)
    Added []string
    
    // Removed resources (in cluster, not in local)
    Removed []string
    
    // Modified resources (different between local and cluster)
    Modified []ModifiedResource
}

// ModifiedResource represents a resource with changes
type ModifiedResource struct {
    // Name is the resource identifier (kind/namespace/name)
    Name string
    
    // Diff is the rendered diff output
    Diff string
}

// Styles contains lipgloss styles for output
type Styles struct {
    // Status styles
    StatusReady       lipgloss.Style
    StatusNotReady    lipgloss.Style
    StatusProgressing lipgloss.Style
    StatusFailed      lipgloss.Style
    
    // Table styles
    TableBorder lipgloss.Style
    TableHeader lipgloss.Style
    
    // Diff styles (delegated to dyff)
}

// DefaultStyles returns the default style configuration
func DefaultStyles() *Styles
```

## Interface Definitions

### Loader

```go
// Package: internal/cue

// Loader loads OPM modules and bundles
type Loader interface {
    // LoadModule loads a module from a directory
    LoadModule(ctx context.Context, dir string, valuesFiles []string) (*Module, error)
    
    // LoadBundle loads a bundle from a directory
    LoadBundle(ctx context.Context, dir string, valuesFiles []string) (*Bundle, error)
}
```

### Renderer

```go
// Package: internal/cue

// Renderer renders modules to Kubernetes manifests
type Renderer interface {
    // RenderModule generates manifests from a module
    RenderModule(ctx context.Context, module *Module) (*ManifestSet, error)
    
    // RenderBundle generates manifests from a bundle
    RenderBundle(ctx context.Context, bundle *Bundle) (*ManifestSet, error)
}
```

### Kubernetes Client

```go
// Package: internal/kubernetes

// Client provides Kubernetes operations
type Client interface {
    // Apply applies resources using server-side apply
    Apply(ctx context.Context, manifests *ManifestSet, opts ApplyOptions) error
    
    // Delete deletes resources by label selector
    Delete(ctx context.Context, selector LabelSelector, opts DeleteOptions) error
    
    // Diff computes diff between manifests and live cluster state
    Diff(ctx context.Context, manifests *ManifestSet) (*DiffResult, error)
    
    // Status retrieves status of deployed resources
    Status(ctx context.Context, selector LabelSelector) (*ModuleStatus, error)
    
    // Wait blocks until resources matching selector are healthy
    Wait(ctx context.Context, selector LabelSelector, timeout time.Duration) error
}

// LabelSelector specifies labels to match resources
type LabelSelector struct {
    ModuleName      string
    ModuleNamespace string
}
```

### OCI Client

```go
// Package: internal/oci

// Client provides OCI registry operations
type Client interface {
    // Publish pushes a module/bundle to a registry
    Publish(ctx context.Context, dir string, ref string, opts PublishOptions) (*Artifact, error)
    
    // Fetch pulls a module/bundle from a registry
    Fetch(ctx context.Context, ref string, opts FetchOptions) error
    
    // Resolve resolves a reference to a digest
    Resolve(ctx context.Context, ref string) (*Artifact, error)
}
```

## State Transitions

### Module Lifecycle

```text
┌─────────────┐     init      ┌─────────────┐
│   (none)    │ ────────────► │   Created   │
└─────────────┘               └─────────────┘
                                    │
                              vet/tidy/build
                                    │
                                    ▼
                              ┌─────────────┐
                              │  Validated  │
                              └─────────────┘
                                    │
                                 apply
                                    │
                                    ▼
                              ┌─────────────┐
                              │  Deployed   │ ◄─── apply (update)
                              └─────────────┘
                                    │
                                 delete
                                    │
                                    ▼
                              ┌─────────────┐
                              │  Deleted    │
                              └─────────────┘
```

### Resource Health States

```text
┌─────────────┐
│  Applying   │
└─────────────┘
      │
      ▼
┌─────────────┐     conditions met     ┌─────────────┐
│ Progressing │ ─────────────────────► │    Ready    │
└─────────────┘                        └─────────────┘
      │                                       │
      │ timeout/error                         │ degraded
      ▼                                       ▼
┌─────────────┐                        ┌─────────────┐
│   Failed    │                        │  NotReady   │
└─────────────┘                        └─────────────┘
```

## Validation Rules

### Module Validation

| Field | Rule |
|-------|------|
| `metadata.apiVersion` | Required, must match pattern `domain/path@vN` |
| `metadata.name` | Required, RFC-1123 subdomain |
| `metadata.version` | Required, valid semver |
| `module.cue` | Must exist at module root |
| `values.cue` | Must exist at module root |
| `cue.mod/module.cue` | Must exist |

### Values File Validation

| Rule |
|------|
| Must be valid CUE, YAML, or JSON |
| Must unify without errors with module schema |
| All required fields (`!`) must be provided |

### Label Validation

| Label | Rule |
|-------|------|
| `module.opmodel.dev/name` | Required, must match module name |
| `module.opmodel.dev/namespace` | Required, must match target namespace |
| `module.opmodel.dev/version` | Required, must match module version |
| `component.opmodel.dev/name` | Required, must match component version |
| `app.kubernetes.io/managed-by` | Required, must be `open-platform-model` |
