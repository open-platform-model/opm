---
title: "What OPM is"
description: "What OPM is, in Kubernetes terms, and the problem it solves."
type: explanation
sidebar:
  order: 30
---

Open Platform Model (OPM) is first and foremost an [application model](/docs/concepts/application-and-platform-models/). The module describes what should be deployed as components. A schema defines the settings you can change. A module is distributed as an OCI artifact.

To deploy a module, you have to create a module instance. It embeds the module and holds the values you defined. OPM then renders the instance into plain Kubernetes objects.

This page assumes you run Kubernetes and have used Helm, but have never used CUE or OPM. It covers the parts OPM is made of, how they fit together, and why they are split the way they are. To try OPM first, follow the [Quickstart](/docs/start/quickstart/). For a term-by-term comparison with Kubernetes and Helm, see [OPM for Kubernetes users](/docs/start/opm-for-kubernetes-users/).

## In Kubernetes terms

If you use Helm today, think of OPM as Helm together with a GitOps controller such as Flux. A module is the chart, and a module instance is the release: one configured copy of the module, in one namespace. `opm instance build` does what `helm template` does, and `opm instance apply` does what `helm upgrade --install` does. The OPM operator has the role Flux's helm-controller has for a HelmRelease. It watches ModuleInstance resources in the cluster, and renders and applies the ones it manages.

The comparison stops at templates. A module has no templates, and it usually names no Kubernetes kinds. Instead, each component is described with resources and traits, such as a container, a replica count or an exposed port. The transformers on the platform decide which Kubernetes objects a component becomes. This means the platform, not the module author, has the final say on what is rendered, and the same module can render differently on two platforms.

A module instance also keeps its identity when you upgrade. OPM derives it from the module's path without the major version (`opmodel.dev/modules/web_app`), the instance name and the namespace. You can upgrade the module, even to a new major version, and OPM still sees the objects as belonging to the same module instance.

## How it works

<!-- One diagram of the flow, left to right: module plus values become an instance; the instance is rendered against a platform (catalogs, transformers); the result is a set of Kubernetes objects; the CLI or the operator applies them and records an inventory. Keep each subsection to a short paragraph that names the term and points to its concept page by title. Check against: core/SPEC.md (sections 1 to 4), library/opm/kernel/doc.go -->

### A module describes the application

<!-- `#Module`: `metadata` (snake_case `name` equal to the module path's last segment, `modulePath` with its `@vN` major, `version`), `#components` (one entry per workload), `#config` (the configuration schema a deployer's values must satisfy) and `debugValues` (example values the CLI uses when it builds a module without an instance). A module ships no Kubernetes manifests. Concept page: "Modules and instances". Check against: core/src/module.cue, core/SPEC.md (section 3.2), modules/web_app/module.cue -->

### Components are built from blueprints, resources and traits

<!-- A `#Component` attaches primitives from a catalog: resources (things that must exist, such as a container or a volume), traits (behaviour added to them, such as scaling or exposure) and blueprints (ready compositions, such as `stateless-workload`). The component's `spec` is the unification of what it attaches. Use `modules/web_app/components.cue` as the illustrative snippet: one component attaching the `StatelessWorkload` blueprint and the `Expose` trait. Concept pages: "Components and blueprints", "Resources and traits". Check against: core/src/component.cue, core/src/resource.cue, core/src/trait.cue, core/src/blueprint.cue, modules/web_app/components.cue, catalog_opm/opm/blueprints/v1beta1/ -->

### Catalogs supply the vocabulary and the transformers

<!-- A `#Catalog` is a versioned CUE module that lists the resources, traits and blueprints it defines (`#resources`, `#traits`, `#blueprints`) and the transformers that turn them into Kubernetes objects (`#transformers`). Two first-party catalogs: `opmodel.dev/catalogs/opm@v4` (the abstractions) and `opmodel.dev/catalogs/k8s@v1` (raw Kubernetes kinds carried through as-is). Concept page: "Platforms and catalogs". Check against: core/src/catalog.cue, catalog_opm/opm/catalog.cue, catalog_opm/k8s/catalog.cue -->

### A platform decides which catalogs apply

<!-- A `#Platform` is a CUE module whose `#registry` imports its catalogs, one entry per catalog module path; the imported build is chosen by the platform module's own `cue.mod/module.cue` pins. Which platform the CLI uses: `opm instance build` and `opm instance vet` never read the cluster (`--platform`, else `~/.opm/platform/` written by `opm config init`); `opm instance apply` and `opm instance diff` use `--platform`, else the cluster's `Platform` resource (a cluster-scoped singleton named `cluster`), else the local default with a warning. The operator generates its platform module from the `Platform` resource. Check against: core/src/platform.cue, cli/internal/config/templates.go, cli/internal/platform/resolve.go, cli/internal/cmd/instance/build.go, cli/internal/cmd/instance/apply.go, opm-operator/api/v1alpha1/platform_types.go -->

### An instance binds a module to values and a namespace

<!-- `#ModuleInstance`: `metadata.name`, `metadata.namespace`, `#module` (the imported module), `values`. Its `metadata.uuid` is derived, and every rendered object carries it as the `module-instance.opmodel.dev/uuid` label. Rendered object names default to `<instance>-<component>`, the Helm fullname convention. Concept page: "Identity and names". Check against: core/src/module_instance.cue, core/src/component.cue, cli/examples/instances/podinfo/instance.cue -->

### Rendering matches components to transformers

<!-- The kernel renders an instance in one CUE build: each transformer's required labels, resources and traits are compared with each component, every matching transformer's `#transform` runs, and the outputs are the Kubernetes objects. A component nothing matches, or a demanded resource nothing supplies, fails the render. Concept page: "How matching works". Check against: core/src/transformer.cue, library/opm/kernel/doc.go, library/opm/errors/unmatched.go, library/opm/errors/match.go -->

### The CLI or the operator applies the result

<!-- `opm instance apply` server-side-applies the objects and records them in a `ModuleInstance` custom resource (`status.inventory`), so the CRD must be installed first (`opm operator install --crds-only`). The operator reconciles a `ModuleInstance` that names a published module by `spec.module.path` and `spec.module.version`. `spec.owner` (`cli` or `operator`) says which of the two manages an instance. Concept page: "Who owns an instance". Check against: cli/internal/cmd/instance/apply.go, cli/README.md, opm-operator/api/v1alpha1/moduleinstance_types.go, opm-operator/internal/reconcile/moduleinstance.go -->

## Why it is built this way

<!-- Rewrite from core/SPEC.md's Rationale sections in plain words, with no decision numbers. Opinion is allowed here: say which option OPM chose and why. Check against: core/SPEC.md -->

### Module authors and platform teams change different things

<!-- A platform team publishes catalogs on its own release cadence; an application team assembles modules from what the catalogs publish. Keeping rendering in transformers (adapters beside the model) means a module does not change when a platform changes how a workload becomes objects. Check against: core/SPEC.md (section 1, "Type System Overview", and section 4.1 Rationale) -->

### Configuration is a schema, not a template

<!-- `#config` is the module's public contract and must be expressible in OpenAPI v3 with no CUE comprehensions, so tools other than CUE (web forms, generated bindings) can read it. Values are unified with it rather than substituted into text. Verify: values passed with `-f` are refused with `field not allowed` for an unknown field, but in testing a misspelled field written inside the instance package (`values: {replica: 2}` in `instance.cue` or its sibling `values.cue`) was accepted silently by `opm instance build` and `opm instance vet`; do not claim every misspelling fails until this is settled. Check against: core/SPEC.md (section 3.2 Rationale), core/src/module.cue, core/src/module_instance.cue, cli/internal/cmd/instance/vet.go, library/opm/kernel/doc.go -->

### Instance identity survives upgrades

<!-- The instance UUID is computed from the module's registry path (without its major), the instance name and the namespace, never from the module's version. The owner label must not move on upgrade, because pruning compares it: an identity that moved on every release would leave objects running while reporting success. Check against: core/SPEC.md (section 3.5 Rationale), core/src/module_instance.cue -->

### The platform module is the resolution

<!-- Catalog builds are chosen by the platform module's `cue.mod/module.cue` pins, so a render is a function of committed source: publishing a newer catalog does not change an existing platform, and upgrading a catalog is a reviewed edit. `opm platform pull` writes the cluster's platform module to disk so a local build reproduces what the cluster renders. Check against: core/SPEC.md (section 3.4 Rationale), core/src/platform.cue, cli/internal/cmd/platform/pull.go -->

## Common mistakes

<!-- One subsection per misreading, each heading stating the correct reading, each body two or three sentences naming the wrong assumption and pointing to the page that covers it. Check against: the paths in each subsection -->

### OPM does not model your whole platform

The name reaches further than OPM does today. OPM models applications. It models a platform only as far as rendering needs: which catalogs the platform uses. For what each of the two models covers, and where the platform model stands, see [The application model and the platform model](/docs/concepts/application-and-platform-models/).

### A module names components, not Kubernetes objects

<!-- The wrong assumption: a module is a folder of manifests like a chart's `templates/`. Correct reading: the platform's transformers decide which objects a component becomes; to see them, run `opm instance build` or `opm module build`. Check against: core/src/component.cue, core/src/transformer.cue, cli/internal/cmd/module/build.go -->

### The same module can render differently on two platforms

<!-- The wrong assumption: a published module version fixes the output. Correct reading: output depends on the catalogs and builds the platform pins, which is why `opm platform pull` exists and why the CLI reports version skew between a module's `cue.mod` pins and the platform's. Check against: core/src/platform.cue, library/opm/errors/skew.go, cli/internal/cmd/platform/pull.go, opm-operator/api/v1alpha1/platform_types.go (`skewPolicy`) -->

### `opm module apply` is for iterating, `opm instance apply` is for deploying

<!-- The wrong assumption: applying a module directory is the deploy path. Correct reading: `opm module apply` synthesizes an instance from `debugValues` (named `<module>-debug` unless `--name` is given); a persistent deploy is an instance file applied with `opm instance apply`. Switching between the two with different names leaves the first instance's inventory behind unless it is deleted. Check against: cli/internal/cmd/module/apply.go -->

### An instance is managed by the CLI or by the operator, never both

<!-- The wrong assumption: the operator picks up what the CLI applied, or the CLI can hand an instance over. Correct reading: `spec.owner` is set when the instance is created (`cli` for everything `opm instance apply` creates); the operator only acknowledges a `cli` instance; no command moves an instance between the two. Concept page: "Who owns an instance". Check against: cli/README.md, cli/internal/inventory/ownership.go, opm-operator/api/v1alpha1/moduleinstance_types.go -->

### Deleting the ModuleInstance resource does not always delete the workloads

<!-- The wrong assumption: deleting the custom resource removes what it deployed, as `helm uninstall` does. Correct reading: for an operator-managed instance the operator removes the workloads only when `spec.prune` is `true` (no default, and the CLI never writes it); deleting a CLI-managed instance's resource with kubectl drops its inventory and leaves the objects running. Use `opm instance delete` and read "Deletion and pruning". Check against: opm-operator/internal/reconcile/moduleinstance.go, opm-operator/api/v1alpha1/moduleinstance_types.go, cli/README.md, cli/internal/cmd/instance/delete.go -->

## What enforces this

<!-- A list, one rule per item, each with its badge (cue, kernel, publish or convention) and the command where it fails. Rules to cover: values given with `-f` satisfy the module's `#config` (cue; fails at `opm module vet`, `opm instance build`; see the Verify note above); a trait attaches only to a component whose resources are in its `appliesTo` (cue); a module's `metadata.name` equals its module path's last segment (cue); a module's version major matches its path major (publish; `#IdentityPackage`, checked by `opm module vet` and `opm module publish`); every component matches at least one transformer (kernel; `UnmatchedComponentsError`); every demanded resource and every non-optional trait is served by a transformer on the platform (kernel; `UnresolvedDemandsError`); at most one provider per provider-fulfilled contract (kernel; `OverSubscribedContractsError`, also reported by `opm platform check`); an instance keeps the owner it was created with (convention: the CLI never rewrites `spec.owner`, and the CRD carries no rule that refuses a change). Concept page: "What enforces a rule". Check against: core/src/module.cue, core/src/trait.cue, core/src/identity_package.cue, library/opm/errors/unmatched.go, library/opm/errors/match.go, library/opm/errors/oversubscribed.go, cli/internal/cmd/module/vet.go, cli/internal/publish/identity.go, opm-operator/config/crd/bases/opmodel.dev_moduleinstances.yaml -->
