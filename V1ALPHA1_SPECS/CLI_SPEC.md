# OPM CLI v1 Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-10-28

## Overview

This document specifies the command-line interface (CLI) for the Open Platform Model (OPM) v1. The CLI is the primary tool for developers and platform engineers to work with OPM modules, Definitions (Units, Traits, Blueprints), and platform resources.

## Root Command

```text
opm - Open Platform Model CLI
```

The `opm` command is the entry point for all OPM operations.

---

## Commands

### 1. Module Operations (`mod` / `module`)

Handles everything related to modules: initialization, building, validation, and deployment.

#### `opm mod init <name> [flags]`

Initialize a new OPM module.

**Arguments:**

- `<name>` - Module name (required)

**Flags:**

- `--blueprint <oci-ref>` - Use a blueprint module as template
- `--version <version>` - Initial version (default: v0.1.0)
- `--description <text>` - Module description

**Examples:**

```bash
# Initialize a new module
opm mod init my-app

# Initialize from a blueprint
opm mod init my-app --blueprint oci://registry.opm.dev/blueprints/webapp

# Initialize with version
opm mod init my-app --version v1.0.0 --description "My application"
```

#### `opm mod build <module-file> [flags]`

Build a module and generate platform resources.

**Arguments:**

- `<module-file>` - Path to module file (default: ./module.cue)

**Flags:**

- `--output <dir>` - Output directory (required)
- `--format <yaml|json>` - Output format (default: yaml)
- `--verbose`, `-v` - Verbose output
- `--timings` - Show timing information
- `--platform <name>` - Target platform (if multiple providers available)

**Examples:**

```bash
# Build module
opm mod build ./module.cue --output ./k8s

# Build with JSON output
opm mod build ./module.cue --output ./manifests --format json

# Verbose build with timings
opm mod build ./module.cue --output ./k8s --verbose --timings
```

#### `opm mod vet <module-file> [flags]`

Validate module definition against schema and constraints.

**Arguments:**

- `<module-file>` - Path to module file (default: ./module.cue)

**Flags:**

- `--strict` - Enable strict validation
- `--all-errors` - Show all errors (not just first)

**Examples:**

```bash
# Validate module
opm mod vet ./module.cue

# Strict validation
opm mod vet ./module.cue --strict --all-errors
```

#### `opm mod apply <module-file> [flags]`

Apply module to target platform.

**Arguments:**

- `<module-file>` - Path to module file (default: ./module.cue)

**Flags:**

- `--dry-run` - Show what would be applied without applying
- `--platform <name>` - Target platform
- `--wait` - Wait for resources to be ready
- `--timeout <duration>` - Timeout for wait (default: 5m)

**Examples:**

```bash
# Dry run
opm mod apply ./module.cue --dry-run

# Apply and wait
opm mod apply ./module.cue --wait --timeout 10m
```

#### `opm mod show <module-file> [flags]`

Display module information.

**Arguments:**

- `<module-file>` - Path to module file (default: ./module.cue)

**Flags:**

- `--components` - List components
- `--scopes` - List scopes
- `--values` - Show value schema
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Show all module information
opm mod show ./module.cue

# Show only components
opm mod show ./module.cue --components

# Show value schema as JSON
opm mod show ./module.cue --values --output json
```

#### `opm mod export <module-file> [flags]`

Export module definition in different formats.

**Arguments:**

- `<module-file>` - Path to module file (default: ./module.cue)

**Flags:**

- `--format <cue|json|yaml>` - Export format (default: cue)
- `--output <file>` - Output file (default: stdout)

**Use Cases:**

- Share module definition with others
- Generate documentation
- Integration with other tools that don't understand CUE
- Create a "compiled" single-file version of multi-file modules

**Examples:**

```bash
# Export as normalized CUE
opm mod export ./module.cue --format cue > normalized.cue

# Export as JSON schema
opm mod export ./module.cue --format json > module.json

# Export as YAML
opm mod export ./module.cue --format yaml > module.yaml
```

**Note:** This exports the **module definition itself**, not the platform resources. Use `opm mod build` to generate platform resources.

---

### 2. Registry Operations (Primary)

Manage and interact with the Definition registry (Units, Traits, Blueprints, Policies, Scopes).

#### `opm registry unit list [flags]`

Alias: `opm unit list`

List available Units from the registry.

**Flags:**

- `--registry <path|url>` - Specify registry location
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# List all units (both forms work)
opm registry unit list
opm unit list

# List as JSON
opm unit list --output json
```

#### `opm registry trait list [flags]`

Alias: `opm trait list`

List available Traits from the registry.

**Flags:**

- `--registry <path|url>` - Specify registry location
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# List all traits (both forms work)
opm registry trait list
opm trait list

# List as JSON
opm trait list --output json
```

#### `opm registry blueprint list [flags]`

Alias: `opm blueprint list`

List available Blueprints from the registry.

**Flags:**

- `--registry <path|url>` - Specify registry location
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# List all blueprints (both forms work)
opm registry blueprint list
opm blueprint list

# List as JSON
opm blueprint list --output json
```

#### `opm registry describe <fqn> [flags]`

Show detailed information about a specific Definition (auto-detects type: Unit, Trait, Blueprint, Policy, Scope).

**Arguments:**

- `<fqn>` - Fully Qualified Name (e.g., `opm.dev/units/workload@v1#Container`)

**Flags:**

- `--schema` - Show full schema definition
- `--examples` - Show usage examples
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Describe a Blueprint
opm registry describe opm.dev/blueprints@v1#StatelessWorkload

# Describe a Unit with schema
opm registry describe opm.dev/units/workload@v1#Container --schema

# Describe a Trait with examples
opm registry describe opm.dev/traits@v1#Replicas --examples
```

**Note on FQN Structure:**

FQNs follow the pattern `<repo-path>@v<major>#<Name>` (e.g., `opm.dev/units/workload@v1#Container`). In OPM definitions:

- **Root level**: `apiVersion: "opm.dev/v1/core"` and `kind` fields identify the OPM definition type
- **Metadata level**: `metadata.apiVersion` (element-specific, e.g., `opm.dev/units/workload@v1`), `metadata.name`, and computed `metadata.fqn`
- The FQN is automatically computed from `metadata.apiVersion` and `metadata.name`

See [FQN Specification](FQN_SPEC.md) for complete details.

#### `opm registry search <query> [flags]`

Search for Definitions by name, description, or tags across all types.

**Arguments:**

- `<query>` - Search term

**Flags:**

- `--type <unit|trait|blueprint|policy|scope>` - Filter by Definition type
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Search across all Definition types
opm registry search database

# Search only Blueprints
opm registry search workload --type blueprint

# Search with JSON output
opm registry search storage --output json
```

#### `opm registry cache <subcommand>`

Manage registry cache.

**Subcommands:**

- `clear` - Clear registry cache
- `status` - Show cache status and statistics
- `path` - Show cache directory location

**Examples:**

```bash
# Clear cache
opm registry cache clear

# Show cache status
opm registry cache status

# Show cache path
opm registry cache path
```

---

### 3. Provider Operations (`provider` / `prov`)

Manage providers and transformers.

#### `opm provider list [flags]`

List available providers.

**Flags:**

- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# List all providers
opm provider list

# List as JSON
opm prov list --output json
```

#### `opm provider describe <provider-name> [flags]`

Show detailed provider information.

**Arguments:**

- `<provider-name>` - Provider name (e.g., `kubernetes`, `terraform`)

**Flags:**

- `--verbose`, `-v` - Show detailed information
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Describe provider
opm provider describe kubernetes

# Verbose description
opm prov describe kubernetes --verbose
```

#### `opm provider transformers [provider-name] [flags]`

Alias: `opm provider trans`

List and describe transformers.

**Arguments:**

- `[provider-name]` - Optional provider filter

**Flags:**

- `--unit <fqn>` - Filter by Unit type
- `--trait <fqn>` - Filter by Trait type
- `--blueprint <fqn>` - Filter by Blueprint type
- `--verbose`, `-v` - Show transformer logic/details
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# List all transformers across all providers
opm provider transformers

# List transformers for specific provider
opm provider transformers kubernetes

# List transformers for specific Blueprint
opm provider trans --blueprint opm.dev/blueprints@v1#StatelessWorkload

# List transformers for specific Unit
opm provider trans --unit opm.dev/units/workload@v1#Container

# Verbose output
opm prov trans kubernetes --verbose
```

#### `opm provider validate <config-file> [flags]`

Validate provider configuration.

**Arguments:**

- `<config-file>` - Path to provider configuration file

**Flags:**

- `--strict` - Enable strict validation

**Examples:**

```bash
# Validate provider config
opm provider validate ./provider.cue

# Strict validation
opm prov validate ./provider.cue --strict
```

---

### 4. OCI Registry Operations (`registry` / `reg`)

Interact with OCI registries for modules and Definitions.

#### `opm registry login <registry-url> [flags]`

Authenticate to an OCI registry.

**Arguments:**

- `<registry-url>` - Registry URL (e.g., `registry.opm.dev`, `localhost:5000`)

**Flags:**

- `--username <user>`, `-u` - Username
- `--password <pass>`, `-p` - Password (not recommended, use --password-stdin)
- `--password-stdin` - Read password from stdin

**Examples:**

```bash
# Login with prompt
opm registry login registry.opm.dev --username myuser

# Login with stdin
echo "$REGISTRY_PASSWORD" | opm registry login registry.opm.dev --username myuser --password-stdin

# Login to local registry
opm reg login localhost:5000
```

#### `opm registry logout <registry-url>`

Log out from an OCI registry.

**Arguments:**

- `<registry-url>` - Registry URL

**Examples:**

```bash
# Logout
opm registry logout registry.opm.dev
```

#### `opm registry push <module-path> <oci-ref> [flags]`

Push a module to an OCI registry.

**Arguments:**

- `<module-path>` - Local module path
- `<oci-ref>` - Target OCI reference (e.g., `oci://registry.opm.dev/org/module`)

**Flags:**

- `--version <version>` - Module version (required)
- `--latest` - Also tag as latest

**Examples:**

```bash
# Push module
opm registry push ./my-app oci://localhost:5000/opm/my-app --version v1.0.0

# Push and tag as latest
opm reg push ./my-app oci://registry.opm.dev/org/my-app --version v1.2.3 --latest
```

#### `opm registry pull <oci-ref> [flags]`

Pull a module from an OCI registry.

**Arguments:**

- `<oci-ref>` - OCI reference (e.g., `oci://registry.opm.dev/org/module@v1.0.0`)

**Flags:**

- `--output <dir>` - Output directory (default: current directory)

**Examples:**

```bash
# Pull module
opm registry pull oci://registry.opm.dev/org/my-app@v1.0.0

# Pull to specific directory
opm reg pull oci://registry.opm.dev/org/my-app@v1.0.0 --output ./modules
```

#### `opm registry list <oci-prefix> [flags]`

List modules in an OCI registry.

**Arguments:**

- `<oci-prefix>` - Registry prefix (e.g., `localhost:5000/opm`, `registry.opm.dev/org`)

**Flags:**

- `--tags` - Show all tags for each module

**Examples:**

```bash
# List modules
opm registry list localhost:5000/opm

# List with tags
opm reg list registry.opm.dev/org --tags
```

---

### 5. Configuration (`config` / `conf` / `cfg`)

Manage OPM configuration stored in `~/.opm/`.

#### `opm config init [flags]`

Initialize OPM config directory (`~/.opm/`).

**Flags:**

- `--force` - Overwrite existing configuration

**Examples:**

```bash
# Initialize config
opm config init

# Force reinitialize
opm conf init --force
```

#### `opm config show [flags]`

Display current configuration.

**Flags:**

- `--path` - Show config directory path
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Show all config
opm config show

# Show config path
opm cfg show --path

# Show as JSON
opm conf show --output json
```

#### `opm config set <key> <value>`

Set a configuration value.

**Arguments:**

- `<key>` - Configuration key (dot-notation)
- `<value>` - Configuration value

**Examples:**

```bash
# Set default registry
opm config set registry.default localhost:5000

# Enable cache
opm cfg set cache.enabled true

# Set cache TTL
opm conf set cache.ttl 24h
```

#### `opm config get <key>`

Get a configuration value.

**Arguments:**

- `<key>` - Configuration key (dot-notation)

**Examples:**

```bash
# Get default registry
opm config get registry.default

# Get cache enabled status
opm cfg get cache.enabled
```

#### `opm config unset <key>`

Remove a configuration value.

**Arguments:**

- `<key>` - Configuration key (dot-notation)

**Examples:**

```bash
# Unset default registry
opm config unset registry.default
```

#### `opm config edit`

Open configuration file in editor.

Uses `$EDITOR` environment variable, falls back to `vim`, `nano`, or `vi`.

**Examples:**

```bash
# Edit config
opm config edit
```

---

### 6. Development Tools (`dev`)

Development and debugging utilities.

#### `opm dev inspect <module-file> [flags]`

Inspect module transformation pipeline stages.

**Arguments:**

- `<module-file>` - Path to module file

**Flags:**

- `--stage <stage>` - Show specific stage (components|scopes|transformers|resources)
- `--component <name>` - Focus on specific component
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Inspect full pipeline
opm dev inspect ./module.cue

# Inspect transformer stage
opm dev inspect ./module.cue --stage transformers

# Inspect specific component
opm dev inspect ./module.cue --component web-server --stage resources
```

#### `opm dev diff <module-file-1> <module-file-2> [flags]`

Compare outputs from two module definitions.

**Arguments:**

- `<module-file-1>` - First module file
- `<module-file-2>` - Second module file

**Flags:**

- `--output <dir>` - Save outputs to directory for inspection
- `--context <lines>` - Lines of context in diff (default: 3)

**Examples:**

```bash
# Diff two modules
opm dev diff ./module-v1.cue ./module-v2.cue

# Diff with more context
opm dev diff ./module-v1.cue ./module-v2.cue --context 10
```

#### `opm dev graph <module-file> [flags]`

Generate module dependency graph.

**Arguments:**

- `<module-file>` - Path to module file

**Flags:**

- `--format <dot|mermaid>` - Graph format (default: dot)
- `--output <file>` - Output file (default: stdout)

**Examples:**

```bash
# Generate DOT graph
opm dev graph ./module.cue --format dot > module.dot

# Generate Mermaid diagram
opm dev graph ./module.cue --format mermaid > module.md
```

#### `opm dev watch <module-file> [flags]`

Watch module files and rebuild on changes.

**Arguments:**

- `<module-file>` - Path to module file to watch

**Flags:**

- `--output <dir>` - Output directory (required)
- `--format <yaml|json>` - Output format (default: yaml)

**Examples:**

```bash
# Watch and rebuild
opm dev watch ./module.cue --output ./k8s

# Watch with JSON output
opm dev watch ./module.cue --output ./manifests --format json
```

---

### 7. Version (`version`)

Display version information.

#### `opm version [flags]`

**Flags:**

- `--short` - Short version only (e.g., `v1.0.0`)
- `--json` - Output as JSON

**Output Includes:**

- OPM CLI version
- CUE version (used by OPM)
- Go version (used to build CLI)
- Commit SHA
- Build date
- OS/Architecture

**Examples:**

```bash
# Full version info
opm version

# Short version
opm version --short

# JSON output
opm version --json
```

**Example Output:**

```text
OPM CLI:      v1.0.0
CUE Version:  v0.14.2
Go Version:   go1.23.1
Commit:       a1b2c3d4
Build Date:   2025-10-28T10:30:00Z
OS/Arch:      linux/amd64
```

---

### 8. Completion (`completion`)

Generate shell completion scripts.

#### `opm completion <shell>`

**Arguments:**

- `<shell>` - Shell type (bash|zsh|fish|powershell)

**Examples:**

```bash
# Bash - load in current session
source <(opm completion bash)

# Bash - install permanently
opm completion bash > /etc/bash_completion.d/opm

# Zsh
opm completion zsh > ~/.zsh/completion/_opm

# Fish
opm completion fish > ~/.config/fish/completions/opm.fish

# PowerShell
opm completion powershell > opm.ps1
```

---

### 9. Documentation (`docs`)

Access documentation and help.

#### `opm docs open [topic]`

Open online documentation in browser.

**Arguments:**

- `[topic]` - Optional topic (units|traits|blueprints|modules|providers|cli)

**Examples:**

```bash
# Open main docs
opm docs open

# Open Units docs
opm docs open units

# Open Blueprints docs
opm docs open blueprints

# Open CLI reference
opm docs open cli
```

#### `opm docs man <command>`

Show manual page for a command.

**Arguments:**

- `<command>` - Command name

**Examples:**

```bash
# Show man page for mod build
opm docs man "mod build"

# Show man page for unit list
opm docs man "unit list"

# Show man page for registry describe
opm docs man "registry describe"
```

---

## Global Flags

Available on all commands:

| Flag | Short | Description |
|------|-------|-------------|
| `--help` | `-h` | Show help for command |
| `--config <path>` | | Custom config file location |
| `--verbose` | `-v` | Verbose output |
| `--quiet` | `-q` | Suppress non-error output |
| `--no-color` | | Disable colored output |
| `--log-level <level>` | | Set log level (debug\|info\|warn\|error) |
| `--log-format <format>` | | Log format (text\|json) |

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPM_CONFIG_PATH` | Config directory location | `~/.opm` |
| `OPM_REGISTRY_PATH` | Definition registry path override | - |
| `OPM_CACHE_DIR` | Cache directory | `~/.cache/opm` (Linux/Mac)<br>`%LOCALAPPDATA%\opm\cache` (Windows) |
| `OPM_REGISTRY` | Default OCI registry | - |
| `OPM_LOG_LEVEL` | Default log level | `info` |
| `NO_COLOR` | Disable colored output | - |
| `EDITOR` | Editor for `config edit` | `vim`, `nano`, or `vi` |

### Platform-Specific Cache Locations

**Linux/Mac:** `~/.cache/opm` (follows XDG Base Directory specification)

**Windows:** `%LOCALAPPDATA%\opm\cache`

**Cache Structure:**

```text
~/.cache/opm/
├── registry/          # Definition registry cache (Units, Traits, Blueprints)
├── modules/           # Downloaded modules
└── oci/               # OCI registry metadata
```

---

## Exit Codes

| Code | Description |
|------|-------------|
| `0` | Success |
| `1` | General error |
| `2` | Validation error |
| `3` | Network error |
| `4` | Authentication error |
| `130` | Interrupted (SIGINT) |

---

## Command Aliases

Short forms for common commands:

| Full Command | Aliases / Notes |
|--------------|-----------------|
| `module` | `mod`, `m` |
| `provider` | `prov` |
| `registry` | `reg` |
| `config` | `conf`, `cfg` |
| `completion` | `comp` |
| `opm unit list` | Alias for `opm registry unit list` |
| `opm trait list` | Alias for `opm registry trait list` |
| `opm blueprint list` | Alias for `opm registry blueprint list` |

---

## Configuration File Structure

The OPM configuration is stored as a CUE module in `~/.opm/`.

**Directory Structure:**

```text
~/.opm/
├── cue.mod/
│   └── module.cue      # CUE module definition
├── config.cue          # Main configuration
└── registries.cue      # Registry credentials (optional)
```

**Example `config.cue`:**

```cue
package opmconfig

config: {
    oci: {
        defaultRegistry: "registry.opm.dev"
    }
    cache: {
        enabled: true
        ttl:     "24h"
    }
    registry: {
        path: ""  // Override Definition registry path
    }
    log: {
        level:  "info"
        format: "text"
    }
}
```

---

## Common Workflows

### Initialize and Build a Module

```bash
# 1. Initialize new module
opm mod init my-app --blueprint oci://registry.opm.dev/blueprints/webapp

# 2. Edit module definition
vim module.cue

# 3. Validate module
opm mod vet ./module.cue

# 4. Build platform resources
opm mod build ./module.cue --output ./k8s --verbose

# 5. Apply to platform
opm mod apply ./module.cue
```

### Work with Registry Definitions

```bash
# 1. List available Blueprints
opm blueprint list

# 2. List available Units
opm unit list

# 3. Describe a specific Blueprint
opm registry describe opm.dev/blueprints@v1#StatelessWorkload --examples

# 4. Describe a specific Unit
opm registry describe opm.dev/units/workload@v1#Container --schema

# 5. Search across all Definition types
opm registry search database

# 6. Clear cache if needed
opm registry cache clear
```

### Develop with Local Registry

```bash
# 1. Start local registry (see Makefile.registry)
make -f Makefile.registry start

# 2. Configure CLI to use local registry
export OPM_REGISTRY=localhost:5000

# 3. Login to local registry
opm registry login localhost:5000

# 4. Push module to local registry
opm registry push ./my-module oci://localhost:5000/opm/my-module --version v0.1.0

# 5. List modules in registry
opm registry list localhost:5000/opm

# 6. Pull module
opm registry pull oci://localhost:5000/opm/my-module@v0.1.0
```

### Debug Module Transformation

```bash
# 1. Inspect transformation pipeline
opm dev inspect ./module.cue --verbose

# 2. Focus on specific component
opm dev inspect ./module.cue --component web-server --stage transformers

# 3. Compare two module versions
opm dev diff ./module-v1.cue ./module-v2.cue

# 4. Generate dependency graph
opm dev graph ./module.cue --format mermaid > diagram.md

# 5. Watch for changes during development
opm dev watch ./module.cue --output ./k8s
```

---

## Design Principles

1. **Consistent Command Structure**: All commands follow `opm <noun> <verb>` pattern
2. **Sensible Defaults**: Common use cases work with minimal flags
3. **Progressive Disclosure**: Basic usage is simple, advanced features available via flags
4. **Composability**: Commands can be piped and combined with standard Unix tools
5. **Machine-Readable Output**: All commands support JSON/YAML output for scripting
6. **XDG Compliance**: Follows XDG Base Directory specification on Linux/Mac
7. **Clear Separation**: Config in `~/.opm/`, cache in `~/.cache/opm` (Linux/Mac)

---

## Future Considerations

Commands that may be added in future versions:

1. **`opm platform`** - Manage platform definitions
2. **`opm upgrade`** - Self-update CLI
3. **`opm policy`** - Manage policy definitions
4. **`opm scope`** - Manage scope definitions
5. **`opm plugin`** - Extensibility via plugins

---

**Status:** This specification is a draft for OPM v1 CLI development.

**Next Steps:**

1. Review and approve specification
2. Design Go CLI framework structure
3. Implement core commands (version, config, completion)
4. Implement module commands (init, build, vet)
5. Implement registry commands (unit, trait, blueprint list/describe, cache)
6. Implement provider commands
7. Implement OCI registry commands (login, push, pull)
8. Implement dev tools
9. Write tests and documentation
10. Package and release

---

**Document Version:** 1.0.0-draft
**Date:** 2025-10-28
