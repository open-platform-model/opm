---
title: "Quickstart"
description: "Create a module from a template and render it, then deploy a published module to a local kind cluster."
type: tutorial
weight: 10
---

In this quickstart, we create a module with the `opm` CLI and render it on our machine. Then we deploy a published module to a local kind cluster, change it, and remove it again. It takes about fifteen minutes.

The quickstart has three parts:

- **Set up** (step 1) configures the CLI.
- **The module** (steps 2 to 4) runs on your machine only. You can stop after step 4 if you only want to see what a module is.
- **The instance** (steps 5 to 9) deploys a published module to a cluster.

## Before you begin

- The `opm` CLI, [v1.0.0-alpha.24](https://github.com/open-platform-model/cli/releases/tag/v1.0.0-alpha.24). Download the archive for your system, `opm-<os>-<arch>.tar.gz`, and put `opm` on your `PATH`.
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

Validate with: opm config vet
```

`config.cue` tells `opm` where OPM publishes its templates, catalogs and modules. It writes no platform: each render uses the platform you pass with `--platform`, else the cluster's Platform, else one generated from the catalogs the module or instance itself pins. See [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/).

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
INFO Building synthetic instance "hello-debug" for module "hello"
INFO platform: module deps (opmodel.dev/catalogs/opm@v4 v4.4.0; generated module /home/you/.opm/cache/platforms/8936a1c7…)
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@4.4.0
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/hpa-transformer@4.4.0
INFO m:hello-debug: ▸ web ← opmodel.dev/catalogs/opm/transformers/service-transformer@4.4.0
INFO m:hello: r:Deployment/default/hello-debug-web              ✓ valid
INFO m:hello: r:Service/default/hello-debug-web                 ✓ valid
INFO m:hello: ✔ Module valid (2 resources)
```

`opm module vet` checks the module's identity and version, and that its example values fit the configuration schema. Then it renders the module against the catalogs the module itself depends on, which the `platform: module deps` line names. Three transformers matched the `web` component. See [How matching works](/docs/concepts/how-matching-works/).

## 4. Render the module

```sh
opm module build .
```

The output should look similar to this, shortened:

```text
INFO Building synthetic instance "hello-debug" for module "hello"
INFO platform: module deps (opmodel.dev/catalogs/opm@v4 v4.4.0; generated module /home/you/.opm/cache/platforms/8936a1c7…)
...
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

To render a module on its own, `opm` creates a temporary instance named `hello-debug` from the module's example values. Two of the three transformers produced a Service and a Deployment. The HPA transformer produced nothing, because the template sets a fixed replica count.

> [!TIP]
> **You can stop here**
>
> This is the end of the module part. The rest of the quickstart deploys a module to a cluster.

## 5. Create an instance

Leave the module directory, and create an instance of the published module `web_app`:

```sh
cd ..
opm instance init shop opmodel.dev/modules/web_app -n default
```

The output should look similar to this:

```text
INFO Resolved opmodel.dev/modules/web_app -> v1 1.0.4 (highest major on core v2)
Values template: debugValues (module declares no initValues; review before deploying)
Initialized instance shop/
  cue.mod/module.cue
  instance.cue
  values.cue

Validate it:  opm instance vet shop/instance.cue
```

`web_app` is built the same way as `hello`: one `web` component with the same four settings. `opm instance init` fetched its newest release and wrote an instance named `shop` in the directory `shop/`. `cue.mod/module.cue` pins the module, `instance.cue` names the instance and its namespace, and `values.cue` holds the values to deploy with:

```cue
// Starting values from the module's debugValues, the author's test values.
// Review them before deploying.
package instance

values: {
	image: {
		repository: "nginx"
		tag:        "1.27"
		digest:     ""
	}
	replicas:    1
	port:        80
	serviceType: "ClusterIP"
}
```

Check the instance:

```sh
opm instance vet shop/instance.cue
```

The output should look similar to this:

```text
INFO platform: instance deps (opmodel.dev/catalogs/opm@v4 v4.1.0; generated module /home/you/.opm/cache/platforms/1bd308a6…)
INFO m:shop: ▸ web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@4.1.0
INFO m:shop: ▸ web ← opmodel.dev/catalogs/opm/transformers/hpa-transformer@4.1.0
INFO m:shop: ▸ web ← opmodel.dev/catalogs/opm/transformers/service-transformer@4.1.0
INFO m:shop: r:Deployment/default/shop-web                     ✓ valid
INFO m:shop: r:Service/default/shop-web                        ✓ valid
INFO m:shop: ✔ Instance valid (2 resources)
```

An instance renders against a platform. There is no cluster yet, and no kube context, so `opm` generated one from the catalogs `shop/cue.mod/module.cue` pins, which the `platform: instance deps` line names. With a kube context, `opm instance vet` first looks for the cluster's Platform, and falls back to these catalogs with a warning when it finds none. See [Modules and instances](/docs/concepts/modules-and-instances/).

> [!NOTE]
> **Deploying your own module**
>
> `opm instance init` works with published modules. To deploy the module from part 2 the same way, publish it first. See [Publish a module](/docs/authoring/publish-a-module/).

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
opm instance apply shop/instance.cue
```

The output should look similar to this, shortened:

```text
WARN cluster Platform not used (no Platform CR in the cluster) — rendering against the instance's own deps
INFO platform: instance deps (opmodel.dev/catalogs/opm@v4 v4.1.0; generated module /home/you/.opm/cache/platforms/1bd308a6…)
...
INFO m:shop: applying 2 resources
INFO m:shop: r:Deployment/default/shop-web                     + created
INFO m:shop: r:Service/default/shop-web                        + created
INFO m:shop: applied 2 resources successfully (2 created)
✔ Instance applied
```

Check the instance:

```sh
opm instance status shop -n default
```

The output should look similar to this:

```text
Instance:    shop
Version:    v1.0.4
Owner:      cli
Namespace:  default
Status:     Ready
Resources:  2 total (2 ready)

KIND         NAME       COMPONENT   STATUS   AGE
Deployment   shop-web   web         Ready    21s
Service      shop-web   web         Ready    21s
```

Right after the apply, the Deployment can show `NotReady` while its pods start. Run the command again after a few seconds.

The cluster has no Platform, so `opm` warned and rendered against the instance's own catalogs, as in step 5. `opm instance apply` does not create a Platform; only `opm operator install` seeds one, and not with `--crds-only` or `--skip-platform`. Until the cluster has one, every apply and diff warns the same way. See [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/).

## 8. Change the instance

First, make a mistake. In `shop/values.cue`, set `replicas: 0`, and check the instance:

```sh
opm instance vet shop/instance.cue
```

The output should look similar to this, shortened:

```text
ERRO render failed: 2 issues
...
invalid value 0 (out of bound >=1)
  values.unifiedModule.#components.web.spec.statelessWorkload.scaling.count
    > module.cue:40:18
    > values.cue:11:15
```

The module's configuration schema allows one replica or more, so `opm` refuses the value before anything reaches the cluster.

Now set `replicas: 3`, and compare the instance with what runs in the cluster:

```sh
opm instance diff shop/instance.cue
```

The output should look similar to this, shortened:

```text
1 modified

--- Deployment/shop-web (default) [modified]

spec.replicas
± value change
- 1
+ 3
```

Apply the change:

```sh
opm instance apply shop/instance.cue
```

The output should look similar to this, shortened:

```text
INFO m:shop: r:Deployment/default/shop-web                     ~ configured
INFO m:shop: r:Service/default/shop-web                        = unchanged
INFO m:shop: applied 2 resources successfully (1 configured, 1 unchanged)
✔ Instance applied
```

Only the Deployment changed, and the Service stayed as it was.

## 9. Clean up

```sh
opm instance delete shop -n default --force
kind delete cluster --name opm-quickstart
```

The output of the first command should look similar to this:

```text
INFO m:shop: deleting resources in namespace "default"
INFO m:shop: r:Deployment/default/shop-web                     - deleted
INFO m:shop: r:Service/default/shop-web                        - deleted
INFO m:shop: all resources have been deleted
✔ Instance deleted
```

`opm instance delete` removes every object the instance recorded, then the ModuleInstance resource itself. `--force` skips the confirmation prompt. See [Deletion and pruning](/docs/operating/deletion-and-pruning/).

## What you built

We created a module from the standard template, checked it and rendered it on our machine. Then we created an instance of a published module and deployed it to a kind cluster. We had a bad value refused, changed the Deployment from one replica to three, and removed everything the instance created.

## Next steps

- [What OPM is](/docs/start/what-is-opm/)
- [Your first module](/docs/authoring/your-first-module/)
- [Publish a module](/docs/authoring/publish-a-module/)

<!-- Steps 1 to 5 re-run on 2026-09-29 with opm v1.0.0-alpha.24 built from the tag, in a fresh home directory with no kubeconfig; the step 5 vet output and the step 7 WARN and platform lines follow that release (the step 7 lines from internal/platform/resolve.go, not yet re-run on kind). Tested end to end on 2026-09-29 with the released opm v1.0.0-alpha.23 (linux-amd64 archive, checksum verified), the templates at 1.0.2 and web_app 1.0.4 from GHCR, kind v0.32.0 with its default node image and kubectl v1.36.3, in a fresh home directory with an empty CUE cache and no registry overrides. Every output on this page is from that run; the generated-module hashes in steps 3, 4, 5 and 7 are shortened. web_app declares no initValues, so init prints the debugValues line in step 5; if web_app gains initValues, update that line and the values.cue listing. Re-run every step and update the outputs when the named release changes. -->
