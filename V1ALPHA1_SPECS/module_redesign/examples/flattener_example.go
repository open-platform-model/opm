// Package main demonstrates a simplified module flattener implementation
//
// This example shows how to flatten a ModuleDefinition (with composites)
// into a Module IR (with only primitives and modifiers).
//
// Key operations:
// 1. Load ModuleDefinition CUE value
// 2. Extract components
// 3. Resolve composite elements to primitives
// 4. Inline element schemas
// 5. Generate flattened Module output
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"sort"
	"strings"
	"time"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/format"
)

const (
	version = "v0.1.0"
)

// Element represents a resolved element with inlined schema
type Element struct {
	FQN         string
	Name        string
	Kind        string // "primitive", "modifier", "composite"
	APIVersion  string
	Target      []string
	Schema      cue.Value
	Composes    []string // For composites
	Modifies    []string // For modifiers
	Labels      map[string]string
	Description string
	Hash        string
	Provenance  ProvenanceInfo
}

// ProvenanceInfo tracks where an element came from
type ProvenanceInfo struct {
	SourceComposite string
	ViaComposite    string
	ElementHash     string
}

// Flattener handles ModuleDefinition → Module transformation
type Flattener struct {
	ctx          *cue.Context
	elementCache map[string]*Element
	version      string
}

// NewFlattener creates a new flattener instance
func NewFlattener(ctx *cue.Context) *Flattener {
	return &Flattener{
		ctx:          ctx,
		elementCache: make(map[string]*Element),
		version:      version,
	}
}

// Flatten converts a ModuleDefinition to a Module (IR)
func (f *Flattener) Flatten(moduleDefValue cue.Value) (cue.Value, error) {
	log.Println("Starting flattening process...")

	// Extract module metadata
	metadataValue := moduleDefValue.LookupPath(cue.ParsePath("#metadata"))
	if !metadataValue.Exists() {
		return cue.Value{}, fmt.Errorf("module metadata not found")
	}

	// Process each component
	componentsValue := moduleDefValue.LookupPath(cue.ParsePath("components"))
	if !componentsValue.Exists() {
		return cue.Value{}, fmt.Errorf("components not found")
	}

	flattenedComponents := make(map[string]*ComponentIR)

	componentsIter, err := componentsValue.Fields(cue.All())
	if err != nil {
		return cue.Value{}, fmt.Errorf("iterate components: %w", err)
	}

	for componentsIter.Next() {
		compID := componentsIter.Label()
		compValue := componentsIter.Value()

		log.Printf("Flattening component: %s", compID)

		flatComp, err := f.flattenComponent(compID, compValue)
		if err != nil {
			return cue.Value{}, fmt.Errorf("flatten component %s: %w", compID, err)
		}

		flattenedComponents[compID] = flatComp
		log.Printf("  ✓ Expanded to %d primitives/modifiers", len(flatComp.Elements))
	}

	// Build output Module structure
	moduleValue, err := f.buildModuleValue(moduleDefValue, flattenedComponents)
	if err != nil {
		return cue.Value{}, fmt.Errorf("build module value: %w", err)
	}

	log.Println("Flattening complete!")
	return moduleValue, nil
}

// ComponentIR represents a flattened component
type ComponentIR struct {
	ID          string
	Metadata    cue.Value
	Elements    map[string]*Element // Only primitives + modifiers
	DataFields  cue.Value
	Provenance  []string // List of source composites
}

// flattenComponent processes a single component
func (f *Flattener) flattenComponent(id string, compValue cue.Value) (*ComponentIR, error) {
	comp := &ComponentIR{
		ID:       id,
		Elements: make(map[string]*Element),
		Metadata: compValue.LookupPath(cue.ParsePath("#metadata")),
	}

	// Extract component elements
	elementsValue := compValue.LookupPath(cue.ParsePath("#elements"))
	if !elementsValue.Exists() {
		return comp, nil // No elements, return empty
	}

	elemIter, err := elementsValue.Fields(cue.All())
	if err != nil {
		return nil, fmt.Errorf("iterate elements: %w", err)
	}

	for elemIter.Next() {
		elemFQN := elemIter.Label()
		elemValue := elemIter.Value()

		log.Printf("    Processing element: %s", elemFQN)

		// Resolve this element
		resolvedElem, err := f.resolveElement(elemFQN, elemValue)
		if err != nil {
			return nil, fmt.Errorf("resolve element %s: %w", elemFQN, err)
		}

		// If composite, expand to primitives/modifiers
		if resolvedElem.Kind == "composite" {
			log.Printf("      Expanding composite: %s", elemFQN)

			primitives, err := f.expandComposite(resolvedElem, elemFQN)
			if err != nil {
				return nil, fmt.Errorf("expand composite %s: %w", elemFQN, err)
			}

			// Add all primitives to component
			for _, prim := range primitives {
				comp.Elements[prim.FQN] = prim
				log.Printf("        → %s (%s)", prim.Name, prim.Kind)
			}

			// Track provenance
			comp.Provenance = append(comp.Provenance, resolvedElem.FQN)
		} else {
			// Primitive or modifier - add directly
			comp.Elements[resolvedElem.FQN] = resolvedElem
			log.Printf("      → %s (%s)", resolvedElem.Name, resolvedElem.Kind)
		}
	}

	// Store data fields (preserve as-is)
	comp.DataFields = compValue

	return comp, nil
}

// expandComposite recursively expands a composite element to primitives/modifiers
func (f *Flattener) expandComposite(composite *Element, originFQN string) ([]*Element, error) {
	var primitives []*Element

	for _, composedFQN := range composite.Composes {
		log.Printf("        Resolving composed element: %s", composedFQN)

		// Resolve composed element (needs to look it up from element registry)
		// For this example, we'll simulate by checking cache
		composedElem, err := f.resolveElementByFQN(composedFQN)
		if err != nil {
			// In real implementation, would fetch from element registry
			log.Printf("        Warning: Could not resolve %s (would fetch from registry)", composedFQN)
			continue
		}

		// Recursively expand if composite
		if composedElem.Kind == "composite" {
			subPrimitives, err := f.expandComposite(composedElem, originFQN)
			if err != nil {
				return nil, fmt.Errorf("expand sub-composite %s: %w", composedFQN, err)
			}
			primitives = append(primitives, subPrimitives...)
		} else {
			// Add primitive or modifier with provenance
			composedElem.Provenance.SourceComposite = originFQN
			primitives = append(primitives, composedElem)
		}
	}

	return primitives, nil
}

// resolveElement inlines element schema and computes hash
func (f *Flattener) resolveElement(fqn string, elemValue cue.Value) (*Element, error) {
	// Check cache first
	if cached, ok := f.elementCache[fqn]; ok {
		return cached, nil
	}

	elem := &Element{
		FQN:    fqn,
		Labels: make(map[string]string),
	}

	// Extract element fields
	if nameValue := elemValue.LookupPath(cue.ParsePath("name")); nameValue.Exists() {
		name, err := nameValue.String()
		if err == nil {
			elem.Name = name
		}
	}

	if kindValue := elemValue.LookupPath(cue.ParsePath("kind")); kindValue.Exists() {
		kind, err := kindValue.String()
		if err == nil {
			elem.Kind = kind
		}
	}

	if apiValue := elemValue.LookupPath(cue.ParsePath("#apiVersion")); apiValue.Exists() {
		api, err := apiValue.String()
		if err == nil {
			elem.APIVersion = api
		}
	}

	// Extract target
	if targetValue := elemValue.LookupPath(cue.ParsePath("target")); targetValue.Exists() {
		targetIter, _ := targetValue.List()
		for targetIter.Next() {
			if t, err := targetIter.Value().String(); err == nil {
				elem.Target = append(elem.Target, t)
			}
		}
	}

	// Inline schema (this is the key operation)
	schemaValue := elemValue.LookupPath(cue.ParsePath("schema"))
	if schemaValue.Exists() {
		elem.Schema = schemaValue
	}

	// Extract composes (for composites)
	if elem.Kind == "composite" {
		composesValue := elemValue.LookupPath(cue.ParsePath("composes"))
		if composesValue.Exists() {
			composesIter, _ := composesValue.List()
			for composesIter.Next() {
				if c, err := composesIter.Value().String(); err == nil {
					elem.Composes = append(elem.Composes, c)
				}
			}
		}
	}

	// Extract modifies (for modifiers)
	if elem.Kind == "modifier" {
		modifiesValue := elemValue.LookupPath(cue.ParsePath("modifies"))
		if modifiesValue.Exists() {
			modifiesIter, _ := modifiesValue.List()
			for modifiesIter.Next() {
				if m, err := modifiesIter.Value().String(); err == nil {
					elem.Modifies = append(elem.Modifies, m)
				}
			}
		}
	}

	// Extract labels
	if labelsValue := elemValue.LookupPath(cue.ParsePath("labels")); labelsValue.Exists() {
		labelsIter, _ := labelsValue.Fields(cue.All())
		for labelsIter.Next() {
			if v, err := labelsIter.Value().String(); err == nil {
				elem.Labels[labelsIter.Label()] = v
			}
		}
	}

	// Extract description
	if descValue := elemValue.LookupPath(cue.ParsePath("description")); descValue.Exists() {
		if desc, err := descValue.String(); err == nil {
			elem.Description = desc
		}
	}

	// Compute hash
	elem.Hash = f.computeElementHash(elem)

	// Cache and return
	f.elementCache[fqn] = elem
	return elem, nil
}

// resolveElementByFQN looks up an element by FQN (from registry or cache)
func (f *Flattener) resolveElementByFQN(fqn string) (*Element, error) {
	// Check cache
	if cached, ok := f.elementCache[fqn]; ok {
		return cached, nil
	}

	// In real implementation, would fetch from element registry
	// For this example, return error
	return nil, fmt.Errorf("element not found in cache: %s", fqn)
}

// computeElementHash computes a deterministic hash of element content
func (f *Flattener) computeElementHash(elem *Element) string {
	// Hash key components
	h := sha256.New()
	h.Write([]byte(elem.FQN))
	h.Write([]byte(elem.Kind))
	h.Write([]byte(elem.APIVersion))

	// Hash schema (if exists)
	if elem.Schema.Exists() {
		schemaBytes, _ := format.Node(elem.Schema.Syntax())
		h.Write(schemaBytes)
	}

	// Hash composes/modifies
	for _, c := range elem.Composes {
		h.Write([]byte(c))
	}
	for _, m := range elem.Modifies {
		h.Write([]byte(m))
	}

	return hex.EncodeToString(h.Sum(nil))[:16] // First 16 chars
}

// buildModuleValue constructs the output Module CUE value
func (f *Flattener) buildModuleValue(
	originalModule cue.Value,
	components map[string]*ComponentIR,
) (cue.Value, error) {
	// Build CUE structure for flattened module
	var sb strings.Builder

	sb.WriteString("package generated\n\n")
	sb.WriteString("import opm \"github.com/open-platform-model/core\"\n\n")
	sb.WriteString("module: opm.#ModuleIR & {\n")

	// Add metadata with provenance
	sb.WriteString("  #metadata: {\n")

	// Copy original metadata
	metadataValue := originalModule.LookupPath(cue.ParsePath("#metadata"))
	if metadataValue.Exists() {
		metadataIter, _ := metadataValue.Fields(cue.All())
		for metadataIter.Next() {
			label := metadataIter.Label()
			value := metadataIter.Value()

			// Special handling for different field types
			if label == "labels" || label == "annotations" {
				sb.WriteString(fmt.Sprintf("    %s: {\n", label))
				subIter, _ := value.Fields(cue.All())
				for subIter.Next() {
					if v, err := subIter.Value().String(); err == nil {
						sb.WriteString(fmt.Sprintf("      \"%s\": \"%s\"\n", subIter.Label(), v))
					}
				}
				sb.WriteString("    }\n")
			} else {
				if v, err := value.String(); err == nil {
					sb.WriteString(fmt.Sprintf("    %s: \"%s\"\n", label, v))
				}
			}
		}
	}

	// Add provenance annotations
	sb.WriteString("    annotations: {\n")
	sb.WriteString("      \"opm.dev/flattened\": \"true\"\n")
	sb.WriteString(fmt.Sprintf("      \"opm.dev/flattener\": \"%s\"\n", f.version))
	sb.WriteString(fmt.Sprintf("      \"opm.dev/flattened-at\": \"%s\"\n", time.Now().Format(time.RFC3339)))
	sb.WriteString("    }\n")
	sb.WriteString("  }\n\n")

	// Add components
	sb.WriteString("  components: {\n")

	// Sort component IDs for deterministic output
	componentIDs := make([]string, 0, len(components))
	for id := range components {
		componentIDs = append(componentIDs, id)
	}
	sort.Strings(componentIDs)

	for _, compID := range componentIDs {
		comp := components[compID]
		sb.WriteString(fmt.Sprintf("    %s: {\n", compID))

		// Add provenance annotation
		if len(comp.Provenance) > 0 {
			sb.WriteString("      #metadata: {\n")
			sb.WriteString("        annotations: {\n")
			sb.WriteString(fmt.Sprintf("          \"opm.dev/origin-composite\": \"%s\"\n", comp.Provenance[0]))
			sb.WriteString(fmt.Sprintf("          \"opm.dev/composed-of\": \"%s\"\n", strings.Join(getElementFQNs(comp.Elements), ",")))
			sb.WriteString("        }\n")
			sb.WriteString("      }\n")
		}

		// Add elements (sorted for determinism)
		sb.WriteString("      #elements: {\n")

		elementFQNs := make([]string, 0, len(comp.Elements))
		for fqn := range comp.Elements {
			elementFQNs = append(elementFQNs, fqn)
		}
		sort.Strings(elementFQNs)

		for _, fqn := range elementFQNs {
			elem := comp.Elements[fqn]
			sb.WriteString(fmt.Sprintf("        \"%s\": {\n", fqn))
			sb.WriteString(fmt.Sprintf("          name: \"%s\"\n", elem.Name))
			sb.WriteString(fmt.Sprintf("          kind: \"%s\"\n", elem.Kind))
			sb.WriteString(fmt.Sprintf("          #apiVersion: \"%s\"\n", elem.APIVersion))

			// Add provenance
			sb.WriteString("          _provenance: {\n")
			if elem.Provenance.SourceComposite != "" {
				sb.WriteString(fmt.Sprintf("            sourceComposite: \"%s\"\n", elem.Provenance.SourceComposite))
			}
			sb.WriteString(fmt.Sprintf("            elementHash: \"sha256:%s\"\n", elem.Hash))
			sb.WriteString("          }\n")

			// Schema would be inlined here (simplified for example)
			sb.WriteString("          schema: {...}\n")

			sb.WriteString("        }\n")
		}

		sb.WriteString("      }\n")

		// Data fields would be preserved here
		sb.WriteString("      // Data fields preserved from source\n")

		sb.WriteString("    }\n")
	}

	sb.WriteString("  }\n")

	// Preserve values schema
	valuesValue := originalModule.LookupPath(cue.ParsePath("values"))
	if valuesValue.Exists() {
		sb.WriteString("  values: {...}\n")
	}

	sb.WriteString("}\n")

	// Compile output CUE
	outputValue := f.ctx.CompileString(sb.String())
	if err := outputValue.Err(); err != nil {
		return cue.Value{}, fmt.Errorf("compile output: %w", err)
	}

	return outputValue, nil
}

// Helper function to get element FQNs
func getElementFQNs(elements map[string]*Element) []string {
	fqns := make([]string, 0, len(elements))
	for fqn := range elements {
		fqns = append(fqns, fqn)
	}
	sort.Strings(fqns)
	return fqns
}

// Example usage
func main() {
	ctx := cuecontext.New()

	// Example ModuleDefinition with composite element
	moduleDefSource := `
package example

import opm "github.com/open-platform-model/core"

myModule: opm.#ModuleDefinition & {
    #metadata: {
        name: "example-app"
        version: "1.0.0"
        labels: {
            team: "platform"
        }
    }

    components: {
        frontend: {
            #metadata: {
                name: "frontend"
            }

            // This would be a composite element in real code
            #elements: {
                "elements.opm.dev/core/v0.StatelessWorkload": {
                    name: "StatelessWorkload"
                    kind: "composite"
                    #apiVersion: "elements.opm.dev/core/v0"
                    target: ["component"]
                    schema: {...}
                    composes: [
                        "elements.opm.dev/core/v0.Container",
                        "elements.opm.dev/core/v0.Replicas",
                    ]
                    description: "Stateless workload"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                }
            }

            // Data fields
            container: {
                name: "frontend"
                image: "nginx:latest"
            }
            replicas: {count: 3}
        }
    }

    values: {
        frontend: {
            image!: string
        }
    }
}
`

	// Parse ModuleDefinition
	moduleDefValue := ctx.CompileString(moduleDefSource)
	if err := moduleDefValue.Err(); err != nil {
		log.Fatalf("Parse ModuleDefinition: %v", err)
	}

	// Create flattener
	flattener := NewFlattener(ctx)

	// Flatten
	moduleValue, err := flattener.Flatten(moduleDefValue.LookupPath(cue.ParsePath("myModule")))
	if err != nil {
		log.Fatalf("Flatten: %v", err)
	}

	// Format and print output
	outputBytes, err := format.Node(moduleValue.Syntax())
	if err != nil {
		log.Fatalf("Format output: %v", err)
	}

	fmt.Println("\n=== FLATTENED MODULE ===")
	fmt.Println(string(outputBytes))

	log.Println("\nFlattening demonstration complete!")
	log.Println("In production, this would:")
	log.Println("  1. Fetch elements from registry")
	log.Println("  2. Fully inline all schemas")
	log.Println("  3. Recursively expand composites")
	log.Println("  4. Preserve all data fields")
	log.Println("  5. Add comprehensive provenance metadata")
}