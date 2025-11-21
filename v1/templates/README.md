# OPM Module Templates

Official module templates for the Open Platform Model, published as OCI artifacts.

## Available Templates

| Template | OCI Reference | Level | Use Case |
|----------|--------------|-------|----------|
| **simple** | `opm.dev/templates/simple:v1.0.0-alpha.1` | Beginner | Learning, demos, quick prototypes (1-3 components) |
| **standard** | `opm.dev/templates/standard:v1.0.0-alpha.1` | Intermediate | Production applications, team projects (3-10 components) |
| **advanced** | `opm.dev/templates/advanced:v1.0.0-alpha.1` | Advanced | Large-scale applications, platform engineering (10+ components) |

## Template Structure

Each template is a separate CUE module with the following structure:

```
{template-name}/
├── cue.mod/module.cue        # CUE module definition (uses @v1 format)
├── template/
│   └── template.cue          # Template metadata for CLI discovery
├── module_definition.cue      # ModuleDefinition or template structure
└── README.md                 # Template-specific documentation
```

### Template Metadata

Each template includes `template/template.cue` with root-level metadata:

```cue
package main

import (
    core "opm.dev/core@v1"
)

core.#TemplateDefinition

metadata: {
    apiVersion:  "templates.opm.dev/core@v1"
    name:        "Simple"
    description: "A single-file template for learning OPM..."
    level:       "beginner"
    fileCount:   1
    useCase:     "Learning, demos, quick experiments"
}
```

**Key Points:**
- The CLI extracts the root-level `metadata` field
- Does not validate against `#TemplateDefinition` (for simplicity)
- Used by `opm mod template list` and `opm mod template show`
- The `template/` directory is removed during `opm mod init`

## Reference Format

### OCI Artifacts (Publishing/Fetching)
Use **colon** (`:`) for versions:

```bash
# Correct OCI format
opm.dev/templates/simple:v1.0.0-alpha.1
opm.dev/templates/standard:v1.0.0
opm.dev/templates/advanced:latest

# Incorrect
opm.dev/templates/simple@v1.0.0-alpha.1  # ❌ Wrong separator
```

### CUE Modules (in cue.mod/module.cue)
Use **at sign** (`@`) for major versions:

```cue
// Correct CUE module format
module: "opm.dev/templates/simple@v1"

// Incorrect
module: "opm.dev/templates/simple:v1"  // ❌ Wrong separator
```

## Publishing Templates

### Prerequisites

1. Start local OCI registry:
   ```bash
   task registry:start  # From project root
   ```

2. Ensure all templates are valid:
   ```bash
   task validate:all
   ```

### Publish All Templates

```bash
task publish:all VERSION=v1.0.0-alpha.1
```

This publishes:
- `opm.dev/templates/simple:v1.0.0-alpha.1`
- `opm.dev/templates/standard:v1.0.0-alpha.1`
- `opm.dev/templates/advanced:v1.0.0-alpha.1`

### Publish Individual Templates

```bash
# Publish simple template
task publish:simple VERSION=v1.0.0-alpha.1

# Publish standard template
task publish:standard VERSION=v1.0.0-alpha.1

# Publish advanced template
task publish:advanced VERSION=v1.0.0-alpha.1
```

### Verify Publication

```bash
# Check registry
curl http://localhost:5000/v2/opm.dev/templates/simple/tags/list

# Test fetching (from project root)
cd /tmp
cue mod init test.local/test@v0
CUE_REGISTRY=localhost:5000 cue mod get opm.dev/templates/simple@v1
```

## Using Templates

### Initialize with Template

```bash
# Use simple name (resolves to official template)
opm mod init myapp --template simple

# Use full OCI reference with version
opm mod init myapp --template opm.dev/templates/standard:v1.0.0-alpha.1

# Use custom template from registry
opm mod init myapp --template oci://localhost:5000/custom-template:v2.0.0
```

### What Happens During Init

1. CLI parses template reference
2. Downloads template from OCI registry (with caching)
3. Copies template files to destination
4. **Removes `template/` directory** (metadata not needed in final module)
5. Replaces placeholders (`{{MODULE_NAME}}`, etc.)
6. Updates `cue.mod/module.cue` with user's module path

## Creating Custom Templates

### 1. Create Template Structure

```bash
mkdir -p my-template/template
cd my-template
```

### 2. Create CUE Module

```bash
# Create module definition
cat > cue.mod/module.cue <<EOF
module: "github.com/myorg/my-template@v1"

language: {
    version: "v0.15.0"
}

source: {
    kind: "self"
}

deps: {
    "opm.dev@v1": {
        v: "v1.0.2"
    }
}
EOF
```

### 3. Create Template Metadata

```bash
cat > template/template.cue <<EOF
package main

import (
    core "opm.dev/core@v1"
)

core.#TemplateDefinition

metadata: {
    apiVersion:  "templates.opm.dev/core@v1"
    name:        "MyTemplate"
    description: "Custom template for..."
    level:       "intermediate"
    fileCount:   5
    useCase:     "Specific use case..."
}
EOF
```

### 4. Create Template Files

Add your module structure files (module_definition.cue, components.cue, etc.)

### 5. Publish to OCI

```bash
# Validate
cue vet ./...

# Publish
CUE_REGISTRY=localhost:5000 cue mod publish v1.0.0
```

### 6. Use Your Template

```bash
opm mod init my-project --template oci://localhost:5000/github.com/myorg/my-template:v1.0.0
```

## Template Development Workflow

### 1. Make Changes

Edit template files in `simple/`, `standard/`, or `advanced/`

### 2. Validate

```bash
task validate:all
```

### 3. Test Locally

```bash
# Publish to local registry
task publish:all VERSION=v1.0.0-dev

# Test with CLI
opm mod init test-app --template opm.dev/templates/standard:v1.0.0-dev
```

### 4. Increment Version

Follow [Semantic Versioning](https://semver.org):

- `v1.0.0-alpha.1` → `v1.0.0-alpha.2` (alpha iterations)
- `v1.0.0-alpha.2` → `v1.0.0-beta.1` (move to beta)
- `v1.0.0-beta.1` → `v1.0.0` (stable release)
- `v1.0.0` → `v1.0.1` (patch)
- `v1.0.1` → `v1.1.0` (minor)
- `v1.1.0` → `v2.0.0` (major - breaking changes)

### 5. Publish Release

```bash
task publish:all VERSION=v1.0.0
```

## Taskfile Commands

| Command | Description |
|---------|-------------|
| `task validate:all` | Validate all templates |
| `task validate:simple` | Validate simple template |
| `task validate:standard` | Validate standard template |
| `task validate:advanced` | Validate advanced template |
| `task publish:all VERSION=x.y.z` | Publish all templates |
| `task publish:simple VERSION=x.y.z` | Publish simple template |
| `task publish:standard VERSION=x.y.z` | Publish standard template |
| `task publish:advanced VERSION=x.y.z` | Publish advanced template |
| `task info` | Show template module information |
| `task test:fetch VERSION=x.y.z` | Test fetching from registry |
| `task clean` | Clean generated files |

## Template Design Principles

### 1. Minimal Metadata

Templates should include only what's necessary:
- CUE module definition
- Template metadata (in `template/` directory)
- Module structure files
- README documentation

### 2. Root-Level Metadata

The `template/template.cue` file should have `metadata` at root level for easy CLI parsing:

```cue
// ✅ Good - metadata at root
metadata: {
    name: "MyTemplate"
    ...
}

// ❌ Bad - nested metadata
some_field: {
    metadata: {
        ...
    }
}
```

### 3. Clear Documentation

Each template should have:
- Comprehensive README explaining when to use it
- Inline comments in CUE files
- Examples of customization

### 4. Progressive Complexity

Templates should follow a clear progression:
- **Simple**: Everything in one file, minimal structure
- **Standard**: Separated files, single package
- **Advanced**: Multi-package organization, reusable templates

### 5. Real-World Examples

Templates should contain working examples, not just placeholders:
- Actual component definitions
- Realistic value schemas
- Common use cases

## Troubleshooting

### Template Not Found

```bash
Error: template not found: simple
```

**Solution:** Ensure templates are published to the registry:
```bash
task publish:all VERSION=v1.0.0-alpha.1
```

### Invalid Reference Format

```bash
Error: invalid reference format: opm.dev/templates/simple@v1.0.0
```

**Solution:** Use colon (`:`) for OCI references, not `@`:
```bash
# Correct
opm mod init app --template opm.dev/templates/simple:v1.0.0

# Incorrect
opm mod init app --template opm.dev/templates/simple@v1.0.0
```

### Template Directory Not Removed

If `template/` directory exists in generated module:

**Cause:** CLI bug or manual copying
**Solution:** Remove manually:
```bash
rm -rf template/
```

### Validation Errors

```bash
Error: found packages "main" and "module"
```

**Cause:** Package name mismatch
**Solution:** Ensure all files in same directory use same package name

## Learn More

- [Simple Template README](simple/README.md)
- [Standard Template README](standard/README.md)
- [Advanced Template README](advanced/README.md)
- [CLI Specification](../V1ALPHA1_SPECS/CLI_SPEC.md)
- [Module Structure Guide](../V1ALPHA1_SPECS/cli/MODULE_STRUCTURE_GUIDE.md)
- [OPM Documentation](../README.md)

## Contributing

To contribute a new template:

1. Create template structure following patterns above
2. Add `template/template.cue` with metadata
3. Write comprehensive README
4. Add validation tests
5. Submit pull request

Official templates are maintained by the OPM team and follow strict quality standards.
