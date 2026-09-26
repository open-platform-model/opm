---
title: "Deploy a module with the CLI"
description: "Install a module on a cluster with the opm command and watch it come up."
type: tutorial
sidebar:
  order: 10
---

<!-- Open with the end result: a running copy of the published module `opmodel.dev/modules/web_app@v1` (nginx behind a ClusterIP Service) on a local kind cluster, deployed as the instance `hello` in namespace `hello` with `opm instance apply`. The reader ends with a Deployment `hello-web` running two replicas, a Service `hello-web`, and a ModuleInstance `hello` that records both, with `spec.owner: cli`. No operator runs at any point. Name the result in one sentence, then start.

Source warnings for the author: `cli/QUICKSTART.md` is stale. Its examples `examples/instances/jellyfin`, `garage` and `mc_java_fleet` no longer exist, and its import `opmodel.dev/core/v1alpha1/modulerelease@v1` is the retired v1 shape. The only example left is `cli/examples/instances/podinfo`, which imports a `testing.opmodel.dev` fixture module and is not fit for public docs. `opm-kind-demo/QUICKSTART.md` pins opm-operator v1.0.0-alpha.4 and an older Platform shape (`filter.range`); use it only for the kind cluster step, never for versions. Resource names follow the core default `<instance>-<component>`, so the instance name `hello` and component `web` give `hello-web`.

Check against: modules/web_app/module.cue, modules/web_app/components.cue, modules/web_app/identity/identity.cue, core/src/component.cue, cli/examples/instances/podinfo/instance.cue -->

## Before you begin

<!-- Exact tools and versions, as links, nothing explained:
- The `opm` CLI v1.0.0-alpha.21, the release binary archive `opm-<os>-<arch>` from the open-platform-model/cli GitHub releases. Every CLI release is a GitHub prerelease, so link the tag, not a "latest" URL. Verify: the archive extension and the current release at publish time. Building from source needs Go 1.26 (go.mod says `go 1.26.0`; the QUICKSTART's "Go 1.25+" is stale).
- kind, and Docker for kind to run on.
- kubectl.
- CUE v0.17 or newer (`cue`). The CLI never runs `cue`, but the instance module's dependencies are written into `cue.mod/module.cue` by `cue mod tidy` in step 4. Verify: that no `opm` command populates an instance module's dependencies.
- Network access to ghcr.io. The modules, core and catalogs are public there, no login needed.

Check against: cli/.goreleaser.yml, cli/release-please-config.json, cli/.release-please-manifest.json, cli/go.mod, cli/QUICKSTART.md -->

## 1. Initialize the CLI configuration

<!-- Run `opm config init`. Show its output: "Configuration initialized at ~/.opm", the three created files (`~/.opm/config.cue`, `~/.opm/platform/cue.mod/module.cue`, `~/.opm/platform/platform.cue`) and the line "Validate with: opm config vet". Then run `opm config vet` and show its three check lines: "Config file found", "Config schema validation passed", "Platform module builds".

One line on why: `config.cue` maps `opmodel.dev` to `ghcr.io/open-platform-model`, so no `OPM_REGISTRY` export is needed for `opm`, and `~/.opm/platform/` is the local default platform, pinning the catalogs `opmodel.dev/catalogs/opm@v4` at v4.4.0 and `opmodel.dev/catalogs/k8s@v1` at v1.0.0-alpha.3. Link the concept page "Platforms and catalogs".

Check against: cli/internal/cmd/config/init.go, cli/internal/cmd/config/vet.go, cli/internal/config/templates.go, cli/internal/config/resolver.go -->

## 2. Create a kind cluster

<!-- Run `kind create cluster --name opm-tutorial`. Show kind's creation output ending with the hint to run `kubectl cluster-info --context kind-opm-tutorial`. The new context becomes kubectl's current context, and `opm` uses the kubeconfig's current context unless `--context` or `OPM_CONTEXT` says otherwise. Do not use `task cluster:create` from the CLI repository: it needs a checkout of that repository.

Check against: cli/internal/config/templates.go, cli/Taskfile.yml, opm-kind-demo/Taskfile.yml -->

## 3. Install the ModuleInstance CRD

<!-- Run `opm operator install --crds-only`. Show the output: "installing opm-operator (CRDs only)", one line per CRD (moduleinstances, modulepackages, platforms and transformerregistrations, all under opmodel.dev), and "opm-operator v1.0.0-alpha.19 installed (embedded, 4 resource(s) applied)". Verify: the count and the per-CRD line wording.

One line on why: `opm instance apply` records what it deployed in a ModuleInstance, so the CRD must exist first. Without it, apply stops with "ModuleInstance CRD not found — run 'opm operator install --crds-only'". This installs no controller and creates no Platform. Link the concept page "Who owns an instance".

Check against: cli/internal/cmd/operator/install.go, cli/internal/operator/manifest.go, cli/internal/operator/plan.go, cli/internal/inventory/gates.go -->

## 4. Write an instance file

<!-- Create a directory `hello`, run `cue mod init` in it, and write two files, mirroring the layout of `cli/examples/instances/podinfo`:

`instance.cue`: `package hello`, imports `core "opmodel.dev/core@v2"` and `web_app "opmodel.dev/modules/web_app@v1"`, embeds `core.#ModuleInstance`, sets `metadata: {name: "hello", namespace: "hello"}` and `#module: web_app`.

`values.cue`: `package hello` and `values: replicas: 2`. The module's `#config` also takes `image`, `port` and `serviceType`, all with defaults.

Then run `CUE_REGISTRY='opmodel.dev=ghcr.io/open-platform-model,registry.cue.works' cue mod tidy` and show the resulting `deps` block of `cue.mod/module.cue`: `opmodel.dev/modules/web_app@v1`, `opmodel.dev/core@v2` and `opmodel.dev/catalogs/opm@v4`. Verify: the module path to give `cue mod init` (for example `example.com/hello`), whether `tidy` resolves the prerelease-only `core@v2` line, and the published `web_app` version (identity says 1.0.4; an unreleased deps bump may have moved it).

One line on why: `metadata.namespace` is required, and `values` must satisfy the module's `#config`. Link the concept page "Modules and instances".

Check against: core/src/module_instance.cue, modules/web_app/module.cue, modules/web_app/cue.mod/module.cue, cli/examples/instances/podinfo/instance.cue, cli/examples/instances/podinfo/values.cue, cli/examples/cue.mod/module.cue -->

## 5. Render the instance

<!-- Run `opm instance build ./instance.cue` from the `hello` directory. `values.cue` beside it is loaded automatically. Show a trimmed YAML excerpt: the Deployment `hello-web` in namespace `hello` with `replicas: 2`, and the Service `hello-web`, each carrying the labels `module-instance.opmodel.dev/name: hello`, `module-instance.opmodel.dev/uuid` and `app.kubernetes.io/managed-by: opm-cli`. Verify: the exact label set on the rendered objects.

One line on why: build is offline. It reads no cluster and renders against the local default platform from step 1, so mistakes in values surface here, before anything reaches the cluster.

Check against: cli/internal/cmd/instance/build.go, cli/internal/workflow/render/render.go, cli/internal/cmdutil/flags.go, core/src/transformer.cue -->

## 6. Apply the instance

<!-- Run `opm instance apply ./instance.cue --create-namespace`. Show the output: the warning "cluster Platform not used (no Platform CR in the cluster) — falling back to the local default platform", the provenance line "platform: <home>/.opm/platform (local default)", `namespace "hello" created`, one line per resource (`r:Deployment/hello/hello-web` and `r:Service/hello/hello-web`, each "created"), "applied 2 resources successfully (2 created)", "Instance applied", and last "seeded cluster Platform from the local default platform (write-if-absent)". Verify: the order of these lines in a real run.

One line on why: the warning is expected, because step 3 created no Platform. Apply writes the ModuleInstance `hello` with `spec.owner: cli` and the two resources in `status.inventory`, then copies the local default platform into a Platform named `cluster`, so the next apply on this cluster reads that instead of falling back. Link the concept page "Who owns an instance".

Check against: cli/internal/cmd/instance/apply.go, cli/internal/workflow/apply/apply.go, cli/internal/workflow/render/env.go, cli/internal/platform/resolve.go, cli/internal/platform/cluster.go, cli/internal/output/styles.go -->

## 7. Check the running instance

<!-- Run `opm instance status hello -n hello`. Show the header lines `Instance: hello`, `Version:`, `Owner: cli`, `Namespace: hello`, `Status:` and `Resources: 2 total (2 ready)`, then the resource table. Follow with `kubectl get deployment,service -n hello` to show the same two objects through kubectl, and `kubectl get moduleinstance hello -n hello` to show the record. Verify: the Status value once both replicas are ready.

Check against: cli/internal/cmd/instance/status.go, cli/internal/kubernetes/status.go, cli/internal/workflow/query/status.go -->

## 8. Delete the instance

<!-- Run `opm instance delete hello -n hello --force`. Show the "deleted" line for each resource and the final "Instance deleted". The ModuleInstance goes last, after both resources. Then run `kubectl delete namespace hello`: a namespace made by `--create-namespace` is not in the inventory, so `opm instance delete` leaves it. End with `kind delete cluster --name opm-tutorial`.

One line on why: the CLI manages this instance, so the CLI deletes its resources itself. Deleting the ModuleInstance with kubectl instead would leave both resources running. Link the concept page "Deletion and pruning".

Check against: cli/internal/cmd/instance/delete.go, cli/internal/kubernetes/delete.go, cli/internal/kubernetes/client.go -->

## What you built

<!-- Two or three sentences: a published module, rendered on your machine against the local default platform and applied by the CLI, with its inventory recorded in a ModuleInstance the CLI owns. Nothing in the cluster reconciled it: it changed only when you ran `opm`, and it would stay as deployed until the next `opm instance apply`.

Check against: cli/README.md, opm-operator/internal/reconcile/moduleinstance.go -->

## Next steps

<!-- Three links at most: the concept page "Who owns an instance", the how-to guide "Install the operator", and the reference page "CLI Reference".

Check against: cli/internal/inventory/ownership.go, cli/internal/cmd/operator/install.go, cli/internal/cmd/root.go -->
