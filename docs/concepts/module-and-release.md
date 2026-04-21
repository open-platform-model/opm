# Module and ModuleRelease

OPM splits an application into two objects. The split keeps the author's intent separate from the deployer's configuration, so each side owns what they should own and nothing else.

## The split

- A [Module](../glossary.md#module) is the **portable intent**. It declares Components, a `#config` schema listing which values are tunable, and sane defaults. Authored once, deployed many times.
- A [ModuleRelease](../glossary.md#modulerelease) is the **concrete deployment**. It references a Module, supplies final values for this environment, and targets a specific namespace.

A [Module Author](../glossary.md#module-author) writes Modules. An [End-user](../glossary.md#end-user) writes ModuleReleases.

## A worked example

A two-tier blog with a web frontend and API backend. The Module is split across three files.

**module.cue** — metadata and the config schema:

```cue
import "opmodel.dev/core@v0"

core.#Module

metadata: {
    apiVersion: "example.com/blog@v0"
    name:       "Blog"
    version:    "0.1.0"
}

#config: {
    web: {
        image:    string
        replicas: int & >=1
        port:     int & >0 & <=65535
    }
    api: {
        image:    string
        replicas: int & >=1
        port:     int & >0 & <=65535
    }
}

values: #config
```

The `#config` schema is the **value contract** — it is what the end-user sees. Type constraints (`int & >=1`, `>0 & <=65535`) reject invalid values before anything reaches the cluster.

**components.cue** — the Components, referencing `#config`:

```cue
import (
    resources_workload "opmodel.dev/resources/workload@v0"
    traits_workload    "opmodel.dev/traits/workload@v0"
    traits_network     "opmodel.dev/traits/network@v0"
)

#components: {
    web: {
        resources_workload.#Container
        traits_workload.#Replicas
        traits_network.#Expose

        spec: {
            container: {
                name:  "web"
                image: #config.web.image
                ports: http: targetPort: 80
            }
            replicas: #config.web.replicas
            expose: ports: http: exposedPort: #config.web.port
        }
    }

    api: {
        resources_workload.#Container
        traits_workload.#Replicas

        spec: {
            container: {
                name:  "api"
                image: #config.api.image
                ports: http: targetPort: #config.api.port
            }
            replicas: #config.api.replicas
        }
    }
}
```

**values.cue** — concrete defaults:

```cue
values: {
    web: {
        image:    "nginx:1.25"
        replicas: 4
        port:     8080
    }
    api: {
        image:    "node:20-alpine"
        replicas: 4
        port:     3000
    }
}
```

The defaults satisfy the schema, so the Module is deployable as-is. An end-user who does not care to override anything writes a trivial ModuleRelease.

## The ModuleRelease

```cue
core.#ModuleRelease

metadata: {
    name:      "blog-prod"
    namespace: "production"
}

module: "example.com/blog@0.1.0"

values: {
    web: {
        image:    "ghcr.io/acme/blog-web:v1.4.2"
        replicas: 10
        port:     8080
    }
    api: {
        image:    "ghcr.io/acme/blog-api:v1.4.2"
        replicas: 6
        port:     3000
    }
}
```

The end-user only thinks about values. The schema guarantees anything they put here is valid. The Module does the rest.

## Why two layers

The split makes three things cleaner than a single-file tool like Helm:

- **Ownership is explicit.** Authors own Components; consumers own values; the `#config` schema is the contract between them.
- **Validation happens before deployment.** CUE unifies the ModuleRelease values against `#config`; out-of-range values fail at build time, not in production.
- **Upgrades are sane.** Platform teams can extend a Module via CUE unification without forking — adding a trait, adding a policy, tightening a constraint — and every ModuleRelease picks up the change on its next build.

## How does it run?

Once a ModuleRelease exists, something has to render it to Kubernetes manifests and apply them. Two paths:

- **[CLI](../cli.md)** — you run `opm` locally against a release file. Push model. Good for dev loops, CI, and one-shot deployments.
- **[Operator](../operator.md)** — a controller in the cluster watches `ModuleRelease` CRDs and reconciles them continuously. Pull / GitOps model. Good for drift correction and multi-tenant platforms.

Both use the same rendering logic. The ModuleRelease object is the same either way.

See [catalog/docs/core/constructs.md](../../../catalog/docs/core/constructs.md) for the formal Module and ModuleRelease specifications and [opm-operator/docs/design/](../../../opm-operator/docs/design/) for reconciliation internals.

## Next steps

- [Resources, Traits, and Blueprints](resources-traits-blueprints.md) — the composition primitives used inside Components
- [Module Gallery](../modules-gallery.md) — real Modules
- [CLI](../cli.md) — how to build and apply a ModuleRelease locally
- [Operator](../operator.md) — how to run ModuleReleases continuously in-cluster
