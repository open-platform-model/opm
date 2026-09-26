---
title: "Quickstart"
description: "Deploy a ready-made module to a local kind cluster, from start to finish."
type: tutorial
sidebar:
  order: 10
---

<!-- Open with the end result, in one or two sentences with "we": we deploy the published module `opmodel.dev/modules/web_app@v1` (an nginx web server) to a local kind cluster with the `opm` CLI, as an instance named `hello` in the `default` namespace. At the end the reader has a Deployment and a Service, both named `hello-web`, running on the cluster, has seen the same objects rendered as YAML before applying them, and has removed them again. Never "you will learn". Check against: modules/web_app/module.cue, modules/web_app/components.cue, cli/QUICKSTART.md, cli/examples/instances/podinfo/instance.cue -->

## Before you begin

<!-- Tools with exact versions, as links, nothing explained: the `opm` CLI from the GitHub releases of open-platform-model/cli (archives named `opm-<os>-<arch>.tar.gz`; name the release this page is tested against); the CUE CLI, v0.17.1 or later in the v0.17 line (the cli's CI installs `cuelang.org/go/cmd/cue@v0.17.1`); Docker or another container runtime kind supports; kind; kubectl. The cli tests against the kind node image `kindest/node:v1.34.3`. Network access to `ghcr.io` for the public OPM registry. Verify: which CLI release to name. v1.0.0-alpha.21 seeds its local platform with core v2.0.0-alpha.9 and catalog `opmodel.dev/catalogs/opm@v4` v4.1.0, while `cue mod tidy` in step 2 pins core v2.0.0-alpha.10, so that combination may print a version skew warning; main seeds alpha.10 and v4.4.0. Check against: cli/.goreleaser.yml, cli/.github/workflows/release.yml, cli/Taskfile.yml (`K8S_NODE_IMAGE`), cli/internal/config/templates.go -->

## 1. Configure OPM

<!-- Two commands. First `export CUE_REGISTRY='opmodel.dev=ghcr.io/open-platform-model,registry.cue.works'`, so the `cue` command in step 2 resolves OPM modules from the public registry on GHCR (the `opm` command reads its own mapping from its config file, which the next command writes). Then `opm config init`, which writes `~/.opm/config.cue` (with `registry` set to the GHCR mapping) and the local default platform module `~/.opm/platform/` (`cue.mod/module.cue` pinning core and the two first-party catalogs, `platform.cue` importing them) and fetches nothing. Show its output. Optionally `opm config vet` to prove the platform module builds; it fetches the pinned catalogs on first run. One line on why: every render needs a platform, and this is the one the CLI uses on a laptop; link "Platforms and catalogs". Verify: the exact output of `opm config init` and `opm config vet` (in testing, `opm config vet --config <path>` still read `~/.opm/config.cue`). Check against: cli/internal/cmd/config/init.go, cli/internal/cmd/config/vet.go, cli/internal/config/templates.go, cli/internal/config/resolver.go -->

## 2. Write an instance file

<!-- Create a directory `hello` and run `cue mod init example.com/hello@v0` in it. Write `instance.cue` in package `hello`: import `core "opmodel.dev/core@v2"` and `web_app "opmodel.dev/modules/web_app@v1"`, embed `core.#ModuleInstance`, set `metadata: {name: "hello", namespace: "default"}`, set `#module: web_app`, and set `values: {replicas: 2}`. Then run `cue mod tidy`, and show the resulting `cue.mod/module.cue`, whose `deps` list `opmodel.dev/modules/web_app@v1` at v1.0.4, `opmodel.dev/core@v2` and `opmodel.dev/catalogs/opm@v4`. One line on why: the module is the application and the instance is one deployed copy of it with its values; link "Modules and instances". Tested 2026-09-25: this file renders with web_app v1.0.4. Do not claim that a misspelled key under `values` fails here: in testing, `values: {replica: 2}` in the instance package rendered silently with the module default of one replica. Check against: core/src/module_instance.cue, cli/examples/instances/podinfo/instance.cue, cli/examples/cue.mod/module.cue, modules/web_app/module.cue -->

## 3. Render the instance

<!-- Run `opm instance build ./instance.cue`. The output should look similar to: log lines naming the platform source (`~/.opm/platform`) and the matched transformers (`web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@<version>`, `hpa-transformer`, `service-transformer`), then YAML for a `Service` and a `Deployment`, both named `hello-web` in namespace `default`, the Deployment with `replicas: 2` and image `nginx:1.27`, each carrying the `module-instance.opmodel.dev/name: hello` and `module-instance.opmodel.dev/uuid` labels. Trim the YAML to the kind, name and replicas lines. One line on why: rendering is offline and needs no cluster, so the reader sees exactly what will be applied; link "How matching works". Check against: cli/internal/cmd/instance/build.go, modules/web_app/components.cue, catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/service_transformer.cue -->

## 4. Create a cluster

<!-- Two commands. `kind create cluster --name opm-quickstart`, then `opm operator install --crds-only`, which server-side-applies only the OPM CustomResourceDefinitions (ModuleInstance, ModulePackage, Platform, TransformerRegistration) and waits for them to be Established; no operator runs. Show the install output. One line on why: `opm instance apply` records what it deployed in a `ModuleInstance` resource, so the CRD must exist first; link "Who owns an instance". Verify: the exact output of `opm operator install --crds-only`. Check against: cli/internal/cmd/operator/install.go, opm-operator/config/crd/bases/ -->

## 5. Deploy the instance

<!-- Run `opm instance apply ./instance.cue`. No `--create-namespace` is needed because `default` exists. The output should look similar to: a warning that no cluster `Platform` was readable and the local default platform was used, the two objects applied, and a success line. Mention in one sentence that on this first apply the CLI also creates the cluster's `Platform` resource named `cluster` from the local platform, only if none exists. One line on why: the CLI applies with server-side apply and writes a `ModuleInstance` named `hello` with `spec.owner: cli` holding the inventory. Verify: the exact warning and success text; this step was not run against a live cluster while drafting. Check against: cli/internal/cmd/instance/apply.go, cli/internal/workflow/apply/apply.go, cli/internal/platform/cluster.go, cli/internal/inventory/cr.go -->

## 6. Check the instance

<!-- Run `opm instance status hello -n default` and show its table: the Deployment and the Service with their status. Then `kubectl get moduleinstance hello -n default` to show the record the CLI wrote. Optionally `opm instance list -n default`. Verify: the column headings of `opm instance status` and the `kubectl get moduleinstance` print columns (Ready, Module, Version). Check against: cli/internal/cmd/instance/status.go, cli/internal/cmd/instance/list.go, opm-operator/api/v1alpha1/moduleinstance_types.go -->

## 7. Remove the instance

<!-- Run `opm instance delete hello -n default --force` (`--force` skips the confirmation prompt) and show that it deletes the two objects and the `ModuleInstance` record. Then `kind delete cluster --name opm-quickstart`. One line on why: `opm instance delete` removes what the inventory lists; deleting the `ModuleInstance` with kubectl instead would leave the objects running. Link "Deletion and pruning". Verify: the exact delete output. Check against: cli/internal/cmd/instance/delete.go, cli/README.md -->

## What you built

<!-- Two or three sentences: an instance file that deploys a published module with one value changed, rendered to plain Kubernetes objects on the laptop, applied to a kind cluster by the CLI with its inventory recorded on the cluster, then removed. No theory. Check against: cli/internal/cmd/instance/apply.go, core/src/module_instance.cue -->

## Next steps

<!-- Three links at most, by title: the concept page "Modules and instances", the tutorial "Your first module" or the how-to guide "Install the operator" (pick one how-to guide), and the reference page "CLI Reference". Check against: core/docs/site/concepts/modules-and-instances.md, opm-operator/docs/site/operating/install-the-operator.md, opmodel.dev/site/content/docs/reference/cli/index.md -->
