# ADR-001: Kubernetes is the target

## Status

Accepted (2026-10-20). Reversibility: two-way. A second target is a new project that this decision does not prevent; it only stops that target from shaping the work of today.

## Context

OPM v2 splits the catalog in two. A primitive set defines what a module can ask for: resources, traits and blueprints. A provider holds the transformers that render those primitives into objects. A platform lists the providers it runs.

One reason given for the split was portability. With primitives apart from the providers that render them, a provider for docker-compose, Podman or Incus could render the same modules. If OPM aims at several targets, every primitive must have a meaning that each target can render. That pulls the primitive set toward what all targets share (a container, a volume, a port, an environment) and away from what Kubernetes users need: backup, network policy, disruption budgets, autoscaling, service accounts and custom resources.

No user or deployment of OPM needs a target other than Kubernetes today. Each extra target also multiplies the fixtures, publish gates and documentation that every primitive needs.

## Decision

OPM targets Kubernetes. Primitives may be shaped for Kubernetes: a primitive is judged by how well it serves Kubernetes users, not by whether another runtime could render it. OPM makes no promise of another target.

The split of primitive set and provider stays, for reasons inside Kubernetes. One primitive can have several Kubernetes implementations, for example backup through k8up or Velero, or a gateway through Istio or Envoy Gateway, and the platform team chooses which one renders it. A cluster can run several platforms, so tenants can bind the same primitive to different providers. A provider can release a rendering fix without a new primitive set and without a module release.

A provider for another runtime (docker-compose, Podman, Incus) is a later project. It starts when a real user needs it, and it then decides how far the existing primitives serve that runtime.

Merging the primitive set and the provider back into one catalog was rejected: it would remove the choice of implementation from the platform team. Aiming at several targets now was rejected: it would shape every primitive for users who do not exist yet.

## Consequences

**Positive:** Primitive design answers to one runtime, so primitives can use Kubernetes concepts directly and stay small. Fixtures, gates and documentation cover one target. The docs explain the split by what it gives Kubernetes users, not by a portability that nobody uses.

**Negative:** Modules written for OPM do not run outside Kubernetes. A later provider for another runtime will find primitives that have no meaning there and will need to report them as not supported or leave them out.

**Trade-off:** OPM competes with Helm on Kubernetes alone: on typed configuration, validation, composition and safe upgrades, not on the number of runtimes it reaches.
