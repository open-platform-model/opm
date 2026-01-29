# Quickstart: OPM Template Distribution

**Plan**: [plan.md](./plan.md) | **Date**: 2026-01-29

This guide covers common workflows for using and creating OPM templates.

## Prerequisites

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| OPM CLI | v1.0+ | `opm version` |
| Docker/Podman | (for publishing) | `docker version` |

## Using Templates

### Initialize Module from Official Template

```bash
# List available templates
opm template list

# Output:
# NAME        VERSION  DESCRIPTION
# simple      1.0.0    Single-file module for learning and prototypes
# standard    1.0.0    Separated files for team projects
# advanced    1.0.0    Multi-package structure for complex applications

# Initialize with default template (standard)
opm mod init my-app

# Initialize with specific template
opm mod init my-app --template simple
opm mod init my-platform --template advanced

# Verify generated module
cd my-app && opm mod vet
```

### Inspect Template Before Using

```bash
# Show template details
opm template show standard

# Output:
# Name:        standard
# Version:     1.0.0
# Description: Separated files for team projects
# Reference:   registry.opmodel.dev/templates/standard:1.0.0
#
# Placeholders:
#   - ModuleName
#   - ModulePath
#   - Version
#
# Files:
#   template.cue
#   module.cue.tmpl
#   values.cue.tmpl
#   components.cue.tmpl
#   cue.mod/
#     module.cue.tmpl
```

### Use Custom Registry

```bash
# Set registry via environment
export OPM_REGISTRY=registry.mycompany.com

# Or via config file (~/.opm/config.cue)
# registry: "registry.mycompany.com"

# Templates now resolve from custom registry
opm mod init my-app --template standard
# Fetches: oci://registry.mycompany.com/templates/standard:latest
```

### Use Template from Specific Registry

```bash
# Full OCI reference
opm mod init my-app --template oci://ghcr.io/myorg/templates/web-app:v2

# Implicit OCI (scheme auto-detected)
opm mod init my-app --template ghcr.io/myorg/templates/web-app:v2
```

### Use Local Template (Development)

```bash
# Local filesystem template
opm mod init my-app --template file://./my-local-template

# Useful for testing templates before publishing
```

## Creating Templates

### Download Existing Template for Customization

```bash
# Download official template as starting point
opm template get standard --dir ./my-template

# Edit template files
cd my-template
# Modify template.cue, *.tmpl files...
```

### Template Structure

```text
my-template/
├── template.cue              # Manifest (required)
├── module.cue.tmpl           # Template files
├── values.cue.tmpl
└── cue.mod/
    └── module.cue.tmpl
```

### Template Manifest (`template.cue`)

```cue
package template

name:        "my-template"
version:     "1.0.0"
description: "My custom template for microservices"

placeholders: ["ModuleName", "ModulePath", "Version"]
```

### Template File Example (`module.cue.tmpl`)

```cue
package main

import "opmodel.dev/core@v0"

core.#Module

metadata: {
    apiVersion:  "{{.ModulePath}}@v0"
    name:        "{{.ModuleName}}"
    version:     "{{.Version}}"
    description: "Generated from my-template"
}

#spec: {
    // Your configuration schema
    replicas: int & >=1 & <=10 | *3
}
```

### Validate Template

```bash
cd my-template
opm template validate

# Output (success):
# Template is valid: my-template v1.0.0

# Output (error):
# Error: template validation failed
#   manifest: description must be at least 10 characters
# Exit code: 2
```

### Test Template Locally

```bash
# Test with file:// reference
opm mod init test-app --template file://./my-template

# Verify generated module
cd test-app && opm mod vet

# Clean up
cd .. && rm -rf test-app
```

### Publish Template

```bash
# Login to registry (uses docker credentials)
docker login ghcr.io

# Publish template
opm template publish ghcr.io/myorg/templates/my-template:v1

# Verify it's accessible
opm template show ghcr.io/myorg/templates/my-template:v1
```

### Version Updates

```bash
# Update version in template.cue
# version: "1.1.0"

# Publish new version
opm template publish ghcr.io/myorg/templates/my-template:v1.1.0

# Also update :latest tag
opm template publish ghcr.io/myorg/templates/my-template:latest
```

## Template Reference Formats

| Format | Example | Description |
|--------|---------|-------------|
| Shorthand | `standard` | Official template from default registry |
| OCI explicit | `oci://ghcr.io/org/tpl:v1` | Full OCI reference |
| OCI implicit | `ghcr.io/org/tpl:v1` | Auto-prefixed with `oci://` |
| Local | `file://./my-template` | Local filesystem path |

## Placeholder Reference

| Placeholder | Source | Default |
|-------------|--------|---------|
| `{{.ModuleName}}` | `--name` flag or directory name | Directory name |
| `{{.ModulePath}}` | `--module` flag or derived | `example.com/<dirname>` |
| `{{.Version}}` | Hardcoded | `0.1.0` |

**Note**: Directory names with hyphens are converted to underscores in `ModulePath` for CUE compatibility.

```bash
# Example derivation
opm mod init my-cool-app
# ModuleName: my-cool-app
# ModulePath: example.com/my_cool_app
```

## Troubleshooting

### Registry Connectivity

```bash
# Check registry is accessible
opm template list

# Error: cannot connect to registry
# - Verify OPM_REGISTRY or config.registry
# - Check network connectivity
# - Verify credentials in ~/.docker/config.json
```

### Template Not Found

```bash
opm mod init app --template unknown
# Error: template not found: unknown

# List available templates
opm template list
```

### Validation Errors

```bash
opm template validate
# Error: template validation failed
#   - template.cue not found
#   - At least one .tmpl file required

# Ensure template structure is correct
ls -la
# template.cue
# module.cue.tmpl
# ...
```

### Generated Module Fails Validation

```bash
opm mod init app --template my-template
cd app && opm mod vet
# Error: CUE validation failed

# Check template files for:
# - Valid CUE syntax in .tmpl files
# - Correct placeholder usage
# - Proper imports
```
