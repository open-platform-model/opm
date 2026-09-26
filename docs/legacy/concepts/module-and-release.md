# Module and ModuleRelease

OPM splits an application into two objects. The split keeps the author's intent separate from the deployer's configuration, so each side owns what they should own and nothing else.

## The split

- A [Module](../glossary.md#module) is the **portable intent**. It declares Components, a `#config` schema listing which values are tunable (with defaults), and `debugValues` for local validation. Authored once, deployed many times.
- A [ModuleRelease](../glossary.md#modulerelease) is the **concrete deployment**. It imports a Module, supplies final values for this environment, and targets a specific namespace.

A [Module Author](../glossary.md#module-author) writes Modules. An [End-user](../glossary.md#end-user) writes ModuleReleases.

## A worked example

A two-tier blog with a web frontend and API backend. The Module is split across two files.

**`module.cue`** — metadata, config schema, and debug values:

```cue
package blog

import (
    m "opmodel.dev/core/v1alpha1/module@v1"
    "opmodel.dev/opm/v1alpha1/schemas@v1"
)

m.#Module

metadata: {
    modulePath:       "example.com/modules"
    name:             "blog"
    version:          "0.1.0"
    description:      "Two-tier blog: web frontend + API backend"
    defaultNamespace: "blog"
}

#config: {
    web: {
        image:   schemas.#Image & {
            repository: string | *"nginx"
            tag:        string | *"1.25"
        }
        scaling: int & >=1 | *1
        port:    int & >0 & <=65535 | *8080
    }
    api: {
        image:   schemas.#Image & {
            repository: string | *"node"
            tag:        string | *"20-alpine"
        }
        scaling: int & >=1 | *1
        port:    int & >0 & <=65535 | *3000
    }
}

// Concrete values used by `opm module vet` and local tooling.
// ModuleRelease values override these at deploy time.
debugValues: {
    web: {
        image: {repository: "nginx",        tag: "1.25"}
        scaling: 4
        port:    8080
    }
    api: {
        image: {repository: "node",         tag: "20-alpine"}
        scaling: 4
        port:    3000
    }
}
```

The `#config` schema is the **value contract** — it is what the end-user sees. Type constraints (`int & >=1`, `>0 & <=65535`) reject invalid values before anything reaches the cluster. `debugValues` supplies concrete values for local `opm module vet`; a ModuleRelease supplies the real values at deploy time.

**`components.cue`** — the Components, referencing `#config`:

```cue
package blog

import (
    resources_workload "opmodel.dev/opm/v1alpha1/resources/workload@v1"
    traits_workload    "opmodel.dev/opm/v1alpha1/traits/workload@v1"
    traits_network     "opmodel.dev/opm/v1alpha1/traits/network@v1"
)

#components: {
    web: {
        metadata: labels: "core.opmodel.dev/workload-type": "stateless"

        resources_workload.#Container
        traits_workload.#Scaling
        traits_workload.#RestartPolicy
        traits_network.#Expose

        spec: {
            container: {
                name:  "web"
                image: #config.web.image
                ports: http: targetPort: 80
            }
            scaling: count: #config.web.scaling
            restartPolicy: "Always"
            expose: ports: http: {
                targetPort:  80
                exposedPort: #config.web.port
                type:        "ClusterIP"
            }
        }
    }

    api: {
        metadata: labels: "core.opmodel.dev/workload-type": "stateless"

        resources_workload.#Container
        traits_workload.#Scaling
        traits_workload.#RestartPolicy

        spec: {
            container: {
                name:  "api"
                image: #config.api.image
                ports: http: targetPort: #config.api.port
            }
            scaling: count: #config.api.scaling
            restartPolicy: "Always"
        }
    }
}
```

That's the whole Module. There is no separate `values.cue` file — defaults live inside `#config` with the `*` syntax, and `debugValues` is there for local validation only.

## The ModuleRelease

A ModuleRelease imports the published Module and supplies concrete values for one environment.

```cue
package blog_prod

import (
    mr "opmodel.dev/core/v1alpha1/modulerelease@v1"
    blog "example.com/modules/blog@v1"
)

mr.#ModuleRelease

metadata: {
    name:      "blog-prod"
    namespace: "production"
}

#module: blog

values: {
    web: {
        image: {repository: "ghcr.io/acme/blog-web", tag: "v1.4.2"}
        scaling: 10
        port:    8080
    }
    api: {
        image: {repository: "ghcr.io/acme/blog-api", tag: "v1.4.2"}
        scaling: 6
        port:    3000
    }
}
```

Two things worth noticing:

- `#module: blog` is a **direct CUE import reference**, not a string. The Module is unified in as a value, which is why the ModuleRelease can catch schema violations at build time.
- `values` overrides the defaults from `#config`. The schema still applies, so `scaling: "a lot"` would fail here before anything reaches the cluster.

The end-user only thinks about `values`. The schema guarantees anything they put here is valid. The Module does the rest.

## Why two layers

The split makes three things cleaner than a single-file tool like Helm:

- **Ownership is explicit.** Authors own Components; consumers own values; the `#config` schema is the contract between them.
- **Validation happens before deployment.** CUE unifies the ModuleRelease values against `#config`; out-of-range values fail at build time, not in production.
- **Upgrades are sane.** Platform teams can extend a Module via CUE unification without forking — adding a trait, tightening a constraint — and every ModuleRelease picks up the change on its next build.

## How does it run?

Once a ModuleRelease exists, something has to render it to Kubernetes manifests and apply them. Two paths:

- **[CLI](../cli.md)** — you run `opm release build` and `opm release apply` locally. Push model. Good for dev loops, CI, and one-shot deployments.
- **[Operator](../operator.md)** — a controller in the cluster watches `ModuleRelease` CRDs and reconciles them continuously. Pull / GitOps model. Good for drift correction and multi-tenant platforms.

Both use the same rendering logic. The ModuleRelease object is the same either way.

See [catalog/docs/core/constructs.md](https://github.com/open-platform-model/catalog/blob/main/docs/core/constructs.md) for the formal Module and ModuleRelease specifications and [opm-operator/docs/design/](https://github.com/open-platform-model/opm-operator/tree/main/docs/design) for reconciliation internals.

## Next steps

- [Resources, Traits, and Blueprints](resources-traits-blueprints.md) — the composition primitives used inside Components
- [Module Gallery](../modules-gallery.md) — real Modules
- [CLI](../cli.md) — how to build and apply a ModuleRelease locally
- [Operator](../operator.md) — how to run ModuleReleases continuously in-cluster
