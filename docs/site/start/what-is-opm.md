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

The `opm` CLI has the role Helm has, and the OPM operator has the role Flux's helm-controller has. A module is the chart. A module instance is the release (one configured copy of the module, in one namespace). `opm instance build` renders an instance without contacting the cluster, as `helm template` does. `opm instance apply` renders it and applies the result, as `helm upgrade --install` does. The operator watches ModuleInstance resources and applies the instances it manages, as helm-controller does for a HelmRelease.

The comparison stops at templates. A module has no templates. It describes its components. The platform you render against decides which Kubernetes objects each component becomes. The same module can therefore render differently on two platforms.

OPM keeps its record of an instance in the cluster, in a ModuleInstance resource. The resource lists the objects OPM applied for the instance. Helm keeps its release record in a Secret instead. The CLI writes this resource too. You have to install its CRD even if you do not run the operator. `opm operator install --crds-only` installs only the CRDs.

## How it works

OPM works in four steps. You choose or write a module. You create a module instance from it, with your values. OPM renders the instance against a platform, whose transformers turn each component into Kubernetes objects. The CLI or the operator then applies the objects and records what it applied.

```text
   module            your values
      │                   │
      └─────────┬─────────┘
                ▼
         module instance
                │  rendered against a platform:
                │  its transformers match each component
                ▼
       Kubernetes objects
                │  applied by the CLI or the operator
                ▼
  the cluster, with an inventory
  in the ModuleInstance resource
```

### A module describes the application

You write a module in CUE, a configuration language that checks data against a schema. CUE is also composable. It combines values and schemas from many files and modules into one, and it refuses the result when two of them disagree. These two properties are why OPM is built on CUE. A component combines parts from a catalog. An instance combines a module with your values. CUE checks every combination.

A module describes an application as a set of named components. A component is one deployable unit. Often it is a workload, such as a web server with its ports and its replica count. It can also be something that does not run: the application's configuration, the roles it needs, or a custom resource definition.

The module also holds a configuration schema. The schema lists the settings a deployer can change, with their types and defaults. A module can also hold example values, which the CLI uses when you build the module without an instance. A module holds no Kubernetes manifests.

Every module has a module path, such as `opmodel.dev/modules/web_app@v1`. The path ends in the major version, and the segment before it is the module's name. You publish the module to an OCI registry under that path, with a full version such as `1.2.0`. `opm module publish` refuses a version that is already in the registry.

For more, see [Modules and instances](/docs/concepts/modules-and-instances/).

### Components are built from blueprints, resources and traits

You build a component from parts that a catalog publishes. A resource is something that must exist, such as a container or a volume. A trait adds behaviour to a resource, such as scaling or an exposed port. A blueprint is a ready-made set of resources and traits, such as a stateless workload.

The component's settings are the settings of every part it attaches, combined. CUE checks that the parts agree, and a component cannot add a setting that no part defines.

This is the one component of the `web_app` example module, shortened:

```cue
#components: {
	web: {
		bp.#StatelessWorkload // blueprint: a stateless workload
		tr.#Expose            // trait: expose ports

		spec: {
			statelessWorkload: {
				container: {
					image: #config.image
					ports: http: targetPort: #config.port
				}
				scaling: count: #config.replicas
			}
			expose: type: #config.serviceType
		}
	}
}
```

The component attaches the stateless workload blueprint and the expose trait, and fills in their settings from the module's configuration. It names no Deployment and no Service. The platform decides which objects it becomes.

For more, see [Components and blueprints](/docs/concepts/components-and-blueprints/) and [Resources and traits](/docs/concepts/resources-and-traits/).

### Catalogs supply the vocabulary and the transformers

A catalog is a versioned CUE module that publishes these parts. It lists the resources, traits and blueprints it defines. It also carries transformers. A transformer turns a component into Kubernetes objects. The deployment transformer turns a stateless workload into a Deployment, and the service transformer turns an exposed port into a Service.

OPM publishes two catalogs. `opmodel.dev/catalogs/opm@v4` holds the abstractions, such as the stateless workload and the expose trait. `opmodel.dev/catalogs/k8s@v1` holds raw Kubernetes kinds, passed through as they are, for what the abstractions do not cover, yet.

For more, see [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/).

### A platform decides which catalogs apply

A platform is a CUE module that imports the catalogs it uses. Its `cue.mod/module.cue` pins one version of each catalog, the way any CUE module pins its dependencies. Those pins decide which transformers a render uses.

`opm config init` writes a default platform to `~/.opm/platform/`, with both first-party catalogs. `opm instance build` and `opm instance vet` render against it, or against the platform directory you pass with `--platform`. They never contact the cluster. `opm instance apply` and `opm instance diff` use the cluster's platform unless you pass `--platform`. If the cluster has no platform, or you cannot read it, they fall back to the local default and warn.

On a cluster, the platform is a Platform resource. It is cluster-scoped and must be named `cluster`. It lists the module path and version of each catalog. The operator generates a platform module from it, and so does the CLI when it renders against the cluster.

### An instance binds a module to values and a namespace

A module instance is a small CUE package of its own. It imports a module and gives it a name and a namespace:

```cue
package shop

import (
	core "opmodel.dev/core@v2"
	web_app "opmodel.dev/modules/web_app@v1"
)

core.#ModuleInstance

metadata: {
	name:      "shop"
	namespace: "shop"
}

#module: web_app
```

You give it values in two ways: in a `values` field in the package, or in a file you pass with `-f`. OPM unifies every value with the module's configuration schema and with the other values. A later file does not override an earlier one. Two different values for one setting are an error.

OPM computes the instance's ID from the module path without its major version, the instance name and the namespace. Every object the instance renders carries the ID in the `module-instance.opmodel.dev/uuid` label. Objects are named `<instance>-<component>` by default, the way Helm names them `<release>-<chart>`. The instance above renders objects named `shop-web`.

For more, see [Identity and names](/docs/concepts/identity-and-names/).

### Rendering matches components to transformers

OPM renders an instance in one CUE evaluation. A transformer lists what it requires: resources, traits and labels. The labels come from the parts a component attaches, such as the stateless workload blueprint. A transformer matches a component that has everything it requires. Every transformer that matches runs, so one component can become several objects. The `web` component matches the deployment transformer and the service transformer, so it renders a Deployment and a Service.

When a render cannot handle everything in an instance, it fails. It fails if a component matches no transformer. It also fails if a resource or trait in a component is handled by no transformer that matched it. A trait marked optional is the exception: if nothing handles it, the render continues with a warning.

For more, see [How matching works](/docs/concepts/how-matching-works/).

### The CLI or the operator applies the result

Rendering does not touch the cluster. The CLI or the operator applies the objects.

`opm instance apply` applies them with server-side apply. It records what it applied in the instance's ModuleInstance resource, under `status.inventory`. On the next apply, it deletes the objects the new render no longer produces. Pass `--no-prune` to keep them.

The operator reconciles ModuleInstance resources that name a published module by path and version. It fetches the module from the registry, renders it against the cluster's platform, applies the objects and records the inventory. It cannot use a module that exists only on your disk.

Each instance has one owner, recorded in `spec.owner` as `cli` or `operator`. Every instance that `opm instance apply` creates is owned by the CLI, and the operator does not apply or prune it. A ModuleInstance resource you write yourself, with no owner, belongs to the operator. If you run `opm instance apply` against an instance the operator owns, the CLI applies nothing itself. It updates the module and values in the resource, and the operator applies them.

For more, see [Who owns an instance](/docs/concepts/who-owns-an-instance/).

## Why it is built this way

### Module authors and platform teams change different things

OPM keeps rendering out of the module on purpose. A platform team and an application team change different things, on different schedules. The platform team decides which Kubernetes objects the catalog's parts become on its clusters, and it publishes that decision as transformers in a catalog. The application team describes its application with the parts the catalog defines.

When the platform team changes how a stateless workload becomes objects, it changes one transformer. No module has to change. In a Helm chart, the chart author makes both decisions.

### Configuration is a schema, not a template

A module's configuration schema is its public contract. It has to be expressible as OpenAPI v3, with no CUE loops or conditionals. That way, tools that do not run CUE can read it: a web form, a kubectl plugin, or generated code in another language.

Your values are unified with the schema, not substituted into text. Two values that disagree are an error, instead of one overriding the other. Values you pass with `-f` are checked against the schema before anything renders. A wrong type or an unknown setting stops the render instead of reaching the cluster.

### Instance identity survives upgrades

The operator uses the instance's ID to decide which objects it may delete. Before it prunes an object, it compares the object's ID label with the instance's ID. It skips an object whose label names a different ID. If the ID changed with each module version, every upgrade would leave the old objects running, and the operator would still report success.

So the ID leaves out the module's version, and its major version too. Moving an instance from `@v1` to `@v2` of a module keeps its ID. The ID does include the module path, the instance name and the namespace. Two different modules never share an ID, even when they have the same name.

### Catalog versions are pinned by the platform

A render depends only on files you can commit. The platform module's `cue.mod` pins each catalog's version, so publishing a newer catalog does not change an existing platform. Upgrading a catalog is an edit to that file, and you review it like any other change.

The same pins let you reproduce a cluster's render on your machine. `opm platform pull` writes the cluster's platform module to a directory. `opm instance build --platform <dir>` then renders the instance the way the cluster does.

## Common mistakes

### OPM does not model your whole platform

The name reaches further than OPM does today. OPM models applications. It models a platform only as far as rendering needs: which catalogs the platform uses. For what each of the two models covers, and where the platform model stands, see [The application model and the platform model](/docs/concepts/application-and-platform-models/).

### A module names components, not Kubernetes objects

A module is not a folder of manifests, like a Helm chart's `templates/` directory. It describes components, and the platform's transformers decide which objects each one becomes. To see the objects, run `opm instance build`, or `opm module build` for a module on its own.

### Only values passed with `-f` are checked for unknown settings

OPM checks a values file you pass with `-f` against the schema, and refuses a setting the schema does not have. Values written in the instance's own package, such as in a `values.cue` file, are not checked that way. A misspelled setting there is ignored without an error.

### The same module can render differently on two platforms

A published module version does not fix the output. The output also depends on the catalogs the platform uses, and on the versions it pins. If your instance asks for a newer core or catalog than the platform pins, OPM renders with the platform's version and warns. A platform set to refuse skew fails the render instead. See [Version skew](/docs/diagnostics/version-skew/).

### `opm module apply` is for iterating, `opm instance apply` is for deploying

`opm module apply` does not deploy the module as it is. It creates an instance named `<module>-debug` from the module's example values, in the `default` namespace unless you pass `--namespace`. Use it while you write a module. To deploy, write an instance and apply it with `opm instance apply`. The debug instance stays in the cluster until you delete it with `opm instance delete`.

### An instance is managed by the CLI or by the operator, never both

The operator does not take over an instance the CLI applied. It only records that the CLI manages it. OPM has no command that moves an instance from one owner to the other. See [Who owns an instance](/docs/concepts/who-owns-an-instance/).

### Deleting the ModuleInstance resource does not always delete what it deployed

Deleting a ModuleInstance resource is not `helm uninstall`. If the CLI owns the instance, `kubectl delete` removes only the resource. The objects stay in the cluster, and nothing tracks them any more. If the operator owns the instance, it deletes the objects only when `spec.prune` is `true`, and the field has no default.

Use `opm instance delete`, and read [Deletion and pruning](/docs/operating/deletion-and-pruning/) first. For an instance the CLI owns, `opm instance delete` deletes every object in the inventory, Namespaces and CRDs included.

## What enforces this

Each rule names what refuses a violation. [What enforces a rule](/docs/concepts/what-enforces-a-rule/) explains the four badges.

- `cue`: A module's name must equal the last segment of its module path. `cue vet` and every command that loads the module refuse a mismatch.
- `publish`: A module's version must have the major version its path names, such as `1.2.0` for a path ending in `@v1`. `opm module vet` and `opm module publish` refuse a mismatch.
- `publish`: A published version cannot be published again. `opm module publish` refuses it.
- `kernel`: Values passed with `-f` must fit the module's configuration schema. `opm instance vet` and `opm instance build` refuse a wrong type or an unknown setting.
- `kernel`: Every component must match at least one transformer. The render fails otherwise, in the CLI and in the operator.
- `kernel`: Every resource, and every trait that is not optional, must be handled by a transformer that matched its component. The render fails otherwise.
- `convention`: A module's configuration schema must be expressible as OpenAPI v3. Nothing checks it.
- `convention`: A trait attaches only to a component that has a resource the trait applies to. Nothing checks it: CUE accepts the trait on any component.
- `convention`: An instance keeps the owner it was created with. The CLI never changes an owner, but nothing refuses a change you make with kubectl.
