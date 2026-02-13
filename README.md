# Open Platform Model (OPM)

**A cloud-native application model that lets platform teams and developers speak the same language — with type safety, portable definitions, composable building blocks, and zero vendor lock-in.**

---
> **⚠️ UNDER HEAVY DEVELOPMENT** — This project is actively being developed and APIs may change frequently.

## Vision

Open Platform Model defines a portable, composable way to describe applications and the platform capabilities they rely on. Teams build and run software across different infrastructures and providers — including future sovereign providers — without rewriting everything each time.

Instead of teaching every developer the full details of the platform, hard-coding vendor specifics into every service, or coupling application definitions to specific runtimes, OPM standardizes how applications and their behavior are described.

---

## Why OPM?

Modern platform teams face the same tension everywhere: Developers want fast delivery. Operations need safety and reliability. Leadership wants portability and control.

Today that usually means Helm charts with string templating and no built-in guardrails, raw Kubernetes YAML that leaks every internal detail, or proprietary vendor tooling that locks you in.

OPM takes a different approach:

* **Type safety by default**
  OPM is defined in [CUE](https://cuelang.org). Invalid configuration is rejected before deployment, not in production.

* **Clear separation of responsibility**
  Developers declare intent. Platform teams extend definitions. Consumers get approved releases.

* **Composability by design**
  Resources, Traits, and Blueprints are independent building blocks that compose without coupling.

* **Portability by design**
  Application definitions are runtime-agnostic. The same Module can target different providers without changes.

---

## Core Concepts

In OPM, everything is built from a small set of definition types. Each has a clear job. Together they describe what should run, how it should behave, and how it's delivered.

### Resource

A Resource describes something that physically exists at runtime. It's the fundamental building block.

Examples: `#Container` (a workload), `#Volumes` (persistent storage), `#ConfigMaps`, `#Secrets`.

### Trait

A Trait is an optional modifier that adjusts how a Component behaves. Resources are "what exists." Traits are "how it behaves."

Examples: `#Scaling` (replica count, autoscaling), `#Expose` (network access), `#HealthCheck` (probes), `#SecurityContext`.

### Blueprint

A Blueprint bundles Resources and Traits into a reusable, higher-level pattern. Most developers use Blueprints instead of wiring Resources and Traits manually.

Examples: `#StatelessWorkload`, `#StatefulWorkload`, `#DaemonWorkload`, `#TaskWorkload`, `#ScheduledTaskWorkload`.

Platform teams can publish Blueprints as "golden paths" for their organization.

### Policy

A Policy enforces governance rules on Components. Unlike Traits (which express preferences), Policies express requirements that can block, warn, or audit on violation.

Examples: `#NetworkRules` (ingress/egress constraints), `#SharedNetwork` (DNS policy).

### Component

A Component is what you actually declare inside a Module. It represents one logical part of an application.

A Component is built by composing Resources + Traits, or by using a Blueprint (which packages them for you). Labels from all attached definitions are unified automatically.

### Module

A Module is the portable application definition. It contains Components, a `#config` schema (the value contract), and `values` (sane defaults).

Developers write Modules to describe application intent. Platform teams can extend them via CUE unification without forking.

---

## Module & ModuleRelease

OPM formalizes how something goes from "what I want" to "what actually runs" in two objects:

**Module** — the portable intent. Declares components, defines which values are tunable.

**ModuleRelease** — the concrete deployment. References a Module, supplies final values, targets a specific namespace.

### Example

A two-tier blog application with a web frontend and API backend. The module is split into three files:

**module.cue** — metadata and config schema:

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

**components.cue** — component definitions referencing `#config`:

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

    metadata: labels: "core.opmodel.dev/workload-type": "stateless"

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

    metadata: labels: "core.opmodel.dev/workload-type": "stateless"

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

The `#config` schema enforces constraints (ports in range, replicas >= 1). The `values` file satisfies that schema. A ModuleRelease can override any value while the schema guarantees validity.

---

## CUE & Kubernetes

OPM is pure CUE — no YAML templating, no string interpolation.

CUE transformers convert the platform-agnostic model into Kubernetes resources at build time. A component with workload-type `stateless` produces a Deployment; `stateful` produces a StatefulSet; traits like `#Expose` produce a Service; and so on. The Kubernetes provider currently ships with transformers for Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, Services, Ingress, HPAs, PVCs, ConfigMaps, Secrets, and ServiceAccounts.

No runtime controller is required. The CLI evaluates CUE and applies the resulting manifests directly.

---

## CLI

The `opm` CLI handles the full module lifecycle:

```bash
opm mod init ./my-module       # Scaffold a new module
opm mod build ./my-module      # Render Kubernetes manifests
opm mod apply ./my-module      # Deploy to a cluster (server-side apply)
opm mod diff ./my-module       # Semantic diff vs. live cluster state
opm mod status --name my-app   # Health and readiness of deployed resources
opm mod delete --name my-app   # Remove all module resources
```

See the [Quickstart](../cli/QUICKSTART.md) for setup instructions.

---

## How OPM Compares to Helm

| Aspect                 | Helm Charts                         | OPM                                                      |
| ---------------------- | ----------------------------------- | -------------------------------------------------------- |
| Type Safety            | Mostly runtime errors               | Compile-time validation with CUE                         |
| Configuration          | String templating in YAML           | Structured definitions with constraints                  |
| Separation of Concerns | Single blob, unclear ownership      | Module (author) → ModuleRelease (consumer)               |
| Reuse                  | Subcharts, values files             | Blueprints (Resources + Traits pre-bundled)              |
| Composability          | Limited, tightly coupled            | Independent building blocks that compose without coupling |
| Portability            | Usually vendor- or cluster-specific | Same Module, different providers                         |
| Governance             | External tooling (OPA, Kyverno)     | Policy definitions built into the model                  |

---

## Roadmap

### Phase 1: Application Model & CLI (current)

Stabilize core definitions. Native validation (`opm mod vet`). Secrets and config lifecycle. OCI-based module distribution. Rendering pipeline maturity.

### Phase 2: Kubernetes Controller

In-cluster controller watching ModuleRelease CRDs. Continuous reconciliation and drift detection.

### Phase 3: Platform Model

Commodity service interfaces. Provider certification. Multi-provider rendering. Ecosystem where providers offer standardized capabilities and customers assemble portable applications.

---

## License

Open Platform Model (OPM) is licensed under Apache License 2.0. See `LICENSE`.

---

**Build sovereign, portable platforms — not just clusters.**
