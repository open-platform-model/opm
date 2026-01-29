# Contract: Error Message Format

**Plan**: [../plan.md](../plan.md) | **Date**: 2026-01-29
**Source**: [spec.md](../spec.md) FR-008, FR-010, FR-014, FR-016

This document defines the error message format contract for the OPM CLI. All error output MUST adhere to this schema.

## Error Message Schema

| Field | Required | Description |
|-------|----------|-------------|
| Type | Yes | Error category matching exit code name (see exit-codes.md) |
| Message | Yes | Specific description of what went wrong |
| Location | Conditional | File path + line number (required for validation errors) |
| Field | Conditional | Field name (required for config/schema errors) |
| Context | Optional | Additional context (registry URL, resource name, provider, etc.) |
| Hint | Optional | Actionable suggestion for resolution |

## Output Format

All errors are written to `stderr` in this format:

```text
Error: <type>
  <Location: file:line> (if applicable)
  <Field: name> (if applicable)
  <Context: value> (if applicable)
  
  <message>
  
Hint: <suggestion> (if applicable)
```

## Type Mapping

| Exit Code | Error Type String |
|-----------|-------------------|
| 1 | general error |
| 2 | validation failed |
| 3 | connectivity failed |
| 4 | permission denied |
| 5 | not found |
| 6 | CUE binary version mismatch |

## Examples

### Validation Error (Exit Code 2)

```text
Error: validation failed
  Location: /path/to/module.cue:42
  Field: metadata.version
  
  invalid value "1.0" (expected semver format)
  
Hint: Version must follow semantic versioning (e.g., "1.0.0")
```

### Cluster Connectivity Error (Exit Code 3)

```text
Error: connectivity failed
  Context: production-cluster
  
  dial tcp 10.0.0.1:6443: i/o timeout
  
Hint: Check your kubeconfig and network connectivity
```

### Registry Unreachable (Exit Code 3)

```text
Error: connectivity failed
  Context: localhost:5000
  
  cannot connect to registry: connection refused
  
Hint: Verify the registry is running and accessible
```

### Provider Fetch Failed (Exit Code 3)

```text
Error: connectivity failed
  Context: opmodel.dev/providers@v0
  Registry: localhost:5000
  
  timeout after 5s fetching provider module
  
Hint: Check registry connectivity and provider module availability
```

### Version Mismatch (Exit Code 6)

```text
Error: CUE binary version mismatch
  Required: 0.15.x (matches OPM CLI's CUE SDK)
  Found: 0.12.0
  
Install a compatible CUE version or upgrade OPM CLI.
```

### Config Not Found (Exit Code 5)

```text
Error: not found
  Location: ~/.opm/config.cue
  
  configuration file does not exist
  
Hint: Run 'opm config init' to create default configuration
```

### Permission Denied (Exit Code 4)

```text
Error: permission denied
  Context: deployments.apps
  Namespace: production
  
  User "developer" cannot create resource "deployments" in API group "apps"
  
Hint: Contact your cluster administrator for RBAC permissions
```

## Implementation Notes

### Go Types

```go
// Package: internal/errors

// ErrorDetail captures structured error information
type ErrorDetail struct {
    Type     string            // Required: error category
    Message  string            // Required: specific description
    Location string            // Optional: file:line
    Field    string            // Optional: field name
    Context  map[string]string // Optional: additional key-value context
    Hint     string            // Optional: suggestion
}

func (e *ErrorDetail) Error() string {
    var b strings.Builder
    b.WriteString("Error: ")
    b.WriteString(e.Type)
    b.WriteString("\n")
    
    if e.Location != "" {
        b.WriteString("  Location: ")
        b.WriteString(e.Location)
        b.WriteString("\n")
    }
    if e.Field != "" {
        b.WriteString("  Field: ")
        b.WriteString(e.Field)
        b.WriteString("\n")
    }
    for k, v := range e.Context {
        b.WriteString("  ")
        b.WriteString(k)
        b.WriteString(": ")
        b.WriteString(v)
        b.WriteString("\n")
    }
    
    b.WriteString("\n  ")
    b.WriteString(e.Message)
    b.WriteString("\n")
    
    if e.Hint != "" {
        b.WriteString("\nHint: ")
        b.WriteString(e.Hint)
        b.WriteString("\n")
    }
    
    return b.String()
}
```

### Color Support

When stderr is a TTY and `NO_COLOR` is not set:

- `Error:` prefix in red
- `Location:`, `Field:`, context keys in dim/gray
- `Hint:` prefix in yellow
- Message in default color

## Testing Requirements

Error format compliance MUST be verified in E2E tests by parsing stderr output and validating:

1. Error type matches expected exit code
2. Location is present for validation errors
3. Field is present for schema errors
4. Context includes relevant identifiers
5. Hint provides actionable guidance
