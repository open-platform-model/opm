# OPM CLI v1 Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-08

---

## Overview

This document serves as the main index and quick reference for the Open Platform Model (OPM) CLI. For detailed command documentation, see the linked documents below.

The CLI is the primary tool for developers and platform engineers to work with OPM modules, Definitions (Resources, Traits, Blueprints), and platform resources.

---

## Related Documentation

This specification is organized across multiple focused documents:

### Command References

- **[Module and Bundle Commands](cli/COMMANDS_MODULE.md)** - Module/bundle init, render, vet, show, publish, get, tidy, fix, template commands
- **[Registry Commands](cli/COMMANDS_REGISTRY.md)** - Definition registry (resource, trait, blueprint, policy, scope) and OCI registry operations
- **[Provider Commands](cli/COMMANDS_PROVIDER.md)** - Provider list, describe, transformers, validate
- **[Configuration Commands](cli/COMMANDS_CONFIG.md)** - Configuration init, show, set, get, unset, edit
- **[Development Tools](cli/COMMANDS_DEV.md)** - Dev inspect, diff, graph, watch
- **[Utility Commands](cli/COMMANDS_UTILITY.md)** - Version, doctor, completion, docs

### Supporting Documentation

- **[Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md)** - Directory structure, templates, and file organization patterns
- **[CLI Configuration](cli/CLI_CONFIGURATION.md)** - Configuration management, environment variables, and credentials
- **[CLI Workflows](cli/CLI_WORKFLOWS.md)** - Common usage patterns and examples
- **[CLI Implementation Decisions](cli/CLI_IMPLEMENTATION_DECISIONS.md)** - Technical decisions and design principles
- **[CLI Open Decisions](cli/CLI_OPEN_DECISIONS.md)** - Open questions and future considerations

---

## Quick Reference

### Command Groups

#### Module and Bundle Operations

For detailed documentation, see [COMMANDS_MODULE.md](cli/COMMANDS_MODULE.md).

| Command | Description |
|---------|-------------|
| `opm mod init <name>` | Initialize a new module |
| `opm mod render <path>` | Render to platform resources (Kubernetes, etc.) |
| `opm mod vet <path>` | Validate module definition |
| `opm mod show <path>` | Display module information |
| `opm mod publish <path> <dest>` | Publish module to OCI registry |
| `opm mod get <source>` | Get module from OCI registry |
| `opm mod tidy` | Tidy module dependencies (requires CUE v0.15.0+) |
| `opm mod fix` | Fix deprecated CUE syntax |
| `opm mod template list` | List available templates |
| `opm mod template show <name>` | Show template details |
| `opm bundle init <name>` | Initialize a new bundle |
| `opm bundle render <path>` | Render bundle to platform resources |
| `opm bundle vet <path>` | Validate bundle definition |
| `opm bundle show <path>` | Display bundle information |
| `opm bundle tidy` | Tidy bundle dependencies |
| `opm bundle fix` | Fix deprecated CUE syntax |

#### Registry Operations

For detailed documentation, see [COMMANDS_REGISTRY.md](cli/COMMANDS_REGISTRY.md).

| Command | Description |
|---------|-------------|
| `opm registry resource list` | List available Units (alias: `opm resource list`) |
| `opm registry trait list` | List available Traits (alias: `opm trait list`) |
| `opm registry blueprint list` | List available Blueprints (alias: `opm blueprint list`) |
| `opm registry policy list` | List available Policies (alias: `opm policy list`) |
| `opm registry scope list` | List available Scopes (alias: `opm scope list`) |
| `opm registry describe <fqn>` | Describe a Definition by FQN |
| `opm registry search <query>` | Search for Definitions |
| `opm registry cache <subcommand>` | Manage registry cache (clear, status, path) |
| `opm registry login <url>` | Authenticate to OCI registry |
| `opm registry logout <url>` | Log out from OCI registry |
| `opm registry list <prefix>` | List modules in OCI registry |

#### Provider Operations

For detailed documentation, see [COMMANDS_PROVIDER.md](cli/COMMANDS_PROVIDER.md).

| Command | Description |
|---------|-------------|
| `opm provider list` | List available providers |
| `opm provider describe <name>` | Show provider details |
| `opm provider transformers [name]` | List transformers (alias: `opm provider trans`) |
| `opm provider validate <file>` | Validate provider configuration |

#### Configuration

For detailed documentation, see [COMMANDS_CONFIG.md](cli/COMMANDS_CONFIG.md).

| Command | Description |
|---------|-------------|
| `opm config init` | Initialize OPM config directory |
| `opm config show` | Display configuration |
| `opm config set <key> <value>` | Set configuration value |
| `opm config get <key>` | Get configuration value |
| `opm config unset <key>` | Remove configuration value |
| `opm config edit` | Edit config in $EDITOR |

#### Development Tools

For detailed documentation, see [COMMANDS_DEV.md](cli/COMMANDS_DEV.md).

| Command | Description |
|---------|-------------|
| `opm dev inspect <path>` | Inspect module transformation pipeline |
| `opm dev diff <path1> <path2>` | Compare module outputs |
| `opm dev graph <path>` | Generate dependency graph |
| `opm dev watch <path>` | Watch and auto-render on changes |

#### Utility Commands

For detailed documentation, see [COMMANDS_UTILITY.md](cli/COMMANDS_UTILITY.md).

| Command | Description |
|---------|-------------|
| `opm version` | Show version information |
| `opm doctor` | Diagnose OPM environment |
| `opm completion <shell>` | Generate shell completion |
| `opm docs open [topic]` | Open documentation in browser |
| `opm docs man <command>` | Show command manual page |

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
| `OPM_REGISTRY_URL` | Override registry URL from config (used for both OPM and passed to CUE commands) | Read from `~/.opm/config.cue` |
| `OPM_LOG_LEVEL` | Default log level | Read from `~/.opm/config.cue` |
| `NO_COLOR` | Disable colored output | - |
| `EDITOR` | Editor for `config edit` | `vim`, `nano`, or `vi` |
| `CUE_REGISTRY` | _(Read-only)_ Set automatically by `opm mod tidy` when calling external CUE binary. Do not set manually. | - |

**Note:** OPM uses `OPM_REGISTRY_URL` for its registry configuration. When delegating to external CUE commands (e.g., `opm mod tidy`), OPM automatically sets `CUE_REGISTRY` to ensure CUE uses the same registry. Do not set `CUE_REGISTRY` manually as it will be overridden.

### Platform-Specific Cache Locations

**Linux/Mac:** `~/.cache/opm` (follows XDG Base Directory specification)

**Windows:** `%LOCALAPPDATA%\opm\cache`

**Cache Structure:**

```text
~/.cache/opm/
├── registry/          # Definition registry cache (Resources, Traits, Blueprints)
├── modules/           # Downloaded modules
├── templates/         # Template cache (OCI templates with TTL-based expiration)
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
| `bundle` | `bun` |
| `provider` | `prov` |
| `registry` | `reg` |
| `config` | `conf`, `cfg` |
| `completion` | `comp` |
| `opm resource list` | Alias for `opm registry resource list` |
| `opm trait list` | Alias for `opm registry trait list` |
| `opm blueprint list` | Alias for `opm registry blueprint list` |
| `opm policy list` | Alias for `opm registry policy list` |
| `opm scope list` | Alias for `opm registry scope list` |

---

## Common Workflows

For complete workflow examples and usage patterns, see **[CLI Workflows Guide](cli/CLI_WORKFLOWS.md)**.

**Quick examples:**

```bash
# Initialize and render a module
opm mod init my-app --template standard
opm mod render ./my-app --platform kubernetes --output ./k8s

# Work with registry definitions
opm blueprint list
opm registry describe opm.dev/blueprints@v1#StatelessWorkload --examples

# Develop with local registry
export OPM_REGISTRY_URL=localhost:5000
opm mod publish ./my-module oci://localhost:5000/opm/my-module:v0.1.0
```

---

## Architecture Overview

OPM uses a **two-layer architecture**:

1. **Authoring Layer** - Flexible structure (ModuleDefinition/BundleDefinition)
2. **Deployment Layer** - Platform-specific resources (via `opm mod render`)

**Note**: The Module IR (intermediate representation) concept exists in the schema (`v1/core/module.cue`) but is not currently implemented. OPM focuses on direct ModuleDefinition → platform resources transformation.

**Available Templates:**

Templates are distributed via OCI registry with embedded fallback for official templates:

- **Simple** (`opm.dev/templates/simple`) - Single file (beginners, quick starts)
- **Standard** (`opm.dev/templates/standard`) - Three files (most applications)
- **Advanced** (`opm.dev/templates/advanced`) - Multi-file organization (complex applications)
- **Platform Bundle** - Bundle with multiple modules (platform teams)

Templates can be referenced by:
- **Short name**: `simple`, `standard`, `advanced` (resolves to official templates)
- **Full OCI reference**: `opm.dev/templates/standard:v1.0.0-alpha.1`
- **Custom template**: `oci://localhost:5000/custom-template:v2.0.0`

For complete template details, see [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md).

---

## Configuration

The OPM configuration is stored as a CUE module in `~/.opm/`, automatically generated on first CLI use or via `opm config init`.

**Directory Structure:**

```text
~/.opm/
├── cue.mod/module.cue  # CUE module definition
├── config.cue          # Main configuration (all defaults written here)
└── credentials         # Sensitive credentials (optional, kubectl-style)
```

**Design Philosophy:** All configuration defaults are written to `config.cue` on initialization, making them visible and editable. No hidden or hardcoded configuration in the CLI binary.

For complete configuration details, see [CLI Configuration Guide](cli/CLI_CONFIGURATION.md).

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-08
