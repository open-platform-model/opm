---
title: "What OPM does not do"
description: "The Helm and Kubernetes features OPM has no counterpart for, and what it has instead."
type: reference
weight: 41
---

This page lists the systems a Kubernetes or Helm user may expect that the Open Platform Model (OPM) does not have. Each row names the nearest Helm or Kubernetes feature and what OPM has in its place. The rows follow the order you meet them: authoring a module, deploying and deleting an instance, then the platform. Each term's definition is in the [Glossary](/docs/reference/glossary/). A row marked **Direction** has a note under [Direction](/docs/start/what-opm-does-not-do/#direction) naming an enhancement whose design covers some or all of it.

| System | Nearest Helm or Kubernetes feature | What exists today |
| --- | --- | --- |
| Lifecycle hooks ([**Direction**](/docs/start/what-opm-does-not-do/#lifecycle-hooks)) | Helm hooks, a template annotated `helm.sh/hook` such as `pre-install`, and `helm test`. | A module cannot declare anything to run before or after an install, upgrade or delete. A Job in a module is applied with the other objects, and nothing waits for it to finish. No command runs tests against a deployed instance. A container's `preStopCommand` (`lifecycle.preStop`) and the `graceful-shutdown` trait (`terminationGracePeriodSeconds`) are Kubernetes container and pod settings, not OPM hooks. |
| Workflows ([**Direction**](/docs/start/what-opm-does-not-do/#workflows)) | Ordered steps with a wait between them, such as Argo CD sync waves or Argo Workflows. | A module cannot declare steps, order them or wait between them. A render produces one set of objects. `opm instance apply` applies them in the order the render produced them. The operator applies CustomResourceDefinitions (CRDs), Namespaces and ClusterRoles first and waits for them, then the rest in a fixed kind order. |
| Installing several modules as one release | An umbrella chart: subcharts under `dependencies` in `Chart.yaml`, installed as one release and switched by a `condition` or `tags` value. | OPM has nothing that installs several modules as one unit. An instance deploys one module, and `opm instance apply` and a `ModulePackage` each render one instance. Within a module, a CUE `if` on a value switches a component on or off. `spec.dependsOn` on a `ModulePackage` waits for other packages to report `Ready`, which means applied, not healthy. |
| Signature verification of pulled modules ([**Direction**](/docs/start/what-opm-does-not-do/#signature-verification-of-pulled-modules)) | `helm install --verify` against a chart's provenance file, or `spec.verify` (cosign or Notation) on a Flux `OCIRepository`. | OPM verifies no signature on a module or catalog it pulls. When the operator, `opm instance init` or an `opm module` command given a published path fetches a module, it checks that the module's declared path and version match the ones requested. A module an instance package imports through `cue.mod` gets no check, and Flux's `spec.verify` covers only the artifact a `ModulePackage` reads, not what its instance imports. |
| Patching rendered objects | `helm install --post-renderer`, or Kustomize patches over rendered output, such as a Flux `HelmRelease`'s `postRenderers`. | Nothing edits the rendered objects between render and apply, and a `ModuleInstance` has no field for a patch. Before render, an instance package can set a component field the module's schema allows and leaves open. To change anything else, patch the output of `opm instance build` and apply it yourself. OPM records no such patch, and its next apply of that instance sets every rendered field back. |
| Waiting for workloads to become ready | `helm install --wait` and `helm upgrade --wait`, a Flux `Kustomization` with `spec.wait` or `spec.healthChecks`, and Argo CD resource health. | Nothing waits for an instance's workloads to become healthy. `opm instance apply` returns once it has applied or, for an instance the operator owns, once the operator reports `Ready` within `--timeout`, which means applied, not running. `opm instance status` exits with code 2 if an object is not ready, but counts a DaemonSet, or a custom resource with no `Ready` condition, as ready once it exists. |
| Drift correction | Flux re-applying a `Kustomization` on every `interval`, a Flux `HelmRelease` with `spec.driftDetection.mode: enabled`, and Argo CD `selfHeal`. | OPM does not undo drift on its own. A `ModuleInstance` reconcile sets `Drifted` when a live object differs from the render, but not when one was deleted, and a hand edit starts no reconcile. When nothing rendered has changed, the operator skips the apply, so the edit stays. `opm instance diff` shows drift on demand, and `opm instance apply` undoes it for an instance the CLI owns. |
| Rollback | `helm rollback` to a stored revision, and `helm upgrade --rollback-on-failure` (formerly `--atomic`). | No command or field returns an instance to an earlier version. Nothing undoes a failed apply: a failed `opm instance apply` leaves the objects it already applied. A `ModuleInstance` spec holds one module version and one set of values. The operator's `status.history` records digests, and nothing replays them. To go back, apply the earlier version and values again. |
| Moving an instance between the CLI and the operator | Putting a release installed with `helm install` under a Flux `HelmRelease`. | OPM has no command that moves an instance from one owner to the other. `spec.owner` on a `ModuleInstance` records the owner, and every instance `opm instance apply` creates gets `cli`. No command changes it in either direction, and the operator does not act on an instance the CLI owns. |
| Export to GitOps manifests ([**Direction**](/docs/start/what-opm-does-not-do/#export-to-gitops-manifests)) | `helm template --output-dir` to commit rendered manifests. | No command reads a deployed instance back out as files to commit. `opm instance build --split --out-dir <dir>` writes what an instance package renders, one file per object. That output carries no `ModuleInstance`, so OPM never prunes those objects. Files from an earlier build stay in `<dir>`. `opm platform pull` writes the cluster's platform module, not its instances. |
| Keeping an object when its instance is deleted ([**Direction**](/docs/start/what-opm-does-not-do/#keeping-an-object-when-its-instance-is-deleted)) | The `helm.sh/resource-policy: keep` annotation, often on a PersistentVolumeClaim. | No annotation or field marks one object to keep. `helm.sh/resource-policy: keep` reaches the object, and nothing reads it. `opm instance delete` on an instance the CLI owns deletes every object in its inventory: a PersistentVolumeClaim, a Namespace with everything in it, a CRD with every object of its kind. For an instance the operator owns, `spec.prune` decides, and its default, `false`, leaves every object in place. |
| Provider classes | A StorageClass or IngressClass: several implementations of one API, chosen per object, with a default. | A platform has at most one provider for each contract a catalog leaves to a provider (`fulfilment: "provider"`, such as the `backup` trait). A component cannot choose between providers. A second provider, even a second major version of one catalog, fails every render on that platform with `OverSubscribedContractsError`. `opm platform check` and the operator report the contract as over-subscribed. Kubernetes classes work as usual: a volume's `persistentClaim.storageClass` becomes the claim's `storageClassName`. |
| A model of the platform itself ([**Direction**](/docs/start/what-opm-does-not-do/#a-model-of-the-platform-itself)) | Kubernetes API discovery of a cluster's CRDs and classes, or a service catalog such as Backstage. | OPM models a platform only as far as rendering needs: the catalogs it admits, the version of each, and the contracts they define and require. `opm platform check` reports them. The `Platform` resource holds `type`, `registry` and `skewPolicy`, and nothing else about the cluster. `type` is a label that rendering does not consult. OPM does not describe a cluster's controllers, its APIs or the services it offers to teams. |

## Direction

<!-- Direction note rules (0018:D3, as amended): one note per row an enhancement's design covers, a NOTE alert titled Direction under an h3 named exactly as the row's System cell (the row links that h3's anchor), the enhancement's number and title, its status in the present tense, whether it covers the row fully or in part, no date, no promise, no decision or question numbers. A design that only touches a row gets no note: 0026 (two providers serving different catalog majors) for Provider classes, 0007 (side manifests do not patch rendered objects) for Patching, 0005 (readiness reporting, no decision) for Waiting. Links point at GitHub until the site has an Enhancements tab; then change each to /enhancements/NNNN/ in the same change that adds the tab, because the build fails on a link to a missing page. Check against: enhancements/INDEX.md, enhancements/0009/03-decisions.md, enhancements/0012/03-decisions.md, enhancements/0014/03-decisions.md, enhancements/0014/07-questions.md, enhancements/0023/03-decisions.md, enhancements/0023/07-questions.md, enhancements/0027/03-decisions.md -->

Each note names an enhancement whose design covers some or all of one row above. An enhancement is a design, not a feature: none of what these notes describe exists in OPM today.

### Lifecycle hooks

> [!NOTE]
> **Direction**
>
> Enhancement 0009, [Operational Primitives: Op, Action, Lifecycle, Workflow](https://github.com/open-platform-model/enhancements/tree/main/0009), is a draft, and none of its lifecycle design is built. It covers part of this row. Its design lets a module declare steps for nine fixed phases, from `pre-install` to `post-uninstall`, and plans each phase so that the CLI or the operator runs it one step at a time. A step that runs a command or a container and waits for it, in place of a Job nothing waits for, depends on step kinds the design lists but does not define. It adds no command that runs tests against a deployed instance.

### Workflows

> [!NOTE]
> **Direction**
>
> Enhancement 0009, [Operational Primitives: Op, Action, Lifecycle, Workflow](https://github.com/open-platform-model/enhancements/tree/main/0009), is a draft, and none of its workflow design is built. It covers part of this row. Its design lets a module declare a named workflow of ordered steps, which runs only when someone invokes it by name. It leaves the render and the apply unchanged, so the rendered objects are still applied in the order the row describes, and nothing in it orders those objects the way sync waves do.

### Signature verification of pulled modules

> [!NOTE]
> **Direction**
>
> Enhancement 0023, [Artifact Provenance, Signatures and Platform Trust Policy](https://github.com/open-platform-model/enhancements/tree/main/0023), is a draft, and most of its design is open on purpose. It covers part of this row. Its design attaches signatures and build records to every published module and catalog, and checks each one a platform fetches against that platform's trust policy before its content is used. The check applies only on a platform that declares a trust policy, and a failing artifact is refused by the operator but only reported by the CLI. Whether the check extends to an artifact's dependencies, such as the module an instance package imports through `cue.mod`, is undecided.

### Export to GitOps manifests

> [!NOTE]
> **Direction**
>
> Enhancement 0014, [Export a Deployed Instance as GitOps Manifests](https://github.com/open-platform-model/enhancements/tree/main/0014), is a draft, and no work on it has started. It covers part of this row. Its design adds a command that reads a deployed `ModuleInstance` and writes a directory to commit: the instance, its Namespace, the ServiceAccount that applies it, that account's RBAC and a `kustomization.yaml`. The command writes nothing unless the published module still renders exactly what is deployed, and it refuses an instance rendered from local files. Whether it exports an instance the CLI owns, which is every instance `opm instance apply` creates, is undecided.

### Keeping an object when its instance is deleted

> [!NOTE]
> **Direction**
>
> Enhancement 0012, [Kubernetes as a First-Class Kernel Platform](https://github.com/open-platform-model/enhancements/tree/main/0012), is a draft, and no work on it has started. It covers part of this row. Its design has neither the CLI nor the operator ever delete a Namespace or a CRD in an instance's inventory, and has both skip a live object that another owner manages. It protects those objects by kind and adds no annotation or field that keeps one chosen object, so a PersistentVolumeClaim is as deletable as it is today.

### A model of the platform itself

> [!NOTE]
> **Direction**
>
> Enhancement 0027, [Self-Service Kinds from Published Modules](https://github.com/open-platform-model/enhancements/tree/main/0027), is a draft, and no work on it has started. It covers one part of this row: the services a platform offers to teams. Its design lets a platform team bind a published module, its major version, an exact release and an update policy in one cluster-wide object, served as a Kubernetes kind that a team creates by supplying values alone. No enhancement designs a description of a cluster's controllers or APIs.

## See also

- [What OPM is](/docs/start/what-is-opm/): how the parts fit together, and why they are split the way they are.
- [OPM for Kubernetes users](/docs/start/opm-for-kubernetes-users/): each OPM term next to the closest Kubernetes or Helm idea.
- [Who owns an instance](/docs/concepts/who-owns-an-instance/): what `spec.owner` decides for an instance.
- [Operator conditions](/docs/diagnostics/operator-conditions/): what `Ready` and `Drifted` mean on an instance the operator owns.
- [Deletion and pruning](/docs/operating/deletion-and-pruning/): what deleting an instance removes and what it leaves running.
- [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/): what a platform declares, what a catalog supplies, and how a contract gets its provider.
- [The application model and the platform model](/docs/concepts/application-and-platform-models/): what OPM models about an application and about a platform.
