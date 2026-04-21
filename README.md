# Open Platform Model (OPM)

**A cloud-native application model that lets platform teams and developers speak the same language — with type safety, portable definitions, composable building blocks, and zero vendor lock-in.**

---

> **⚠️ UNDER HEAVY DEVELOPMENT** — This project is actively being developed and APIs may change frequently.

## Vision

Open Platform Model defines a portable, composable way to describe applications and the platform capabilities they rely on. Teams build and run software across different infrastructures and providers — including future sovereign providers — without rewriting everything each time.

Instead of teaching every developer the full details of the platform, hard-coding vendor specifics into every service, or coupling application definitions to specific runtimes, OPM standardizes how applications and their behavior are described.

## Why OPM?

Modern platform teams face the same tension everywhere: Developers want fast delivery. Operations need safety and reliability. Leadership wants portability and control.

Today that usually means Helm charts with string templating and no built-in guardrails, raw Kubernetes YAML that leaks every internal detail, or proprietary vendor tooling that locks you in.

OPM takes a different approach:

- **Type safety by default.** OPM is defined in [CUE](https://cuelang.org). Invalid configuration is rejected before deployment, not in production.
- **Clear separation of responsibility.** Developers declare intent. Platform teams extend definitions. Consumers get approved releases.
- **Composability by design.** Resources, Traits, and Blueprints are independent building blocks that compose without coupling.
- **Portability by design.** Application definitions are runtime-agnostic. The same Module can target different providers without changes.

## What OPM looks like

A Component, written in OPM, that describes a web workload:

```cue
web: {
    resources_workload.#Container
    traits_workload.#Scaling
    traits_network.#Expose

    spec: {
        container: {image: #config.web.image, ports: http: targetPort: 80}
        scaling: count: #config.web.scaling
        expose: ports: http: {targetPort: 80, exposedPort: #config.web.port}
    }
}
```

One Resource (`#Container`), two Traits (`#Scaling`, `#Expose`), one typed `#config` supplying the values. An author packages Components like this into a **Module**; a consumer deploys it with a **ModuleRelease** that supplies concrete values. CUE transformers convert the result to Kubernetes manifests at build time — no runtime controller required.

See [Module and ModuleRelease](docs/concepts/module-and-release.md) for the full worked example, or [Concepts Overview](docs/concepts/overview.md) to walk through every building block.

## Start here

- **[Documentation index](docs/index.md)** — pick your path.
- **[Getting Started](docs/getting-started.md)** — scaffold your first module.
- **[Concepts Overview](docs/concepts/overview.md)** — the model in one page.
- **[Module Gallery](docs/modules-gallery.md)** — real modules shipping today.
- **[CLI](docs/cli.md)** / **[Operator](docs/operator.md)** — the two ways to run OPM.

## How it compares to Helm

In short: compile-time validation instead of runtime templating, explicit ownership boundaries between authors and consumers, composable Resources/Traits/Blueprints instead of monolithic charts, and built-in Policy support. See [OPM vs. Helm](docs/opm-vs-helm.md) for the full comparison.

## Roadmap

### Phase 1: Application Model & CLI (current)

Stabilize core definitions. Native validation (`opm module vet`). Secrets and config lifecycle. OCI-based module distribution. Rendering pipeline maturity.

### Phase 2: Kubernetes Controller (current)

In-cluster [operator](docs/operator.md) watching `ModuleRelease` CRDs. Continuous reconciliation and drift detection.

### Phase 3: Platform Model

Commodity service interfaces. Provider certification. Multi-provider rendering. Ecosystem where providers offer standardized capabilities and customers assemble portable applications.

## License

Open Platform Model (OPM) is licensed under Apache License 2.0. See `LICENSE`.

---

**Build sovereign, portable platforms — not just clusters.**
