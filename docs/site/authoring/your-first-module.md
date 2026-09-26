---
title: "Your first module"
description: "Write a small module from an empty file and render it."
type: tutorial
sidebar:
  order: 10
---

<!-- Open with the end result, in the "we" voice: we build a module called `hello` with one component, `web`, that runs nginx as a stateless workload behind a Service, and we render it on the laptop into a Deployment and a Service written to `./manifests`, ready to apply. No cluster is involved at any point. Never "you will learn".
Settle one tension before writing: the description promises "from an empty file", but the verified path lets `opm mod init` create `cue.mod/module.cue` (dependency pins) and `identity/identity.cue`, and only `module.cue` is written from empty (step 3). Either say that in one line here or reword the description.
Run every command from the directory that holds `hello/`, passing `./hello`, so the values file in step 6 stays outside the module package. Do not copy cli/QUICKSTART.md's build section: it scaffolds `my_app` and then runs `cd my-app`, and its instance examples name files that no longer exist.
Check against: cli/internal/cmd/module/init.go, cli/templates/minimal/, cli/QUICKSTART.md -->

## Before you begin

<!-- Tools and exact versions only, nothing explained.
- The `opm` CLI at v1.0.0-alpha.21, the latest entry in cli/CHANGELOG.md when this was outlined. Verify: how a reader installs it. cli/.goreleaser.yml suggests release binaries; cli/QUICKSTART.md builds from source with `task build && task install`, which also needs Go 1.25+ and Task.
- Network access to ghcr.io. The registry mapping `opm config init` writes routes `opmodel.dev` to `ghcr.io/open-platform-model`, which serves core, the catalogs and the `minimal` template.
- No Kubernetes cluster and no CUE toolchain. Verify by walking the tutorial: none of these commands shells out to `cue`.
Check against: cli/CHANGELOG.md, cli/.goreleaser.yml, cli/internal/config/templates.go (DefaultRegistry) -->

## 1. Create the local OPM configuration

<!-- Command: `opm config init`.
Output to show: `Configuration initialized at <home>/.opm`, then "Created files:" listing `config.cue`, `platform/cue.mod/module.cue` and `platform/platform.cue` under `~/.opm`, then `Validate with: opm config vet`.
One line on why: rendering needs a platform, and this writes the local default platform (subscribed to opmodel.dev/catalogs/opm@v4 and opmodel.dev/catalogs/k8s@v1) that `opm module build` uses when there is no `--platform` flag. It also writes the registry mapping step 2 needs. Link the concept page "Platforms and catalogs".
If `~/.opm/config.cue` already exists the command refuses with "configuration already exists" and a hint to use `--force`. Tell the reader to skip the step in that case rather than overwrite.
Check against: cli/internal/cmd/config/init.go, cli/internal/config/templates.go, cli/internal/platform/resolve.go -->

## 2. Scaffold the module

<!-- Command: `opm mod init example.com/modules/hello@v0 minimal` (`mod` is an alias of `module`).
Output to show: `Scaffolded example.com/modules/hello@v0 from opmodel.dev/templates/minimal@v1 <version>`, then the file tree: `hello/`, `cue.mod/module.cue`, `identity/identity.cue`, `module.cue`, then `Validate it:  opm module vet hello`. Verify: the template version the registry serves today (the source in cli/templates/minimal/identity/identity.cue says 1.0.2).
Say that the path's last segment, `hello`, becomes the package name and the module name, so it must be snake_case, and that `identity/identity.cue` now holds `ModulePath: "example.com/modules/hello@v0"` and `Version: "0.1.0"`.
One line on why: the identity package is the single place the module's path and version are written. Link the concept page "Identity and names".
Check against: cli/internal/cmd/module/init.go, cli/internal/scaffold/scaffold.go (ValidateNewModulePath, InitialVersion, Reidentify), cli/internal/scaffold/ref.go (Official, DefaultTemplate) -->

## 3. Write the metadata and configuration

<!-- File edit: empty `hello/module.cue` and write it from the top:
- `package hello`
- imports: `m "opmodel.dev/core@v2"`, `res "opmodel.dev/catalogs/opm/resources/v1beta1"`, `id "example.com/modules/hello/identity"`
- `m.#Module`
- `metadata: {name: "hello", modulePath: id.ModulePath, version: id.Version, description: "..."}`
- `#config` with `image: res.#Image & {repository: string | *"nginx", tag: string | *"1.29", digest: string | *""}`, `replicas: int & >=1 | *1` and `port: int & >0 & <=65535 | *80`
- `debugValues` giving each of those fields a concrete value.
`res.#Image` requires `digest` even when it is empty, so the snippet must keep `digest: ""`.
Command after the edit: `opm module vet ./hello`.
Output to show: five check lines, "Identity conforms to #IdentityPackage" (identity/identity.cue), "Coordinates agree" (example.com/modules/hello@v0), "Version matches path major" (0.1.0), "Values satisfy #config" (debugValues) and "Module config valid".
One line on why: `#config` is the contract every instance's values are checked against. Link the concept page "Modules and instances".
Check against: core/src/module.cue (#Module), cli/templates/minimal/module.cue, modules/web_app/module.cue (literal name), catalog_opm/opm/resources/v1beta1/container.cue (#Image), cli/internal/cmd/module/vet.go -->

## 4. Add a web component

<!-- File edit: add the import `bp "opmodel.dev/catalogs/opm/blueprints/v1beta1"` and a `#components` block holding one component, `web`, that embeds `bp.#StatelessWorkload` and sets `spec: statelessWorkload: {container: {name: "web", image: #config.image, ports: http: {name: "http", targetPort: #config.port}}, scaling: count: #config.replicas}`.
Command: `opm module build ./hello`.
Output to show: the log lines `Building synthetic instance "hello-debug" for module "hello"`, `platform: <home>/.opm/platform (local default)`, `▸ web ← opmodel.dev/catalogs/opm/transformers/deployment-transformer@<catalog version>` and a second match line for `hpa-transformer`, which pairs with every stateless component (the blueprint always carries the Scaling trait) and renders nothing unless `scaling.auto` is set; say so in half a line, since the reader will see it. Then YAML for one Deployment named `hello-debug-web` in namespace `default` with `replicas: 1` and image `nginx:1.29`. The name is the synthetic instance name plus the component name.
One line on why: the blueprint stamps the workload-type label that selects the Deployment transformer. Link the concept page "Components and blueprints".
Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue, catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/hpa_transformer.cue, library/opm/kernel/parity_harness_test.go (shippedCases), cli/internal/workflow/render/module.go (syntheticIdentity), core/src/component.cue (resourceName default), cli/internal/workflow/render/log_output.go -->

## 5. Expose the component as a Service

<!-- File edit: add the import `tr "opmodel.dev/catalogs/opm/traits/v1beta1"`, embed `tr.#Expose` in `web`, and add `spec: expose: {ports: http: statelessWorkload.container.ports.http & {exposedPort: #config.port}, type: "ClusterIP"}`.
Command: `opm module build ./hello`.
Output to show: a further match line naming `service-transformer`, and YAML that now holds the Deployment and a Service, both named `hello-debug-web`. The `#Expose` wrapper names the Service after the component's short DNS name.
One line on why: a trait adds behaviour to a component without changing its blueprint. Link the concept page "Resources and traits".
Check against: catalog_opm/opm/traits/v1beta1/expose.cue (#Expose, #ExposeSchema), catalog_opm/opm/transformers/service_transformer.cue, cli/templates/standard/components.cue -->

## 6. Render with your own values

<!-- File edit: create `values.cue` beside `hello/`, not inside it, holding `values: replicas: 3`. The top-level `values:` wrapper is optional and unwrapped on load. Verify: a `.cue` file inside the module directory joins the module's package, which is why the file stays outside.
Command: `opm module build ./hello -f values.cue`.
Output to show: the Deployment with `replicas: 3` and everything else unchanged. Say that `-f` files replace `debugValues` rather than layering on them, and fields the file leaves out take their `#config` defaults (Verify that last point by running it).
One line on why: an instance supplies values, the module keeps its defaults. Link the concept page "Modules and instances".
Check against: cli/internal/workflow/render/values.go (ResolveModuleValues), library/opm/kernel/source_loader.go (LoadSourceFromFile), cli/internal/workflow/render/module.go -->

## 7. Write the manifests to files

<!-- Command: `opm module build ./hello -f values.cue --split --out-dir ./manifests` (`--out-dir` defaults to `./manifests`).
Output to show: the log line `wrote 2 resources to ./manifests`, then a listing of `manifests/deployment-hello-debug-web.yaml` and `manifests/service-hello-debug-web.yaml`. Files are named `<kind>-<name>.yaml`.
No explanation beyond one line pointing at "Deploy a module with the CLI" for putting them on a cluster.
Check against: cli/internal/cmd/module/build.go, cli/internal/cmdutil/manifest_output.go, cli/internal/output/split.go (buildFilename) -->

## What you built

<!-- Two or three sentences on the result: a module directory with an identity package, a `module.cue` holding metadata, a configuration contract with defaults, example values and one component built from the stateless blueprint with the Expose trait; rendered offline against the local default platform into a Deployment and a Service; a values file changed the replica count without editing the module. No theory.
Check against: cli/templates/minimal/, cli/templates/standard/components.cue -->

## Next steps

<!-- Three at most, by title: the concept page "Components and blueprints", the how-to guide "Attach a trait to a component" (or "Deploy a module with the CLI" if the author prefers the deploy path), and the reference entry "Catalog members".
Check against: core/docs/site/concepts/components-and-blueprints.md, catalog_opm/docs/site/authoring/attach-a-trait.md, opm/docs/site/operating/deploy-with-the-cli.md, catalog_opm/docs/site/reference/catalog-members.md -->
