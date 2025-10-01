# OPM Roadmap

> This roadmap outlines OPM's development direction organized by phases. Items are subject to change based on community feedback and priorities.

## Legend

- 🟢 In Progress
- 🔵 Planned
- 🟡 Research/RFC
- ⚪ Future Consideration

---

## Phase 1: Foundation - Module Model & System

**Goal**: Complete the Module model and system to robustly describe any resource (workloads, config, volumes, operator abstractions, CRDs)

### 1.1 Core Module System 🟢

- [x] Element type system (primitive, modifier, composite, custom)
- [x] Component and module definitions
- [x] Three-layer architecture (ModuleDefinition → Module → ModuleRelease)
- [ ] Complete core element library
  - [ ] Workload elements (Container, StatelessWorkload, StatefulWorkload, etc.)
  - [ ] Data elements (Volume, ConfigMap, Secret, Database)
  - [ ] Connectivity elements (NetworkScope, Expose)
- [ ] Module dependency resolution
- [ ] Provider transformer system foundation
- [ ] Label-based element filtering and discovery system
  - [ ] Query elements by category, platform, maturity, compliance
  - [ ] Filter registry by label selectors
  - [ ] Element compatibility checking based on labels

**Exit Criteria**: Module model can describe any type of resource including custom CRDs

### 1.2 Kubernetes Operator Integration 🔵

**Goal**: Enable Kubernetes operators (Crossplane, CNPG, etc.) to be defined as ModuleDefinitions

- [ ] Operator ModuleDefinition patterns
  - [ ] Define operator deployment (controller, webhooks, RBAC)
  - [ ] Include CRD definitions in ModuleDefinition
  - [ ] Operator lifecycle management (install, upgrade, uninstall)
- [ ] Reference implementations
  - [ ] Crossplane operator ModuleDefinition
  - [ ] CloudNativePG (CNPG) operator ModuleDefinition
  - [ ] Example third-party operator

**Exit Criteria**: Deploy and manage Kubernetes operators using OPM ModuleDefinitions

### 1.3 CRD-as-Element System 🔵

**Goal**: Enable operator CRDs to be defined as OPM Elements (primitives, modifiers or custom)

- [ ] CRD element mapping
  - [ ] CustomResourceDefinition → Element schema generation
  - [ ] Determine element classification (primitive vs modifier)
  - [ ] Support for CRD versioning (v1alpha1, v1beta1, v1)
- [ ] Element code generation from CRDs
  - [ ] Schema extraction from OpenAPI v3 specs
  - [ ] Automatic element registry updates
- [ ] Reference implementations
  - [ ] Crossplane Composition as Element
  - [ ] CNPG Cluster as Element
  - [ ] Example custom CRD as Element

**Exit Criteria**: Use operator-provided CRDs as first-class OPM elements in ModuleDefinitions

### 1.4 Kubernetes Platform Provider 🔵

**Goal**: Complete Kubernetes provider with transformers for native resources and CRD-based resources

- [ ] Native workload transformers
  - [ ] Deployment (stateless)
  - [ ] StatefulSet (stateful)
  - [ ] DaemonSet (daemon)
  - [ ] Job (task)
  - [ ] CronJob (scheduled-task)
- [ ] Networking transformers
  - [ ] Service
  - [ ] Ingress
  - [ ] NetworkPolicy
- [ ] Data transformers
  - [ ] ConfigMap
  - [ ] Secret
  - [ ] PersistentVolumeClaim
- [ ] CRD transformers
  - [ ] Dynamic transformer generation for CRD-based elements
  - [ ] Support for status reconciliation

**Exit Criteria**: Deploy complete applications to Kubernetes including operator-managed resources

### 1.5 Developer Tooling & CLI 🔵

**Goal**: CLI for working with OPM

- [ ] CLI tool (`opm` command)
  - [ ] Module validation (`opm validate`)
  - [ ] Element inspection (`opm describe element`)
  - [ ] Module scaffolding (`opm init`)
  - [ ] Deployment to platforms (`opm apply`, `opm deploy`)
  - [ ] CRD-to-Element generation (`opm generate element`)
- [ ] Module templates and examples
  - [ ] Standard application templates
  - [ ] Operator integration examples
- [ ] Clear error messages and debugging
  - [ ] CUE validation errors made user-friendly
  - [ ] Transformer debugging mode

**Exit Criteria**: Developers can create, validate, and deploy modules end-to-end using the CLI

### 1.6 Testing Framework 🟢

**Goal**: Enable automated testing and CI validation of elements, modules, and transformers

- [ ] Element validation framework
  - [ ] Schema validation tests
  - [ ] Element compatibility tests
  - [ ] Label and metadata validation
- [ ] Module validation tests
  - [ ] Component composition validation
  - [ ] Dependency resolution tests
  - [ ] Platform scope enforcement tests
- [ ] Transformer testing
  - [ ] Required/optional element satisfaction tests
  - [ ] Output resource validation
  - [ ] Platform-specific rendering tests
- [ ] CI/CD integration
  - [ ] GitHub Actions workflows
  - [ ] Pre-commit hooks for CUE formatting and validation
  - [ ] Automated regression testing
- [ ] Test utilities and fixtures
  - [ ] Sample modules for testing
  - [ ] Mock providers for unit testing
  - [ ] Test assertion helpers

**Exit Criteria**: All elements, modules, and transformers have automated tests running in CI

**Phase 1 Overall Exit Criteria**: Deploy a complete application to Kubernetes using OPM with native resources, operator-managed resources, type-safe validation, and comprehensive automated testing

---

## Phase 2: Platform Maturity

**Goal**: Production-ready platform with compliance, governance, and ecosystem

### Security & Compliance 🔵

- [ ] OSCAL framework integration
  - [ ] Component definition generation
  - [ ] Control mapping (NIST 800-53, FedRAMP, PCI-DSS, SOC2)
  - [ ] Automated compliance reports
  - [ ] Audit trail generation
- [ ] PlatformScope enforcement
- [ ] Secret management improvements
  - [ ] Secret generation patterns
  - [ ] External secret store integration

### Module Ecosystem 🔵

- [ ] Reference application showcase
  - [ ] Web applications (3-tier architecture)
  - [ ] Microservices patterns
  - [ ] Data pipelines
  - [ ] Stateful workloads (databases)
- [ ] Golden path templates
- [ ] Best practices documentation
- [ ] Module validation patterns

### Documentation & Community 🔵

- [ ] Comprehensive guides
  - [ ] Getting started tutorial
  - [ ] Element development guide
  - [ ] Provider implementation guide
  - [ ] Platform team guide
- [ ] Architecture decision records
- [ ] Community governance model
- [ ] Contribution guidelines

**Exit Criteria**: Platform teams can enforce policies and developers can deploy production workloads with confidence

---

## Phase 3: Automation & Scale

**Goal**: GitOps workflows, module registry, and operator-driven deployments

### GitOps & Operators 🔵

- [ ] Kubernetes operator for OPM
- [ ] Module lifecycle management
- [ ] ArgoCD integration
- [ ] Flux integration
- [ ] Automated rollouts and rollbacks

### Module Registry 🔵

- [ ] CUE central registry integration
- [ ] Module versioning and semver
- [ ] Module discovery and search
- [ ] Module signing and verification
- [ ] Dependency resolution

### Workflow System 🟡

- [ ] Pipeline definitions for module operations
  - [ ] Pre-deploy validation
  - [ ] Post-deploy verification
  - [ ] Upgrade/downgrade procedures
- [ ] CI/CD integration patterns
- [ ] Task orchestration

### Advanced Features 🟡

- [ ] Module bundles/stacks (multi-module deployments)
- [ ] Runtime query system (environment metadata)
- [ ] Component identity (SPIFFE/SPIRE integration)
- [ ] Cross-module dependencies (in bundles/stacks)

**Exit Criteria**: Modules can be published, discovered, and deployed through GitOps with full lifecycle automation

---

## Phase 4: Multi-Platform & Ecosystem

**Goal**: Expand beyond Kubernetes with additional providers and rich ecosystem

### Additional Providers 🟡

- [ ] Docker Compose provider
- [ ] Cloud-specific optimizations
  - [ ] AWS (ECS, EKS, Lambda)
  - [ ] Azure (AKS, Container Apps)
  - [ ] GCP (GKE, Cloud Run)
- [ ] Cross-platform validation

### Developer Ecosystem ⚪

- [ ] IDE extensions
  - [ ] VS Code extension
  - [ ] IntelliJ/JetBrains plugin
- [ ] CUE language server enhancements
- [ ] Module marketplace/hub
- [ ] Community module catalog

### Advanced Governance ⚪

- [ ] OPA integration for policy evaluation
- [ ] Multi-tenant isolation
- [ ] Cost optimization insights
- [ ] Resource quotas and limits

**Exit Criteria**: Modules are portable across multiple platforms with a thriving community ecosystem

---

## Research & Open Questions

Areas we're actively exploring:

### Workflow Strategy

- Should OPM define its own pipeline system or standardize integration with existing CI/CD tools?
- Should there be separate standards for CI/CD pipelines vs. application lifecycle operations?

### Dependency Management

- How to handle element dependencies across modules?
- Strategy for deprecating elements while maintaining backward compatibility
- Versioning strategy for elements vs. modules

### Platform Integration

- Design for runtime queries to pull environment-specific metadata
- How should platform teams curate and enforce module catalogs?
- Integration patterns with service meshes, observability platforms

### Element Evolution

- How to add new elements when the project is in wide use?
- Migration paths for breaking changes

### Element Discovery & Filtering

- Label-based element filtering and query system
- Element discovery by category, platform, maturity, compliance requirements
- Dynamic element selection based on runtime context

---

## Contributing to the Roadmap

We welcome community input on priorities and direction!

- **Feature Proposals**: Submit a PEP (Platform Enhancement Proposal) in `/enhancements/peps/`
- **Discussions**: Join [GitHub Discussions](https://github.com/open-platform-model/opm/discussions)
- **Feedback**: Comment on related GitHub issues
- **Roadmap Updates**: This roadmap is reviewed and updated regularly based on progress and feedback

---

## Inspiration & Related Work

OPM's roadmap is informed by:

- [Open Application Model (OAM)](https://oam.dev)
- [KubeVela](https://kubevela.io) - OAM implementation patterns
- [Crossplane](https://crossplane.io) - Composition and provider architecture
- [Timoni](https://timoni.sh) - CUE-based module management
- [OSCAL](https://pages.nist.gov/OSCAL/) - Security compliance framework
- [DevX](https://github.com/stakpak/devx) - Developer experience patterns and stack composition using CUE
