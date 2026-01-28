# Quickstart: Module Template Development

**Plan**: [plan.md](./plan.md) | **Date**: 2026-01-23

This guide helps developers implement or extend the module template system.

## Prerequisites

See [002-cli-spec/quickstart.md](../002-cli-spec/quickstart.md) for full CLI development setup.

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Go | 1.22+ | `go version` |
| CUE | 0.11.x | `cue version` |
| Task | 3.0+ | `task --version` |

## Project Structure

Templates are embedded in the CLI binary from:

```text
cli/
├── internal/
│   ├── cmd/mod/
│   │   ├── init.go           # opm mod init command
│   │   └── template.go       # opm mod template list/show
│   └── templates/
│       ├── embed.go          # go:embed directive
│       ├── registry.go       # Template registry
│       ├── renderer.go       # Template rendering logic
│       ├── simple/           # Simple template files
│       │   ├── module.cue.tmpl
│       │   ├── values.cue.tmpl
│       │   └── cue.mod/
│       │       └── module.cue.tmpl
│       ├── standard/         # Standard template files
│       │   ├── module.cue.tmpl
│       │   ├── values.cue.tmpl
│       │   ├── components.cue.tmpl
│       │   └── cue.mod/
│       │       └── module.cue.tmpl
│       └── advanced/         # Advanced template files
│           ├── module.cue.tmpl
│           ├── values.cue.tmpl
│           ├── components.cue.tmpl
│           ├── scopes.cue.tmpl
│           ├── policies.cue.tmpl
│           ├── debug_values.cue.tmpl
│           ├── cue.mod/
│           │   └── module.cue.tmpl
│           ├── components/
│           │   ├── web.cue.tmpl
│           │   ├── api.cue.tmpl
│           │   ├── worker.cue.tmpl
│           │   └── db.cue.tmpl
│           └── scopes/
│               ├── frontend.cue.tmpl
│               └── backend.cue.tmpl
```

## Adding a New Template

1. Create directory under `internal/templates/<name>/`
2. Add template files with `.tmpl` extension
3. Register in `registry.go`:

```go
var Templates = map[string]Template{
    "simple":   {Name: "simple", ...},
    "standard": {Name: "standard", Default: true, ...},
    "advanced": {Name: "advanced", ...},
    // Add new template here
}
```

1. Run `task test` to validate

## Template Placeholders

Templates use Go text/template syntax:

| Placeholder | Description |
|-------------|-------------|
| `{{.ModuleName}}` | Module name from `--name` or directory |
| `{{.ModulePath}}` | CUE module path from `--module` or derived |
| `{{.Version}}` | Hardcoded `0.1.0` |

## Testing Templates

```bash
# Run all template tests
task test:templates

# Test specific template
go test ./internal/templates -v -run TestSimple

# Validate generated output passes opm mod vet
go test ./internal/templates -v -run TestTemplateValidation
```

## Common Tasks

### Build with embedded templates

```bash
task build
# Templates are embedded at compile time
```

### Test template rendering

```bash
# Create temp module and validate
./bin/opm mod init test-app --template simple
cd test-app && ../bin/opm mod vet
```

### Verify all templates

```bash
for t in simple standard advanced; do
  ./bin/opm mod init "test-$t" --template "$t"
  (cd "test-$t" && ../bin/opm mod vet) && echo "$t: OK"
  rm -rf "test-$t"
done
```
