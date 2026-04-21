# OPM Documentation

Open Platform Model (OPM) is a portable, composable way to describe applications and the platform capabilities they rely on. You write your application once, in CUE, as a typed [Module](glossary.md#module). You deploy it with a [ModuleRelease](glossary.md#modulerelease) that supplies environment-specific values. The CLI or the operator renders the result to Kubernetes.

## Where to go next

- **I'm curious — what is this?** → [Concepts Overview](concepts/overview.md)
- **I want to try it** → [Getting Started](getting-started.md)
- **I'm evaluating it** → [OPM vs. Helm](opm-vs-helm.md) and the [roadmap](../README.md#roadmap)
- **Show me real modules** → [Module Gallery](modules-gallery.md)

## The three pieces

OPM consists of a model, a CLI, and an operator.

- **The model** — the definitions and the composition rules. Covered in [Concepts Overview](concepts/overview.md), [Resources, Traits, and Blueprints](concepts/resources-traits-blueprints.md), and [Module and ModuleRelease](concepts/module-and-release.md). The formal schema reference lives in [open-platform-model/catalog](https://github.com/open-platform-model/catalog/tree/main/docs).
- **The [CLI](cli.md)** — the tool you use today to build, validate, and deploy Modules locally.
- **The [operator](operator.md)** — the in-cluster controller that reconciles `ModuleRelease` custom resources continuously (experimental).

## Going deeper

- [Glossary](glossary.md) — canonical definitions for every OPM term.
- [Analysis](analysis/) — older research notes (cloud-native alignment, CRD lifecycle).

## For contributors

This repo also holds internal specifications in `specs/` and architecture decision records in `adr/`. Those are contributor-facing — end-users should stay in `docs/`.

## Project status

OPM is under heavy development. APIs may change. The CLI is usable today; the [operator](operator.md) is experimental.
