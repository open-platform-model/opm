# OPM CLI Command Reference

**Specification**: [../spec.md](../spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-22

## Overview

The OPM CLI provides the following command groups:

- `opm mod` — Operations on individual modules
- `opm config` — CLI configuration management

**Invocation Pattern:**

```text
opm <group> <command> [arguments] [flags]
```

---

## Exit Codes

| Code | Name | Description |
|------|------|-------------|
| `0` | Success | Command completed successfully |
| `1` | General Error | Unspecified error occurred |
| `2` | Validation Error | CUE schema validation failed, invalid values file |
| `3` | Connectivity Error | Cannot reach Kubernetes cluster |
| `4` | Permission Denied | Insufficient RBAC permissions on cluster |
| `5` | Not Found | Resource, module, or CUE module not found |
| `6` | Version Mismatch | CUE binary version incompatible with CLI |

---

## Compatibility

### CUE Binary Version Requirement

The OPM CLI delegates `mod vet` and `mod tidy` commands to the external CUE binary. To ensure consistent behavior, the CUE binary version MUST match the CUE SDK version that the OPM CLI was built against on **MAJOR** and **MINOR** version components.

**Version Matching Rules:**

| SDK Version | Binary Version | Result |
|-------------|----------------|--------|
| `0.11.0` | `0.11.5` | Compatible (PATCH may differ) |
| `0.11.0` | `0.12.0` | Incompatible (MINOR differs) |
| `0.11.0` | `1.0.0` | Incompatible (MAJOR differs) |

**Behavior:**

- **At startup:** If CUE binary is found and version mismatches, a warning is printed to stderr.
- **On `vet`/`tidy` commands:** If version mismatches, the command exits with code `6` and an error message.
- **If CUE binary not found:** Commands requiring CUE binary exit with code `1` and an error message.

**Example warning (startup):**

```text
Warning: CUE binary version (0.12.0) does not match OPM CLI's CUE SDK (0.11.0).
Commands 'mod vet' and 'mod tidy' may behave unexpectedly.
```

**Example error (on vet/tidy):**

```text
Error: CUE binary version mismatch.
  Required: 0.11.x (matches OPM CLI's CUE SDK)
  Found:    0.12.0

Install a compatible CUE version or upgrade OPM CLI.
Exit code: 6
```

### Version Information

The `opm version` command displays full version and compatibility information.

**Synopsis:**

```text
opm version
```

**Output (compatible):**

```text
OPM CLI:
  Version:  v1.2.0
  Build ID: 2026-01-22T14:30:00Z/abc123def

CUE:
  SDK Version:    v0.11.0
  Binary Version: v0.11.5 (compatible)
  Binary Path:    /usr/local/bin/cue
```

**Output (incompatible):**

```text
OPM CLI:
  Version:  v1.2.0
  Build ID: 2026-01-22T14:30:00Z/abc123def

CUE:
  SDK Version:    v0.11.0
  Binary Version: v0.12.0 (incompatible - MINOR version mismatch)
  Binary Path:    /usr/local/bin/cue
```

**Output (CUE binary not found):**

```text
OPM CLI:
  Version:  v1.2.0
  Build ID: 2026-01-22T14:30:00Z/abc123def

CUE:
  SDK Version:    v0.11.0
  Binary Version: not found
  Binary Path:    -
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPM_KUBECONFIG` | Path to kubeconfig file | `~/.kube/config` |
| `OPM_CONTEXT` | Kubernetes context to use | Current context |
| `OPM_NAMESPACE` | Default namespace for operations | `default` |
| `OPM_CONFIG` | Path to OPM config file | `~/.opm/config.cue` |
| `OPM_REGISTRY` | Default registry for all CUE module resolution. When set, all CUE imports resolve from this registry (e.g., `localhost:5000` redirects `opmodel.dev/core@v0` lookups). Passed to CUE binary as `CUE_REGISTRY`. | — |
| `OPM_CACHE_DIR` | Local cache directory | `~/.opm/cache` |
| `NO_COLOR` | Disable colored output when set | — |

---

## Global Flags

These flags are available on all commands.

| Flag | Short | Type | Env Override | Description |
|------|-------|------|--------------|-------------|
| `--kubeconfig` | | `string` | `OPM_KUBECONFIG` | Path to kubeconfig file |
| `--context` | | `string` | `OPM_CONTEXT` | Kubernetes context to use |
| `--namespace` | `-n` | `string` | `OPM_NAMESPACE` | Target namespace. Overrides the module namespace |
| `--config` | `-c` | `string` | `OPM_CONFIG` | Path to OPM config file |
| `--output-format` | `-o` | `string` | | Output format: `text` (default), `yaml`, `json` |
| `--verbose` | `-v` | `bool` | | Increase log verbosity (debug level) |
| `--help` | `-h` | `bool` | | Show help for command |
| `--version` | | `bool` | | Show CLI version |

---

## Module Commands

### `opm mod init`

Create a new module from a template.

**Synopsis:**

```text
opm mod init <name> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<name>` | Yes | Name of the new module (used as directory name) |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--template` | `-t` | `string` | `standard` | Builtin template: `simple`, `standard`, `advanced` |
| `--dir` | `-d` | `string` | `./<name>` | Directory to create module in |

**Examples:**

```sh
# Create module with default template (standard)
opm mod init my-app

# Create module with simple template (minimal, single-file)
opm mod init my-app --template simple

# Create module with advanced template (multi-package)
opm mod init my-app --template advanced

# Create module in specific directory
opm mod init my-app --dir ./modules/my-app
```

**Related:** `opm mod build`, `opm mod apply`

---

### `opm mod vet`

Validate module CUE definitions.

This command delegates to `cue vet` and validates that the module's CUE files are syntactically correct and satisfy all schema constraints.

**Synopsis:**

```text
opm mod vet [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--concrete` | | `bool` | `false` | Require all values to be concrete |

**Examples:**

```sh
# Validate current module
opm mod vet

# Validate with concrete values required
opm mod vet --concrete
```

**Notes:**

- This command requires the CUE binary to be installed and available in `PATH`
- CUE binary version must be compatible with CLI (see [Compatibility](#compatibility))
- When `OPM_REGISTRY` is configured, the CLI sets `CUE_REGISTRY` environment variable before invoking `cue vet`, redirecting all module resolution to the configured registry
- Exits with code `2` on validation errors, code `6` on version mismatch

**Related:** `opm mod tidy`, `opm mod build`

---

### `opm mod tidy`

Manage module dependencies.

This command delegates to `cue mod tidy` and ensures the module's `cue.mod/module.cue` file is up to date with all required dependencies.

**Synopsis:**

```text
opm mod tidy [flags]
```

**Arguments:** None

**Flags:** None (uses global flags only)

**Examples:**

```sh
# Update module dependencies
opm mod tidy
```

**Notes:**

- This command requires the CUE binary to be installed and available in `PATH`
- CUE binary version must be compatible with CLI (see [Compatibility](#compatibility))
- When `OPM_REGISTRY` is configured, the CLI sets `CUE_REGISTRY` environment variable before invoking `cue mod tidy`, redirecting all module resolution to the configured registry
- Modifies `cue.mod/module.cue` in place
- Exits with code `6` on version mismatch

**Related:** `opm mod vet`

---

### `opm mod build`

Render a module's CUE definition into Kubernetes manifests.

> **Note**: Implementation details for this command are specified in [004-render-and-lifecycle-spec](../../004-render-and-lifecycle-spec/spec.md).

**Synopsis:**

```text
opm mod build [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-f` | `string[]` | | Values file(s) to supply concrete values (can be specified multiple times, in which case all are unified by CUE) |
| `--output-format` | `-o` | `string` | `text` | Output format: `text` (default, equals `yaml`), `yaml`, `json`, or `dir` |
| `--out-dir` | | `string` | `./manifests` | Output directory (only used with `--output-format dir`) |

**Mutually Exclusive:** `--output-format` values `text`, `yaml`, and `json` write to stdout; `dir` writes to `--out-dir`.

**Examples:**

```sh
# Build and output YAML to stdout (default)
opm mod build

# Build with values file
opm mod build -v values.cue

# Build with multiple values files (all unified in CUE, meaning there is no hierarchy)
opm mod build -v base.cue -v production.cue

# Output as JSON
opm mod build -o json

# Output to directory structure
opm mod build -o dir --out-dir ./deploy/manifests
```

**Related:** `opm mod apply`, `opm mod diff`

---

### `opm mod apply`

Apply module resources to a Kubernetes cluster.

> **Note**: Implementation details for this command are specified in [004-render-and-lifecycle-spec](../../004-render-and-lifecycle-spec/spec.md).

**Synopsis:**

```text
opm mod apply [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-f` | `string[]` | | Values file(s) to supply concrete values |
| `--dry-run` | | `bool` | `false` | Server-side dry run without making changes |
| `--diff` | | `bool` | `false` | Show diff of changes before applying |
| `--wait` | `-w` | `bool` | `false` | Wait for resources to become ready |
| `--timeout` | | `duration` | `5m` | Timeout for the operation |

**Examples:**

```sh
# Apply module to cluster
opm mod apply

# Apply with values
opm mod apply -v production.cue

# Preview changes without applying
opm mod apply --dry-run

# Show diff and apply
opm mod apply --diff

# Apply and wait for readiness
opm mod apply --wait --timeout 10m
```

**Notes:**

- Uses Kubernetes server-side apply for idempotent operations
- Requires valid kubeconfig and cluster connectivity

**Related:** `opm mod diff`, `opm mod delete`, `opm mod status`

---

### `opm mod delete`

Delete all Kubernetes resources associated with a module.

> **Note**: Implementation details for this command are specified in [004-render-and-lifecycle-spec](../../004-render-and-lifecycle-spec/spec.md).

**Synopsis:**

```text
opm mod delete [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-f` | `string[]` | | Values file(s) to identify resources to delete |
| `--dry-run` | | `bool` | `false` | Show what would be deleted without deleting |
| `--force` | | `bool` | `false` | Skip confirmation and force-delete stuck resources |
| `--timeout` | | `duration` | `5m` | Timeout for the operation |

**Examples:**

```sh
# Delete module resources (with confirmation prompt in TTY)
opm mod delete

# Delete specific deployment
opm mod delete -v production.cue

# Preview deletion
opm mod delete --dry-run

# Force delete without confirmation
opm mod delete --force
```

**Notes:**

- In non-TTY environments, `--force` is required to proceed
- Force delete removes finalizers from stuck resources

**Related:** `opm mod apply`, `opm mod status`

---

### `opm mod diff`

Show differences between local module definition and live cluster state.

> **Note**: Implementation details for this command are specified in [004-render-and-lifecycle-spec](../../004-render-and-lifecycle-spec/spec.md).

**Synopsis:**

```text
opm mod diff [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-f` | `string[]` | | Values file(s) to supply concrete values |
| `--no-color` | | `bool` | `false` | Disable colored diff output |

**Examples:**

```sh
# Show diff against cluster
opm mod diff

# Diff with specific values
opm mod diff -v production.cue

# Diff without colors (for piping)
opm mod diff --no-color | less
```

**Notes:**

- Output is colorized by default when stdout is a TTY
- Exits with code `0` if no differences, `1` if differences exist

**Related:** `opm mod apply`, `opm mod build`

---

### `opm mod status`

Report the readiness and health of a deployed module's resources.

> **Note**: Implementation details for this command are specified in [004-render-and-lifecycle-spec](../../004-render-and-lifecycle-spec/spec.md).

**Synopsis:**

```text
opm mod status [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--output-format` | `-o` | `string` | `text` | Output format: `text` (default, equals `table`), `json`, or `yaml` |
| `--watch` | `-w` | `bool` | `false` | Continuously watch status updates |

**Examples:**

```sh
# Show status table (default)
opm mod status

# Output as JSON
opm mod status -o json

# Watch status continuously
opm mod status --watch
```

**Output Columns (table format):**

- `KIND` — Kubernetes resource kind
- `NAME` — Resource name
- `STATUS` — Ready, NotReady, Progressing, Failed
- `AGE` — Time since creation
- `MESSAGE` — Status message or error

**Related:** `opm mod apply`, `opm mod delete`

---

## Config Commands

The `opm config` command group manages CLI configuration.

### `opm config init`

Create a new OPM configuration file with default values.

**Synopsis:**

```text
opm config init [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--force` | | `bool` | `false` | Overwrite existing config file |

**Examples:**

```sh
# Create default config file at ~/.opm/config.cue
opm config init

# Overwrite existing config
opm config init -f
```

**Notes:**

- Creates `~/.opm/config.cue` with all default values populated
- Creates `~/.opm/` directory if it doesn't exist
- Exits with code `1` if config file exists and `--force` not specified

**Related:** `opm config vet`

---

### `opm config vet`

Validate the OPM configuration file against the internal schema.

**Synopsis:**

```text
opm config vet [flags]
```

**Arguments:** None

**Flags:** None (uses global `--config` flag)

**Examples:**

```sh
# Validate default config file
opm config vet

# Validate specific config file
opm config vet --config ./my-config.cue
```

**Output (valid):**

```text
Config file is valid: /home/user/.opm/config.cue
```

**Output (invalid):**

```text
Error: config validation failed
  File: /home/user/.opm/config.cue
  
  namespace: invalid value "123-invalid" (must be valid Kubernetes namespace)
  
Exit code: 2
```

**Notes:**

- Validates YAML config against internal CUE schema
- Exits with code `0` if valid, `2` if validation fails, `5` if config file not found

**Related:** `opm config init`
