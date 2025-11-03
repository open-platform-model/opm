# OPM CLI v1 Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

## Overview

This document specifies the command-line interface (CLI) for the Open Platform Model (OPM) v1. The CLI is the primary tool for developers and platform engineers to work with OPM modules, Definitions (Units, Traits, Blueprints), and platform resources.

---

## Related Documentation

This specification is organized across multiple focused documents:

- **[Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md)** - Directory structure, templates, and file organization patterns
- **[CLI Configuration](cli/CLI_CONFIGURATION.md)** - Configuration management, environment variables, and credentials
- **[CLI Workflows](cli/CLI_WORKFLOWS.md)** - Common usage patterns and examples
- **[CLI Implementation](cli/CLI_IMPLEMENTATION.md)** - Technical decisions, design principles, and developer notes

---

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

- `--template <name|oci-ref>` - Use a template for initialization (simple|standard|advanced or OCI reference)
- `--version <version>` - Initial version (default: v0.1.0)
- `--description <text>` - Module description

**Examples:**

```bash
# Initialize a new module (uses standard template by default)
opm mod init my-app

# Initialize from built-in template
opm mod init my-app --template simple
opm mod init my-app --template standard
opm mod init my-app --template advanced

# Initialize from OCI registry template
opm mod init my-app --template oci://registry.opm.dev/templates/webapp

# Initialize with version
opm mod init my-app --version v1.0.0 --description "My application"
```

**See also:** [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md) for details on available templates and directory organization patterns.

#### `opm mod build <module-file> [flags]`

Flatten ModuleDefinition to optimized Module (pure CUE output only).

**Purpose:**

Compiles and flattens a ModuleDefinition into an optimized Module intermediate representation (IR). This step:

- Loads and unifies all CUE files in the package
- Flattens Blueprints into Units + Traits
- Outputs a single, optimized `.module.cue` file (pure CUE)
- **Does not** generate platform-specific resources (use `opm mod render` for that)

**Arguments:**

- `<module-file>` - Path to module file or directory (default: ./module.cue or current directory)

**Flags:**

- `--output <file>` - Output file path (required) - must end in `.module.cue`
- `--verbose`, `-v` - Verbose output
- `--timings` - Show timing information and performance metrics

**File Discovery:**

The CLI automatically discovers `module.cue` in the following order:

1. Explicit file path: `./path/to/module.cue`
2. Current directory: `.` searches for `./module.cue`
3. Subdirectory: `./my-app` searches for `./my-app/module.cue`

All `.cue` files in the same package are automatically unified by CUE.

**Examples:**

```bash
# Build module (explicit file)
opm mod build ./module.cue --output ./dist/my-app.module.cue

# Build module (auto-detect in current directory)
opm mod build . --output ./dist/my-app.module.cue

# Build module (auto-detect in subdirectory)
opm mod build ./my-app --output ./dist/my-app.module.cue

# Verbose build with timings
opm mod build ./module.cue --output ./dist/my-app.module.cue --verbose --timings
```

**Performance Benefits:**

Pre-building (flattening) a ModuleDefinition provides significant performance improvements:

| Operation | ModuleDefinition | Module (Flattened) | Improvement |
|-----------|------------------|-------------------|-------------|
| First build | 5-10s | - | - |
| Rendering | 2-3s | 0.5-1s | 50-80% faster |
| Memory usage | 100% | 40-60% | 40-60% reduction |

**See also:**

- [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md) for file organization
- `opm mod render` to generate platform-specific resources

#### `opm mod render <module-file> [flags]`

Render ModuleDefinition or Module to platform-specific resources.

**Purpose:**

Generates platform-specific resources (Kubernetes YAML, Docker Compose, etc.) from a ModuleDefinition or pre-built Module. This command:

- Accepts either ModuleDefinition or Module as input
- If given ModuleDefinition, flattens it on-the-fly (no intermediate file saved)
- Matches components to platform transformers
- Executes transformers to generate platform resources
- Outputs YAML or JSON files

**Arguments:**

- `<module-file>` - Path to ModuleDefinition or Module file (default: ./module.cue or current directory)

**Flags:**

- `--output <dir>` - Output directory for platform resources (required)
- `--platform <name>` - Target platform (kubernetes, docker-compose) - required
- `--format <yaml|json>` - Output format (default: yaml)
- `--verbose`, `-v` - Verbose output
- `--timings` - Show timing information

**Supported Platforms:**

- `kubernetes` - Kubernetes manifests (Deployments, Services, ConfigMaps, etc.)
- `docker-compose` - Docker Compose files (coming soon)

**Examples:**

```bash
# Render from ModuleDefinition (flattens on-the-fly)
opm mod render ./module.cue --platform kubernetes --output ./k8s

# Render from pre-built Module (faster)
opm mod render ./dist/my-app.module.cue --platform kubernetes --output ./k8s

# Render to JSON
opm mod render ./module.cue --platform kubernetes --output ./manifests --format json

# Render with verbose output
opm mod render ./module.cue --platform kubernetes --output ./k8s --verbose

# Render to Docker Compose
opm mod render ./module.cue --platform docker-compose --output ./compose
```

**Typical Workflow:**

```bash
# Option 1: Direct rendering (convenient for development)
opm mod render ./my-app --platform kubernetes --output ./k8s

# Option 2: Pre-build then render (faster for repeated renders)
opm mod build ./my-app --output ./dist/my-app.module.cue
opm mod render ./dist/my-app.module.cue --platform kubernetes --output ./k8s
opm mod render ./dist/my-app.module.cue --platform docker-compose --output ./compose
```

**See also:**

- `opm mod build` to pre-flatten ModuleDefinition for better performance
- `opm provider transformers` to list available transformers per platform

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

**Purpose:**

Renders and applies platform-specific resources to the target platform. This command:

- Renders resources (like `opm mod render`) if not already rendered
- Applies resources to the target platform (e.g., kubectl apply for Kubernetes)

**Arguments:**

- `<module-file>` - Path to ModuleDefinition or Module file (default: ./module.cue)

**Flags:**

- `--platform <name>` - Target platform (kubernetes, docker-compose) - required
- `--dry-run` - Show what would be applied without applying
- `--wait` - Wait for resources to be ready
- `--timeout <duration>` - Timeout for wait (default: 5m)
- `--verbose`, `-v` - Verbose output

**Examples:**

```bash
# Apply to Kubernetes (renders on-the-fly)
opm mod apply ./module.cue --platform kubernetes

# Dry run to see what would be applied
opm mod apply ./module.cue --platform kubernetes --dry-run

# Apply and wait for resources to be ready
opm mod apply ./module.cue --platform kubernetes --wait --timeout 10m

# Apply from pre-built Module
opm mod apply ./dist/my-app.module.cue --platform kubernetes
```

**See also:**

- `opm mod render` to generate resources without applying
- `opm mod build` to pre-flatten ModuleDefinition

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

#### `opm mod tidy`

Tidy module dependencies using CUE's module management.

**Description:**

Ensures that the `cue.mod/module.cue` file matches the dependencies actually used in the module. Removes unused dependencies and adds missing ones.

**Examples:**

```bash
# Tidy module dependencies
opm mod tidy

# Equivalent to running
cue mod tidy
```

**Use Cases:**

- Clean up unused dependencies
- Add missing dependencies automatically
- Maintain clean module definition

#### `opm mod fix`

Fix deprecated CUE syntax and migrate to newer versions.

**Description:**

Updates CUE code to use current syntax and idioms. Useful when upgrading CUE versions or migrating older module definitions.

**Examples:**

```bash
# Fix CUE syntax in current module
opm mod fix

# Equivalent to running
cue fix ./...
```

**Use Cases:**

- Migrate modules to newer CUE versions
- Update deprecated syntax
- Modernize module definitions

---

### 2. Bundle Operations (`bundle` / `bun`)

**Overview:** Bundles are collections of modules with values. They enable grouping related modules for easier distribution and management. Platform teams can inherit and modify bundles, and end-users deploy them as BundleReleases.

**Architecture Note:** Since both Modules and Bundles are CUE modules under the hood, `opm bundle` commands reuse the same implementation logic as `opm mod` commands, just operating on Bundle definitions instead of Module definitions.

**Bundle Hierarchy:**

- **BundleDefinition**: Collection of ModuleDefinitions with value schema (developer/platform team creates)
- **Bundle**: Compiled/optimized form with flattened modules
- **BundleRelease**: Deployed instance with concrete values (end-user creates)

#### `opm bundle init <name> [flags]`

Alias: `opm bun init`

Initialize a new OPM bundle.

**Arguments:**

- `<name>` - Bundle name (required)

**Flags:**

- `--template <name|oci-ref>` - Use a bundle template (platform-bundle or OCI reference)
- `--version <version>` - Initial version (default: v0.1.0)
- `--description <text>` - Bundle description

**Examples:**

```bash
# Initialize a new bundle (uses platform-bundle template by default)
opm bundle init my-platform

# Initialize from built-in template
opm bundle init my-platform --template platform-bundle

# Initialize from OCI registry template
opm bun init my-platform --template oci://registry.opm.dev/templates/k8s-platform

# Initialize with version
opm bundle init my-platform --version v1.0.0 --description "My platform bundle"
```

**See also:** [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md) for details on bundle templates and organization patterns.

#### `opm bundle build <bundle-file> [flags]`

Alias: `opm bun build`

Flatten BundleDefinition to optimized Bundle (pure CUE output only).

**Purpose:**

Compiles and flattens a BundleDefinition into an optimized Bundle intermediate representation (IR). This step:

- Loads and unifies all CUE files in the package
- Flattens all included ModuleDefinitions to Modules
- Flattens Blueprints into Units + Traits for each module
- Outputs a single, optimized `.bundle.cue` file (pure CUE)
- **Does not** generate platform-specific resources (use `opm bundle render` for that)

**Arguments:**

- `<bundle-file>` - Path to bundle file or directory (default: ./bundle.cue or current directory)

**Flags:**

- `--output <file>` - Output file path (required) - must end in `.bundle.cue`
- `--verbose`, `-v` - Verbose output
- `--timings` - Show timing information and performance metrics

**File Discovery:**

The CLI automatically discovers `bundle.cue` in the following order:

1. Explicit file path: `./path/to/bundle.cue`
2. Current directory: `.` searches for `./bundle.cue`
3. Subdirectory: `./platform` searches for `./platform/bundle.cue`

All `.cue` files in the same package are automatically unified by CUE.

**Examples:**

```bash
# Build bundle (explicit file)
opm bundle build ./bundle.cue --output ./dist/platform.bundle.cue

# Build bundle (auto-detect in current directory)
opm bundle build . --output ./dist/platform.bundle.cue

# Build bundle (auto-detect in subdirectory)
opm bundle build ./my-platform --output ./dist/platform.bundle.cue

# Verbose build with timings
opm bundle build ./bundle.cue --output ./dist/platform.bundle.cue --verbose --timings
```

**Performance Benefits:**

Pre-building a BundleDefinition flattens all included modules, providing the same performance benefits as `opm mod build` for each module.

**See also:**

- [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md) for bundle organization
- `opm bundle render` to generate platform-specific resources

#### `opm bundle render <bundle-file> [flags]`

Alias: `opm bun render`

Render BundleDefinition or Bundle to platform-specific resources for all included modules.

**Purpose:**

Generates platform-specific resources (Kubernetes YAML, Docker Compose, etc.) from a BundleDefinition or pre-built Bundle. This command:

- Accepts either BundleDefinition or Bundle as input
- If given BundleDefinition, flattens it on-the-fly (no intermediate file saved)
- Renders resources for all modules in the bundle
- Matches components to platform transformers
- Executes transformers to generate platform resources
- Outputs YAML or JSON files

**Arguments:**

- `<bundle-file>` - Path to BundleDefinition or Bundle file (default: ./bundle.cue or current directory)

**Flags:**

- `--output <dir>` - Output directory for platform resources (required)
- `--platform <name>` - Target platform (kubernetes, docker-compose) - required
- `--format <yaml|json>` - Output format (default: yaml)
- `--verbose`, `-v` - Verbose output
- `--timings` - Show timing information

**Supported Platforms:**

- `kubernetes` - Kubernetes manifests (Deployments, Services, ConfigMaps, etc.)
- `docker-compose` - Docker Compose files (coming soon)

**Examples:**

```bash
# Render from BundleDefinition (flattens on-the-fly)
opm bundle render ./bundle.cue --platform kubernetes --output ./k8s

# Render from pre-built Bundle (faster)
opm bundle render ./dist/platform.bundle.cue --platform kubernetes --output ./k8s

# Render to JSON
opm bun render ./bundle.cue --platform kubernetes --output ./manifests --format json

# Render with verbose output
opm bundle render ./bundle.cue --platform kubernetes --output ./k8s --verbose
```

**Typical Workflow:**

```bash
# Option 1: Direct rendering (convenient for development)
opm bundle render ./my-platform --platform kubernetes --output ./k8s

# Option 2: Pre-build then render (faster for repeated renders)
opm bundle build ./my-platform --output ./dist/platform.bundle.cue
opm bundle render ./dist/platform.bundle.cue --platform kubernetes --output ./k8s
```

**See also:**

- `opm bundle build` to pre-flatten BundleDefinition for better performance
- `opm provider transformers` to list available transformers per platform

#### `opm bundle vet <bundle-file> [flags]`

Alias: `opm bun vet`

Validate bundle definition against schema and constraints.

**Arguments:**

- `<bundle-file>` - Path to bundle file (default: ./bundle.cue)

**Flags:**

- `--strict` - Enable strict validation
- `--all-errors` - Show all errors (not just first)

**Examples:**

```bash
# Validate bundle
opm bundle vet ./bundle.cue

# Strict validation
opm bun vet ./bundle.cue --strict --all-errors
```

#### `opm bundle apply <bundle-file> [flags]`

Alias: `opm bun apply`

Apply bundle to target platform.

**Purpose:**

Renders and applies platform-specific resources for all modules in the bundle to the target platform. This command:

- Renders resources for all modules (like `opm bundle render`) if not already rendered
- Applies resources to the target platform (e.g., kubectl apply for Kubernetes)

**Arguments:**

- `<bundle-file>` - Path to BundleDefinition or Bundle file (default: ./bundle.cue)

**Flags:**

- `--platform <name>` - Target platform (kubernetes, docker-compose) - required
- `--dry-run` - Show what would be applied without applying
- `--wait` - Wait for resources to be ready
- `--timeout <duration>` - Timeout for wait (default: 5m)
- `--verbose`, `-v` - Verbose output

**Examples:**

```bash
# Apply to Kubernetes (renders on-the-fly)
opm bundle apply ./bundle.cue --platform kubernetes

# Dry run to see what would be applied
opm bundle apply ./bundle.cue --platform kubernetes --dry-run

# Apply and wait for resources to be ready
opm bun apply ./bundle.cue --platform kubernetes --wait --timeout 10m

# Apply from pre-built Bundle
opm bundle apply ./dist/platform.bundle.cue --platform kubernetes
```

**See also:**

- `opm bundle render` to generate resources without applying
- `opm bundle build` to pre-flatten BundleDefinition

#### `opm bundle show <bundle-file> [flags]`

Alias: `opm bun show`

Display bundle information.

**Arguments:**

- `<bundle-file>` - Path to bundle file (default: ./bundle.cue)

**Flags:**

- `--modules` - List included modules
- `--values` - Show value schema
- `--output <format>` - Output format (text|json|yaml)

**Examples:**

```bash
# Show all bundle information
opm bundle show ./bundle.cue

# Show only modules
opm bun show ./bundle.cue --modules

# Show value schema as JSON
opm bundle show ./bundle.cue --values --output json
```

#### `opm bundle tidy`

Alias: `opm bun tidy`

Tidy bundle dependencies using CUE's module management.

**Examples:**

```bash
# Tidy bundle dependencies
opm bundle tidy
```

#### `opm bundle fix`

Alias: `opm bun fix`

Fix deprecated CUE syntax in bundle definition.

**Examples:**

```bash
# Fix CUE syntax in current bundle
opm bundle fix
```

---

### 3. Registry Operations (Primary)

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

Watch module files and re-render on changes.

**Purpose:**

Watches ModuleDefinition files for changes and automatically re-renders platform resources. Useful for development workflows with live reloading.

**Arguments:**

- `<module-file>` - Path to module file to watch

**Flags:**

- `--output <dir>` - Output directory (required)
- `--platform <name>` - Target platform (kubernetes, docker-compose) - required
- `--format <yaml|json>` - Output format (default: yaml)

**Examples:**

```bash
# Watch and re-render on changes
opm dev watch ./module.cue --platform kubernetes --output ./k8s

# Watch with JSON output
opm dev watch ./module.cue --platform kubernetes --output ./manifests --format json
```

**See also:**

- `opm mod render` for one-time rendering

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
| `OPM_REGISTRY` | Default OCI registry (overrides `config.cue`) | Read from `~/.opm/config.cue` |
| `OPM_LOG_LEVEL` | Default log level | Read from `~/.opm/config.cue` |
| `NO_COLOR` | Disable colored output | - |
| `EDITOR` | Editor for `config edit` | `vim`, `nano`, or `vi` |

**Note:** OPM ignores `CUE_REGISTRY` environment variable to avoid confusion. Use `OPM_REGISTRY` instead.

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

The OPM configuration is stored as a CUE module in `~/.opm/`, automatically generated on first CLI use or via `opm config init`.

**Directory Structure:**

```text
~/.opm/
├── cue.mod/module.cue  # CUE module definition
├── config.cue          # Main configuration (all defaults written here)
└── credentials         # Sensitive credentials (optional, kubectl-style)
```

**Design Philosophy:** All configuration defaults are written to `config.cue` on initialization, making them visible and editable. No hidden or hardcoded configuration in the CLI binary.

**For complete configuration details, see [CLI Configuration Guide](cli/CLI_CONFIGURATION.md).**

---

## Common Workflows

This specification focuses on command syntax and options. For complete workflow examples and usage patterns, see **[CLI Workflows Guide](cli/CLI_WORKFLOWS.md)**.

**Quick examples:**

```bash
# Initialize and build a module
opm mod init my-app --template standard
opm mod build ./module.cue --output ./dist/my-app.module.cue

# Work with registry definitions
opm blueprint list
opm registry describe opm.dev/blueprints@v1#StatelessWorkload --examples

# Develop with local registry
export OPM_REGISTRY=localhost:5000
opm registry push ./my-module oci://localhost:5000/opm/my-module --version v0.1.0
```

For comprehensive workflows including CI/CD integration, multi-environment deployment, and debugging, see the [CLI Workflows Guide](cli/CLI_WORKFLOWS.md).

---

## Directory Structure & Templates

**For complete information on directory structures, templates, and file organization, see [Module Structure Guide](cli/MODULE_STRUCTURE_GUIDE.md).**

### Architecture Overview

OPM uses a **three-layer architecture**:

1. **Authoring Layer** - Flexible structure (ModuleDefinition/BundleDefinition in `module.cue`/`bundle.cue`)
2. **Compiled Layer** - Single optimized file (Module/Bundle, CLI-generated `.module.cue`/`.bundle.cue`)
3. **Deployment Layer** - Single deployment file (ModuleRelease/BundleRelease with concrete values)

### Available Templates

- **Simple** - Everything in one `module.cue` file (beginners, quick starts)
- **Standard** - Separate `module.cue`, `components.cue`, and `values.cue` (most applications)
- **Advanced** - Multi-file organization with external template imports (complex applications)
- **Platform Bundle** - Bundle with multiple modules (platform teams)
- **Custom OCI Templates** - From OCI registry (e.g., `oci://registry.opm.dev/templates/webapp`)

**Example initialization:**

```bash
# Simple template
opm mod init my-app --template simple

# Standard template (recommended)
opm mod init my-app --template standard

# Advanced template
opm mod init my-app --template advanced

# From OCI registry
opm mod init my-app --template oci://registry.opm.dev/templates/webapp
```

### File Discovery

```bash
# Explicit file path
opm mod build ./path/to/module.cue

# Auto-detect in current directory
opm mod build .  # Searches for ./module.cue

# Auto-detect in subdirectory
opm mod build ./my-app  # Searches for ./my-app/module.cue
```

CUE automatically unifies all `.cue` files in the same package—no imports needed between files in the same directory.

---

## Technical Implementation & Design

**For implementation details, design decisions, and research notes, see [CLI Implementation Guide](cli/CLI_IMPLEMENTATION.md).**

### Quick Summary

- **CLI Framework**: Cobra (kubectl-like patterns)
- **Configuration**: CUE-based config in `~/.opm/config.cue` with explicit defaults
- **OCI Registry**: CUE's built-in registry support
- **Design Principles**: Consistent command structure, sensible defaults, progressive disclosure, machine-readable output

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
