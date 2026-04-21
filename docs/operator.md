# The OPM Operator

> **Experimental — not production-ready.** The operator is under active development. Prefer the [CLI](cli.md) for day-to-day work today; read this page to understand where the project is heading.

The OPM operator is a Kubernetes controller that runs inside your cluster and continuously reconciles `ModuleRelease` custom resources. Where the CLI is a push model, the operator is pull: you commit a ModuleRelease to Git and the operator brings the cluster to match it and keeps it that way.

## What it actually does

1. Watches `ModuleRelease` (and `BundleRelease`) custom resources.
2. Fetches the referenced Module as an OCI artifact (via the Flux source controller).
3. Evaluates the CUE in-cluster, using the values from the ModuleRelease.
4. Renders Kubernetes manifests.
5. Applies them with server-side apply, using a tenant `ServiceAccount` for impersonation.
6. Detects drift between the desired state and the cluster, and corrects it on the next reconcile.
7. Reports health and conditions back on the ModuleRelease `status`.

The rendering logic is the same one the CLI uses. The difference is **who runs it and how often**.

## CLI vs. operator

| | CLI | Operator |
|---|---|---|
| Who triggers a deploy | a person or CI job | a controller, continuously |
| Delivery model | push | pull / GitOps |
| Drift correction | no — only on next `apply` | yes — every reconcile |
| Multi-tenancy | per-user `kubeconfig` | per-namespace `ServiceAccount` + impersonation |
| Needs in-cluster components | no | yes (operator + Flux source controller) |
| Good for | dev loops, CI, one-shots, demos | long-lived platforms, GitOps, many tenants |

If you are new to OPM, start with the CLI. If you are building a platform for multiple teams and want ModuleReleases to self-heal, the operator is the path.

## Custom resources

- **`ModuleRelease`** — the primary reconciliation unit. References one Module, supplies values, targets a namespace, declares a `ServiceAccount` for impersonation.
- **`BundleRelease`** — orchestrates several ModuleReleases together. Used when an application spans multiple Modules (for example, an app + its database + its cache).

## Multi-tenant model

Each tenant namespace names a `ServiceAccount`. The operator impersonates that `ServiceAccount` when it applies manifests, so the cluster's existing RBAC decides what the tenant is allowed to create. The operator's own privileges never leak into tenant workloads.

See [`TENANCY.md`](https://github.com/open-platform-model/opm-operator/blob/main/docs/TENANCY.md) for the worked example.

## Status today

- Both controllers (`ModuleRelease`, `BundleRelease`) exist and are tested.
- Installation uses the Kubebuilder manifests or the bundled Helm chart.
- There are 15 ADRs capturing the design decisions and several open enhancement proposals.
- Not used in production anywhere yet. The API may still change.

## Going deeper

- **Install and try it**: [`opm-operator/README.md`](https://github.com/open-platform-model/opm-operator/blob/main/README.md).
- **Design docs** (controller architecture, reconciliation loop, SSA ownership, CUE-OCI transport, naming taxonomy): [`opm-operator/docs/design/`](https://github.com/open-platform-model/opm-operator/tree/main/docs/design).
- **Tenancy and RBAC**: [`opm-operator/docs/TENANCY.md`](https://github.com/open-platform-model/opm-operator/blob/main/docs/TENANCY.md).
- **Where ModuleRelease fits in the model**: [Module and ModuleRelease](concepts/module-and-release.md).
