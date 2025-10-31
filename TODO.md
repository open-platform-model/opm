# TODO

## v0

- [ ] Docs: Start with WHY, then WHAT then HOW. Then quickstart
- [ ] Go through all element "Specs" and add sane default to relevant values.
  - **Status**: PARTIALLY COMPLETE - Some defaults exist (e.g., `Replicas.count: int | *1`, `Container.protocol: *"TCP"`), needs comprehensive review
- [x] ~~Refactor how Modifier elements points out what primitive elements they are compatible with.~~
  - **Status**: COMPLETE - `modifies: []` field exists
- [x] ~~Investigate in replacing workloadType with "hints" or "annotations" in element. Would function similarly to labels in #Element but would NOT be used for categorization or filtering. Would have workloadType, and could be expanded in the future with more fields.~~
  - **Completed 2025-10-02**: Implemented annotations system
  - Replaced `workloadType?: #WorkloadTypes` field with `labels?: [string]: string` map
  - Workload type now specified via `"core.opm.dev/workload-type"` label
- [x] ~~Implement standard status definition for module, should inherit from components in some way.~~
  - **Completed**: Module status implemented in `module.cue`
  - `#ModuleDefinition.#status`: Has `componentCount` and `scopeCount` fields
  - `#Module.#status`: Extended with `#allComponents` aggregation and counts
  - Note: Component-level status still pending (see above)

## v1

- [ ] Change everything from "v0" to "v1alpha1"
- [ ] Rethink the usage of # for structs. Ruleset for where it should be used MUST be defined.
- [ ] Rename #Element.name to #Element.#kind, just like everything else. Also rename #Element.kind to #Element.type to not confuse people.
- [ ] Implement standard status definition for component.
- [ ] Find a better way to handle secrets. Maybe a way to generate. Maybe a way to inform the platform team of what the secrets should be and how they should look (an informed handoff). Secrets should be implemented by the platform so that they are actual secrets (today we are just templating values, which is insecure). For K8s this would mean a secret being referenced in a Container.env would create the secret and then reference it in the container. This MUST be solved.
- [ ] Ability to bundle several Modules into a Bundle, that can be deployed as a whole into a platform. Support scopes in bundles.
- [ ] Add deteremistic UUID to all components and module definitions.
- [ ] Support the [OSCAL](https://pages.nist.gov/OSCAL/) model

### v1 Research

- [ ] Rethink how modules are designed/shipped.
  - What is a ModuleDefinition & Module & ModuleRelease
  - What is the folder structure?
  - What files must exist?
  - Should we introduce ModuleRelease again?
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
