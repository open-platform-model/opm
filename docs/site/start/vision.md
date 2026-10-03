---
title: "Where OPM is going"
description: "The vision behind OPM: from an application model to a platform model, and an open ecosystem of the providers platforms are built from."
type: explanation
weight: 50
---

Open Platform Model (OPM) is an application model today. This page says where the project wants to take it: to a model of the platform as well, and to an open ecosystem of the companies that provide what platforms offer. It speaks in intent. Unless a sentence says something works today, it describes a goal, and nothing on this page is a design. What OPM does today is on [What OPM is](/docs/start/what-is-opm/) and [The application model and the platform model](/docs/concepts/application-and-platform-models/).

## The vision in brief

OPM aims to model both individual applications and the platforms they run on. Modules would supply what a platform offers, and the platform would offer it to the modules of every team that uses it. An organisation would define its platforms once and instantiate them onto the infrastructure it chooses: a Kubernetes cluster, a public cloud or its own data centre.

Around the model, the project wants an ecosystem in which cloud and infrastructure companies, small and large, offer their services in one open, shared form. The motivation is data sovereignty: an organisation should decide where its software and data run, and not depend on a few large cloud providers. All of it is meant to be open source.

## From an application model to a platform model

Today a module describes an application in catalog terms, and a platform is a list of catalogs whose transformers turn the module into Kubernetes objects. The platform half answers one question: how does this module become objects on this cluster?

A platform model would describe the platform itself: what it is built from, what it offers its teams, the settings that hold across it, and the infrastructure it runs on. A platform team would write its platform the way a module author writes a module: as typed, versioned data that is checked before anything is applied.

## A circular system

The two models are meant to depend on each other.

1. A provider publishes a module that supplies a capability, such as a database service, a backup engine or a certificate authority.
1. A platform admits that module and offers the capability to the teams that use the platform.
1. A team's module names the capability in catalog terms and does not care who provides it.
1. A team's module can itself become a provider: one team's database service becomes a capability the next team uses.

The first two steps work today in a narrow form. A provider module can render a `TransformerRegistration` that claims its catalog. Once the operator accepts the claim and the provider's instance reports `Ready`, the catalog joins the platform, and every module on that platform can use the contracts the catalog implements. No published module uses this mechanism today. The rest of the circle is the goal.

The circle has a hard edge. A provider module needs a platform to render on before it can extend one, so something has to come first.

## Platforms that move

AWS, GCP and Kubernetes are platforms in their own right. In OPM's terms they are infrastructure: what an organisation's own platforms run on. An organisation could define one or more platforms, such as one for internal tools and one for customer-facing services, and instantiate each wherever it needs it, in a public cloud or self-hosted.

Portability has a limit, and the model has to face it. A platform that offers a managed database has to get that database from somewhere on every infrastructure it runs on. OPM's answer is the one it already gives applications: the platform names the capability as a contract, and a provider on each infrastructure supplies it. This works today for a single trait, though OPM publishes no backup provider yet, so k8up and Velero here are examples:

{{< opm/one-trait-any-provider >}}

Kubernetes is the first infrastructure, and the only one OPM renders for today. AWS, GCP and OpenStack are where the project wants to go next.

## An open ecosystem of providers

The platform model and its parts are meant to grow into an ecosystem of consumers and providers. Consumers assemble portable applications from capabilities. Providers offer those capabilities, and compete on price, performance, location and trust. Changing a provider becomes a change to a platform, not a rewrite of every application.

That gives smaller cloud and infrastructure companies a way in. Today a team that needs a database, object storage, a queue and an identity service tends to buy all of them from one large provider, because each one is wired into its applications differently. In a shared, open form, many smaller providers could together offer what only the largest providers offer alone, and the large providers could take part on the same terms.

## Why: less reliance on a few cloud providers

Amazon, Microsoft and Google, three providers based outside Europe, hold about 70% of the European cloud market, and European providers hold about 15% ([Synergy Research Group, July 2025](https://www.srgresearch.com/articles/european-cloud-providers-local-market-share-now-holds-steady-at-15)). Moving away is expensive. Applications are written against one provider's services, and data egress fees and licensing terms add to the cost. European policy now pushes the other way. The cloud-switching rules of the [EU Data Act](https://eur-lex.europa.eu/eli/reg/2023/2854/oj) have applied since 12 September 2025. Until 12 January 2027 a provider may charge no more than its own direct costs for a switch, and from that date it may charge nothing, data egress included. The Commission proposed a [Cloud and AI Development Act](https://digital-strategy.ec.europa.eu/en/library/proposal-cloud-and-ai-development-act-cada) on 3 June 2026; it is not yet law.

EuroStack is one of the ideas OPM grew from. A [2025 report for the Bertelsmann Stiftung](https://www.bertelsmann-stiftung.de/en/publications/publication/did/eurostack-a-european-alternative-for-digital-sovereignty) states that more than 80% of Europe's digital technologies and infrastructures are imported, and proposes a European stack of its own, from chips through cloud to software and AI. The [EuroStack Initiative's open letter of March 2025](https://euro-stackletter.eu/wp-content/uploads/2025/03/EuroStack_Initiative_Letter_14-March-.pdf) asks for a "pooling and federating" approach: existing, dispersed European offerings combined into scaled alternatives, with open source and interoperability. OPM works on one layer of that picture, a shared, open form in which many providers' services add up to a platform.

A model that keeps applications and platforms independent of any one provider turns switching into an edit. That is the contribution OPM wants to make. It does not make anything sovereign by itself: open source and portability are prerequisites, not the whole answer. Who controls a service, which law it falls under and how far it can be trusted are questions a model can at most describe.

## Open source, all the way down

OPM's model, its CLI, its operator, its kernel and its catalogs are open source under the Apache 2.0 license, and the platform model and its parts must stay open source too. Providers in the ecosystem should publish what platforms consume, their modules and their catalogs, as open source as well. A platform should never depend on a part its owner cannot read, fork or run.

## How OPM relates to other projects

Several projects cover part of this ground. The project knows of none that combines a typed application model, a platform described as data, and an ecosystem of providers across infrastructures. That combination is what OPM aims for.

| Project | What it does | Where OPM differs |
| --- | --- | --- |
| [KubeVela](https://kubevela.io/) and the Open Application Model | Applications built from components, traits, policies and workflow steps, with definitions written in CUE, run by a control plane in a Kubernetes cluster. The Open Application Model is the specification behind KubeVela. | The closest to OPM's application model. OPM renders a module against a platform's catalogs before anything reaches a cluster, and treats the platform itself as data. |
| [Crossplane](https://www.crossplane.io/) | Lets a platform team define its own APIs that compose cloud infrastructure, through providers for cloud APIs, and any Kubernetes resource, applications included, reconciled by a control plane. | Crossplane composes resources at run time in a control plane. OPM wants a typed model of the platform and the application that is checked before anything is applied, in which a Crossplane composition could be one way to supply a capability. |
| [Kratix](https://www.kratix.io/) | Promises package a platform capability as an API with the workflows that fulfil it. Kratix writes their output to destinations: Kubernetes clusters, or other systems through Git. | The closest to the provider idea. OPM describes a capability as a typed contract in a catalog, not as a workflow. |
| [Sovereign Cloud Stack](https://sovereigncloudstack.org/en/) | Certifiable open standards and a modular reference stack for sovereign infrastructure on OpenStack and Kubernetes, maintained by the Forum SCS-Standards in the Open Source Business Alliance. | It standardises infrastructure, and OPM sits above it. A Sovereign Cloud Stack cloud is the kind of infrastructure an OPM platform would run on. |
| [IPCEI-CIS](https://www.8ra.com/) (the 8ra initiative) | An Important Project of Common European Interest, funded by member states and approved by the Commission in December 2023, that builds a multi-provider cloud-edge continuum. | It works on federating infrastructure and services across providers. OPM works on the model of the application and the platform above them. |
| [EuroStack](https://www.bertelsmann-stiftung.de/en/publications/publication/did/eurostack-a-european-alternative-for-digital-sovereignty) | A policy initiative for digital sovereignty across the whole stack, from chips through cloud to software and AI, built on open source, open standards and pooled European providers. | It works on policy, investment and procurement. OPM is software for one layer of the stack it describes. |

## Open questions

The vision leaves hard questions open. Each one needs an answer before the platform model can be designed.

- **Where does the platform model end?** A platform could render cloud APIs directly, the way Crossplane does, or run on Kubernetes everywhere and leave the cloud underneath. The two lead to very different models.
- **How does the circle start?** A provider module needs a platform before it can extend one, and two providers can depend on each other.
- **Who checks what a provider adds?** A provider's module changes what every module on the platform renders. Enhancement 0023, [Artifact Provenance, Signatures and Platform Trust Policy](/enhancements/0023/), is a draft that designs a platform trust policy for the artifacts a platform fetches.
- **Who writes the providers, and why?** An ecosystem needs its first providers before it has users.
- **Who governs the shared parts?** The catalogs that consumers and providers share have to stay open and neutral, so that no single company controls the vocabulary.
- **What can the model say about trust and jurisdiction?** Data sovereignty is about control, jurisdiction and assurance levels. Whether OPM should describe them, and how, is open.

## What exists today

- [The application model and the platform model](/docs/concepts/application-and-platform-models/): what OPM models today, and the drafts that touch the platform side
- [What OPM does not do](/docs/start/what-opm-does-not-do/): the systems OPM has no counterpart for
- Enhancement 0027, [Self-Service Kinds from Published Modules](/enhancements/0027/): a draft that designs the services a platform offers to teams
- Enhancement 0026, [Module-Dictated Catalog Versions and the Generated Platform](/enhancements/0026/): a draft that changes how a platform admits catalogs
