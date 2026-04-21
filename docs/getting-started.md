# Getting Started

## What you'll build

Your first OPM module: a tiny scaffold that you will inspect, validate, and (optionally) deploy to a local Kubernetes cluster. By the end you will have seen every piece of the model — [Resource](glossary.md#resource), [Trait](glossary.md#trait), [Component](glossary.md#component), [Module](glossary.md#module), [ModuleRelease](glossary.md#modulerelease) — in a concrete file you wrote.

## Prerequisites

To scaffold and validate a module:

- **Go 1.25+** — to build the CLI.
- **[Task](https://taskfile.dev)** — task runner used by the CLI repo.
- **[CUE](https://cuelang.org) v0.15+** — the language OPM is written in.

To also deploy to a cluster (optional):

- **kind** and **kubectl** — for a local Kubernetes cluster.
- **Docker** — for a local OCI registry that hosts the catalog modules.

See [`cli/README.md`](../../cli/README.md#requirements) for current version details.

## Steps

### 1. Build the CLI

```bash
git clone https://github.com/open-platform-model/cli.git
cd cli
task build && task install
```

You should now have `opm` on your PATH.

### 2. Scaffold a module

```bash
opm module init hello
cd hello
ls
```

You will see a `module.cue` and a `components.cue` (from the default `standard` template), plus a `cue.mod/` directory containing dependency info.

### 3. Peek at the files

Open `module.cue`. You will find the metadata block and a `#config` schema — this is the **value contract** for your Module. Open `components.cue`. You will find `#components` containing a single component that mixes in a [Resource](glossary.md#resource) (`#Container`) and a couple of [Traits](glossary.md#trait). That is the whole model in a dozen lines.

Try changing the default image in `module.cue` to see the schema accept it.

### 4. Validate

```bash
opm module vet .
```

This runs CUE's type-checker over your module. If the schema is wrong, you hear about it now, not in production. No cluster required for this step.

### 5. Deploy (optional)

To actually render and apply to a cluster, follow the full path in [`cli/QUICKSTART.md`](../../cli/QUICKSTART.md). It walks you through starting a local OCI registry, publishing the catalog modules, creating a kind cluster, and deploying an example release. The commands you will use:

```bash
opm release vet    ./release.cue
opm release build  ./release.cue
opm release apply  ./release.cue
opm release status <release-name> -n <namespace>
opm release delete <release-name> -n <namespace>
```

## What just happened

You scaffolded a Module. Inside, one Component composed a Resource (`#Container`) with Traits. `opm module vet` asked CUE to unify your `#config` schema with the defaults and confirm every constraint held. Had you gone on to `opm release apply`, the CLI would have loaded your Module, unified it with the values from a `release.cue`, run the Kubernetes Provider's [Transformers](glossary.md#transformer), and server-side-applied the resulting manifests. Same logic the [operator](operator.md) uses in-cluster.

## Next steps

- **Understand the model**: [Concepts Overview](concepts/overview.md)
- **See the two-layer split**: [Module and ModuleRelease](concepts/module-and-release.md)
- **Do the full end-to-end**: [`cli/QUICKSTART.md`](../../cli/QUICKSTART.md)
- **Browse real modules**: [Module Gallery](modules-gallery.md)
- **Reach for the operator**: [The OPM Operator](operator.md)
