---
title: "Quickstart"
description: "Create a module from a template, render it, and deploy an instance of it to a local kind cluster."
type: tutorial
sidebar:
  order: 10
---

In this quickstart, we create a module with the `opm` CLI and render it on our machine. Then we deploy an instance of it to a local kind cluster, change it, and remove it again. It takes about fifteen minutes.

The quickstart has three parts:

- **Set up** (step 1) configures the CLI.
- **The module** (steps 2 to 4) runs on your machine only. You can stop after step 4 if you only want to see what a module is.
- **The instance** (steps 5 to 9) deploys the module to a cluster.

## Before you begin

- The `opm` CLI, [v1.0.0-alpha.22](https://github.com/open-platform-model/cli/releases/tag/v1.0.0-alpha.22). Download the archive for your system, `opm-<os>-<arch>.tar.gz`, and put `opm` on your `PATH`.
- Network access to `ghcr.io`, where the OPM templates, catalogs and modules are published.
- For steps 6 to 9: [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) v0.32.0, [Docker](https://docs.docker.com/get-started/get-docker/) or [Podman](https://podman.io/docs/installation) to run it, and [kubectl](https://kubernetes.io/docs/tasks/tools/).

## 1. Configure OPM

```sh
opm config init
```

The output should look similar to this:

```text
✔ Configuration initialized at /home/you/.opm

Created files:
  /home/you/.opm/config.cue
  /home/you/.opm/platform/cue.mod/module.cue
  /home/you/.opm/platform/platform.cue

Validate with: opm config vet
```

`config.cue` tells `opm` where OPM publishes its templates, catalogs and modules. `platform/` is the platform `opm` renders against on your machine. See [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/).

## 2. Create a module

```sh
opm module init example.com/modules/hello@v0
cd hello
```

The output of the first command should look similar to this:

```text
Scaffolded example.com/modules/hello@v0 from opmodel.dev/templates/standard@v1 v1.0.2

hello/                        Module directory
  components.cue
  cue.mod/module.cue
  identity/identity.cue
  module.cue

Validate it:  opm module vet hello
```

The standard template holds one component, `web`: a web server with an exposed port. `module.cue` holds the configuration schema, the settings an instance can change, each with a type and a default:

```cue
#config: {
	// Container image
	image: res.#Image & {
		repository: string | *"nginx"
		tag:        string | *"1.29"
		digest:     string | *""
	}

	// Replica count
	replicas: int & >=1 | *1

	// Container/Service port
	port: int & >0 & <=65535 | *80

	// Kubernetes Service type
	serviceType: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}
```

See [Modules and instances](/docs/concepts/modules-and-instances/).

## 3. Check the module

```sh
opm module vet .
```

The output should look similar to this:

```text
INFO m:hello: ✔ Identity conforms to #IdentityPackage  identity/identity.cue
INFO m:hello: ✔ Coordinates agree                 example.com/modules/hello@v0
INFO m:hello: ✔ Version matches path major        0.1.0
INFO m:hello: ✔ Values satisfy #config            debugValues
INFO m:hello: ✔ Module config valid
```

`opm module vet` checks the module on its own: its identity, its version, and that its example values fit the configuration schema. Nothing is rendered yet.

## 4. Render the module

```sh
opm module build .
```

The output should look similar to this, shortened:

```text
INFO Building synthetic instance "hello-debug" for module "hello"
INFO platform: /home/you/.opm/platform (local default)
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@4.4.0
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/hpa-transformer@4.4.0
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/service-transformer@4.4.0
apiVersion: v1
kind: Service
metadata:
    name: hello-debug-web
    namespace: default
...
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-debug-web
    namespace: default
spec:
    replicas: 1
...
```

To render a module on its own, `opm` creates a temporary instance named `hello-debug` from the module's example values. Three transformers on the platform matched the `web` component. Two of them produced a Service and a Deployment. The HPA transformer produced nothing, because the template sets a fixed replica count. See [How matching works](/docs/concepts/how-matching-works/).

:::tip[You can stop here]
This is the end of the module part. The rest of the quickstart deploys the module to a cluster.
:::

## 5. Write an instance

Create a directory for the instance inside the module:

```sh
mkdir -p instances/dev
```

Create `instances/dev/instance.cue` with this content:

```cue
package dev

import (
	core "opmodel.dev/core@v2"
	hello "example.com/modules/hello@v0"
)

core.#ModuleInstance

metadata: {
	name:      "hello"
	namespace: "default"
}

#module: hello

values: {
	replicas: 2
}
```

Check the instance:

```sh
opm instance vet ./instances/dev/instance.cue
```

The output should look similar to this:

```text
INFO platform: /home/you/.opm/platform (local default)
INFO m:hello: ▸ web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@4.4.0
INFO m:hello: ▸ web ← opmodel.dev/catalogs/opm/transformers/hpa-transformer@4.4.0
INFO m:hello: ▸ web ← opmodel.dev/catalogs/opm/transformers/service-transformer@4.4.0
INFO m:hello: r:Deployment/default/hello-web                    ✓ valid
INFO m:hello: r:Service/default/hello-web                       ✓ valid
INFO m:hello: ✔ Instance valid (2 resources)
```

The instance deploys the module as `hello` in the `default` namespace, with two replicas. See [Modules and instances](/docs/concepts/modules-and-instances/).

:::note[An instance can live anywhere]
This instance sits inside the module's directory, so it can import `hello` before `hello` is published. That is a shortcut for trying out a module. For a published module, `opm instance init` creates a standalone instance in a directory of its own, for example:

```sh
opm instance init hello opmodel.dev/modules/web_app --namespace default
```
:::

## 6. Create a cluster

```sh
kind create cluster --name opm-quickstart
opm operator install --crds-only
```

The output of the second command should look similar to this:

```text
INFO installing opm-operator (CRDs only)
INFO r:CustomResourceDefinition/moduleinstances.opmodel.dev  + created
INFO r:CustomResourceDefinition/modulepackages.opmodel.dev  + created
INFO r:CustomResourceDefinition/platforms.opmodel.dev  + created
INFO r:CustomResourceDefinition/transformerregistrations.opmodel.dev  + created
✔ opm-operator v1.0.0-alpha.19 installed (embedded, 4 resource(s) applied)
```

`opm` records what it deploys in a ModuleInstance resource, so the cluster needs the OPM resource definitions. No operator runs. See [Who owns an instance](/docs/concepts/who-owns-an-instance/).

## 7. Deploy the instance

```sh
opm instance apply ./instances/dev/instance.cue
```

The output should look similar to this, shortened:

```text
WARN cluster Platform not used (no Platform CR in the cluster) — falling back to the local default platform
...
INFO m:hello: applying 2 resources
INFO m:hello: r:Deployment/default/hello-web                    + created
INFO m:hello: r:Service/default/hello-web                       + created
INFO m:hello: applied 2 resources successfully (2 created)
✔ Instance applied
INFO seeded cluster Platform from the local default platform (write-if-absent)
```

Check the instance:

```sh
opm instance status hello -n default
```

The output should look similar to this:

```text
Instance:    hello
Version:    v0.1.0
Owner:      cli
Namespace:  default
Status:     Ready
Resources:  2 total (2 ready)

KIND         NAME        COMPONENT   STATUS   AGE
Deployment   hello-web   web         Ready    24s
Service      hello-web   web         Ready    24s
```

The cluster had no platform, so `opm` rendered against your local one and then copied it to the cluster. From now on, `opm instance apply` and `opm instance diff` render against the cluster's platform. See [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/).

## 8. Change the instance

First, make a mistake. In `instances/dev/instance.cue`, set `replicas: 0`, and check the instance:

```sh
opm instance vet ./instances/dev/instance.cue
```

The output should look similar to this, shortened:

```text
ERRO render failed: 2 issues
...
invalid value 0 (out of bound >=1)
  values.unifiedModule.#components.web.spec.statelessWorkload.scaling.count
    > module.cue:43:18
    > instance.cue:18:12
```

The configuration schema allows one replica or more, so `opm` refuses the value before anything reaches the cluster.

Now set `replicas: 3`, and compare the instance with what runs in the cluster:

```sh
opm instance diff ./instances/dev/instance.cue
```

The output should look similar to this, shortened:

```text
1 modified

--- Deployment/hello-web (default) [modified]

spec.replicas
± value change
- 2
+ 3
```

Apply the change:

```sh
opm instance apply ./instances/dev/instance.cue
```

The output should look similar to this, shortened:

```text
INFO m:hello: r:Deployment/default/hello-web                    ~ configured
INFO m:hello: r:Service/default/hello-web                       = unchanged
INFO m:hello: applied 2 resources successfully (1 configured, 1 unchanged)
✔ Instance applied
```

Only the Deployment changed, and the Service stayed as it was.

## 9. Clean up

```sh
opm instance delete hello -n default --force
kind delete cluster --name opm-quickstart
```

The output of the first command should look similar to this:

```text
INFO m:hello: deleting resources in namespace "default"
INFO m:hello: r:Deployment/default/hello-web                    - deleted
INFO m:hello: r:Service/default/hello-web                       - deleted
INFO m:hello: all resources have been deleted
✔ Instance deleted
```

`opm instance delete` removes every object the instance recorded, then the ModuleInstance resource itself. `--force` skips the confirmation prompt. See [Deletion and pruning](/docs/operating/deletion-and-pruning/).

## What you built

We created a module from the standard template, checked it and rendered it on our machine. Then we deployed an instance of it to a kind cluster and had a bad value refused. We changed the Deployment from two replicas to three, and removed everything the instance created.

## Next steps

- [What OPM is](/docs/start/what-is-opm/)
- [Your first module](/docs/authoring/your-first-module/)
- [Deploy with the CLI](/docs/operating/deploy-with-the-cli/)

<!-- Tested end to end on 2026-09-28 with the released opm v1.0.0-alpha.22 (linux-amd64 archive, checksum verified), the templates at 1.0.2 from GHCR, kind v0.32.0 with its default node image and kubectl v1.36.3, in a fresh home directory with an empty CUE cache and no registry overrides. Every output on this page is from that run. cli#229 will change steps 3 and 4: module build and vet will render against the module's own deps instead of ~/.opm/platform. The note in step 5 describes opm instance init from the planned cli change add-instance-init, which alpha.22 does not ship; its example command is untested. Run it and correct the syntax when the command is released. Re-run every step and update the outputs when the named release changes. -->
