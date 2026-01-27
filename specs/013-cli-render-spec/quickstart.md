# Quickstart: CLI Render

New to the render system? Here's how to build your modules.

## Basic Usage

Render the module in the current directory to stdout (YAML):

```bash
opm mod build
```

Render a specific module directory:

```bash
opm mod build --dir ./catalog/core
```

## Output Formats

Render as JSON:

```bash
opm mod build -o json
```

Write to a single file:

```bash
opm mod build --output-file manifests.yaml
```

Split resources into separate files:

```bash
opm mod build --split --output-dir ./dist
```

## Debugging

See which transformers matched and why:

```bash
opm mod build --verbose
```

Inspect the raw JSON output with details:

```bash
opm mod build --verbose=json
```

## Strict Mode

Fail if any component has traits that were not handled by any transformer:

```bash
opm mod build --strict
```
