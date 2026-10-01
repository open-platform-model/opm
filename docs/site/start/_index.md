---
title: "Start here"
description: "New to OPM? See what it is, install it, try it, and learn how it works."
weight: 1
---

Open Platform Model (OPM) is first and foremost an [application model](/docs/concepts/application-and-platform-models/). This page shows how its parts fit together, one picture at a time, and links to the page that explains each one.

## From module to running objects

{{< opm/module-to-cluster >}}

Read more: [What OPM is](/docs/start/what-is-opm/).

## Three roles, three artifacts

{{< opm/roles-and-artifacts >}}

Read more: [Platforms and catalogs](/docs/concepts/platforms-and-catalogs/), and why OPM splits the roles in [What OPM is](/docs/start/what-is-opm/).

## How a component becomes objects

{{< opm/component-to-objects >}}

Read more: [How matching works](/docs/concepts/how-matching-works/).

## Where things live

{{< opm/where-things-live >}}

Read more: [Deploy a module with the CLI](/docs/operating/deploy-with-the-cli/) and [Publish a module](/docs/authoring/publish-a-module/).

## Three ways to deploy

{{< opm/three-ways-to-deploy >}}

Read more: [Who owns an instance](/docs/concepts/who-owns-an-instance/) and [Operator resources](/docs/reference/operator-resources/).

## Release status

OPM is in beta. The beta lines are the core schema `opmodel.dev/core@v2`, the raw Kubernetes catalog `opmodel.dev/catalogs/k8s@v1`, the Go library, the `opm` CLI and the operator. The raw Kubernetes catalog, the library, the CLI and the operator ship versions `1.0.0-beta.N`, and core ships versions `2.0.0-beta.N`. Each beta line is on the path to a stable release.

A breaking change can still land during the beta. It comes with a migration note in the release's changelog, and it raises the beta number, for example from `-beta.1` to `-beta.2`. It never moves a module path to a new major version. The abstraction catalog `opmodel.dev/catalogs/opm@v4` and the published modules are already stable and follow semantic versioning: a breaking change there is a new major version. A core change that would force a new major of the abstraction catalog needs the maintainers' approval. At the stable release, each beta line drops its `-beta.N` suffix, in dependency order starting with core.

The beta is a release status, not a contract level. A resource, trait or blueprint carries its own `apiVersion` (`v1alpha1`, `v1beta1`, `v1`), which moves on its own ladder with its own promise; see the [Glossary](/docs/reference/glossary/). The operator's resources stay at `opmodel.dev/v1alpha1` until the stable release.

## Where to start

- To try OPM, follow the [Quickstart](/docs/start/quickstart/).
- To install the `opm` CLI or the operator, see [Installation](/docs/start/installation/).
- To understand how it works, read [What OPM is](/docs/start/what-is-opm/).
- If you know Kubernetes or Helm, read [OPM for Kubernetes users](/docs/start/opm-for-kubernetes-users/).
- To know its limits, read [What OPM does not do](/docs/start/what-opm-does-not-do/).
