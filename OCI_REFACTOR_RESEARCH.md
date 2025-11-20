# OPM OCI Refactor - Research Report

**Date:** 2025-11-08
**Audience:** Implementation teams and AI agents
**Purpose:** Comprehensive research and design specification for OCI-aligned OPM architecture

---

## Executive Summary

### Problem Statement

The current OPM system relies on CUE's native module system for publishing and distribution. While functional, this approach doesn't provide:

- Fine-grained control over artifact structure
- Direct OCI registry authentication management
- Multi-registry support with separate credentials
- Custom artifact types optimized for OPM's architecture
- Explicit control over layer organization and caching

### Goals

**Primary Goals:**

1. **100% OCI Alignment** - Design OPM artifacts as proper OCI artifacts with custom mediaTypes
2. **Registry Authentication** - Support login/logout with Docker-compatible credential storage
3. **Module Publishing** - Publish ModuleDefinitions to OCI registries with proper versioning
4. **Module Fetching** - Retrieve modules from registries using path or full OCI URLs
5. **Multi-Registry Support** - Configure multiple registries with independent credentials

**Success Criteria:**

- ✅ Ability to login/logout of registries (HIGH PRIORITY)
- ✅ Ability to get/publish OPM ModuleDefinitions from/to registry (HIGH PRIORITY)
- ✅ Support for both path-based and full OCI URL references (HIGH PRIORITY)
- ✅ Multiple registries with different credentials in `~/.opm/config.cue` (LOW PRIORITY)

### Key Findings

1. **OCI v1.1 Specification** provides `artifactType` field, enabling custom artifact types without requiring custom config blobs
2. **Multi-layer artifacts** allow separation of ModuleDefinition (source) from compiled Module (optimized IR)
3. **Docker-compatible authentication** enables reuse of existing credential infrastructure
4. **Real-world patterns** from Helm, WASM, and CUE modules provide proven design templates
5. **Content-addressable storage** enables efficient caching and deduplication

---

## Current OPM Architecture

### Module System

OPM implements a three-layer module architecture:

#### 1. ModuleDefinition (v1/core/module.cue)

- **Purpose**: Portable application blueprint created by developers/platform teams
- **Contains**: Components, optional scopes, value schema (constraints only)
- **Metadata FQN**: `{apiVersion}#{name}` (e.g., "opm.dev/modules/core@v1#Blog")
- **Key Characteristic**: No concrete values, no flattened state

#### 2. Module (v1/core/module.cue)

- **Purpose**: Compiled/optimized form (Intermediate Representation)
- **Result of**: Flattening a ModuleDefinition
  - Blueprints expanded into Resources, Traits, and Policies
  - Structure optimized for runtime evaluation
- **State**: Ready for binding with concrete values

#### 3. ModuleRelease (v1/core/module.cue)

- **Purpose**: Concrete deployment instance
- **Contains**: Module reference + concrete values + target namespace
- **Status Tracking**: Phase, conditions, deployedAt, resources
- **Created By**: Users/deployment systems

### Bundle System

#### BundleDefinition (v1/core/bundle.cue)

- **Purpose**: Collection of modules for easier distribution
- **Contains**: Multiple ModuleDefinitions, value schema, metadata

#### Bundle (v1/core/bundle.cue)

- **Purpose**: Compiled bundle form
- **Contains**: Compiled modules

#### BundleRelease (v1/core/bundle.cue)

- **Purpose**: Deployed bundle instance
- **Contains**: Bundle reference + concrete values

### Template System (v1/core/template.cue)

- **Purpose**: Module template for initializing new OPM modules
- **Metadata**: Category (module/bundle), level (beginner/intermediate/advanced), use case
- **FQN Pattern**: `{apiVersion}#{name}`

### Provider System (v1/core/provider.cue)

#### Provider

- **Purpose**: Platform-specific transformer system
- **Contains**: Transformer registry, metadata, declared resources/traits/policies
- **Labels**: Provider categorization (e.g., `"core.opm.dev/format": "kubernetes"`)

#### Transformer

- **Purpose**: Converts platform resources/traits/policies to target format
- **Declares**: Resources, traits, policies it handles
- **Transform Function**: Input (component + context) → Output (provider resources array)

### Current Publishing Mechanism

#### Template Publishing (templates/Taskfile.yml)

- Each template is a separate CUE module
- Published to OCI registry with semantic versioning
- Three official templates: simple, standard, advanced
- Uses `cue mod publish` command
- OCI reference format: `opm.dev/templates/{name}:{version}`
- CUE module format: `opm.dev/templates/{name}@v1`

#### Core Module Publishing (.tasks/publish.yml)

- Module path: `opm.dev@v1`
- Version storage: Per-module versioning in `v1/versions.yml` (legacy: single `v1/VERSION` file)
- Tasks: `publish:local`, `publish:validate`, `publish:test:local`, `release:local`
- Validation: Format check, CUE vet, dependency resolution

#### Registry Infrastructure

- Local registry: `opm-registry` container (registry:2)
- Port: 5000
- Data directory: `.registry-data/`
- Management via Taskfile: start/stop/status/cache-clear

### Current CLI Implementation

#### Configuration (cli/pkg/config/config.go)

```go
type Config struct {
    Registry    RegistryConfig    // OCI registry URL
    Definitions DefinitionsConfig // CUE module import
    Cache       CacheConfig       // Cache settings
    Log         LogConfig         // Logging
}
```

**Defaults:**

- Registry: `localhost:5000`
- Definitions module: `opm.dev@v1`
- Config file: `~/.opm/config.cue`

**Environment Variables:**

- `OPM_REGISTRY_URL`
- `OPM_DEFINITIONS_MODULE`
- `OPM_DEFINITIONS_PATH`
- `OPM_CACHE_DIR`
- `OPM_LOG_LEVEL`, `OPM_LOG_FORMAT`

#### Registry Implementation (cli/internal/registry/registry.go)

**Current State:** Stub implementation with hardcoded data

- `LoadRegistry()` - Returns stub registry
- `ListResources()`, `ListTraits()`, `ListBlueprints()`, `ListPolicies()`, `ListScopes()`
- `GetDefinition()` - Returns stub detail

**Structure:**

```go
type DefinitionInfo struct {
    FQN         string
    Name        string
    Type        string   // "resource", "trait", "blueprint", "policy", "scope"
    Version     string
    Description string
    Tags        []string
}
```

**TODO:** Load from actual CUE definitions

#### Template OCI Support (cli/pkg/template/oci.go)

**Functions:**

- `DownloadTemplate()` - Downloads OCI template using `cue mod get`
- `DownloadTemplateWithFallback()` - OCI with embedded fallback
- Creates temporary CUE module, runs `cue mod get`, extracts content

#### Module Tidy (cli/internal/commands/mod/tidy.go)

**Purpose:** Wrapper around `cue mod tidy`

- Checks CUE binary version (requires v0.15.0+)
- Sets `CUE_REGISTRY` from OPM config
- Validates module structure
- Executes: `cue mod tidy`

### Definition Registry (v1/registry.cue)

**Structure:** Flat lookup map by FQN

- Imports all definitions from packages
- Format: `{FQN}: Definition`
- Example: `"opm.dev/resources/workload@v1#Container": #ContainerResource`

### Key Observations

1. **Template-Focused Publishing** - Templates are primary OCI artifacts currently
2. **CUE Native Module System** - Leverages `cue mod publish/get`
3. **Module vs OCI Format**:
   - Module paths: `@v1` suffix (e.g., `opm.dev/templates/simple@v1`)
   - OCI references: `:version` suffix (e.g., `opm.dev/templates/simple:v1.0.0-alpha.1`)
4. **Configuration-Based Registry** - CLI config specifies registry URL
5. **Three-Layer Architecture** enables platform extensions and optimization

---

## OCI Specification Research

### OCI Image Manifest Specification

**Schema Version:** Must be `2` for Docker backward compatibility
**Media Type:** `application/vnd.oci.image.manifest.v1+json`

**Required Fields:**

- `config` - Descriptor referencing configuration blob
- `layers` - Array of descriptors containing artifact content

**Optional Fields:**

- `mediaType` - Should be included for compatibility
- `artifactType` - Artifact type for non-container content (OCI v1.1+)
- `subject` - References another manifest for relationships (OCI v1.1+)
- `annotations` - Arbitrary metadata (string-string map)

### OCI v1.1 Updates (February 2024)

**Critical Additions:**

1. **artifactType Field**
   - Enables type declaration without custom config mediaType
   - Replaces need for separate artifact manifest
   - Backward compatible (older registries ignore unknown fields)

2. **subject Field**
   - Defines weak associations between manifests
   - Creates Merkle DAG structure
   - Use cases: signatures, SBOMs, attestations

**Impact:** All use cases requiring custom artifacts can now use standard image manifest

### Standard Empty Descriptor

For artifacts without associated content:

- Media type: `application/vnd.oci.empty.v1+json`
- Digest: `sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a`
- Size: 2 bytes
- Content: `{}`

### Descriptor Format

All descriptors share this structure:

```json
{
  "mediaType": "application/vnd.example.artifact.v1+json",
  "digest": "sha256:5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03",
  "size": 12345,
  "annotations": {
    "key": "value"
  }
}
```

### Manifest Components

#### Config Object

**Purposes:**

1. Type identification (via `config.mediaType` or manifest's `artifactType`)
2. Metadata storage (how clients should process the artifact)

**Usage Patterns:**

- **No config needed**: Use empty descriptor
- **Custom metadata**: Define custom config mediaType with meaningful data
- **Both approaches**: Set both `artifactType` and distinct `config.mediaType`

#### Layers Array

- **Ordering**: Index 0 = base/primary content
- **Multiple layers**: Each with independent mediaType
- **Organization**: Defined by artifact author
- **Empty layers**: At least one recommended for portability

#### Annotations

**Best Practices:**

- Keep manifest size manageable
- Use for small metadata only
- Leverage blobs for larger data
- Standard annotation: `org.opencontainers.image.ref.name` for tags

#### Subject Field

- Creates weak associations in Merkle DAG
- Used by referrers API
- Example: Link signatures/attestations to images

### MediaType Naming Conventions

**Standard Format (RFC 6838):**

**Config:**

```text
application/vnd.[org].[objectType].[optional-sub-type].config.[version]+json
```

**Layer:**

```text
application/vnd.[org].[layerType].[layerSubType].layer.[version]+[format]
```

**Examples:**

- OCI Image: `application/vnd.oci.image.config.v1+json`
- Helm Config: `application/vnd.cncf.helm.config.v1+json`
- Helm Layer: `application/vnd.cncf.helm.chart.content.v1.tar+gzip`
- WASM: `application/vnd.wasm.config.v0+json`, `application/wasm`
- CUE: `application/vnd.cue.module.v1+json`, `application/vnd.cue.modulefile.v1`

**Naming Best Practices:**

1. Always use `vnd.` prefix (vendor tree)
2. Include organization identifier
3. Be specific about object type
4. Include version number (v0, v1, v1alpha1, etc.)
5. Add format suffix when applicable (+json, +tar, +gzip, +cue, +yaml)

**IANA Registration:**

- Optional for most artifacts
- Vendor tree (`vnd.`) doesn't require IANA interaction
- Required only for global standards (e.g., Helm is IANA-registered)

### Real-World Examples

#### Helm Charts (IANA-Registered)

**Manifest Structure:**

- Config: `application/vnd.cncf.helm.config.v1+json` (contains Chart.yaml)
- Layer 0: `application/vnd.cncf.helm.chart.content.v1.tar+gzip` (chart archive)
- Layer 1: `application/vnd.cncf.helm.chart.provenance.v1.prov` (optional signature)

**Design Rationale:**

- Single atomic artifact
- Config contains metadata for quick access
- Optional provenance layer

#### WASM Modules (CNCF TAG Runtime)

**Manifest Structure:**

- Config: `application/vnd.wasm.config.v0+json`
- Layer 0: `application/wasm` (application entrypoint)

**Config Content:**

- Architecture: `wasm`
- OS: `wasip1`
- Component exports/imports for runtime validation

**Design Rationale:**

- Single layer for simplicity
- Config declares module interface
- Future: Multiple layers for "exploded" components

#### CUE Modules

**Manifest Structure:**

- artifactType: `application/vnd.cue.module.v1+json`
- Config: Empty descriptor
- Layer 0: `application/zip` (complete module source archive)
- Layer 1: `application/vnd.cue.modulefile.v1` (extracted cue.mod/module.cue)

**Design Rationale:**

- Empty config (no custom metadata needed)
- Layer 0: Full source for installation
- Layer 1: Metadata file for dependency resolution without downloading full archive
- Performance optimization for package managers

### Multi-Layer Organization

#### When to Use Multiple Layers

**Use multiple layers for:**

1. Different content types (code vs config vs metadata)
2. Optional content (signatures, provenance)
3. Performance optimization (quick metadata access)
4. Independent updates (different update cadences)

**Layer Ordering:**

- Index 0: Primary/entrypoint content
- Index 1+: Supporting content, metadata, signatures
- Semantic ordering: Lower indices = higher priority

#### Config vs Layers vs Annotations

**Use Config for:**

- Type identification
- Structured metadata clients need before downloading layers
- Information needed for dependency resolution
- Platform/architecture specifications

**Use Layers for:**

- Actual artifact content
- Large data requiring content-addressing
- Content with different compression/formats
- Shareable content (registry deduplication)

**Use Annotations for:**

- Small key-value metadata
- Human-readable descriptions
- Tags and labels
- Registry UI display
- Keep manifest size manageable

---

## Registry Authentication

### Docker config.json Format

**Location:**

- Linux/macOS: `$HOME/.docker/config.json`
- Windows: `%USERPROFILE%/.docker/config.json`

**Structure:**

```json
{
  "auths": {
    "registry.example.com": {
      "auth": "base64-encoded-username:password"
    }
  },
  "credsStore": "osxkeychain",
  "credHelpers": {
    "myregistry.example.com": "secretservice"
  }
}
```

### Credential Storage Options

#### 1. Direct Storage (Less Secure)

- Base64-encoded username:password in `auths` field
- Not recommended for production

#### 2. Credential Stores (Recommended)

- macOS: `osxkeychain` (native keychain)
- Windows: `wincred` (Windows Credential Manager)
- Linux: `pass`, `secretservice` (D-Bus Secret Service)

#### 3. Credential Helpers (Per-Registry)

- Registry-specific helper programs
- Examples: `gcr` for Google Container Registry

### Environment Variables

- **DOCKER_CONFIG**: Override config directory location
  - Example: `export DOCKER_CONFIG=/path/to/config/dir`
- **CUE_REGISTRY**: CUE-specific registry override
  - Example: `export CUE_REGISTRY=localhost:5000`

### OAuth Bearer Token Flow

**Step 1:** Initial unauthenticated request

```text
GET /v2/
```

**Step 2:** 401 response with authentication challenge

```text
HTTP/1.1 401 Unauthorized
Www-Authenticate: Bearer realm="https://auth.docker.io/token",
                          service="registry.docker.io",
                          scope="repository:library/python:pull"
```

**Step 3:** Token request

```text
GET https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/python:pull
Authorization: Basic base64(username:password)
```

**Step 4:** Token response

```json
{
  "token": "eyJhbGciOiJSUzI1N...",
  "access_token": "eyJhbGciOiJSUzI1N...",
  "expires_in": 300,
  "issued_at": "2024-01-30T03:35:39.896023447Z"
}
```

**Step 5:** Authenticated request

```text
GET /v2/library/python/manifests/latest
Authorization: Bearer eyJhbGciOiJSUzI1N...
```

### Scope Syntax

**Format:**

```text
repository:[namespace/]name:action[,action...]
```

**Examples:**

- `repository:library/python:pull`
- `repository:myorg/myapp:pull,push`
- `repository:catalog:*` (catalog access)

### Token Characteristics

- **Scoped**: Specific to operations requested
- **Non-reusable**: Cannot reuse across different scopes
- **Short-lived**: Typical expiration 300 seconds (5 minutes)
- **Refreshable**: Request new token when expired

### Authentication Methods

1. **Client TLS certificates**: Mutual TLS authentication
2. **Basic authentication**: Username/password (base64 encoded)
3. **Bearer tokens**: OAuth 2.0 token-based (most common)

---

## Recommended OPM Artifact Designs

### MediaType Definitions

| Artifact Type | artifactType | config.mediaType | Layer MediaTypes |
|---------------|--------------|------------------|------------------|
| **Module** | `application/vnd.opm.module.v1alpha1+json` | `application/vnd.opm.module.config.v1alpha1+json` | `application/vnd.opm.module.definition.v1alpha1+cue`<br>`application/vnd.opm.module.compiled.v1alpha1+cue` |
| **Bundle** | `application/vnd.opm.bundle.v1alpha1+json` | `application/vnd.opm.bundle.config.v1alpha1+json` | `application/vnd.opm.bundle.modules.v1alpha1.tar+gzip` |
| **Template** | `application/vnd.opm.template.v1alpha1+json` | `application/vnd.opm.template.config.v1alpha1+json` | `application/vnd.opm.template.content.v1alpha1.tar+gzip` |
| **Provider** | `application/vnd.opm.provider.v1alpha1+json` | `application/vnd.opm.provider.config.v1alpha1+json` | `application/vnd.opm.provider.transformers.v1alpha1+cue`<br>`application/vnd.opm.provider.renderers.v1alpha1+cue` |
| **Transformer** | `application/vnd.opm.transformer.v1alpha1+json` | `application/vnd.opm.transformer.config.v1alpha1+json` | `application/vnd.opm.transformer.cue.v1alpha1+cue` |

### Module Artifact Design

**Manifest Structure:**

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.opm.module.v1alpha1+json",
  "config": {
    "mediaType": "application/vnd.opm.module.config.v1alpha1+json",
    "digest": "sha256:...",
    "size": 1234
  },
  "layers": [
    {
      "mediaType": "application/vnd.opm.module.definition.v1alpha1+cue",
      "digest": "sha256:...",
      "size": 5678,
      "annotations": {"dev.opm.layer.type": "module-definition"}
    },
    {
      "mediaType": "application/vnd.opm.module.compiled.v1alpha1+cue",
      "digest": "sha256:...",
      "size": 12345,
      "annotations": {"dev.opm.layer.type": "compiled-module"}
    }
  ],
  "annotations": {
    "dev.opm.module.name": "my-app",
    "dev.opm.module.version": "1.0.0"
  }
}
```

**Config Blob Content:**

```json
{
  "apiVersion": "opm.dev/v1alpha1",
  "kind": "ModuleConfig",
  "metadata": {"name": "my-app", "version": "1.0.0"},
  "spec": {
    "components": ["web", "db"],
    "dependencies": {"github.com/open-platform-model/elements": "v0.1.0"}
  }
}
```

**Design Rationale:**

- **artifactType**: Declares OPM Module artifact type
- **Custom config**: Module metadata for quick access (dependency resolution)
- **Layer 0**: ModuleDefinition (uncompressed CUE for quick parsing)
- **Layer 1**: Compiled Module (JSON, optimized IR)
- **Annotations**: Module name/version for registry UI
- **Two-layer approach**: Source + compiled form in single artifact

### Bundle Artifact Design

**Manifest Structure:**

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.opm.bundle.v1alpha1+json",
  "config": {
    "mediaType": "application/vnd.opm.bundle.config.v1alpha1+json",
    "digest": "sha256:...",
    "size": 890
  },
  "layers": [
    {
      "mediaType": "application/vnd.opm.bundle.modules.v1alpha1.tar+gzip",
      "digest": "sha256:...",
      "size": 23456,
      "annotations": {"dev.opm.layer.type": "modules"}
    }
  ]
}
```

**Design Rationale:**

- **Bundle-specific config**: Bundle metadata
- **Single layer**: Compressed archive of all modules
- **Alternative approach**: Use `subject` field to reference individual modules

### Template Artifact Design

**Manifest Structure:**

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.opm.template.v1alpha1+json",
  "config": {
    "mediaType": "application/vnd.opm.template.config.v1alpha1+json",
    "digest": "sha256:...",
    "size": 567
  },
  "layers": [
    {
      "mediaType": "application/vnd.opm.template.content.v1alpha1.tar+gzip",
      "digest": "sha256:...",
      "size": 3456
    }
  ],
  "annotations": {
    "dev.opm.template.type": "standard",
    "dev.opm.template.description": "Standard web application template"
  }
}
```

**Design Rationale:**

- **Single layer**: Complete template structure
- **Config**: Template metadata and usage instructions
- **Annotations**: Template type for filtering/discovery

### Provider Artifact Design

**Manifest Structure:**

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.opm.provider.v1alpha1+json",
  "config": {
    "mediaType": "application/vnd.opm.provider.config.v1alpha1+json",
    "digest": "sha256:...",
    "size": 789
  },
  "layers": [
    {
      "mediaType": "application/vnd.opm.provider.transformers.v1alpha1+cue",
      "digest": "sha256:...",
      "size": 4567
    },
    {
      "mediaType": "application/vnd.opm.provider.renderers.v1alpha1+cue",
      "digest": "sha256:...",
      "size": 5678
    }
  ]
}
```

**Config Blob Content:**

```json
{
  "apiVersion": "opm.dev/v1alpha1",
  "kind": "ProviderConfig",
  "metadata": {"name": "kubernetes", "version": "1.0.0"},
  "spec": {
    "platform": "kubernetes",
    "transformers": ["workload", "data", "network"],
    "renderers": ["yaml", "helm"]
  }
}
```

**Design Rationale:**

- **Separate layers**: Transformers and renderers independently versioned
- **Config**: Provider capabilities and metadata
- **Alternative**: Could include binary executables for native transformers

### Transformer Artifact Design

**Manifest Structure:**

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "artifactType": "application/vnd.opm.transformer.v1alpha1+json",
  "config": {
    "mediaType": "application/vnd.opm.transformer.config.v1alpha1+json",
    "digest": "sha256:...",
    "size": 456
  },
  "layers": [
    {
      "mediaType": "application/vnd.opm.transformer.cue.v1alpha1+cue",
      "digest": "sha256:...",
      "size": 2345
    }
  ],
  "annotations": {
    "dev.opm.transformer.element": "StatelessWorkload",
    "dev.opm.transformer.platform": "kubernetes"
  }
}
```

**Design Rationale:**

- **Lightweight**: Single transformer definition
- **Annotations**: Element type and platform for discovery
- **Use case**: Community-contributed transformers

---

## Implementation Roadmap

### Phase 1: OCI Artifact Type Design (Foundation)

**Objectives:**

- Define all OPM mediaTypes following vendor tree conventions
- Create manifest builder abstractions
- Establish layer organization patterns

**Tasks:**

1. Create mediaType specification document
2. Implement manifest builders in `cli/pkg/oci/manifest/`:
   - `ModuleManifest` - OCI manifest for modules
   - `BundleManifest` - OCI manifest for bundles
   - `TemplateManifest` - OCI manifest for templates
   - `ProviderManifest` - OCI manifest for providers
   - `TransformerManifest` - OCI manifest for transformers
3. Implement descriptor builders (config, layers)
4. Add digest calculation (SHA256)
5. Add size calculation utilities

**Deliverables:**

- `cli/pkg/oci/manifest/` package
- Unit tests for manifest generation
- Documentation for each artifact type

---

### Phase 2: Registry Authentication (HIGH PRIORITY)

**Objectives:**

- Docker-compatible credential storage
- OAuth bearer token authentication
- Registry client with automatic auth

**Tasks:**

#### 2.1 Docker Config Reader

**Package:** `cli/pkg/oci/auth/config.go`

- Read `~/.docker/config.json`
- Support `auths`, `credsStore`, `credHelpers` formats
- Handle `DOCKER_CONFIG` environment variable
- Parse base64-encoded credentials

#### 2.2 Token Authentication

**Package:** `cli/pkg/oci/auth/token.go`

- Parse `Www-Authenticate` header from 401 responses
- Request bearer tokens from auth endpoint
- Cache tokens with expiration tracking
- Auto-refresh before expiration
- Handle scope-specific tokens

#### 2.3 Registry Client

**Package:** `cli/pkg/oci/client/client.go`

- HTTP client with automatic authentication
- Retry logic for token expiration
- Support basic auth and bearer tokens
- TLS certificate validation
- Configurable timeout and retry parameters

#### 2.4 CLI Commands

**Package:** `cli/internal/commands/registry/`

- `opm registry login <url>` - authenticate to registry
- `opm registry logout <url>` - remove credentials
- Store credentials in Docker config format

**Deliverables:**

- `cli/pkg/oci/auth/` package
- `cli/pkg/oci/client/` package
- `opm registry login/logout` commands
- Integration tests with local registry

---

### Phase 3: Module Publishing (HIGH PRIORITY)

**Objectives:**

- Build OCI module artifacts from ModuleDefinitions
- Upload blobs and manifests to registry
- Tag management and versioning

**Tasks:**

#### 3.1 Module Artifact Builder

**Package:** `cli/pkg/oci/module/build.go`

- Load ModuleDefinition from CUE files
- Flatten to compiled Module
- Create two-layer manifest:
  - Layer 0: ModuleDefinition (uncompressed CUE)
  - Layer 1: Compiled Module (JSON)
- Generate config blob with metadata
- Calculate SHA256 digests for all blobs
- Build complete OCI manifest

#### 3.1.5 File Filtering

**Package:** `cli/pkg/oci/ignore/ignore.go`

- Parse `.opmignore` file (gitignore-compatible syntax)
- Apply ignore patterns during artifact building
- Support standard patterns: `*.ext`, `dir/`, `**/pattern`, `!exception`
- Default ignored patterns (when no .opmignore exists):
  - `.git/`, `.github/`
  - `node_modules/`, `vendor/`
  - `.opm/`, `.registry-data/`
  - `*.log`, `*.tmp`, `.DS_Store`
  - `cue.mod/pkg/` (CUE dependencies)
- Allow custom ignore file via CLI flag

**Design Rationale:**

- **Smaller artifacts**: Exclude unnecessary files from published modules
- **Security**: Prevent accidental publishing of secrets/credentials
- **Compatibility**: Reuse gitignore syntax developers already know
- **Performance**: Reduce upload time and registry storage

#### 3.2 Blob Upload

**Package:** `cli/pkg/oci/client/upload.go`

- Monolithic blob upload (for small artifacts)
- Chunked blob upload (for large modules)
- Progress tracking callbacks
- Blob existence check (avoid re-upload)
- Content-addressable storage deduplication
- Error handling and retry logic

#### 3.3 Manifest Upload

**Package:** `cli/pkg/oci/client/manifest.go`

- Upload manifest to registry
- Support OCI v1.0 and v1.1 compatibility
- Handle `artifactType` field properly
- Tag management (create/update/delete)
- Verify upload success

#### 3.4 CLI Publish Command

**Package:** `cli/internal/commands/mod/publish.go`

**Usage:**

```bash
opm mod publish <path> <version> [--registry <url>]
opm mod publish ./my-module v1.0.0
opm mod publish ./my-module v1.0.0 --registry localhost:5000
opm mod publish oci://ghcr.io/org/my-module:v1.0.0
```

**Options:**

- `--registry` - Override default registry
- `--latest` - Also tag as :latest
- `--config` - Custom config blob
- `--annotations` - Add manifest annotations
- `--platform` - Target platform (future multi-platform support)
- `--ignore-file` - Custom ignore file (defaults to .opmignore)

**Deliverables:**

- `cli/pkg/oci/module/` package
- Blob and manifest upload implementation
- `opm mod publish` command
- Integration tests with local registry
- Progress indicators for uploads

---

### Phase 4: Module Fetching (HIGH PRIORITY)

**Objectives:**

- Download OCI module artifacts from registry
- Extract and reconstruct module structure
- Cache downloaded artifacts

**Tasks:**

#### 4.1 Manifest Download

**Package:** `cli/pkg/oci/client/download.go`

- Fetch manifest by reference (tag or digest)
- Validate manifest structure
- Parse layers and config descriptors
- Handle redirects
- Verify content-type headers

#### 4.2 Layer Extraction

**Package:** `cli/pkg/oci/client/layers.go`

- Download specific layers by digest
- Extract compressed archives (tar+gzip)
- Verify layer integrity (SHA256)
- Progress tracking
- Parallel layer downloads

#### 4.3 Module Reconstruction

**Package:** `cli/pkg/oci/module/fetch.go`

- Download module manifest
- Extract ModuleDefinition from Layer 0
- Extract compiled Module from Layer 1
- Reconstruct module directory structure
- Write to local filesystem
- Preserve file permissions

#### 4.4 CLI Get Command

**Package:** `cli/internal/commands/mod/get.go`

**Usage:**

```bash
opm mod get <reference> [--output <dir>]
opm mod get myorg/my-module:v1.0.0
opm mod get oci://ghcr.io/org/my-module:v1.0.0
opm mod get myorg/my-module@sha256:abc123...
```

**Options:**

- `--output` - Destination directory
- `--registry` - Override default registry
- `--layer` - Download specific layer only
- `--force` - Overwrite existing files

**Deliverables:**

- Manifest and layer download implementation
- Module reconstruction logic
- `opm mod get` command
- Integration tests
- Caching strategy implementation

---

### Phase 5: Configuration Management

**Objectives:**

- Multi-registry support
- Enhanced configuration schema
- Environment variable overrides

**Tasks:**

#### 5.1 Enhanced Config Structure

**Package:** `cli/pkg/config/config.go`

**New Structure:**

```go
type Config struct {
    Registries map[string]RegistryConfig
    Default    string
    Cache      CacheConfig
    Log        LogConfig
}

type RegistryConfig struct {
    URL        string
    Insecure   bool
    CredHelper string
}
```

#### 5.2 Config File Format

**File:** `~/.opm/config.cue`

**Example:**

```cue
registries: {
    "local": {
        url: "localhost:5000"
        insecure: true
    }
    "ghcr": {
        url: "ghcr.io"
        credHelper: "gcr"
    }
}
default: "local"
```

#### 5.3 Environment Variables

- `OPM_REGISTRY` - Default registry name or URL
- `OPM_REGISTRY_INSECURE` - Allow HTTP (true/false)
- `DOCKER_CONFIG` - Auth config location

#### 5.4 Registry Resolution

**Package:** `cli/pkg/oci/reference/`

**Reference Formats:**

- `myorg/mymodule:v1.0.0` → Uses default registry
- `oci://ghcr.io/myorg/mymodule:v1.0.0` → Explicit full path
- `@ghcr:myorg/mymodule:v1.0.0` → Named registry from config

**Deliverables:**

- Enhanced configuration schema
- Multi-registry config support
- Reference parser
- Registry resolver
- Migration guide for existing configs

---

### Phase 6: Bundle, Template, Provider, Transformer Support

**Objectives:**

- Extend OCI support to all artifact types
- Implement specialized builders and fetchers
- Update CLI commands

**Tasks:**

#### 6.1 Bundle Publishing

**Package:** `cli/pkg/oci/bundle/`

- Bundle manifest builder
- Archive multiple modules
- Config with bundle metadata
- `opm bundle publish` command
- `opm bundle get` command

#### 6.2 Template Publishing

**Package:** `cli/pkg/oci/template/`

- Template manifest builder
- Archive template structure
- Template metadata in config
- Update `opm mod init --template oci://...`

#### 6.3 Provider Publishing

**Package:** `cli/pkg/oci/provider/`

- Provider manifest builder
- Separate transformer and renderer layers
- Config with capability declarations
- `opm provider install oci://...` command

#### 6.4 Transformer Publishing

**Package:** `cli/pkg/oci/transformer/`

- Lightweight transformer artifacts
- Annotations for element type/platform
- Community contribution support
- `opm transformer install oci://...` command

**Deliverables:**

- Bundle, template, provider, transformer packages
- CLI commands for each artifact type
- Integration tests
- Documentation updates

---

### Phase 7: Integration & Testing

**Objectives:**

- Integrate OCI support into existing commands
- Comprehensive caching strategy
- End-to-end testing

**Tasks:**

#### 7.1 Update Existing Commands

- `opm mod tidy` - Use OCI registry for dependencies
- `opm mod render` - Fetch modules from OCI
- `opm mod init` - Fetch templates from OCI
- Seamless fallback to CUE native modules

#### 7.2 Cache Integration

**Package:** `cli/pkg/oci/cache/`

- Cache OCI manifests by digest
- Cache blobs content-addressed
- Invalidation on registry change
- Directory structure: `~/.opm/cache/oci/`
  - `oci/blobs/sha256/` - Blob storage
  - `oci/manifests/` - Manifest cache
  - `oci/index.json` - Cache index

#### 7.3 Testing Strategy

- Unit tests for all packages
- Integration tests with local registry
- Authentication flow testing
- Multi-registry scenario testing
- Compatibility with Docker registry v2
- Performance benchmarks
- Error handling and recovery

**Deliverables:**

- Updated existing commands
- OCI cache implementation
- Comprehensive test suite
- Performance benchmarks
- User documentation
- Migration guide

---

### Sprint Breakdown

#### Sprint 1 (HIGH PRIORITY) - Weeks 1-2

- OCI artifact type design and mediaTypes
- Registry authentication (Docker config + bearer tokens)
- Basic registry client with auth
- `opm registry login/logout` commands

#### Sprint 2 (HIGH PRIORITY) - Weeks 3-4

- Module manifest builder
- Blob and manifest upload
- `opm mod publish` command
- Test with local registry

#### Sprint 3 (HIGH PRIORITY) - Weeks 5-6

- Manifest and layer download
- Module reconstruction
- `opm mod get` command
- Integration with existing commands

#### Sprint 4 (MEDIUM PRIORITY) - Weeks 7-8

- Bundle support
- Template OCI support
- Enhanced config with multiple registries
- Cache integration

#### Sprint 5 (LOW PRIORITY) - Weeks 9-10

- Provider and Transformer support
- Advanced features (chunked upload, resumable downloads)
- Performance optimization
- Comprehensive testing and documentation

---

## Key Design Decisions

### 1. Two-Layer Module Artifacts

**Decision:** Store both ModuleDefinition (source) and compiled Module (IR) in separate layers

**Rationale:**

- **Performance**: Compiled Module ready for immediate use
- **Source Preservation**: Original definition available for inspection/extension
- **Optimization**: Clients can download only needed layer
- **Follows CUE Pattern**: Similar to CUE's approach (full archive + metadata file)

**Trade-offs:**

- Larger artifact size vs faster deployment
- Complexity vs flexibility

### 2. OCI v1.1 with v1.0 Fallback

**Decision:** Use OCI v1.1 `artifactType` field with fallback to `config.mediaType`

**Rationale:**

- **Future-proof**: Aligns with latest OCI standard
- **Backward compatible**: Works with older registries
- **Industry standard**: Following Helm/WASM/CUE patterns

**Implementation:**

- Set both `artifactType` and custom `config.mediaType`
- Clients check `artifactType` first, fall back to `config.mediaType`

### 3. Docker-Compatible Authentication

**Decision:** Reuse Docker config.json format and credential storage

**Rationale:**

- **No reinvention**: Leverage existing, proven system
- **User familiarity**: Developers already understand Docker auth
- **Ecosystem compatibility**: Works with existing credential helpers
- **Security**: Supports platform-native secure storage

**Implementation:**

- Read from `~/.docker/config.json`
- Support all credential storage methods
- Respect `DOCKER_CONFIG` environment variable

### 4. Content-Addressed Caching

**Decision:** Cache all artifacts using SHA256 digests

**Rationale:**

- **Deduplication**: Shared layers stored once
- **Integrity**: Automatic corruption detection
- **Immutability**: Digest-based addressing prevents tampering
- **Standard OCI**: Aligns with OCI content-addressable storage

**Implementation:**

- Cache directory: `~/.opm/cache/oci/blobs/sha256/`
- Manifest cache: `~/.opm/cache/oci/manifests/`
- Index file for quick lookup

### 5. Multi-Registry Support (LOW PRIORITY)

**Decision:** Support multiple named registries in config

**Rationale:**

- **Flexibility**: Use different registries for different purposes
- **Organizations**: Support private registries alongside public
- **Migration**: Gradual transition between registries

**Implementation:**

- Named registry configs in `~/.opm/config.cue`
- Default registry for short references
- Explicit registry in OCI URLs

**Trade-off:**

- Complexity vs flexibility
- Deferred to Sprint 4 (not critical path)

### 6. Semantic Versioning with Tags

**Decision:** Support full Semver 2.0 with :latest tag

**Rationale:**

- **Version clarity**: Full semantic meaning
- **Compatibility**: Standard OCI tag format
- **Convenience**: :latest for development

**Implementation:**

- Publish creates version-specific tag (v1.0.0)
- Optional :latest tag with `--latest` flag
- Support digest-based references for immutability

### 7. Namespace Convention

**Decision:** Follow OCI repository naming: `org/name`

**Rationale:**

- **Standard**: Matches Docker/OCI conventions
- **Organization**: Clear ownership
- **Compatibility**: Works with all registries

**Examples:**

- `open-platform-model/core`
- `myorg/my-app`
- `opm.dev/templates/standard`

---

## Technical Specifications

### Package Structure

```text
cli/
├── pkg/
│   └── oci/
│       ├── manifest/         # Manifest builders
│       │   ├── module.go
│       │   ├── bundle.go
│       │   ├── template.go
│       │   ├── provider.go
│       │   └── transformer.go
│       ├── ignore/           # File filtering
│       │   ├── ignore.go     # .opmignore parser
│       │   └── patterns.go   # Pattern matching
│       ├── auth/             # Authentication
│       │   ├── config.go     # Docker config reader
│       │   ├── token.go      # Bearer token flow
│       │   └── credentials.go
│       ├── client/           # Registry client
│       │   ├── client.go     # HTTP client with auth
│       │   ├── upload.go     # Blob/manifest upload
│       │   ├── download.go   # Manifest download
│       │   └── layers.go     # Layer extraction
│       ├── module/           # Module operations
│       │   ├── build.go      # Build module artifact
│       │   └── fetch.go      # Fetch and reconstruct
│       ├── bundle/           # Bundle operations
│       ├── template/         # Template operations
│       ├── provider/         # Provider operations
│       ├── transformer/      # Transformer operations
│       ├── cache/            # OCI cache
│       │   ├── cache.go
│       │   └── index.go
│       └── reference/        # Reference parsing
│           └── reference.go
└── internal/
    └── commands/
        └── registry/         # Registry commands
            ├── login.go
            └── logout.go
```

### CLI Command Additions

**Registry Management:**

- `opm registry login <url> [--username <user>] [--password-stdin]`
- `opm registry logout <url>`

**Module Operations:**

- `opm mod publish <path> <version> [options]`
- `opm mod get <reference> [--output <dir>]`

**Bundle Operations:**

- `opm bundle publish <path> <version>`
- `opm bundle get <reference>`

**Template Operations:**

- `opm mod init --template oci://<reference>` (update existing)

**Provider Operations:**

- `opm provider install <reference>`
- `opm provider list`

**Transformer Operations:**

- `opm transformer install <reference>`

### Configuration Schema

**File:** `~/.opm/config.cue`

```cue
package config

// Multi-registry configuration
registries: {
    [name=string]: {
        url!:       string
        insecure?:  bool
        credHelper?: string
    }
}

// Default registry name
default!: string

// Cache configuration
cache: {
    dir:     string | *"~/.opm/cache"
    maxSize: string | *"10GB"
    ttl:     string | *"168h" // 1 week
}

// Logging configuration
log: {
    level:  string | *"info"
    format: string | *"text"
}
```

### Cache Directory Structure

```text
~/.opm/cache/
└── oci/
    ├── blobs/
    │   └── sha256/
    │       ├── <digest1>     # Blob data
    │       ├── <digest2>
    │       └── ...
    ├── manifests/
    │   └── <registry>/
    │       └── <repository>/
    │           └── <reference>.json
    └── index.json            # Cache index
```

---

## Reference Links

### OCI Specifications

- [OCI Image Manifest Specification](https://github.com/opencontainers/image-spec/blob/main/manifest.md)
- [OCI Artifact Specification](https://github.com/opencontainers/image-spec/blob/main/artifact.md)
- [OCI Image Layout](https://github.com/opencontainers/image-spec/blob/main/image-layout.md)
- [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec)

### Real-World Implementations

- [Helm OCI Support](https://helm.sh/docs/topics/registries/)
- [WASM OCI Artifacts](https://tag-runtime.cncf.io/wgs/wasm/deliverables/wasm-oci-artifact/)
- [CUE Modules in OCI](https://cuelang.org/docs/concept/modules-packages-instances/)

### Authentication

- [Docker Registry Authentication](https://docs.docker.com/registry/spec/auth/)
- [OCI Distribution Auth](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#endpoints)

### MediaType Standards

- [RFC 6838 - Media Type Specifications](https://tools.ietf.org/html/rfc6838)
- [IANA Media Types](https://www.iana.org/assignments/media-types/media-types.xhtml)

---

## Appendix: Implementation Checklist

### Foundation (Sprint 1)

- [ ] Define all OPM mediaTypes
- [ ] Implement manifest builders
- [ ] Implement descriptor builders
- [ ] Add digest calculation utilities
- [ ] Docker config.json reader
- [ ] OAuth bearer token flow
- [ ] Registry HTTP client
- [ ] `opm registry login` command
- [ ] `opm registry logout` command
- [ ] Unit tests for auth
- [ ] Integration tests with local registry

### Publishing (Sprint 2)

- [ ] Module artifact builder
- [ ] ModuleDefinition loader
- [ ] Module flattening integration
- [ ] .opmignore parser
- [ ] File filtering with ignore patterns
- [ ] Default ignore patterns
- [ ] Config blob generator
- [ ] Blob upload (monolithic)
- [ ] Blob upload (chunked)
- [ ] Manifest upload
- [ ] Tag management
- [ ] `opm mod publish` command with --ignore-file flag
- [ ] Progress indicators
- [ ] Error handling
- [ ] Integration tests

### Fetching (Sprint 3)

- [ ] Manifest download
- [ ] Layer download
- [ ] Archive extraction
- [ ] Module reconstruction
- [ ] `opm mod get` command
- [ ] Parallel layer downloads
- [ ] Progress indicators
- [ ] Integration with `mod build`
- [ ] Integration with `mod tidy`
- [ ] Integration tests

### Advanced Features (Sprint 4)

- [ ] Bundle manifest builder
- [ ] Bundle publish/get
- [ ] Template OCI support
- [ ] Enhanced config schema
- [ ] Multi-registry support
- [ ] Registry reference parser
- [ ] OCI cache implementation
- [ ] Cache invalidation
- [ ] Migration guide

### Extended Support (Sprint 5)

- [ ] Provider artifact support
- [ ] Transformer artifact support
- [ ] Resumable downloads
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] Documentation
- [ ] User guides
- [ ] Migration tools

---

**End of Report**
