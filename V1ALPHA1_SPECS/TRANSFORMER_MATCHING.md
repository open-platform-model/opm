# Transformer Matching and Selection Algorithm

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-08

## Overview

This document defines the algorithm for matching OPM components to transformers during the rendering phase. The matching algorithm ensures that every component in a module finds appropriate transformer(s) to convert it into platform-specific resources.

### Key Concepts

- **Component**: A composition of Resources + Traits (after Blueprint flattening)
- **Transformer**: A function that converts components to platform resources
- **Matching**: The process of finding transformer(s) for a component
- **Selection**: Choosing the best transformer when multiple match

---

## Matching Workflow

The complete workflow from ModuleDefinition to Manifests:

```
┌─────────────────┐
│ ModuleDefinition│
│ (with Blueprints│
│ Components)     │
└────────┬────────┘
         │
         ▼
   [BIND VALUES]
         │
         ▼
┌─────────────────┐
│ ModuleRelease   │
│ (Concrete vals) │
└────────┬────────┘
         │
         ▼
  [LOAD PROVIDER]  ← Phase 2.1 (cli/pkg/provider)
         │
         ▼
┌─────────────────┐
│ Provider        │
│ (Transformers)  │
└────────┬────────┘
         │
         ▼
For each component:
    │
    ▼
[MATCH TRANSFORMERS]  ← This Document (Phase 2.2)
    │
    ▼
┌─────────────────┐
│ Matched         │
│ Transformer(s)  │
└────────┬────────┘
    │
    ▼
[EXECUTE TRANSFORM]  ← Phase 2.2 (cli/pkg/transformer)
    │
    ▼
┌─────────────────┐
│ Platform        │
│ Resources       │
└────────┬────────┘
         │
         ▼
  [COLLECT ALL]
         │
         ▼
┌─────────────────┐
│ All Platform    │
│ Resources       │
└────────┬────────┘
         │
         ▼
  [SELECT RENDERER]  ← Phase 2.3 (cli/pkg/renderer)
         │
         ▼
┌─────────────────┐
│ Renderer        │
└────────┬────────┘
         │
         ▼
  [RENDER OUTPUT]
         │
         ▼
┌─────────────────┐
│ Manifests       │
│ (YAML/JSON)     │
└─────────────────┘
```

---

## Component Analysis

Before matching, analyze each component to extract matchable information.

### Step 1: Extract Component Signature

```go
type ComponentSignature struct {
    Name         string
    Resources    []string  // Resource FQNs from component spec
    Traits       []string  // Trait FQNs from component spec
    Policies     []string  // Policy FQNs from component spec (if any)
    Labels       map[string]string
    Provenance   *Provenance  // Blueprint origin (if any)
}
```

**Algorithm:**

```
function ExtractComponentSignature(component Component) -> ComponentSignature:
    sig := ComponentSignature{
        Name:   component.Metadata.Name,
        Labels: component.Metadata.Labels,
    }

    // Extract Resources from spec
    for fieldName, fieldValue in component.Spec:
        if IsResourceField(fieldName):
            resourceFQN := GetResourceFQN(fieldName, component)
            sig.Resources.append(resourceFQN)

    // Extract Traits from spec
    for fieldName, fieldValue in component.Spec:
        if IsTraitField(fieldName):
            traitFQN := GetTraitFQN(fieldName, component)
            sig.Traits.append(traitFQN)

    // Extract Policies if present
    if component.Metadata.Policies != nil:
        for policyRef in component.Metadata.Policies:
            sig.Policies.append(policyRef)

    // Extract provenance if component came from Blueprint
    if component.Metadata.Provenance != nil:
        sig.Provenance = component.Metadata.Provenance

    return sig
```

**Example:**

```cue
// Component after flattening
webServer: {
    metadata: {
        name: "web-server"
        labels: {
            "core.opm.dev/workload-type": "stateless"
        }
        provenance: {
            blueprint: "opm.dev/blueprints@v1#StatelessWorkload"
        }
    }
    spec: {
        container: {...}    // Resource: opm.dev/resources/workload@v1#Container
        replicas: {...}     // Trait: opm.dev/traits/scaling@v1#Replicas
        expose: {...}       // Trait: opm.dev/traits/network@v1#Expose
    }
}

// Extracted signature
{
    Name: "web-server",
    Resources: ["opm.dev/resources/workload@v1#Container"],
    Traits: [
        "opm.dev/traits/scaling@v1#Replicas",
        "opm.dev/traits/network@v1#Expose"
    ],
    Policies: [],
    Labels: {"core.opm.dev/workload-type": "stateless"},
    Provenance: {Blueprint: "opm.dev/blueprints@v1#StatelessWorkload"}
}
```

---

## Transformer Matching Algorithm

### Step 2: Find Candidate Transformers

For a component signature, find all transformers that CAN handle it.

```go
type TransformerCandidate struct {
    Transformer  *Transformer
    MatchScore   int
    MatchReasons []string
}
```

**Algorithm:**

```
function FindCandidateTransformers(
    sig ComponentSignature,
    provider Provider
) -> []TransformerCandidate:

    candidates := []

    for transformerFQN, transformer in provider.Transformers:
        score := 0
        reasons := []

        // REQUIREMENT 1: Component MUST have ALL transformer's requiredResources
        requiredResourceFQNs := Keys(transformer.RequiredResources)
        if !ContainsAll(sig.Resources, requiredResourceFQNs):
            continue  // Skip - component missing required resources

        // REQUIREMENT 2: Component MUST have ALL transformer's requiredTraits
        requiredTraitFQNs := Keys(transformer.RequiredTraits)
        if !ContainsAll(sig.Traits, requiredTraitFQNs):
            continue  // Skip - component missing required traits

        // REQUIREMENT 3: Component MUST have ALL transformer's requiredPolicies
        requiredPolicyFQNs := Keys(transformer.RequiredPolicies)
        if !ContainsAll(sig.Policies, requiredPolicyFQNs):
            continue  // Skip - component missing required policies

        // Base score for meeting all requirements
        score += 100
        reasons.append("Meets all required resources, traits, and policies")

        // BONUS 1: Optional resource coverage
        optionalResourceFQNs := Keys(transformer.OptionalResources)
        handledOptionalResources := Intersection(sig.Resources, optionalResourceFQNs)
        if len(optionalResourceFQNs) > 0:
            optionalResourceCoverage := len(handledOptionalResources) / len(optionalResourceFQNs)
            score += int(optionalResourceCoverage * 30)  // Up to 30 points
            if len(handledOptionalResources) > 0:
                reasons.append(fmt.Sprintf("Handles %d/%d optional resources",
                    len(handledOptionalResources), len(optionalResourceFQNs)))

        // BONUS 2: Optional trait coverage
        optionalTraitFQNs := Keys(transformer.OptionalTraits)
        handledOptionalTraits := Intersection(sig.Traits, optionalTraitFQNs)
        if len(optionalTraitFQNs) > 0:
            optionalTraitCoverage := len(handledOptionalTraits) / len(optionalTraitFQNs)
            score += int(optionalTraitCoverage * 40)  // Up to 40 points
            if len(handledOptionalTraits) > 0:
                reasons.append(fmt.Sprintf("Handles %d/%d optional traits",
                    len(handledOptionalTraits), len(optionalTraitFQNs)))

        // BONUS 3: Optional policy coverage
        optionalPolicyFQNs := Keys(transformer.OptionalPolicies)
        handledOptionalPolicies := Intersection(sig.Policies, optionalPolicyFQNs)
        if len(handledOptionalPolicies) > 0:
            score += len(handledOptionalPolicies) * 20
            reasons.append(fmt.Sprintf("Handles %d optional policies", len(handledOptionalPolicies)))

        // BONUS 4: Label matching for pattern-based selection
        labelMatches := 0
        for key, value in sig.Labels:
            if transformer.Metadata.Labels[key] == value:
                labelMatches++
                score += 10  // 10 points per label match
                reasons.append(fmt.Sprintf("Label match: %s=%s", key, value))

        // BONUS 5: Priority label
        if priorityStr, ok := transformer.Metadata.Labels["core.opm.dev/priority"]:
            priority := ParseInt(priorityStr)
            score += priority
            reasons.append(fmt.Sprintf("Priority: %d", priority))

        candidates.append(TransformerCandidate{
            Transformer:  transformer,
            MatchScore:   score,
            MatchReasons: reasons,
        })

    return candidates
```

### Step 3: Select Best Transformer(s)

From candidates, select the transformer(s) to use.

**Algorithm:**

```
function SelectTransformers(
    candidates []TransformerCandidate,
    sig ComponentSignature,
    strategy SelectionStrategy
) -> []Transformer, error:

    if len(candidates) == 0:
        return error("No transformers found for component %s", sig.Name)

    // Sort by score (descending)
    sort(candidates, by=MatchScore, descending=true)

    switch strategy:

    case "best":
        // Select single best transformer
        best := candidates[0]

        // Check for ambiguity
        if len(candidates) > 1 && candidates[1].MatchScore == best.MatchScore:
            return error("Ambiguous transformer match for component %s: %v",
                sig.Name, [candidates[0].Transformer.Name, candidates[1].Transformer.Name])

        return [best.Transformer], nil

    case "all":
        // Use all matching transformers (for multi-resource components)
        transformers := []
        for candidate in candidates:
            transformers.append(candidate.Transformer)
        return transformers, nil

    case "threshold":
        // Use all transformers above score threshold
        threshold := 100  // Only resource matches or better
        transformers := []
        for candidate in candidates:
            if candidate.MatchScore >= threshold:
                transformers.append(candidate.Transformer)
        return transformers, nil

    default:
        return error("Unknown selection strategy: %s", strategy)
```

**Selection Strategies:**

1. **"best"** (default): Select single transformer with highest score
   - Fail if multiple transformers have same top score (ambiguous)
   - Use for single-resource components

2. **"all"**: Use all matching transformers
   - Useful when component needs multiple platform resources
   - Example: Container resource → Deployment + Service (from Expose trait)

3. **"threshold"**: Use all transformers above minimum score
   - More lenient than "best", more selective than "all"
   - Good for components with multiple optional traits

---

## Match Scoring System

The scoring system prioritizes different match criteria:

| Criterion | Points | Notes |
|-----------|--------|-------|
| Required elements match | 100 | Base score, ALL required resources/traits/policies MUST match |
| Optional resource coverage | 0-30 | Proportional to % of optional resources handled |
| Optional trait coverage | 0-40 | Proportional to % of optional traits handled |
| Optional policy handling | 20 each | Additional policies transformer can enforce |
| Label match | 10 each | Pattern-based matching for Blueprint provenance |
| Priority label | Variable | Explicit priority from transformer metadata |

**Example Scoring:**

```
Component:
  Resources: [Container]
  Traits: [Replicas, Expose, HealthCheck]
  Labels: {workload-type: stateless}

Transformer A (DeploymentTransformer):
  RequiredResources: [Container]
  OptionalTraits: [Replicas, HealthCheck, UpdateStrategy]  ← Handles 2/3 component traits
  Labels: {workload-type: stateless}
  Priority: 10

  Score:
    100 (all requirements met)
    + 26 (2/3 optional traits handled = 66% coverage × 40 points)
    + 10 (label match: workload-type)
    + 10 (priority)
    = 146

Transformer B (ServiceTransformer):
  RequiredResources: [Container]
  RequiredTraits: [Expose]  ← Component has Expose, requirement met
  OptionalTraits: []
  Labels: {workload-type: stateless}
  Priority: 5

  Score:
    100 (all requirements met)
    + 0 (no optional traits to score)
    + 10 (label match: workload-type)
    + 5 (priority)
    = 115

Note: ServiceTransformer REQUIRES Expose trait, so it only matches components with Expose.
DeploymentTransformer has no required traits, so it matches any component with Container.
```

In this example:

- **Strategy "best"**: Would select Transformer A only
- **Strategy "all"**: Would use both A and B (generates Deployment + Service)
- **Strategy "threshold" (100)**: Would use both A and B

---

## Special Cases

### Case 1: Multi-Transformer Components

Some components require multiple transformers to fully implement.

**Example:** Stateless workload with exposed service

```cue
webServer: {
    spec: {
        container: {...}  // → DeploymentTransformer → Deployment
        replicas: {...}   // → (included in Deployment)
        expose: {...}     // → ServiceTransformer → Service
    }
}
```

**Strategy:** Use "all" selection strategy

- DeploymentTransformer handles Container + Replicas
- ServiceTransformer handles Container + Expose
- Output: [Deployment, Service]

### Case 2: Unhandled Traits

If a component has traits not handled by any matched transformer:

```cue
component: {
    spec: {
        container: {...}
        customTrait: {...}  // No transformer handles this
    }
}
```

**Behavior:**

- **Warning**: Log warning about unhandled trait
- **Continue**: Still transform with available transformers
- **Validate**: Optionally fail with `--strict` flag

### Case 3: Conflicting Transformers

If multiple transformers handle the same Resource+Trait combination with equal scores:

```
Transformer A: Resources=[Container], Traits=[Replicas], Score=150
Transformer B: Resources=[Container], Traits=[Replicas], Score=150
```

**Behavior:**

- **Error**: Fail with ambiguous match error
- **Resolution**: Provider must add priority labels or user must be more specific

### Case 4: Provenance-Based Matching

Use Blueprint provenance for enhanced matching:

```cue
component: {
    metadata: {
        provenance: {
            blueprint: "opm.dev/blueprints@v1#StatelessWorkload"
        }
    }
}
```

**Algorithm Enhancement:**

```
if sig.Provenance != nil && sig.Provenance.Blueprint != nil:
    // Add bonus points for transformers with matching blueprint label
    blueprintLabel := transformer.Metadata.Labels["core.opm.dev/blueprint"]
    if blueprintLabel == sig.Provenance.Blueprint:
        score += 25
        reasons.append("Blueprint match")
```

---

## Implementation Pseudocode

Complete matching flow for CLI implementation:

```go
package transformer

type Matcher struct {
    provider Provider
    strategy SelectionStrategy
    strict   bool  // Fail on unhandled traits
}

func (m *Matcher) MatchComponent(component Component) ([]Transformer, error) {
    // Step 1: Extract signature
    sig := ExtractComponentSignature(component)

    // Step 2: Find candidates
    candidates := FindCandidateTransformers(sig, m.provider)

    // Step 3: Validate
    if len(candidates) == 0 {
        return nil, fmt.Errorf(
            "no transformers found for component %s with resources %v",
            sig.Name, sig.Resources)
    }

    // Step 4: Check for unhandled traits
    if m.strict {
        unhandledTraits := m.findUnhandledTraits(sig, candidates)
        if len(unhandledTraits) > 0 {
            return nil, fmt.Errorf(
                "component %s has unhandled traits: %v",
                sig.Name, unhandledTraits)
        }
    }

    // Step 5: Select transformers
    transformers, err := SelectTransformers(candidates, sig, m.strategy)
    if err != nil {
        return nil, err
    }

    return transformers, nil
}

func (m *Matcher) MatchModule(module Module) (map[string][]Transformer, error) {
    results := make(map[string][]Transformer)

    for componentName, component := range module.Components {
        transformers, err := m.MatchComponent(component)
        if err != nil {
            return nil, fmt.Errorf("component %s: %w", componentName, err)
        }
        results[componentName] = transformers
    }

    return results, nil
}
```

---

## Validation Rules

### Pre-Matching Validation

Before matching:

- ✅ Component must have at least one Resource
- ✅ All Resource FQNs must be valid
- ✅ All Trait FQNs must be valid
- ✅ All Policy FQNs must be valid (if present)
- ✅ Provider must have at least one transformer

### Post-Matching Validation

After matching:

- ✅ At least one transformer matched
- ✅ Each matched transformer's `requiredResources` are present in component
- ✅ Each matched transformer's `requiredTraits` are present in component
- ✅ Each matched transformer's `requiredPolicies` are present in component
- ⚠️ Component resources not in any transformer's required/optional maps → Warning
- ⚠️ Component traits not in any transformer's required/optional maps → Warning (or error with --strict)
- ⚠️ Component policies not in any transformer's required/optional maps → Warning
- ❌ Ambiguous matches (same score) → Error
- ❌ No transformers match → Error
- ❌ Component missing required elements from matched transformer → Error

### Execution Validation

Before executing transformers:

- ✅ Transformer declarations match actual component spec
- ✅ Component spec satisfies transformer requirements
- ✅ Context has all required fields

---

## CLI Flags and Configuration

### Matching Configuration

```bash
opm mod render module.cue \
    --provider kubernetes \
    --strategy all \           # best | all (default) | threshold
    --strict \                 # Fail on unhandled traits
    --verbose                  # Show match scoring details
```

**Flags:**

- `--strategy` - Selection strategy: best, **all (default)**, threshold
  - **all**: Use all matching transformers (enables multi-resource output like Deployment + Service)
  - best: Single highest-scoring transformer only
  - threshold: All transformers above minimum score
- `--strict` - Fail on unhandled traits instead of warning
- `--verbose` - Print match scores and reasons for debugging
- `--dry-run` - Show matches without executing transforms

### Debug Output

With `--verbose`, print match details:

```
Component: web-server
  Resources: [opm.dev/resources/workload@v1#Container]
  Traits: [
    opm.dev/traits/scaling@v1#Replicas,
    opm.dev/traits/network@v1#Expose
  ]

Candidates:
  1. DeploymentTransformer (score: 146)
     - Meets all required resources, traits, and policies
     - Handles 2/3 optional traits (Replicas, HealthCheck)
     - Label match: workload-type=stateless
     - Priority: 10

  2. ServiceTransformer (score: 115)
     - Meets all required resources, traits, and policies
     - Required trait Expose is present
     - Label match: workload-type=stateless
     - Priority: 5

Selected (strategy=all):
  - DeploymentTransformer
  - ServiceTransformer

Output:
  - Deployment (from DeploymentTransformer)
  - Service (from ServiceTransformer)
```

---

## Error Messages

### No Transformers Found

```
Error: No transformers found for component "web-server"
  Resources required: [opm.dev/resources/workload@v1#Container]
  Traits declared: [opm.dev/traits/scaling@v1#Replicas]

  Provider "kubernetes" has the following transformers:
    - DeploymentTransformer (resources: [opm.dev/resources/workload@v1#Container])
    - StatefulSetTransformer (resources: [opm.dev/resources/workload@v1#Container, opm.dev/resources/storage@v1#Volume])

  Hint: Component requires Container, but no transformer declares exactly this combination.
```

### Ambiguous Match

```
Error: Ambiguous transformer match for component "web-server"
  Multiple transformers have the same score (150):
    - DeploymentTransformer
    - CustomDeploymentTransformer

  Resolution:
    1. Add priority label to one transformer:
       labels: {"core.opm.dev/priority": "10"}

    2. Use more specific component labels

    3. Manually specify transformer with --use-transformer flag
```

### Unhandled Traits (strict mode)

```
Error: Component "web-server" has unhandled traits (--strict mode)
  Unhandled:
    - opm.dev/traits/custom@v1#CustomTrait

  Matched transformers:
    - DeploymentTransformer (handles: Replicas, HealthCheck)

  Resolution:
    1. Add transformer that handles CustomTrait
    2. Remove --strict flag to allow warnings instead
    3. Remove CustomTrait from component
```

---

## Testing Strategy

### Unit Tests

Test matching logic in isolation:

```go
func TestFindCandidateTransformers(t *testing.T) {
    sig := ComponentSignature{
        Name:      "test-component",
        Resources: []string{"opm.dev/resources/workload@v1#Container"},
        Traits:    []string{"opm.dev/traits/scaling@v1#Replicas"},
    }

    provider := LoadTestProvider("kubernetes")

    candidates := FindCandidateTransformers(sig, provider)

    assert.Len(t, candidates, 2)
    assert.Equal(t, "DeploymentTransformer", candidates[0].Transformer.Name)
}
```

### Integration Tests

Test with real modules and providers:

```go
func TestMatchModule(t *testing.T) {
    module := LoadTestModule("testdata/web-app.cue")
    provider := LoadProvider("providers/kubernetes")

    matcher := &Matcher{
        provider: provider,
        strategy: StrategyAll,
        strict:   false,
    }

    results, err := matcher.MatchModule(module)

    require.NoError(t, err)
    assert.Contains(t, results, "web-server")
    assert.Len(t, results["web-server"], 2) // Deployment + Service
}
```

### Edge Cases

Test edge cases:

- Empty component (no resources)
- Resource-only component (no traits)
- Trait-only component (invalid, should error)
- All traits unhandled
- Ambiguous matches
- Missing provider
- Invalid FQNs

---

## Performance Considerations

### Optimization Strategies

1. **Cache Transformer Declarations**
   - Pre-compute transformer capabilities on provider load
   - Index transformers by resource FQN

2. **Parallel Matching**
   - Match components concurrently (they're independent)
   - Use goroutines/threads for large modules

3. **Early Exit**
   - Stop searching after first match in "best" strategy
   - Skip transformers with incomplete resource coverage

4. **Smart Indexing**

   ```go
   type ProviderIndex struct {
       byResource map[string][]*Transformer  // Resource FQN → Transformers
       byTrait    map[string][]*Transformer  // Trait FQN → Transformers
       byLabel    map[string][]*Transformer  // Label → Transformers
   }
   ```

### Benchmarking

Expected performance targets:

- **Small module** (1-10 components): < 10ms
- **Medium module** (10-100 components): < 100ms
- **Large module** (100-1000 components): < 1s

---

## Related Specifications

- [Provider Definition](PROVIDER_DEFINITION.md) - Provider and Transformer structure
- [Component Definition](COMPONENT_DEFINITION.md) - Component structure
- [Module Definition](MODULE_DEFINITION.md) - Module structure
- [CLI Implementation](cli/CLI_IMPLEMENTATION_DECISIONS.md) - CLI design

---

**Status**: This specification is in draft status and will be refined during CLI implementation.
