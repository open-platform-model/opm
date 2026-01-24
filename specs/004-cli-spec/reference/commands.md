# OPM CLI Command Reference

**Specification**: [../spec.md](../spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-22

## Overview

The OPM CLI provides the following command groups:

- `opm mod` — Operations on individual modules
- `opm bundle` — Operations on bundles (collections of modules)
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
| `5` | Not Found | Resource, module, or OCI artifact not found |
| `6` | Version Mismatch | CUE binary version incompatible with CLI |

---

## Compatibility

### CUE Binary Version Requirement

The OPM CLI delegates `mod vet`, `mod tidy`, `bundle vet`, and `bundle tidy` commands to the external CUE binary. To ensure consistent behavior, the CUE binary version MUST match the CUE SDK version that the OPM CLI was built against on **MAJOR** and **MINOR** version components.

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
| `OPM_CONFIG` | Path to OPM config file | `~/.opm/config.yaml` |
| `OPM_REGISTRY` | Default OCI registry for publish/get | — |
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
| `--verbose` | `-v` | `bool` | | Increase output verbosity |
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
| `--template` | `-t` | `string` | `oci://registry.opm.dev/templates/standard:latest` | OCI URL of template to use |
| `--dir` | `-d` | `string` | `./<name>` | Directory to create module in |

**Examples:**

```sh
# Create module with default template
opm mod init my-app

# Create module from specific template
opm mod init my-app --template oci://registry.opm.dev/templates/microservice:v1

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
- Modifies `cue.mod/module.cue` in place
- Exits with code `6` on version mismatch

**Related:** `opm mod vet`

---

### `opm mod build`

Render a module's CUE definition into Kubernetes manifests.

**Synopsis:**

```text
opm mod build [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) to supply concrete values (can be specified multiple times, in which case all are unified by CUE) |
| `--output` | `-o` | `string` | `yaml` | Output format: `yaml`, `json`, or `dir` |
| `--out-dir` | | `string` | `./manifests` | Output directory (only used with `--output dir`) |

**Mutually Exclusive:** `--output yaml` and `--output json` write to stdout; `--output dir` writes to `--out-dir`.

**Examples:**

```sh
# Build and output YAML to stdout
opm mod build

# Build with values file
opm mod build -v values.cue

# Build with multiple values files (all unified in CUE)
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

Resources are applied in weighted order to respect hard dependencies (CRDs before custom resources, Namespaces before namespaced resources, etc.). See [spec.md Section 6](../spec.md#6-deployment-lifecycle--resource-ordering) for the weighting system.

**Synopsis:**

```text
opm mod apply [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) to supply concrete values |
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

Resources are deleted in reverse weighted order (workloads before namespaces, custom resources before CRDs).

**Synopsis:**

```text
opm mod delete [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) to identify resources to delete |
| `--dry-run` | | `bool` | `false` | Show what would be deleted without deleting |
| `--force` | `-f` | `bool` | `false` | Skip confirmation and force-delete stuck resources |
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

**Synopsis:**

```text
opm mod diff [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) to supply concrete values |
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

**Synopsis:**

```text
opm mod status [flags]
```

**Arguments:** None

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--output` | `-o` | `string` | `table` | Output format: `table`, `json`, or `yaml` |
| `--watch` | `-w` | `bool` | `false` | Continuously watch status updates |

**Examples:**

```sh
# Show status table
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

### `opm mod publish`

Publish a module to an OCI registry.

**Synopsis:**

```text
opm mod publish <oci-url> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-url>` | Yes | OCI registry URL (e.g., `registry.example.com/modules/my-app`) |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--tag` | `-t` | `string` | `latest` | Tag for the published artifact |
| `--force` | `-f` | `bool` | `false` | Overwrite existing tag |

**Examples:**

```sh
# Publish to registry
opm mod publish registry.example.com/modules/my-app

# Publish with specific tag
opm mod publish registry.example.com/modules/my-app -t v1.2.0

# Overwrite existing tag
opm mod publish registry.example.com/modules/my-app -t latest -f
```

**Notes:**

- Validates module with `opm mod vet` before publishing
- Uses OCI registry credentials from Docker config or environment

**Related:** `opm mod get`

---

### `opm mod get`

Download a module from an OCI registry.

**Synopsis:**

```text
opm mod get <oci-url> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-url>` | Yes | OCI registry URL of the module |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--version` | | `string` | `latest` | Version/tag to download |
| `--output-dir` | `-o` | `string` | `$OPM_CACHE_DIR` | Directory to download to |

**Examples:**

```sh
# Download module to cache
opm mod get registry.example.com/modules/my-app

# Download specific version
opm mod get registry.example.com/modules/my-app --version v1.2.0

# Download to specific directory
opm mod get registry.example.com/modules/my-app -o ./vendor/my-app
```

**Related:** `opm mod publish`

---

## Bundle Commands

Bundle commands mirror module commands and operate on bundles (collections of modules). All flags and behaviors are identical unless otherwise noted.

### `opm bundle init`

Create a new bundle from a template.

**Synopsis:**

```text
opm bundle init <name> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<name>` | Yes | Name of the new bundle |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--template` | `-t` | `string` | `oci://registry.opm.dev/templates/bundle:latest` | OCI URL of bundle template |
| `--dir` | `-d` | `string` | `./<name>` | Directory to create bundle in |

**Examples:**

```sh
# Create bundle with default template
opm bundle init my-platform

# Create in specific directory
opm bundle init my-platform --dir ./bundles/platform
```

---

### `opm bundle vet`

Validate bundle CUE definitions.

Delegates to `cue vet`. Validates all modules referenced by the bundle.

**Synopsis:**

```text
opm bundle vet [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--concrete` | | `bool` | `false` | Require all values to be concrete |

**Notes:**

- This command requires the CUE binary to be installed and available in `PATH`
- CUE binary version must be compatible with CLI (see [Compatibility](#compatibility))
- Exits with code `2` on validation errors, code `6` on version mismatch

---

### `opm bundle tidy`

Manage bundle dependencies.

Delegates to `cue mod tidy`.

**Synopsis:**

```text
opm bundle tidy [flags]
```

**Notes:**

- This command requires the CUE binary to be installed and available in `PATH`
- CUE binary version must be compatible with CLI (see [Compatibility](#compatibility))
- Modifies `cue.mod/module.cue` in place
- Exits with code `6` on version mismatch

---

### `opm bundle build`

Render a bundle into Kubernetes manifests.

Renders all modules in the bundle and concatenates their outputs.

**Synopsis:**

```text
opm bundle build [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) for the bundle |
| `--output` | `-o` | `string` | `yaml` | Output format: `yaml`, `json`, or `dir` |
| `--out-dir` | | `string` | `./manifests` | Output directory (with `--output dir`) |

---

### `opm bundle apply`

Apply all bundle resources to a Kubernetes cluster.

Resources across all modules are applied in weighted order.

**Synopsis:**

```text
opm bundle apply [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) for the bundle |
| `--dry-run` | | `bool` | `false` | Server-side dry run |
| `--diff` | | `bool` | `false` | Show diff before applying |
| `--wait` | `-w` | `bool` | `false` | Wait for all resources to become ready |
| `--timeout` | | `duration` | `10m` | Timeout for the operation |

---

### `opm bundle delete`

Delete all resources associated with a bundle.

**Synopsis:**

```text
opm bundle delete [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) to identify resources |
| `--dry-run` | | `bool` | `false` | Show what would be deleted |
| `--force` | | `bool` | `false` | Skip confirmation and force-delete |
| `--timeout` | | `duration` | `10m` | Timeout for the operation |

---

### `opm bundle diff`

Show differences between local bundle and live cluster state.

**Synopsis:**

```text
opm bundle diff [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--values` | `-v` | `string[]` | | Values file(s) for the bundle |
| `--no-color` | | `bool` | `false` | Disable colored output |

---

### `opm bundle status`

Report readiness of all bundle resources.

**Synopsis:**

```text
opm bundle status [flags]
```

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--output` | `-o` | `string` | `table` | Output format: `table`, `json`, `yaml` |
| `--watch` | `-w` | `bool` | `false` | Continuously watch status |

---

### `opm bundle publish`

Publish a bundle to an OCI registry.

**Synopsis:**

```text
opm bundle publish <oci-url> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-url>` | Yes | OCI registry URL for the bundle |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--tag` | `-t` | `string` | `latest` | Tag for the published artifact |
| `--force` | `-f` | `bool` | `false` | Overwrite existing tag |

---

### `opm bundle get`

Download a bundle from an OCI registry.

**Synopsis:**

```text
opm bundle get <oci-url> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-url>` | Yes | OCI registry URL of the bundle |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--version` | | `string` | `latest` | Version/tag to download |
| `--output-dir` | `-o` | `string` | `$OPM_CACHE_DIR` | Directory to download to |

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
| `--force` | `-f` | `bool` | `false` | Overwrite existing config file |

**Examples:**

```sh
# Create default config file at ~/.opm/config.yaml
opm config init

# Overwrite existing config
opm config init -f
```

**Notes:**

- Creates `~/.opm/config.yaml` with all default values populated
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
opm config vet --config ./my-config.yaml
```

**Output (valid):**

```text
Config file is valid: /home/user/.opm/config.yaml
```

**Output (invalid):**

```text
Error: config validation failed
  File: /home/user/.opm/config.yaml
  
  namespace: invalid value "123-invalid" (must be valid Kubernetes namespace)
  registry: missing required field
  
Exit code: 2
```

**Notes:**

- Validates YAML config against internal CUE schema
- Exits with code `0` if valid, `2` if validation fails, `5` if config file not found

**Related:** `opm config init`
