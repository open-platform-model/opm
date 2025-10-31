# V1 DOCUMENTATION PLAN

1. Top-level README (what OPM is, why it exists, how it fits together)
2. Definition Types Deep Dive (how Units / Traits / Blueprints / Components / Policies / Scopes / Lifecycle work)

That's already better structure than most "platform" projects in the wild. Now you should round it out with documents that answer four recurring questions:

* How do I use this?
* How do I extend this?
* How do I trust this?
* How do I run this for real?

Below are the docs I'd write next, in roughly the order they become useful to readers.

---

### 1. Getting Started / Quickstart

Audience: application developers and platform engineers who just landed in the repo.

Goal:
Show someone how to model a minimal service using OPM, step by step, using the current concepts (Unit, Trait, Component, ModuleDefinition, etc.). Zero theory, just "do this, see this."

Contents:

* install/setup requirements (CUE version, CLI if you have one)
* define a simple web service Component with a `#Container` Unit and a `#Replicas` Trait
* wrap it in a ModuleDefinition
* show what the generated Module and ModuleRelease would look like
* explain how policy and scope get applied in that flow

This is where people decide if they keep reading or close the tab. It needs to feel real.

---

### 2. Authoring Components

Audience: application developers.

Goal:
Show how to build a Component directly from Units + Traits, and when you should do that instead of using a Blueprint.

Contents:

* anatomy of a Component
* declaring multiple Units in one Component (example: `#Container` + `#Volume`)
* attaching multiple Traits (scaling + ingress + health)
* how values are exposed for later override
* how this lands in ModuleDefinition

This document becomes the "how to describe your service" page. It's basically developer-facing OPM.

---

### 3. Authoring Blueprints

Audience: platform engineering / platform enablement.

Goal:
Teach platform teams how to create Blueprints that app teams can reuse as safe defaults.

Contents:

* what makes something worth turning into a Blueprint
* how to bundle Units + Traits into a Blueprint
* how to surface only certain knobs as overridable (replicas yes, TLS policy no)
* how to compose Blueprints from other Blueprints
* how to version and publish Blueprints internally

This is the seed of your "internal platform as product." This document is what lets a platform team scale themselves.

---

### 4. Policy and Scope

Audience: platform/security/compliance people.

Goal:
Clarify how governance works in OPM without making developers hate you.

Contents:

* what a Policy is, with real examples (pod security baseline, residency, TLS rules, audit logging)
* what a Scope is, and how Scopes attach Policies to Components
* how both platform teams and developers define Scopes (platform teams for governance, developers for app concerns)
* CUE unification ensures platform-defined Scopes persist in the module
* how Scopes also express allowed relationships between Components (who can talk to who, who can read which secret)
* examples of "deny by default" communication vs explicitly allowed communication

This is critical for selling OPM to serious orgs. It's also important for reducing hand-wavy "security is coming later" energy.

---

### 5. Lifecycle (Future Direction)

Audience: platform / SRE / regulated environments.

Goal:
Lay out where you're going with rollout/upgrade/backup semantics, and why it matters.

Contents:

* what Lifecycle will describe (deployment strategy, upgrade sequencing, pre/post hooks, data safety steps)
* how Lifecycle would sit next to Units / Traits / Scopes instead of being hidden in CI/CD glue
* why this matters for auditability, rollback safety, and sovereignty (especially around stateful services)

Mark this as planned/experimental. This document signals maturity: you're not just describing desired state, you're thinking about safe change.

---

### 6. Module Flow and Responsibilities

Audience: architects, platform leads, leadership.

Goal:
Explain the "three stage" flow — ModuleDefinition → Module → ModuleRelease — and show who owns what, and when.

Contents:

* ModuleDefinition: authored by developers, portable intent
* Module: curated by the platform, with Policy and Scope applied, defaults enforced
* ModuleRelease: concrete instance deployed somewhere with actual values
* what can change in each stage, and what cannot
* how this maps to compliance and handover ("who signed off on what?")

This is good for governance decks and for onboarding new platform engineers.

---

### 7. Reference: Standard Definitions

Audience: everyone.

Goal:
Be the dictionary.

Contents:
For each "built-in" Definition you ship (for example `#Container`, `#Volume`, `#ConfigMap`, `#Secret`, `#Replicas`, `#Expose`, `#HealthCheck`, `#WebService`, etc.):

* what it does
* its fields
* constraints/types/defaults
* which Definition category it belongs to (Unit, Trait, Blueprint, etc.)
* example snippets in CUE

This becomes your API reference. People will ctrl+f this constantly.

---

### 8. Provider / Runtime Integration

Audience: anyone trying to actually run this somewhere.

Goal:
Explain what it means to "implement OPM."

Contents:

* how a runtime or provider consumes a ModuleRelease
* what parts of the Definition must be honored
* what happens with Policy and Scope at execution time
* how Kubernetes is (or will be) targeted: mapping Units/Traits to concrete resources (Deployment, StatefulSet, PVC, Ingress, NetworkPolicy, etc.)
* how a non-Kubernetes runtime could theoretically target the same ModuleRelease

This is where OPM stops being "a model" and becomes "a contract providers can agree to."

Later, this turns into the provider ecosystem story.

---

### 9. Security / Compliance Story

Audience: security, compliance, audit, governance teams (and buyers).

Goal:
Sell why OPM is safer than "a folder of YAML files."

Contents:

* how Policies + Scopes let you express compliance constraints
* how Scopes let you prove isolation, residency, etc.
* how this approach reduces manual review
* (later) how this lines up with OSCAL-style evidence and attestations
* how Module / ModuleRelease gives you traceability: "this went live under which policies, signed off by whom, with which values"

This is how you talk to regulated orgs, governments, banks.

---

### 10. Design Principles

Audience: contributors and standards nerds.

Goal:
Document the philosophy behind OPM so new work doesn't drift.

Contents:

* why Definition types are separate (Unit vs Trait vs Blueprint vs Policy vs Scope)
* why you keep behavior (Traits) separate from governance (Policy)
* why Scope, not Components themselves, controls relationships between Components
* why ModuleDefinition → Module → ModuleRelease is a pipeline instead of one big blob
* what "portability" actually means here (hint: not "runs everywhere magically," but "same intent, different governed realization")

This prevents future contributors from reintroducing bad ideas like "just embed policy directly in every component" or "just template YAML harder."

---

If you write these, you'll have:

* A landing page (README)
* A mental model (Definition Types Deep Dive)
* A how-to (Getting Started)
* A dev guide (Authoring Components)
* A platform guide (Authoring Blueprints)
* A governance guide (Policy and Scope)
* An ops/SRE future story (Lifecycle)
* A responsibility model (ModuleDefinition → Module → ModuleRelease)
* A reference (Standard Definitions)
* A provider contract (Runtime Integration)
* A security/compliance narrative
* A principles doc to keep you honest

That's enough to onboard devs, sell platform engineering internally, convince security, and attract future providers without having to sit in every meeting and re-explain the same diagram.
