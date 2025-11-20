# TODO

## v1

- [x] Change everything from "v0" to "v1alpha1"
- [x] Rethink the usage of # for structs. Ruleset for where it should be used MUST be defined.

### Critical (v1.0 Blockers)

- [x] Update PROVIDER_DEFINITION.md spec to match implementation (requiredResources/optionalResources pattern)
- [x] Update TRANSFORMER_MATCHING.md spec to match implementation (required/optional distinction)
- [ ] Complete `opm mod render` command implementation (currently stub at render.go:112)
- [ ] Implement secret handling mechanism (secretRef, external secret providers, secure storage) - **DEFERRED**: Design needed
- [ ] Implement standard status definition for component
- [x] Fix config file permissions to 0600/0700 (was 0644/0755, world-readable) - **FIXED**: config.cue now 0600, config dir now 0700
- [ ] Expand test coverage to 40%+ (currently 17%, no command tests, no integration tests)
- [x] Implement Kubernetes provider reference implementation in v1/providers/kubernetes/ - **COMPLETE**: 7 transformers implemented (Deployment, StatefulSet, DaemonSet, Job, CronJob, Service, PVC)

#### OCI Registry Integration (Sprints 1-2, HIGH PRIORITY)

- [ ] Define OPM mediaType specifications for all artifact types (module, bundle, template, provider, transformer)
- [ ] Implement Docker config.json reader in cli/pkg/oci/auth/config.go
- [ ] Implement OAuth bearer token flow in cli/pkg/oci/auth/token.go
- [ ] Implement registry HTTP client with automatic auth in cli/pkg/oci/client/client.go
- [ ] Implement `opm registry login <url>` command
- [ ] Implement `opm registry logout <url>` command
- [ ] Implement module artifact builder with two-layer design in cli/pkg/oci/module/build.go
- [ ] Implement .opmignore file parser in cli/pkg/oci/ignore/ignore.go (gitignore-compatible syntax)
- [ ] Implement default ignore patterns (node_modules/, .git/, cue.mod/pkg/, etc.)
- [ ] Implement blob upload (monolithic and chunked) in cli/pkg/oci/client/upload.go
- [ ] Implement manifest upload with tag management in cli/pkg/oci/client/manifest.go
- [ ] Implement `opm mod publish <path> <version>` command with --ignore-file flag
- [ ] Add progress indicators for blob/manifest uploads

### High Priority

#### OCI Registry Integration (Sprint 3)

- [ ] Implement manifest download from registry in cli/pkg/oci/client/download.go
- [ ] Implement layer extraction and verification in cli/pkg/oci/client/layers.go
- [ ] Implement module reconstruction from OCI layers in cli/pkg/oci/module/fetch.go
- [ ] Implement `opm mod get <reference>` command with --output flag
- [ ] Integrate OCI module fetching into `opm mod render` command
- [ ] Integrate OCI module fetching into `opm mod tidy` command
- [ ] Add parallel layer downloads for performance
- [ ] Add progress indicators for downloads

#### Other High Priority

- [ ] Complete registry list command implementations (currently stubs returning placeholder data)
- [ ] Implement bundle command group (init, build, render, vet, show, tidy, fix)
- [ ] Add JSON/YAML output to all commands (provider list/describe/transformers currently stub)
- [ ] Implement path traversal validation for user-provided paths
- [ ] Create missing specification documents:
  - [ ] BLUEPRINT_DEFINITION.md
  - [ ] COMPONENT_DEFINITION.md
  - [ ] SCOPE_DEFINITION.md
  - [ ] MODULE_DEFINITION.md (beyond module_redesign/)
  - [ ] RENDERER_DEFINITION.md
  - [ ] TEMPLATE_DEFINITION.md

### Medium Priority

#### OCI Registry Integration (Sprint 4)

- [ ] Implement bundle artifact builder in cli/pkg/oci/bundle/
- [ ] Implement `opm bundle publish` command
- [ ] Implement `opm bundle get` command
- [ ] Update template system to support OCI references in `opm mod init --template oci://...`
- [ ] Implement multi-registry configuration schema in cli/pkg/config/
- [ ] Implement reference parser for OCI URLs in cli/pkg/oci/reference/
- [ ] Implement content-addressed OCI cache in cli/pkg/oci/cache/
- [ ] Create cache directory structure (~/.opm/cache/oci/blobs/sha256/, manifests/, index.json)
- [ ] Implement cache invalidation logic
- [ ] Add registry search command `opm registry search <query>`
- [ ] Add registry cache management commands (clear, status, path)

#### Other Medium Priority

- [ ] Add OpenAPIv3 schema validation to Resource/Trait/Blueprint/Policy definitions
- [ ] Document label/annotation unification design decision for components
- [ ] Implement config set/get/unset/edit commands
- [ ] Implement dev tools (inspect, diff, graph, watch)
- [ ] Implement utility commands (doctor, completion, docs)
- [ ] Expand #TransformerContext with full module metadata (version, namespace, labels)
- [ ] Expand example coverage:
  - [ ] 10-15 resource examples in v1/resources/
  - [ ] 15-20 trait examples in v1/traits/
  - [ ] 10-15 policy examples in v1/policies/
  - [ ] 5-10 scope examples

### Low Priority

#### OCI Registry Integration (Sprint 5)

- [ ] Implement provider artifact builder in cli/pkg/oci/provider/
- [ ] Implement `opm provider install <reference>` command
- [ ] Implement transformer artifact builder in cli/pkg/oci/transformer/
- [ ] Implement `opm transformer install <reference>` command
- [ ] Add resumable download support for large artifacts
- [ ] Add parallel layer fetching optimization
- [ ] Implement chunked upload optimization for large modules
- [ ] Add comprehensive OCI integration tests with local registry
- [ ] Add performance benchmarks for OCI operations
- [ ] Create OCI migration guide documentation

#### Other Low Priority

- [ ] Add renderer output format validation/constraints
- [ ] Remove debug code from test files (flatten_test.go:315,422)
- [ ] Fix TOCTOU race condition in module init (use MkdirAll directly, check ErrExist)
- [ ] Add renderer scoring/ranking for multiple transformer matches
- [ ] Add transformer values conversion to CUE format
- [ ] Add deterministic sorting for provider list output
- [ ] Add deteremistic UUID to all components and module definitions
- [ ] Support the [OSCAL](https://pages.nist.gov/OSCAL/) model

### v1 Research

- [ ] Rethink how modules are designed/shipped.
  - What is a ModuleDefinition & Module & ModuleRelease
  - What is the folder structure?
  - What files must exist?
  - Should we introduce ModuleRelease again?
- [ ] Add automatic documentation generation based on special comment in the ModuleDefinition CUE code.
  - Should have a summary on what the module does.
  - Should have have an API spec for the "values".
- [ ] Every component requires a unique identity (SPIFFE/SPIRE) so that it can be utilized to grab secrets accesible to the component
- [ ] Investigate the ability to write workflows/pipelines. Tasks that execute in series, either in combination with Modules and Components or completely separately.
- [ ] Investigate the implementation of a runtime query system. The ability to query the platform for extra "not required" data. This data can help in generation but is not required for CUE-OAM to function. The inherint insecurity of this feature can be mitigated by that the query system is a fixed data struct defined in CUE. Meaning we know what the values can be, it just need to be populated at runtimne. It should include some core (builtin) fields, but should also be extendable by the platform team.
- [ ] Investigate the ability to have modules idirectly depend on another set of modules. For example a "grafana" resource would require the "grafana-operator" to exist in the platform. This dependency should be resolved when creating the catalog in some way, and that would mean the platform team can choose to install these dependencies, as they too are #ModuleDefinitions.
- [ ] Investigate the ability and use for sharing more complext components as ready LEGO like blocks to share and reuse.
- [ ] Investigate how an integration with OPA could be used for policies. The ability to define polices in rego and have that be a part of a ModuleDefinition and Module.
- [ ] Investigate Helm v4

## v1+

- [ ] Major redesign of the element registry. OPM CLI and OPM controller should not have to load elements from an registry, it should inherit the elements from the Module/Modules. For OPM controller, instead of passing in the elements into the #PlatfromCatalog we just have to pass in the modules, all elements would then be unified from the modules. For the OPM CLI, we do something similar except it is only for one element. This would still allow us to have a cache and we would get further speed increases from the fact that we only have the elements that we are actually using.

### v1+ Research

- [ ] Investigate how to redesign to improve performance while still keeping the reusability and composability part.
