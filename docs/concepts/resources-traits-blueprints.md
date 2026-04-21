# Resources, Traits, and Blueprints

The three composition primitives in OPM: what exists, how it behaves, and what comes pre-bundled.

## Resource: what exists

A [Resource](../glossary.md#resource) is a thing that physically exists at runtime. Every Component contains at least one Resource.

```cue
web: {
    resources_workload.#Container

    spec: container: {
        image: "nginx:1.25"
        ports: http: targetPort: 80
    }
}
```

Common Resources:

- `#Container` — a containerized workload
- `#Volume` — persistent storage
- `#ConfigMap` — configuration data
- `#Secret` — sensitive configuration

## Trait: how it behaves

A [Trait](../glossary.md#trait) is an optional modifier. Traits tell OPM how a Component should behave once deployed — how many replicas, which ports to expose, which probes to run, whether to restart on failure.

```cue
web: {
    resources_workload.#Container
    traits_workload.#Replicas
    traits_workload.#HealthCheck
    traits_network.#Expose

    spec: {
        container: image: "nginx:1.25"
        replicas: 3
        healthCheck: liveness: httpGet: {path: "/healthz", port: 80}
        expose: ports: http: exposedPort: 8080
    }
}
```

Common Traits:

- `#Replicas` — number of instances to run
- `#HealthCheck` — liveness and readiness probes
- `#Expose` — network exposure (ClusterIP, LoadBalancer)
- `#RestartPolicy` — what happens when containers fail
- `#ResourceLimit` — CPU and memory allocation

You pick the Traits you need. Nothing is required beyond the Resource.

## Blueprint: a reusable pattern

A [Blueprint](../glossary.md#blueprint) is a pre-bundled combination of Resources and Traits that captures a common pattern. Instead of mixing in five things by hand, you mix in one.

The same component written two ways:

**Raw composition**

```cue
web: {
    resources_workload.#Container
    traits_workload.#Replicas
    traits_workload.#HealthCheck
    traits_workload.#RestartPolicy
    traits_network.#Expose

    spec: {
        container: image: "nginx:1.25"
        replicas: 3
        healthCheck: liveness: httpGet: {path: "/", port: 80}
        restartPolicy: "Always"
        expose: ports: http: exposedPort: 8080
    }
}
```

**With a Blueprint**

```cue
web: {
    blueprints_workload.#StatelessWorkload

    spec: statelessWorkload: {
        container: image: "nginx:1.25"
        replicas: 3
    }
}
```

`#StatelessWorkload` bundles Container + Replicas + HealthCheck + RestartPolicy with sensible defaults. Platform teams ship Blueprints as **golden paths**: every team deploying a stateless service uses the same pattern, and platform-wide upgrades happen in one place.

Common Blueprints:

- `#StatelessWorkload` — scalable apps without persistent state
- `#StatefulWorkload` — apps needing stable identity and storage
- `#DaemonWorkload` — one instance per node
- `#TaskWorkload` — run-to-completion jobs
- `#ScheduledTaskWorkload` — cron-style scheduled jobs

Use raw composition when you need something unusual. Use Blueprints for everything else.

## Sidebar: what about Policy?

A [Policy](../glossary.md#policy) looks similar to a Trait — both attach extra behavior to a Component — but the intent is different. A Trait expresses a preference ("I want three replicas"). A Policy expresses a requirement ("must not run as root," "must encrypt at rest"). Policies can **block**, **warn**, or **audit** on violation, so governance teams use them to keep platform rules out of application code.

Policies are covered in depth in the [catalog constructs reference](../../../catalog/docs/core/constructs.md).

## Next steps

- [Module and ModuleRelease](module-and-release.md) — the two-layer split between author and consumer
- [Module Gallery](../modules-gallery.md) — real modules using these patterns
- [Catalog primitives reference](../../../catalog/docs/core/primitives.md) — the formal definitions
- [Catalog constructs reference](../../../catalog/docs/core/constructs.md) — the framework types
