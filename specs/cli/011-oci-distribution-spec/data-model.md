# Data Model: Distribution Types

**Specification**: [spec.md](./spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-28

## OCI Types

Types for OCI registry interactions.

```go
// Package: internal/oci

// ArtifactMediaType defines OCI media types for OPM artifacts
const (
    ModuleMediaType = "application/vnd.opm.module.v1+tar+gzip"
)

// Artifact represents an OCI artifact
type Artifact struct {
    // Reference is the full OCI reference (registry/repo:tag)
    Reference string
    
    // Digest is the artifact digest (sha256:...)
    Digest string
    
    // MediaType is the artifact media type
    MediaType string
    
    // Annotations are OCI annotations
    Annotations map[string]string
}

// PublishOptions configures the publish operation
type PublishOptions struct {
    // Version is the SemVer version tag (required, e.g., "v1.2.3")
    Version string
    
    // Force overwrites existing tag
    Force bool
}

// FetchOptions configures the fetch operation
type FetchOptions struct {
    // Reference is the OCI reference with version (e.g., "registry/repo@v1.2.3")
    Reference string
    
    // OutputDir is the directory to extract to (defaults to CUE cache)
    OutputDir string
}

// Annotations used for OPM artifacts
const (
    AnnotationModuleName    = "dev.opmodel.module.name"
    AnnotationModuleVersion = "dev.opmodel.module.version"
    AnnotationCreated       = "org.opencontainers.image.created"
    AnnotationSource        = "org.opencontainers.image.source"
    AnnotationAuthors       = "org.opencontainers.image.authors"
)
```

## Dependency Management Types

Types for managing module dependencies.

```go
// Package: internal/cue

// Dependency represents a module dependency
type Dependency struct {
    // ImportPath is the CUE import path (e.g., "registry.example.com/my-module")
    ImportPath string
    
    // Version is the resolved SemVer version
    Version string
    
    // Registry is the registry URL
    Registry string
}

// UpdateInfo represents available update information
type UpdateInfo struct {
    // Current is the currently installed version
    Current string
    
    // Latest is the latest available version matching constraints
    Latest string
    
    // UpdateType is the type of update: "patch", "minor", or "major"
    UpdateType string
}
```

## Registry Configuration Types

Types for registry routing configuration. These types replace the singular `Config.Registry` field from 002-cli-spec with a prefix-based routing map compatible with `CUE_REGISTRY` semantics.

```go
// Package: internal/config

// RegistryEntry defines configuration for a single registry
// Maps to CUE_REGISTRY format: hostname[:port][/repoPrefix][+insecure]
type RegistryEntry struct {
    // URL is the registry URL (hostname[:port][/repoPrefix])
    URL string
    
    // Insecure allows HTTP connections (default: false)
    // Adds +insecure suffix in CUE_REGISTRY format
    Insecure bool
}

// RegistryMap maps module prefixes to registry configurations
// Empty string key ("") represents the default registry
// Example: "" -> default, "company.internal" -> prefix-based routing
type RegistryMap map[string]RegistryEntry

// ToCUERegistry converts the map to CUE_REGISTRY format string.
//
// CUE uses longest-prefix-matching for module resolution: when multiple
// prefixes match a module path, the longest (most specific) wins. This
// matching is order-independent.
//
// To ensure deterministic and reproducible output, this function sorts
// prefixes by length (descending, longest first). The default registry
// (empty key) is always appended last.
//
// Example output: "company.internal/critical=harbor-critical.internal/modules+insecure,company.internal=harbor.internal/modules+insecure,registry.opmodel.dev"
func (m RegistryMap) ToCUERegistry() string {
    var parts []string
    
    // Collect and sort prefixes by length (longest first)
    // This ensures deterministic output; CUE resolves via longest-prefix-wins
    var prefixes []string
    for prefix := range m {
        if prefix != "" {
            prefixes = append(prefixes, prefix)
        }
    }
    sort.Slice(prefixes, func(i, j int) bool {
        return len(prefixes[i]) > len(prefixes[j])
    })
    
    // Build output: prefixed registries first (longest to shortest), then default
    for _, prefix := range prefixes {
        entry := m[prefix]
        part := prefix + "=" + entry.URL
        if entry.Insecure {
            part += "+insecure"
        }
        parts = append(parts, part)
    }
    
    // Append default registry last (empty key)
    if entry, ok := m[""]; ok {
        part := entry.URL
        if entry.Insecure {
            part += "+insecure"
        }
        parts = append(parts, part)
    }
    
    return strings.Join(parts, ",")
}

// ParseCUERegistry parses a CUE_REGISTRY format string into RegistryMap
// Supports: [modulePrefix=]hostname[:port][/repoPrefix][+insecure]
func ParseCUERegistry(s string) (RegistryMap, error)
```

## Example Usage

```go
// Publishing a module
opts := &PublishOptions{
    Version: "v1.2.3",
    Force:   false,
}
artifact, err := oci.Publish(ctx, "registry.example.com/my-module", opts)

// Fetching a module
fetchOpts := &FetchOptions{
    Reference:  "registry.example.com/my-module@v1.2.3",
    OutputDir:  "", // use CUE cache
}
artifact, err := oci.Fetch(ctx, fetchOpts)

// Checking for updates
updates, err := cue.CheckUpdates(ctx, modulePath)
for _, update := range updates {
    fmt.Printf("%s: %s -> %s (%s)\n", 
        update.ImportPath, update.Current, update.Latest, update.UpdateType)
}
```
