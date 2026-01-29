# Contract: Exit Codes for Distribution Commands

**Spec**: [../spec.md](../spec.md)  
**Date**: 2026-01-28

This document defines the exit code contract for OPM distribution commands.

## Exit Code Table

| Code | Name | Description |
|------|------|-------------|
| `0` | Success | Command completed successfully |
| `1` | General Error | Unspecified error occurred |
| `2` | Validation Error | Module validation failed before publish |
| `3` | Connectivity Error | Cannot reach OCI registry |
| `4` | Permission Denied | Authentication failed or insufficient registry permissions |
| `5` | Not Found | Module/artifact not found in registry |

## Usage by Command

| Command | Possible Exit Codes |
|---------|---------------------|
| `opm mod publish` | 0, 1, 2, 3, 4 |
| `opm mod get` | 0, 1, 3, 4, 5 |
| `opm mod update` | 0, 1, 3, 4 |
| `opm mod tidy` | 0, 1 |

## Error Examples

```text
Error: registry connectivity failed
  Registry: registry.example.com
  
  dial tcp: lookup registry.example.com: no such host
  
Hint: Verify registry URL and network connectivity
Exit code: 3
```

```text
Error: authentication failed
  Registry: registry.example.com
  
  401 Unauthorized
  
Hint: Run 'docker login registry.example.com' or 'oras login registry.example.com'
Exit code: 4
```

```text
Error: module validation failed
  Cannot publish invalid module
  
  File: /path/to/module.cue:23
  metadata.version: invalid value "1.0" (expected semver format)
  
Hint: Fix validation errors and run 'opm mod publish' again
Exit code: 2
```
