# Contract: Exit Codes

**Plan**: [../plan.md](../plan.md) | **Date**: 2026-01-22  
**Source**: [spec.md](../spec.md) Section "Exit Codes"

This document defines the exit code contract for the OPM CLI. All commands MUST adhere to these exit codes.

## Exit Code Table

| Code | Name | Description | Example Scenarios |
|------|------|-------------|-------------------|
| `0` | Success | Command completed successfully | Apply succeeded, build produced output, status retrieved |
| `1` | General Error | Unspecified error occurred | Unexpected panic, unknown error type |
| `2` | Validation Error | CUE schema validation failed | Invalid module.cue, values don't satisfy schema, missing required fields |
| `3` | Connectivity Error | Cannot reach Kubernetes cluster | No kubeconfig, cluster unreachable, connection timeout |
| `4` | Permission Denied | Insufficient RBAC permissions | Cannot create/delete resources, namespace access denied |
| `5` | Not Found | Resource, module, or artifact not found | Module directory doesn't exist, OCI artifact not in registry |
| `6` | Version Mismatch | CUE binary version incompatible | CUE binary 0.12.x with SDK 0.11.x |

## Exit Code Constants

```go
// Package: internal/cmd

const (
    ExitSuccess          = 0
    ExitGeneralError     = 1
    ExitValidationError  = 2
    ExitConnectivityError = 3
    ExitPermissionDenied = 4
    ExitNotFound         = 5
    ExitVersionMismatch  = 6
)
```

## Usage by Command

### Module Commands

| Command | Possible Exit Codes |
|---------|---------------------|
| `opm mod init` | 0, 1, 5 (template not found) |
| `opm mod vet` | 0, 1, 2, 6 |
| `opm mod tidy` | 0, 1, 6 |
| `opm mod build` | 0, 1, 2 |
| `opm mod apply` | 0, 1, 2, 3, 4 |
| `opm mod delete` | 0, 1, 3, 4 |
| `opm mod diff` | 0 (no diff), 1 (has diff or error), 2, 3 |
| `opm mod status` | 0, 1, 3, 4 |

### Special Cases

#### `opm mod diff`

The diff command has special exit code semantics:

- `0`: No differences found
- `1`: Differences exist OR an error occurred
- `2`: Validation error (invalid module)
- `3`: Cannot connect to cluster

This follows the convention of `diff(1)` and similar tools.

#### `opm mod delete`

The delete command requires `--force` in non-TTY environments:

- Without `--force` in non-TTY: Exit `1` with error message
- With `--force`: Proceeds without confirmation

## Error Message Format

All errors MUST include:

1. **Error type indicator**: Brief categorization
2. **Specific message**: What went wrong
3. **Context**: File path, resource name, etc.
4. **Suggestion**: How to fix (when applicable)

### Examples

```text
Error: validation failed
  File: /path/to/module.cue
  Line: 42
  
  metadata.version: invalid value "1.0" (expected semver format)
  
Hint: Version must follow semantic versioning (e.g., "1.0.0")
Exit code: 2
```

```text
Error: cluster connectivity failed
  Context: production-cluster
  
  dial tcp 10.0.0.1:6443: i/o timeout
  
Hint: Check your kubeconfig and network connectivity
Exit code: 3
```

```text
Error: CUE binary version mismatch
  Required: 0.11.x (matches OPM CLI's CUE SDK)
  Found:    0.12.0
  
Install a compatible CUE version or upgrade OPM CLI.
Exit code: 6
```

## Implementation Notes

### Error Wrapping

Use sentinel errors for known conditions:

```go
var (
    ErrValidation   = errors.New("validation error")
    ErrConnectivity = errors.New("connectivity error")
    ErrPermission   = errors.New("permission denied")
    ErrNotFound     = errors.New("not found")
    ErrVersion      = errors.New("version mismatch")
)

func exitCodeFromError(err error) int {
    switch {
    case errors.Is(err, ErrValidation):
        return ExitValidationError
    case errors.Is(err, ErrConnectivity):
        return ExitConnectivityError
    case errors.Is(err, ErrPermission):
        return ExitPermissionDenied
    case errors.Is(err, ErrNotFound):
        return ExitNotFound
    case errors.Is(err, ErrVersion):
        return ExitVersionMismatch
    default:
        return ExitGeneralError
    }
}
```

### Kubernetes Error Mapping

Map Kubernetes API errors to exit codes:

```go
import apierrors "k8s.io/apimachinery/pkg/api/errors"

func exitCodeFromK8sError(err error) int {
    switch {
    case apierrors.IsNotFound(err):
        return ExitNotFound
    case apierrors.IsForbidden(err), apierrors.IsUnauthorized(err):
        return ExitPermissionDenied
    case apierrors.IsServerTimeout(err), apierrors.IsServiceUnavailable(err):
        return ExitConnectivityError
    default:
        return ExitGeneralError
    }
}
```

## Testing Requirements

Each command MUST have tests verifying correct exit codes:

```go
func TestModVetExitCodes(t *testing.T) {
    tests := []struct {
        name     string
        fixture  string
        wantCode int
    }{
        {"valid module", "fixtures/valid", 0},
        {"invalid schema", "fixtures/invalid-schema", 2},
        {"cue version mismatch", "fixtures/valid", 6}, // with mock
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            code := runCommand("mod", "vet", "--dir", tt.fixture)
            assert.Equal(t, tt.wantCode, code)
        })
    }
}
```
