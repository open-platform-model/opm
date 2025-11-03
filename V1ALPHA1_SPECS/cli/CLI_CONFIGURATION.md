# OPM CLI Configuration Guide

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

---

## Overview

OPM CLI configuration follows a layered priority system with explicit, user-visible defaults. All configuration is stored in `~/.opm/` as a CUE module, making it fully inspectable and editable.

**Design Philosophy:** No hidden or hardcoded configuration. All defaults are written to `config.cue` on initialization, ensuring transparency and user control.

---

## Configuration Directory Structure

The OPM configuration is stored as a full CUE module in `~/.opm/`. This directory is **automatically generated** on first CLI use or via `opm config init`.

```text
~/.opm/
├── cue.mod/
│   └── module.cue      # CUE module definition
├── config.cue          # Main configuration (all defaults written here)
└── credentials         # Sensitive credentials (kubectl-style, optional)
```

### Auto-Generation

The configuration directory and default `config.cue` file are created automatically when:

1. You run any OPM command for the first time
2. You explicitly run `opm config init`

This ensures users always have a visible, editable configuration file.

---

## Configuration File Structure

### Example `config.cue` (auto-generated)

```cue
package opmconfig

// OPM Configuration
// This file is auto-generated but fully user-editable
// All values can be overridden by environment variables or CLI flags

config: {
    registry: {
        default: "registry.opm.dev"  // Default OCI registry for modules
    }
    cache: {
        enabled: true
        ttl:     "24h"
    }
    log: {
        level:  "info"   // debug|info|warn|error
        format: "text"   // text|json
    }
}
```

### Configuration Keys

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `config.registry.default` | string | Default OCI registry for module operations | `registry.opm.dev` |
| `config.cache.enabled` | bool | Enable local caching | `true` |
| `config.cache.ttl` | duration | Cache time-to-live | `24h` |
| `config.log.level` | string | Logging level (debug\|info\|warn\|error) | `info` |
| `config.log.format` | string | Log output format (text\|json) | `text` |

---

## Configuration Priority

Configuration values are resolved in the following priority order (highest to lowest):

1. **Command-line flags** - Explicit flags passed to commands
2. **Environment variables** - `OPM_*` prefixed variables
3. **`~/.opm/config.cue`** - User configuration with written defaults
4. ❌ **No hardcoded defaults** - All defaults must be explicit in `config.cue`

### Example Priority Resolution

```bash
# Priority 1: CLI flag (highest)
opm mod build . --verbose

# Priority 2: Environment variable
export OPM_REGISTRY=localhost:5000
opm mod build .

# Priority 3: config.cue setting
# config.cue: config.registry.default: "registry.opm.dev"
opm mod build .
```

---

## Environment Variables

OPM CLI respects the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `OPM_CONFIG_PATH` | Config directory location | `~/.opm` |
| `OPM_REGISTRY_PATH` | Definition registry path override | - |
| `OPM_CACHE_DIR` | Cache directory | `~/.cache/opm` (Linux/Mac)<br>`%LOCALAPPDATA%\opm\cache` (Windows) |
| `OPM_REGISTRY` | Default OCI registry (overrides `config.cue`) | Read from `~/.opm/config.cue` |
| `OPM_LOG_LEVEL` | Default log level | Read from `~/.opm/config.cue` |
| `NO_COLOR` | Disable colored output | - |
| `EDITOR` | Editor for `config edit` | `vim`, `nano`, or `vi` |

### Important Notes

- **`OPM_REGISTRY` vs `CUE_REGISTRY`**: OPM ignores `CUE_REGISTRY` to avoid confusion. Always use `OPM_REGISTRY` for consistency.
- **Registry Selection Priority**:
  1. `OPM_REGISTRY` environment variable (highest priority)
  2. `~/.opm/config.cue` → `config.registry.default` field
  3. No fallback - if not configured, error with helpful message

---

## Cache Configuration

### Cache Locations (Platform-Specific)

**Linux/Mac:** `~/.cache/opm` (follows XDG Base Directory specification)

**Windows:** `%LOCALAPPDATA%\opm\cache`

### Cache Structure

```text
~/.cache/opm/
├── registry/          # Definition registry cache (Units, Traits, Blueprints)
├── modules/           # Downloaded modules
└── oci/               # OCI registry metadata
```

### Cache Management Commands

```bash
# Clear all caches
opm registry cache clear

# Show cache status and statistics
opm registry cache status

# Show cache directory location
opm registry cache path
```

### Configuring Cache Behavior

Edit `~/.opm/config.cue`:

```cue
config: {
    cache: {
        enabled: true    // Enable/disable caching
        ttl:     "24h"   // How long to keep cached items
    }
}
```

Or use environment variable:

```bash
# Override cache directory
export OPM_CACHE_DIR=/custom/cache/path
```

---

## Credential Management

### OCI Registry Credentials

**Primary Method (Recommended):**

OPM automatically reads OCI registry credentials from Docker's standard configuration file:

```text
~/.docker/config.json
```

This file is managed by Docker/Podman and works with standard authentication flows:

```bash
# Login using Docker CLI (credentials stored in ~/.docker/config.json)
docker login registry.opm.dev

# OPM will automatically use these credentials
opm registry push ./my-module oci://registry.opm.dev/org/my-module --version v1.0.0
```

**OPM Native Login:**

OPM also provides its own login command:

```bash
# Login with OPM CLI
opm registry login registry.opm.dev --username myuser

# With password from stdin (recommended for CI/CD)
echo "$REGISTRY_PASSWORD" | opm registry login registry.opm.dev --username myuser --password-stdin
```

### Other Credentials (Optional)

For non-OCI credentials (API keys, tokens, etc.), store in `~/.opm/credentials`:

```text
~/.opm/credentials
```

**Format:** Base64 encoded, kubectl-style

**Example credentials file:**

```yaml
apiVersion: v1
kind: Config
credentials:
- name: my-api-key
  credential:
    token: <base64-encoded-token>
```

### Security Considerations

**Questions to research:**

- How to encrypt/protect `~/.opm/credentials` file?
- Should we support credential exec plugins (like kubectl credential plugins)?
- What's the best practice for storing sensitive configuration values?

---

## Configuration Management Commands

### Initialize Configuration

```bash
# Initialize config directory and default config.cue
opm config init

# Force reinitialize (overwrites existing)
opm config init --force
```

### Display Configuration

```bash
# Show all configuration
opm config show

# Show config directory path
opm config show --path

# Show as JSON
opm config show --output json
```

### Set Configuration Values

```bash
# Set default registry
opm config set registry.default localhost:5000

# Enable cache
opm config set cache.enabled true

# Set cache TTL
opm config set cache.ttl 24h

# Set log level
opm config set log.level debug
```

### Get Configuration Values

```bash
# Get default registry
opm config get registry.default

# Get cache enabled status
opm config get cache.enabled

# Get log level
opm config get log.level
```

### Unset Configuration Values

```bash
# Unset default registry (removes from config.cue)
opm config unset registry.default

# Unset cache TTL
opm config unset cache.ttl
```

### Edit Configuration File

```bash
# Open config.cue in editor (uses $EDITOR)
opm config edit
```

Uses `$EDITOR` environment variable, falls back to `vim`, `nano`, or `vi`.

---

## Implementation Approach

### Loading Configuration

OPM uses CUE's native capabilities to load and validate configuration:

```go
// Pseudo-code for configuration loading
func LoadConfig() (*Config, error) {
    // 1. Load CUE configuration from ~/.opm/config.cue
    configPath := getConfigPath() // Respects OPM_CONFIG_PATH
    ctx := cuecontext.New()
    config := ctx.CompileFiles(configPath + "/config.cue")

    // 2. Validate against config schema
    if err := config.Validate(); err != nil {
        return nil, fmt.Errorf("invalid config: %w", err)
    }

    // 3. Apply environment variable overrides
    applyEnvOverrides(config)

    // 4. Return typed config struct
    return config, nil
}
```

### Configuration Generation

On first use or `opm config init`:

```go
func InitConfig(force bool) error {
    configDir := getConfigPath()

    // Check if already exists
    if exists(configDir) && !force {
        return fmt.Errorf("config already exists, use --force to overwrite")
    }

    // Create directory structure
    os.MkdirAll(configDir + "/cue.mod", 0755)

    // Write module.cue
    writeFile(configDir + "/cue.mod/module.cue", moduleTemplate)

    // Write config.cue with ALL defaults explicitly written
    writeFile(configDir + "/config.cue", configTemplate)

    return nil
}
```

### No Viper Dependency

Unlike traditional Go CLIs, OPM doesn't need Viper because:

1. Configuration is already in CUE format
2. CUE SDK provides loading and validation
3. Simpler dependency tree
4. Native schema validation

---

## Configuration Migration

### What if the config schema changes?

**Approach:**

1. **Versioned config schema**: Include `apiVersion` in config.cue
2. **Migration command**: `opm config migrate` handles upgrades
3. **Backward compatibility**: Read old formats, write new formats
4. **Clear error messages**: If config is incompatible, show migration instructions

**Example migration:**

```bash
# Detect old config version
$ opm config show
Error: Config version v0 is outdated. Please migrate to v1.

# Run migration
$ opm config migrate
✓ Backing up config to ~/.opm/config.cue.backup
✓ Migrating config to v1
✓ Config successfully migrated

# Verify
$ opm config show
Config version: v1
registry.default: registry.opm.dev
cache.enabled: true
...
```

---

## XDG Compliance

OPM follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) on Linux/Mac:

| Purpose | Location | Environment Variable |
|---------|----------|---------------------|
| Configuration | `~/.opm/` or `$XDG_CONFIG_HOME/opm/` | `OPM_CONFIG_PATH` or `XDG_CONFIG_HOME` |
| Cache | `~/.cache/opm/` or `$XDG_CACHE_HOME/opm/` | `OPM_CACHE_DIR` or `XDG_CACHE_HOME` |
| Data | `~/.local/share/opm/` or `$XDG_DATA_HOME/opm/` | (Future use) |

**Windows:**

- Configuration: `%APPDATA%\opm\`
- Cache: `%LOCALAPPDATA%\opm\cache\`

---

## Best Practices

### For Users

1. **Review defaults after installation**:
   ```bash
   opm config init
   cat ~/.opm/config.cue
   ```

2. **Use environment variables in CI/CD**:
   ```bash
   export OPM_REGISTRY=ci-registry.internal
   export OPM_LOG_LEVEL=debug
   ```

3. **Keep credentials out of config.cue**:
   - Use `~/.docker/config.json` for OCI registries
   - Use `~/.opm/credentials` for other secrets

4. **Version control your config**:
   ```bash
   # Safe to commit (no secrets)
   git add ~/.opm/config.cue

   # Never commit credentials
   echo "~/.opm/credentials" >> .gitignore
   ```

### For Platform Teams

1. **Provide pre-configured config templates**:
   ```bash
   # Distribute company-wide config
   curl -o ~/.opm/config.cue https://internal/opm-config.cue
   ```

2. **Use environment variables for dynamic config**:
   ```bash
   # In deployment scripts
   export OPM_REGISTRY=${ENVIRONMENT}-registry.company.com
   ```

3. **Document custom configuration**:
   ```cue
   // ~/.opm/config.cue
   package opmconfig

   // Company-specific configuration
   // Maintained by Platform Team
   // Last updated: 2025-11-03

   config: {
       registry: {
           default: "registry.company.internal"
       }
       cache: {
           enabled: true
           ttl:     "48h"  // Longer TTL for internal network
       }
   }
   ```

---

## Troubleshooting

### Config not found

```bash
$ opm mod build .
Error: Config not found at ~/.opm/config.cue

Solution:
$ opm config init
✓ Config initialized at ~/.opm/
```

### Invalid config syntax

```bash
$ opm config show
Error: Invalid CUE syntax in config.cue:
  line 5: expected '}', found ','

Solution: Edit config.cue and fix syntax errors
$ opm config edit
```

### Registry not configured

```bash
$ opm registry push ...
Error: No registry configured. Set OPM_REGISTRY or config.registry.default

Solution 1 (environment variable):
$ export OPM_REGISTRY=localhost:5000

Solution 2 (config file):
$ opm config set registry.default localhost:5000
```

### Cache issues

```bash
# Clear cache
$ opm registry cache clear

# Disable cache temporarily
$ opm mod build . --no-cache

# Disable cache permanently
$ opm config set cache.enabled false
```

---

## Related Documentation

- [CLI Specification](../CLI_SPEC.md) - Full CLI reference
- [Module Structure Guide](MODULE_STRUCTURE_GUIDE.md) - Directory organization
- [CLI Workflows](CLI_WORKFLOWS.md) - Common usage patterns

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
