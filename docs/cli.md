# The OPM CLI

The `opm` CLI is the tool you use today to build, validate, and deploy OPM modules. It is the push-model counterpart to the [operator](operator.md): you run it from your laptop or CI; it evaluates CUE locally and talks to the cluster over the Kubernetes API.

## What it does under the hood

1. **Loads** a module or release file from disk (or pulls a module from an OCI registry).
2. **Evaluates** the CUE — unifying `#config` with the supplied values, running every Transformer the Provider ships.
3. **Renders** Kubernetes manifests.
4. **Applies** them with server-side apply, or diffs against live cluster state, or just prints them.

No controllers required. No in-cluster components. Just CUE in, manifests out.

## Command cheat sheet

Two aliases exist: `opm mod` for `opm module` and `opm rel` for `opm release`.

### `opm module` — work with module source

| Command | What it does |
|---|---|
| `module init` | Scaffold a new module from a template |
| `module vet` | Validate a module without rendering manifests |

### `opm release` — work with a ModuleRelease

| Command | What it does |
|---|---|
| `release vet` | Validate a release file |
| `release build` | Render a release file to Kubernetes manifests |
| `release apply` | Server-side apply a release file to a cluster |
| `release diff` | Compare a release file against live cluster state |
| `release status` | Show resource status for a deployed release |
| `release tree` | Show release resource hierarchy |
| `release delete` | Delete release resources from a cluster |
| `release list` | List deployed releases |
| `release events` | Show events for a release |

### `opm config` — CLI configuration

| Command | What it does |
|---|---|
| `config init` | Initialize an `~/.opm/` configuration |
| `config vet` | Validate configuration |

## Typical flow

```bash
opm module init ./blog                 # scaffold
opm module vet ./blog                  # check it parses
opm release vet ./blog/release.cue     # check the release is valid
opm release build ./blog/release.cue   # see the manifests
opm release apply ./blog/release.cue   # deploy
opm release status ./blog/release.cue  # watch it come up
opm release delete ./blog/release.cue  # tear it down
```

## Going deeper

- **End-to-end walkthrough** including local OCI registry, module publishing, and a kind cluster: [`cli/QUICKSTART.md`](../../cli/QUICKSTART.md).
- **CLI-specific docs**: [`cli/README.md`](../../cli/README.md) for the canonical command list and [`cli/docs/roadmap.md`](../../cli/docs/roadmap.md) for what is next.
- **Runnable examples**: [`cli/examples/`](../../cli/examples/) has nine example modules and matching release files.

## When to reach for the operator instead

The CLI is push-model: a human or CI pipeline triggers each deploy. For continuous reconciliation, drift correction, and multi-tenant GitOps setups, see the [operator](operator.md).
