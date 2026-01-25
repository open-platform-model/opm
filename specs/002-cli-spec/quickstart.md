# Quickstart: OPM CLI v2 Development

**Plan**: [plan.md](./plan.md) | **Date**: 2026-01-22

This guide helps developers get started contributing to the OPM CLI.

## Prerequisites

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Go | 1.22+ | `go version` |
| CUE | 0.11.x | `cue version` |
| Task | 3.0+ | `task --version` |
| kubectl | 1.28+ | `kubectl version --client` |
| Docker | 24+ | `docker --version` |

### Optional (for testing)

| Tool | Purpose |
|------|---------|
| kind | Local Kubernetes cluster |
| k3d | Lightweight local cluster |

## Setup

### 1. Clone and Enter Directory

```bash
cd cli/
```

### 2. Install Dependencies

```bash
go mod download
```

### 3. Verify Setup

```bash
task build
./bin/opm version
```

Expected output:

```
OPM CLI:
  Version:  v0.0.0-dev
  Build ID: 2026-01-22T00:00:00Z/dev

CUE:
  SDK Version:    v0.11.x
  Binary Version: v0.11.x (compatible)
  Binary Path:    /usr/local/bin/cue
```

## Project Structure

```
cli/
├── cmd/opm/           # Entry point
├── internal/          # Implementation (not exported)
│   ├── cmd/           # Command handlers
│   ├── config/        # Configuration
│   ├── cue/           # CUE operations
│   ├── kubernetes/    # K8s client
│   ├── oci/           # OCI registry
│   ├── output/        # Terminal output
│   └── version/       # Version info
├── pkg/               # Public API (minimal)
├── tests/             # Test suites
└── Taskfile.yml       # Build tasks
```

## Common Tasks

### Build

```bash
# Build binary
task build

# Build with version info
task build VERSION=v1.0.0

# Cross-compile
task build:all
```

### Test

```bash
# Run all tests
task test

# Run unit tests only
task test:unit

# Run integration tests (requires cluster)
task test:integration

# Run with verbose output
task test:verbose

# Run specific test
go test ./internal/kubernetes -v -run TestApply
```

### Lint

```bash
# Run linters
task lint

# Auto-fix issues
task lint:fix
```

### Format

```bash
# Format code
task fmt
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feat/mod-apply
```

### 2. Make Changes

Follow the package conventions:

- Commands in `internal/cmd/{mod,bundle}/`
- Core logic in `internal/{cue,kubernetes,oci}/`
- Use interfaces for testability

### 3. Add Tests

```go
// internal/kubernetes/apply_test.go
func TestApply_ServerSideApply(t *testing.T) {
    // Arrange
    client := newMockClient()
    manifests := loadTestManifests(t, "fixtures/deployment.yaml")
    
    // Act
    err := client.Apply(context.Background(), manifests, ApplyOptions{})
    
    // Assert
    require.NoError(t, err)
    assert.True(t, client.ApplyCalled)
}
```

### 4. Run Tests

```bash
task test
```

### 5. Commit

```bash
git add .
git commit -m "feat(cli): implement mod apply command"
```

## Adding a New Command

### 1. Create Command File

```go
// internal/cmd/mod/apply.go
package mod

import (
    "github.com/spf13/cobra"
)

var applyCmd = &cobra.Command{
    Use:   "apply",
    Short: "Apply module resources to cluster",
    Long:  `Apply module resources to a Kubernetes cluster using server-side apply.`,
    RunE:  runApply,
}

func init() {
    modCmd.AddCommand(applyCmd)
    
    applyCmd.Flags().StringSliceP("values", "f", nil, "Values files")
    applyCmd.Flags().Bool("dry-run", false, "Server-side dry run")
    applyCmd.Flags().Bool("diff", false, "Show diff before applying")
    applyCmd.Flags().BoolP("wait", "w", false, "Wait for readiness")
    applyCmd.Flags().Duration("timeout", 5*time.Minute, "Timeout")
}

func runApply(cmd *cobra.Command, args []string) error {
    // Implementation
    return nil
}
```

### 2. Register with Parent

The command is automatically registered via `init()`.

### 3. Add Tests

```go
// internal/cmd/mod/apply_test.go
func TestApplyCommand(t *testing.T) {
    tests := []struct {
        name    string
        args    []string
        wantErr bool
    }{
        {"basic apply", []string{}, false},
        {"with values", []string{"-f", "values.cue"}, false},
        {"dry run", []string{"--dry-run"}, false},
    }
    // ...
}
```

## Testing with Local Cluster

### Using kind

```bash
# Create cluster
kind create cluster --name opm-test

# Run integration tests. If OPM_TEST_CLUSTER is set it uses that to execute the integration tests, otherwise it uses envtest.
OPM_TEST_CLUSTER=kind-opm-test task test:integration

# Cleanup
kind delete cluster --name opm-test
```

### Using envtest

Integration tests use envtest by default (no external cluster needed):

```go
func TestIntegration(t *testing.T) {
    testEnv := &envtest.Environment{}
    cfg, err := testEnv.Start()
    require.NoError(t, err)
    defer testEnv.Stop()
    
    // Tests run against real API server
}
```

## Debugging

### Enable Verbose Logging

```bash
./bin/opm --verbose mod build
```

### Debug with Delve

```bash
# Start headless debugger
dlv debug ./cmd/opm --headless --api-version=2 --listen=127.0.0.1:43000 -- mod build

# Connect from another terminal
dlv connect 127.0.0.1:43000
```

### Log to File

```go
// For Bubble Tea or non-TTY debugging
if os.Getenv("DEBUG") != "" {
    f, _ := os.Create("debug.log")
    log.SetOutput(f)
}
```

## Code Style

### Error Handling

```go
// Wrap errors with context
if err != nil {
    return fmt.Errorf("loading module %s: %w", dir, err)
}

// Use sentinel errors for known conditions
if errors.Is(err, ErrNotFound) {
    return ExitNotFound
}
```

### Context Propagation

```go
// Always accept context as first parameter
func Apply(ctx context.Context, manifests *ManifestSet) error {
    // Check for cancellation
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }
    // ...
}
```

### Interface Design

```go
// Accept interfaces
func NewApplier(client kubernetes.Client) *Applier {
    return &Applier{client: client}
}

// Return structs
func (a *Applier) Apply(ctx context.Context, m *ManifestSet) (*ApplyResult, error)
```

## Dependencies

### Adding a Dependency

```bash
go get github.com/example/package@v1.2.3
go mod tidy
```

### Updating Dependencies

```bash
go get -u ./...
go mod tidy
```

## Release Process

Releases are automated via goreleaser:

```bash
# Tag a release
git tag v1.0.0
git push origin v1.0.0

# goreleaser builds and publishes via CI
```

## Getting Help

- **Spec**: [spec.md](./spec.md) - Feature requirements
- **Plan**: [plan.md](./plan.md) - Implementation details
- **Research**: [research.md](./research.md) - Technology decisions
- **Data Model**: [data-model.md](./data-model.md) - Type definitions
- **Commands**: [reference/commands.md](./reference/commands.md) - CLI reference

## Checklist for New Contributors

- [ ] Fork and clone the repository
- [ ] Run `task build` successfully
- [ ] Run `task test` with all tests passing
- [ ] Read the spec and plan documents
- [ ] Pick an issue or task from the backlog
- [ ] Create a feature branch
- [ ] Write tests first (TDD encouraged)
- [ ] Implement the feature
- [ ] Run `task lint` and fix issues
- [ ] Submit a pull request
