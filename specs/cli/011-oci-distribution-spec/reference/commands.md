# Distribution Commands Reference

**Specification**: [../spec.md](../spec.md)  
**Version**: Draft  
**Last Updated**: 2026-01-28

## Module Distribution Commands

### `opm mod publish`

Publish a module to an OCI registry.

**Synopsis:**

```text
opm mod publish <oci-ref> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-ref>` | Yes | OCI registry reference (e.g., `registry.example.com/my-module`) |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--version` | `-v` | `string` | (required) | SemVer version tag (e.g., `v1.2.3`) |
| `--force` | `-f` | `bool` | `false` | Overwrite existing version |

**Examples:**

```sh
# Publish module with version v1.0.0
opm mod publish registry.example.com/my-module --version v1.0.0

# Overwrite existing version
opm mod publish registry.example.com/my-module -v v1.0.0 --force
```

**Notes:**

- Validates module with `opm mod vet` before publishing
- Uses credentials from `~/.docker/config.json`
- `@latest` is not supported - explicit SemVer version required
- Exit codes: 0 (success), 1 (general error), 2 (validation failed), 3 (registry unreachable), 4 (auth failed)

**Related:** `opm mod get`, `opm mod update`

---

### `opm mod get`

Download a module from an OCI registry and add it as a dependency.

**Synopsis:**

```text
opm mod get <oci-ref>@<version> [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `<oci-ref>@<version>` | Yes | Full OCI reference with SemVer version (e.g., `registry.example.com/my-module@v1.2.3`) |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--output-dir` | `-o` | `string` | CUE cache dir | Directory to download module to |

**Examples:**

```sh
# Download module and add to dependencies
opm mod get registry.example.com/my-module@v1.2.3

# Download to specific directory
opm mod get registry.example.com/my-module@v1.2.3 -o ./vendor/my-module
```

**Notes:**

- Updates `module.cue` `deps` field automatically
- Downloads to CUE cache directory by default
- Resolves transitive dependencies
- Uses credentials from `~/.docker/config.json`
- Exit codes: 0 (success), 1 (general error), 3 (registry unreachable), 4 (auth failed), 5 (not found)

**Related:** `opm mod publish`, `opm mod update`, `opm mod tidy`

---

### `opm mod update`

Check for and apply updates to module dependencies.

**Synopsis:**

```text
opm mod update [dependency] [flags]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `[dependency]` | No | Specific dependency to update (updates all if omitted) |

**Flags:**

| Flag | Short | Type | Default | Description |
|------|-------|------|---------|-------------|
| `--check` | | `bool` | `false` | Check for updates without applying (CI-friendly) |
| `--major` | | `bool` | `false` | Include major version updates |

**Examples:**

```sh
# Check for updates to all dependencies (interactive)
opm mod update

# Check for updates without applying (CI mode)
opm mod update --check

# Update specific dependency
opm mod update registry.example.com/my-module

# Include major version updates
opm mod update --major
```

**Notes:**

- Default: only checks for patch/minor updates
- Interactive mode prompts for confirmation
- `--check` mode exits with code 1 if updates available (useful for CI)
- Updates `module.cue` `deps` field on confirmation
- Exit codes: 0 (success/no updates), 1 (updates available in --check mode or error), 3 (registry unreachable), 4 (auth failed)

**Related:** `opm mod get`, `opm mod tidy`

---

### `opm mod tidy`

Remove unused dependencies from module.

**Synopsis:**

```text
opm mod tidy [flags]
```

**Arguments:** None

**Flags:** None (uses global flags only)

**Examples:**

```sh
# Remove unused dependencies
opm mod tidy
```

**Notes:**

- Analyzes imports and removes unreferenced dependencies from `module.cue`
- Cleans local cache of unused modules
- Exit codes: 0 (success), 1 (error)

**Related:** `opm mod get`, `opm mod update`

---

## Authentication

All distribution commands use standard OCI authentication:

- Credentials from `~/.docker/config.json`
- Managed by external tools (`docker login`, `oras login`)
- No built-in login command (following Simplicity principle)

**Setup authentication:**

```sh
# Using docker
docker login registry.example.com

# Using oras
oras login registry.example.com
```
