# Resources, Traits, and Blueprints

The three composition primitives in OPM: what exists, how it behaves, and what comes pre-bundled.

All of the snippets below assume these imports at the top of the file:

```cue
import (
    resources_workload  "opmodel.dev/opm/v1alpha1/resources/workload@v1"
    traits_workload     "opmodel.dev/opm/v1alpha1/traits/workload@v1"
    traits_network      "opmodel.dev/opm/v1alpha1/traits/network@v1"
    blueprints_workload "opmodel.dev/opm/v1alpha1/blueprints/workload@v1"
)
```

## Resource: what exists

A [Resource](../glossary.md#resource) is a thing that physically exists at runtime. Every Component contains at least one Resource.

```cue
web: {
    resources_workload.#Container

    spec: container: {
        name:  "web"
        image: {repository: "nginx", tag: "1.25"}
        ports: http: targetPort: 80
    }
}
```

Common Resources:

- `resources_workload.#Container` — a containerized workload
- `resources_storage.#Volumes` — persistent storage
- `resources_config.#ConfigMaps` — configuration data
- `resources_config.#Secrets` — sensitive configuration

## Trait: how it behaves

A [Trait](../glossary.md#trait) is an optional modifier. Traits tell OPM how a Component should behave once deployed — how many replicas, which ports to expose, how it restarts, how it rolls out, what init containers run first.

```cue
web: {
    resources_workload.#Container
    traits_workload.#Scaling
    traits_workload.#RestartPolicy
    traits_workload.#UpdateStrategy
    traits_network.#Expose

    spec: {
        container: {
            name:  "web"
            image: {repository: "nginx", tag: "1.25"}
            ports: http: targetPort: 80
        }
        scaling: count: 3
        restartPolicy: "Always"
        updateStrategy: type: "RollingUpdate"
        expose: ports: http: {
            targetPort:  80
            exposedPort: 8080
            type:        "ClusterIP"
        }
    }
}
```

Common Traits:

- `traits_workload.#Scaling` — replica count (`spec.scaling.count`)
- `traits_workload.#RestartPolicy` — what happens when a container fails
- `traits_workload.#UpdateStrategy` — rolling vs. recreate
- `traits_workload.#InitContainers` — one-shot containers that run first
- `traits_workload.#SidecarContainers` — helpers that run alongside the main container
- `traits_workload.#Sizing` — CPU and memory requests/limits
- `traits_network.#Expose` — network exposure (ClusterIP, LoadBalancer)
- `traits_network.#HttpRoute` — Gateway API HTTP routing
- `traits_security.#SecurityContext` — user, group, capabilities, privilege controls

You pick the Traits you need. Nothing is required beyond the Resource.

## Blueprint: a reusable pattern

A [Blueprint](../glossary.md#blueprint) is a pre-bundled combination of Resources and Traits that captures a common pattern. `#StatelessWorkload` bundles `#Container` + `#Scaling` + `#RestartPolicy` + `#UpdateStrategy` + `#SidecarContainers` + `#InitContainers` and gathers their values under one `spec.statelessWorkload` key.

The same component written two ways:

**Raw composition**

```cue
web: {
    resources_workload.#Container
    traits_workload.#Scaling
    traits_workload.#RestartPolicy
    traits_workload.#UpdateStrategy

    spec: {
        container: {
            name:  "web"
            image: {repository: "nginx", tag: "1.25"}
        }
        scaling: count:       3
        restartPolicy:        "Always"
        updateStrategy: type: "RollingUpdate"
    }
}
```

**With a Blueprint**

```cue
web: {
    blueprints_workload.#StatelessWorkload

    spec: statelessWorkload: {
        container: {
            name:  "web"
            image: {repository: "nginx", tag: "1.25"}
        }
        scaling: count:       3
        restartPolicy:        "Always"
        updateStrategy: type: "RollingUpdate"
    }
}
```

The Blueprint mixes in the same Resources and Traits under the hood, but collects their values under `spec.statelessWorkload` so a Module author only has to fill one place. Platform teams publish Blueprints so every team deploying a stateless service uses the same shape, and platform-wide updates happen in one definition.

Today most real modules in [open-platform-model/modules](https://github.com/open-platform-model/modules) and the `opm module init` template still compose raw Resources and Traits directly. Blueprints are ready in the catalog; adoption is growing.

Blueprints in `opmodel.dev/opm/v1alpha1/blueprints/workload@v1`:

- `#StatelessWorkload` — scalable apps without persistent state
- `#StatefulWorkload` — apps needing stable identity and storage
- `#DaemonWorkload` — one instance per node
- `#TaskWorkload` — run-to-completion jobs
- `#ScheduledTaskWorkload` — cron-style scheduled jobs

## Sidebar: what about Policy?

A [Policy](../glossary.md#policy) looks similar to a Trait — both attach extra behavior to a Component — but the intent is different. A Trait expresses a preference ("I want three replicas"). A Policy expresses a requirement ("must not run as root," "must encrypt at rest"). Policies can **block**, **warn**, or **audit** on violation.

Two things worth knowing today:

- **Policy is a core type** (`opmodel.dev/core/v1alpha1/policy@v1`) but **no concrete Policy definitions are shipped yet**. Modules currently enforce constraints through the `#config` schema and through traits.
- **`#SecurityContext` is a Trait, not a Policy.** It lives at `traits_security.#SecurityContext`. Docs that called it a Policy elsewhere are describing the category it belongs to conceptually, not its type in the catalog.

## Next steps

- [Module and ModuleRelease](module-and-release.md) — the two-layer split between author and consumer
- [Module Gallery](../modules-gallery.md) — real modules using these patterns
- [Catalog primitives reference](https://github.com/open-platform-model/catalog/blob/main/docs/core/primitives.md) — the formal definitions
- [Catalog constructs reference](https://github.com/open-platform-model/catalog/blob/main/docs/core/constructs.md) — the framework types
