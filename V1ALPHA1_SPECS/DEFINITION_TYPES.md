# OPM Definition Types: Deep Dive

This document explains the core Definition types in OPM in more depth: what they are for, who defines them, when they're used, and how they relate.

Everything in OPM is expressed as a **Definition**.

A Definition is a structured, typed definition in CUE that describes some part of an application or its runtime expectations. Different Definition types live at different layers of responsibility: developer, platform, security/governance, runtime operations.

The core Definition types today are:

* Unit (`#UnitDefinition`)
* Trait (`#TraitDefinition`)
* Blueprint (`#BlueprintDefinition`)
* Policy (`#PolicyDefinition`)
* Component (`#ComponentDefinition`)
* Scope (`#ScopeDefinition`)

There is also a future/experimental Definition type:

* Lifecycle (`#LifecycleDefinition`)

---

## Definition Structure Pattern

All OPM definitions follow a consistent structure pattern with two levels of API versioning:

### Root Level (Fixed)

All definitions have fixed root-level fields for OPM core API versioning:

```cue
apiVersion: "opm.dev/v1/core"  // Fixed for all v1 definitions
kind:       string              // "Unit", "Trait", "Blueprint", "Component", "Policy", "Scope"
```

These fields identify an object as an OPM v1 definition and specify its type.

### Metadata Level (Context-Specific)

The metadata structure differs between **Definition types** and **Instance types**:

#### Definition Types (Unit, Trait, Blueprint, Policy, Module, ModuleDefinition)

Definition types have element-specific versioning in metadata:

```cue
metadata: {
    apiVersion!: string  // Element-specific version path (e.g., "opm.dev/units/workload@v1")
    name!:       string  // Definition name (e.g., "Container")
    fqn:         string  // Computed as "\(apiVersion)#\(name)"
    description?: string
    labels?:      {...}
    annotations?: {...}
}
```

**Example: UnitDefinition**

```cue
#Container: #UnitDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Unit"

    metadata: {
        apiVersion: "opm.dev/units/workload@v1"
        name:       "Container"
        fqn:        "opm.dev/units/workload@v1#Container"  // Computed
        description: "Container unit for workload definitions"
    }

    spec: {
        image!: string
        // ... container spec
    }
}
```

#### Instance Types (ComponentDefinition, ScopeDefinition, ModuleRelease)

Instance types do NOT have `metadata.apiVersion` or `metadata.fqn`. They only have instance identification:

```cue
metadata: {
    name!: string  // Instance name only
    description?: string
    namespace?: string  // Optional, required for ModuleRelease
    labels?:     {...}
    annotations?: {...}
}
```

**Example: ComponentDefinition**

```cue
api: #ComponentDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Component"

    metadata: {
        name: "api"  // No apiVersion or fqn - it's an instance, not a definition
        labels: {
            tier: "backend"
        }
    }

    spec: {
        // Component spec...
    }
}
```

### Why the Two-Level Structure?

1. **Kubernetes Compatibility**: Root-level `apiVersion` and `kind` match Kubernetes manifest structure
2. **Separation of Concerns**: OPM core versioning separate from element/module versioning
3. **Clean Exports**: Definitions export as standard Kubernetes-like resources
4. **Flexible Versioning**: Elements version independently from the core schema
5. **Clear Instance vs Definition**: Instances don't need FQNs as they're not reusable definitions

### Summary Table

| Type | Root apiVersion | Root kind | metadata.apiVersion | metadata.fqn | Use Case |
|------|----------------|-----------|---------------------|--------------|----------|
| UnitDefinition | `opm.dev/core/v1` | `Unit` | ✅ Element-specific | ✅ Computed | Reusable unit definition |
| TraitDefinition | `opm.dev/core/v1` | `Trait` | ✅ Element-specific | ✅ Computed | Reusable trait definition |
| BlueprintDefinition | `opm.dev/core/v1` | `Blueprint` | ✅ Element-specific | ✅ Computed | Reusable blueprint pattern |
| PolicyDefinition | `opm.dev/core/v1` | `Policy` | ✅ Element-specific | ✅ Computed | Reusable policy rule |
| ModuleDefinition | `opm.dev/core/v1` | `ModuleDefinition` | ✅ Module-specific | ✅ Computed | Reusable module template |
| Module | `opm.dev/core/v1` | `Module` | ✅ Module-specific | ✅ Computed | Flattened module |
| ComponentDefinition | `opm.dev/core/v1` | `Component` | ❌ None | ❌ None | Component instance in a module |
| ScopeDefinition | `opm.dev/core/v1` | `Scope` | ❌ None | ❌ None | Scope instance in a module |
| ModuleRelease | `opm.dev/core/v1` | `ModuleRelease` | ❌ None | ❌ None | Deployed module instance |

---

## Unit

### What is a Unit

A **Unit** is the fundamental building block inside a Component. It defines a thing that will actually exist at runtime.

A Component must include at least one Unit.

A Unit can describe:

* a workload (for example: a single container that represents the component's main process),
* persistent state / storage (for example: one or more volumes),
* runtime configuration (for example: a config map or secret),
* supporting primitives like network policy or access control.

The key point: a Unit is concrete. It is not abstract intent. It's "this is part of what runs or is provisioned."

### Examples

* `#Container` – describes a single container. This defines the actual workload identity for that Component.
* `#Volume` – describes one or more volumes.
* `#ConfigMap` – describes config data made available at runtime.
* `#Secret` – describes sensitive runtime inputs.

### Who writes it

Usually application developers (or platform engineers acting in that role) when defining a Component.

### Naming Conventions

Units that allow the user to define a map of things MUST be named with their name in plural.

**Examples:**

* `#Volumes` – if it allows defining multiple volumes as a map:

  ```cue
  volumes: {
    data: {...}
    logs: {...}
  }
  ```

* `#Secrets` – if it allows defining multiple secrets as a map:

  ```cue
  secrets: {
    apiKey: {...}
    dbPassword: {...}
  }
  ```

* `#Container` – singular form is correct if only one container is defined (not a map)

### Why it matters

Without a Unit, a Component is just theory. With at least one Unit, the Component now names a real workload or resource the platform can act on.

---

## Trait

### What is a Trait

A **Trait** describes *behavior and properties* applied to a Component.

Traits are optional. Traits are attachable. Traits do not exist on their own.

Instead of redefining Units, Traits describe how the Component should behave at runtime:

* how it scales (replicas, autoscaling),
* how it is exposed or reachable (networking, ingress),
* how its health is checked (liveness, readiness),
* what security posture it must keep (TLS, pod security),
* how it restarts (restart policies),
* resource requirements (CPU, memory limits).

### Examples

* scaling / replicas (horizontal scaling policies)
* ingress / public exposure / routing details
* readiness / liveness / health checks
* TLS / encryption / transport rules

### Who writes it

Typically application developers, because Traits are closest to runtime intent:

* "I need 3 replicas."
* "Expose this on HTTPS."
* "Check `/healthz` every 5s and restart if it fails."

### Why it matters

Traits let developers express operational needs directly in the model instead of handing those off informally to the platform team.

Traits are also where platform defaults live. If you don't specify a Trait, the platform (or Blueprint) can provide a safe default.

### Relationship to Units and Components

* A Unit says what exists (the workload, storage, config).
* A Trait says how the Component behaves at runtime.
* Traits apply to the Component as a whole, not to individual Units.
* Traits may specify which Units they relate to via `appliesTo`, but they modify Component behavior.

---

## Blueprint

### What is a Blueprint

A **Blueprint** is a reusable, opinionated bundle of Units and Traits.

A Blueprint answers the question most developers actually ask:

* "Just give me a normal web service."
* "Give me a standard stateful thing with storage and backups."

Instead of forcing every team to stitch Units and Traits together by hand, a Blueprint packages a working pattern:

* which Units to include,
* which Traits to attach to them,
* what defaults should be applied.

### Examples

* `WebService` Blueprint:

  * one container Unit,
  * replicas Trait with a sane default,
  * health/readiness Trait,
  * ingress Trait that exposes HTTP under org rules.

* `StatefulService` Blueprint:

  * one container Unit,
  * one volume Unit,
  * backup/retention Trait,
  * readiness Trait designed for slower startup.

Blueprints can also be composed from other Blueprints. A platform team can build increasingly rich shapes out of smaller building blocks.

### Who writes it

Primarily platform engineering / platform enablement teams.

The platform team uses Blueprints to encode "the blessed way we do X here," and to hide a lot of wiring and policy detail from the average developer.

### Why it matters

Blueprints reduce drift. Instead of N slightly different ways to run a web service, you get one controlled pattern. That cuts operational risk and simplifies support.

Blueprints are also the unit you can publish as a catalog for developers.

---

## Policy

### What is a Policy

A **Policy** encodes governance rules:

* security requirements,
* compliance controls,
* residency/sovereignty boundaries,
* operational guardrails.

Policies are not suggestions. Policies define what *must* be true.

Examples:

* All containers must run as non-root.
* Only internal TLS is allowed between these Components.
* Data for this Component must stay within a specific jurisdiction.
* This Component must emit audit logs with retention >= 365 days.

### Validation vs Enforcement

Policies distinguish between **validation** (ensuring correctness) and **enforcement** (governing runtime behavior):

* **CUE Validation**: The structure and schema of all policies are automatically validated by CUE. This is no different from how CUE validates any definition structure.
* **Platform Enforcement**: Each policy specifies when enforcement happens (`deployment`, `runtime`, or `both`) and what happens on violation (`block`, `warn`, or `audit`). This integrates with platform-native enforcement mechanisms like Kyverno, OPA/Gatekeeper, or admission controllers.

The key distinction from regular schema constraints: policies are **governance rules** that can be added/removed independently by platform teams without changing the underlying schemas. Schema constraints define "what's structurally possible," while policies define "what's required by governance."

### Policy Target Field

Every Policy declares where it can be applied through a `target` field:

* `target: "component"` - Component-level only (resource limits, security contexts, backup requirements)
* `target: "scope"` - Scope-level only (network policies, baseline security, resource quotas)

CUE validation ensures policies are only applied where their target allows:

* Component definitions can only include policies with `target: "component"`
* Scope definitions can only include policies with `target: "scope"`

### Component-Level Policies

Applied to individual components. Examples:

* **ResourceLimitPolicy**: CPU, memory, storage quotas
* **SecurityContextPolicy**: User, capabilities, filesystem permissions
* **BackupRetentionPolicy**: Backup schedule, retention periods, recovery settings
* **DataClassificationPolicy**: Sensitive data handling requirements

### Scope-Level Policies

Applied to groups of components. Examples:

* **NetworkRulesPolicy**: Allowed traffic between components
* **PodSecurityPolicy**: Pod security standards baseline
* **ResourceQuotaPolicy**: Total resources for all components in scope
* **AuditLoggingPolicy**: Mandatory audit logging requirements

### Creating Similar Policies for Both Contexts

When similar governance is needed at both component and scope levels (e.g., encryption, monitoring), create two separate policy definitions with the same spec schema:

* **EncryptionPolicyComponent** (`target: "component"`) - Component-level encryption requirements
* **EncryptionPolicyScope** (`target: "scope"`) - Scope-level encryption baseline
* **MonitoringPolicyComponent** (`target: "component"`) - Component-specific monitoring
* **MonitoringPolicyScope** (`target: "scope"`) - Scope-wide monitoring baseline

Each policy gets its own wrapper definition for ergonomic application.

### Who writes it

Platform / security / compliance owners.

### Why it matters

Policies let the platform enforce standards without rewriting every Component by hand.

Instead of "please remember to add these annotations," the Policy makes those rules part of the model itself.

The target field system provides:

* Clear separation of concerns (component-specific vs cross-cutting)
* Type-safe validation (can't apply policies where they don't belong)
* Reusability (same spec schema can be used for both contexts when needed)

See [POLICY_DEFINITION.md](POLICY_DEFINITION.md) for complete policy specification.

---

## Scope

### What is a Scope

A **Scope** defines where and how Policies apply, and how Components are allowed to relate.

Think of Scope as the attachment point and the boundary.

Scopes can:

* apply one or more `#PolicyDefinition` instances to one or many Components,
* define which Components are allowed to communicate,
* define which Components may consume secrets or configuration from others,
* carry baseline posture (network isolation, pod security baseline, etc.).

### Who Defines Scopes

Both platform teams and module developers define Scopes for different purposes:

**Platform teams** define Scopes for:

* Baseline security and compliance posture (for example: Pod Security baseline, mandatory TLS, audit logging requirements)
* Resource governance and quotas
* Organization-wide policy enforcement

**Module developers** define Scopes for:

* Application-level connectivity (which Components in this module can communicate)
* Shared configuration and secret exposure between Components
* Operational concerns specific to the application

### CUE Unification

When platform teams extend a ModuleDefinition via CUE unification, their Scopes are added alongside developer-defined Scopes. CUE's unification semantics ensure that once a Scope is added, it becomes part of the module.

### Why it matters

Scopes give you:

* Reusable security and compliance posture (platform-defined Scopes)
* Application-level connectivity and sharing rules (developer-defined Scopes)
* Centralized places to reason about risk

Notice what this does *not* require:

* You don't have to bake hard-coded cross-component wiring directly into Components
* You don't have to hand-edit security annotations everywhere

Instead, you express relationships and enforcement at the Scope level.

---

## Component

### What is a Component

A **Component** is what the application author actually declares inside a ModuleDefinition.

There are two ways to define a Component:

1. Define Units + Traits directly.
2. Reference a Blueprint.

Either way, a Component represents a logical part of the application (API service, worker job, database, cron, etc.).

### Structure

* If you build a Component manually:

  * include at least one `#UnitDefinition`,
  * optionally attach `#TraitDefinition` instances.

* If you build from a Blueprint:

  * reference the `#BlueprintDefinition`,
  * override only what the Blueprint allowed you to override (for example: image tag, replica count, ingress hostname).

### Who writes it

Application developers.

### Why it matters

The Component defines app shape at the level developers care about:

* "this is my service"
* "this is my queue worker"
* "this is my scheduled cleanup job"

A Component is not the whole application. It's a building block of the application.

---

## Lifecycle (planned)

### What it is

A **Lifecycle** Definition is about change over time.

Where Unit, Trait, Component, Blueprint, Policy, and Scope mostly describe "steady state," Lifecycle would describe how to safely get from one state to another.

This includes:

* rollout / upgrade strategy (rolling update, surge limits, max unavailable, etc.),
* pre-deploy checks and post-deploy health gates,
* data backup and restore steps for stateful changes,
* teardown / migration order for Components that depend on each other,
* grace periods, drain rules, shutdown hooks.

### Who would write it

Likely platform/SRE in partnership with teams that own stateful services.

### Why it matters

Right now, these behaviors usually live in CI/CD pipelines, runbooks, or tribal memory.

Lifecycle Definition would bring them into the model so that:

* upgrades can be repeated safely,
* compliance workflows (like "backup before upgrade") are machine-verifiable,
* and providers can advertise not just "we can run this," but "we can upgrade this safely under these guarantees."

### Status

Lifecycle Definition is future work. It's being called out early because rollout and upgrade semantics are inseparable from real production platforms, especially once you get into regulated environments.

---

## How These Definitions Work Together

Let's walk a realistic path.

1. Developers and/or platform teams write a ModuleDefinition that declares:

   * Components (`#ComponentDefinition`).
   * Those Components either:

     * reference Blueprints, or
     * directly define Units (like `#Container`, `#Volume`) and attach Traits (like `#Replicas`, `#Expose`, `#HealthCheck`).
   * Scopes to describe how Components in this module are allowed to interact.
   * Platform teams can inherit and extend upstream ModuleDefinitions via CUE unification, adding Policies, Scopes, or additional Components.

2. The ModuleDefinition is flattened into a Module:

   * Blueprints are expanded into their constituent Units and Traits.
   * Structure is optimized for runtime evaluation.
   * Ready for binding with concrete values.

3. A user (or deployment process) creates a ModuleRelease:

   * references a specific Module,
   * fills in concrete values (image tag, replica count, hostnames, etc.),
   * targets a specific runtime.

In other words:

* **Units** define concrete runnable pieces (what exists).
* **Traits** define how Components behave at runtime (scaling, health, networking, etc.).
* **Blueprints** package best practices so developers don't have to wire everything.
* **Components** are what application authors actually declare (Units + Traits + data).
* **Policies** and **Scopes** let the platform and security teams enforce rules and shape relationships.
* **Lifecycle** (future) will define how these things roll out and evolve safely.

---

## Mental Model Cheat Sheet

* Unit (`#UnitDefinition`) = "what exists in the component"
* Trait (`#TraitDefinition`) = "how the component behaves at runtime"
* Blueprint (`#BlueprintDefinition`) = "the blessed way to run this kind of thing"
* Component (`#ComponentDefinition`) = "this part of my app (Units + Traits + data)"
* Policy (`#PolicyDefinition`) = "the rules you must follow"
* Scope (`#ScopeDefinition`) = "where those rules apply, and who is allowed to talk to who"
* Lifecycle (`#LifecycleDefinition`) (planned) = "how this changes safely over time"

That's the full picture. This is the contract OPM wants providers to implement and teams to adopt.

---

## Implementation Note: Relationship References

The OPM CUE schemas (in `core/v1/`) use **full definition references** for relationships instead of FQN strings:

```cue
#TraitDefinition: {
    appliesTo!: [...#UnitDefinition]  // Full reference, not string FQN
}

#BlueprintDefinition: {
    composedUnits!: [...#UnitDefinition]  // Full reference, not string FQN
}
```

### Rationale

* **Type safety at CUE evaluation time**: The CUE compiler validates that referenced definitions actually exist and have the correct structure.
* **IDE autocomplete and type checking support**: Editors can provide completions and show errors immediately.
* **Direct CUE unification validation**: Relationships are validated through CUE's type system, not string matching.
* **Clearer dependency tracking**: The dependency graph is explicit in the CUE types.

### Trade-offs

This creates compile-time coupling between definitions. When a TraitDefinition references a UnitDefinition, both must be available in the same CUE evaluation context.

For published Definition catalogs across module boundaries or external registries, FQN strings may be preferred to decouple schemas. The CLI flattening library can convert between representations:

* **Compile-time** (authoring): Full references for type safety
* **Runtime/serialization** (distribution): FQN strings for decoupling

### Alternative Considered

The V1 specification documents originally suggested FQN string references:

```cue
// Not implemented in core/v1
#TraitDefinition: {
    modifies: [...string]  // FQN strings like "opm.dev/elements@v1#Container"
}
```

This approach was **not adopted** for the CUE schemas because:

1. Loss of compile-time validation
2. Harder to maintain and refactor
3. No IDE support for finding references

FQN strings remain useful for **serialization** and **external references** (e.g., when publishing to OCI registries), but full references provide better developer experience during authoring.
