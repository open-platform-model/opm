# OPM vs. Helm

## Executive summary

Open Platform Model (OPM) is a type-safe, constraint-based alternative to Helm for Kubernetes application packaging. Where Helm renders YAML from Go templates at install time, OPM evaluates CUE — catching schema violations at build time, keeping platform concerns separate from application concerns, and composing applications from small, reusable pieces.

OPM formalises the separation into two objects: a **Module** (the portable application definition, authored once) and a **ModuleRelease** (the concrete per-environment deployment that imports the Module and supplies values). Platform teams extend a published Module through CUE unification rather than forking it. The result is stronger guarantees, cleaner ownership, and easier evolution than Helm charts give you today.

## The ten differences that matter

### 1. Type safety and validation

**Helm:**

- Template-based with runtime evaluation.
- YAML templating errors surface only at deploy time.
- Type mismatches surface after the apply has started.
- No built-in schema validation.

**OPM:**

- CUE-based with compile-time type checking.
- Every Module ships a typed `#config` schema with constraints.
- Errors surface at `opm module vet` — before any apply.
- Strong typing prevents invalid configurations from existing.

### 2. True separation of concerns

**Helm:** a single chart mixes application logic, platform defaults, and environment overrides. Platform teams usually fork.

**OPM:** two objects, two owners.

- **Module** — authored once by a developer or platform team. Declares Components, the `#config` contract, and `debugValues` for local tests.
- **ModuleRelease** — written per deployment by the end-user. Imports the Module and supplies concrete values for one environment.

Platform teams can add traits, tighten constraints, or attach policies to a published Module through CUE unification without modifying upstream code.

### 3. Policy (in the works)

**Helm:** no native policy mechanism. You reach for OPA or Kyverno, and the policies live outside the chart.

**OPM:** Policy exists as a core type in the catalog (`opmodel.dev/core/v1alpha1/policy@v1`). No concrete Policy definitions ship today, so modules currently enforce constraints through the `#config` schema (`scaling: int & >=1`) and through traits like `traits_security.#SecurityContext`. The machinery is there for policies to travel with a Module rather than live alongside it.

### 4. Composability and reusability

**Helm:** limited to chart dependencies and subcharts. Template inheritance is fragile. Helper templates create hidden dependencies.

**OPM:** Components are built by mixing in Resources and Traits — small, independent pieces that compose without coupling. Blueprints (for example `#StatelessWorkload`) bundle a common combination so every team gets the same shape. Resources and Traits can be mixed and matched freely.

### 5. Configuration management

**Helm:** `values.yaml` can become massive. No real constraints on value shapes; override precedence is easy to get wrong.

**OPM:** `#config` is the contract. Defaults live inline with `*`, constraints live inline with `&`. The ModuleRelease `values` block overrides the defaults and is validated against the schema at build time. No mystery precedence — CUE's unification makes overrides explicit.

### 6. Developer experience

**Helm:** Go templating is verbose and error-prone. Debugging template errors is painful. Testing requires a full deploy.

**OPM:** CUE is concise, IDE-friendly, and has type checking. `opm module vet` runs without a cluster. Errors carry file and line information.

### 7. Platform integration

**Helm:** platform teams fork charts to add requirements. Upstream updates become merge conflicts.

**OPM:** platform teams extend a published Module via CUE unification. The upstream Module stays untouched; the platform's additions merge cleanly on each build.

### 8. Multi-environment support

**Helm:** multiple `values-*.yaml` files plus conditional templating. Environment drift is common.

**OPM:** one Module, one ModuleRelease per environment. The `#config` schema is the same everywhere; values differ. Dev, staging, and prod use the exact same Module with different values.

### 9. Compliance and governance

**Helm:** compliance is validated externally. No audit trail baked into the package.

**OPM:** constraints in `#config` are enforced at every build; the Module itself carries them. When Policy definitions ship in the catalog, compliance rules will travel alongside the Module the same way.

### 10. Evolution and maintenance

**Helm:** breaking changes require major version bumps. Migration paths are manual.

**OPM:** CUE unification lets Modules evolve gradually. Platform teams can tighten a constraint or add a trait without requiring upstream changes. Every ModuleRelease picks up the change on its next build.

## Real-world example

### Scenario: deploying a small web service

**With Helm:**

```yaml
# values-prod.yaml — mixes app and platform concerns
replicaCount: 3
image:
  repository: ghcr.io/acme/web
  tag: v1.4.2
platform:
  securityContext:
    runAsNonRoot: true
    allowPrivilegeEscalation: false
  # ... hundreds more lines
```

If the platform team wants to enforce the security context, they either fork the chart or maintain an umbrella chart.

**With OPM:** authored once as a Module, deployed as a ModuleRelease.

```cue
// module.cue — published by the Module Author
package web

import (
    m "opmodel.dev/core/v1alpha1/module@v1"
    "opmodel.dev/opm/v1alpha1/schemas@v1"
    resources_workload "opmodel.dev/opm/v1alpha1/resources/workload@v1"
    traits_workload    "opmodel.dev/opm/v1alpha1/traits/workload@v1"
    traits_network     "opmodel.dev/opm/v1alpha1/traits/network@v1"
    traits_security    "opmodel.dev/opm/v1alpha1/traits/security@v1"
)

m.#Module

metadata: {
    modulePath:       "acme.example.com/modules"
    name:             "web"
    version:          "1.0.0"
    description:      "Acme web frontend"
    defaultNamespace: "web"
}

#config: {
    image: schemas.#Image & {
        repository: string | *"ghcr.io/acme/web"
        tag:        string | *"latest"
    }
    scaling: int & >=1 | *1
    port:    int & >0 & <=65535 | *8080
    securityContext: {
        runAsNonRoot:             bool | *true
        allowPrivilegeEscalation: bool | *false
    }
}

#components: {
    app: {
        metadata: labels: "core.opmodel.dev/workload-type": "stateless"

        resources_workload.#Container
        traits_workload.#Scaling
        traits_workload.#RestartPolicy
        traits_network.#Expose
        traits_security.#SecurityContext

        spec: {
            container: {
                name:  "app"
                image: #config.image
                ports: http: targetPort: 80
            }
            scaling: count: #config.scaling
            restartPolicy:  "Always"
            expose: ports: http: {
                targetPort:  80
                exposedPort: #config.port
                type:        "ClusterIP"
            }
            securityContext: #config.securityContext
        }
    }
}

debugValues: {
    image:   {repository: "ghcr.io/acme/web", tag: "v1.4.2"}
    scaling: 3
    port:    8080
    securityContext: {runAsNonRoot: true, allowPrivilegeEscalation: false}
}
```

The platform team can tighten the security context on their extension without forking:

```cue
// Platform overlay — unified with the published Module.
#config: securityContext: {
    runAsNonRoot:             true  // no longer a default; required.
    allowPrivilegeEscalation: false
}
```

The end-user writes a ModuleRelease:

```cue
package web_prod

import (
    mr "opmodel.dev/core/v1alpha1/modulerelease@v1"
    web "acme.example.com/modules/web@v1"
)

mr.#ModuleRelease

metadata: {
    name:      "web-prod"
    namespace: "production"
}

#module: web

values: {
    image:   {repository: "ghcr.io/acme/web", tag: "v1.4.2"}
    scaling: 3
    port:    8080
}
```

Ten lines of deploy-time configuration. Everything else is the Module's concern. The schema rejects `scaling: 0` or a missing image before the apply starts.

## Migration path

- **Phase 1** — wrap existing Helm releases in OPM modules using `#Container` plus raw traits; keep the Helm-rendered chart as the outer source where needed.
- **Phase 2** — move platform defaults and tightening into a CUE overlay instead of a fork.
- **Phase 3** — refactor to native OPM Components with `#StatelessWorkload` or a custom Blueprint where it reduces repetition.
- **Phase 4** — adopt Policy definitions as they ship, and lean on the ModuleRelease GitOps loop via the [operator](operator.md).

## Conclusion

Helm is templated YAML; OPM is unified CUE. The trade-off is an investment in learning CUE in exchange for compile-time guarantees, cleaner ownership boundaries, and safer extension. For small teams running a handful of charts, Helm is still the quickest path. For platforms supporting many teams, many environments, and evolving compliance requirements, OPM is the model that grows with you.
