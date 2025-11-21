package provider

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/build"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

// Loader handles loading providers from CUE files
type Loader struct {
	ctx     *cue.Context
	options LoadOptions
}

// NewLoader creates a new provider loader
func NewLoader(options LoadOptions) *Loader {
	return &Loader{
		ctx:     cuecontext.New(),
		options: options,
	}
}

// LoadFromPath loads a provider from a CUE file or directory
func (l *Loader) LoadFromPath(path string) (*Provider, error) {
	// Check if path exists
	info, err := os.Stat(path)
	if err != nil {
		return nil, &ProviderError{
			Stage:   "loading",
			Message: fmt.Sprintf("path not found: %s", path),
			Cause:   err,
		}
	}

	// Load CUE configuration
	var instances []*build.Instance
	if info.IsDir() {
		instances = load.Instances([]string{"."}, &load.Config{
			Dir: path,
		})
	} else {
		instances = load.Instances([]string{path}, nil)
	}

	if len(instances) == 0 {
		return nil, &ProviderError{
			Stage:   "loading",
			Message: "no CUE instances found",
		}
	}

	// Check for load errors
	inst := instances[0]
	if inst.Err != nil {
		return nil, &ProviderError{
			Stage:   "loading",
			Message: "failed to load CUE instance",
			Cause:   inst.Err,
		}
	}

	// Build the value
	value := l.ctx.BuildInstance(inst)
	// NOTE: We intentionally do NOT call value.Err() here because provider schemas contain
	// transform templates with field references (e.g., #component.spec.container) that are
	// undefined in the schema but will be resolved when transforms are executed with actual
	// component data. Validating the entire value would fail on these template references.

	// Extract provider from value
	// Note: We pass the value even if it has errors, since transforms contain template
	// references that will be resolved at execution time
	provider, err := l.extractProvider(value)
	if err != nil {
		return nil, err
	}

	// Validate if requested
	if l.options.ValidateOnLoad {
		validator := NewValidator(DefaultValidationOptions())
		if err := validator.ValidateProvider(provider); err != nil {
			return nil, &ProviderError{
				Stage:        "validation",
				ProviderName: provider.Metadata.Name,
				Message:      "provider validation failed",
				Cause:        err,
			}
		}
	}

	// Compute hash if requested
	if l.options.ComputeHashes {
		provider.Hash = l.computeProviderHash(provider)
		for fqn, transformer := range provider.Transformers {
			transformer.Hash = l.computeTransformerHash(transformer)
			provider.Transformers[fqn] = transformer
		}
	}

	return provider, nil
}

// extractProvider extracts a Provider from a CUE value
func (l *Loader) extractProvider(value cue.Value) (*Provider, error) {
	// Look for #Provider definition or #KubernetesProvider
	providerVal := value.LookupPath(cue.ParsePath("#Provider"))
	if !providerVal.Exists() {
		// Try #KubernetesProvider
		providerVal = value.LookupPath(cue.ParsePath("#KubernetesProvider"))
	}
	if !providerVal.Exists() {
		// Try to find any value with kind: "Provider"
		providerVal = l.findProviderValue(value)
		if !providerVal.Exists() {
			return nil, &ProviderError{
				Stage:   "extraction",
				Message: "#Provider or #KubernetesProvider definition not found",
			}
		}
	}

	provider := &Provider{
		Transformers: make(map[string]*Transformer),
		Schema:       providerVal,
	}

	// Extract metadata
	metadata, err := l.extractProviderMetadata(providerVal)
	if err != nil {
		return nil, &ProviderError{
			Stage:   "extraction",
			Message: "failed to extract provider metadata",
			Cause:   err,
		}
	}
	provider.Metadata = metadata

	// Extract transformers
	transformersVal := providerVal.LookupPath(cue.ParsePath("transformers"))
	if transformersVal.Exists() {
		transformers, err := l.extractTransformers(transformersVal)
		if err != nil {
			return nil, &ProviderError{
				Stage:        "extraction",
				ProviderName: metadata.Name,
				Message:      "failed to extract transformers",
				Cause:        err,
			}
		}
		provider.Transformers = transformers
	}

	// Compute declared definitions
	provider.DeclaredResources = l.computeDeclaredDefinitions(provider, "resources")
	provider.DeclaredTraits = l.computeDeclaredDefinitions(provider, "traits")
	provider.DeclaredPolicies = l.computeDeclaredDefinitions(provider, "policies")

	return provider, nil
}

// findProviderValue searches for a value with #kind: "Provider"
func (l *Loader) findProviderValue(value cue.Value) cue.Value {
	iter, _ := value.Fields(cue.All())
	for iter.Next() {
		kindVal := iter.Value().LookupPath(cue.ParsePath("#kind"))
		if kindVal.Exists() {
			kind, err := kindVal.String()
			if err == nil && kind == "Provider" {
				return iter.Value()
			}
		}
		// Recurse
		if nested := l.findProviderValue(iter.Value()); nested.Exists() {
			return nested
		}
	}
	return cue.Value{}
}

// extractProviderMetadata extracts provider metadata from CUE value
func (l *Loader) extractProviderMetadata(value cue.Value) (ProviderMetadata, error) {
	metadata := ProviderMetadata{
		Labels:      make(map[string]string),
		Annotations: make(map[string]string),
	}

	metadataVal := value.LookupPath(cue.ParsePath("metadata"))
	if !metadataVal.Exists() {
		return metadata, fmt.Errorf("provider metadata not found")
	}

	// Extract name
	nameVal := metadataVal.LookupPath(cue.ParsePath("name"))
	if nameVal.Exists() {
		name, err := nameVal.String()
		if err != nil {
			return metadata, fmt.Errorf("invalid provider name: %w", err)
		}
		metadata.Name = name
	}

	// Extract description
	descVal := metadataVal.LookupPath(cue.ParsePath("description"))
	if descVal.Exists() {
		desc, err := descVal.String()
		if err == nil {
			metadata.Description = desc
		}
	}

	// Extract version
	versionVal := metadataVal.LookupPath(cue.ParsePath("version"))
	if versionVal.Exists() {
		version, err := versionVal.String()
		if err == nil {
			metadata.Version = version
		}
	}

	// Extract minVersion
	minVersionVal := metadataVal.LookupPath(cue.ParsePath("minVersion"))
	if minVersionVal.Exists() {
		minVersion, err := minVersionVal.String()
		if err == nil {
			metadata.MinVersion = minVersion
		}
	}

	// Extract labels
	labelsVal := metadataVal.LookupPath(cue.ParsePath("labels"))
	if labelsVal.Exists() {
		labels, err := l.extractStringMap(labelsVal)
		if err == nil {
			metadata.Labels = labels
		}
	}

	// Extract annotations
	annotationsVal := metadataVal.LookupPath(cue.ParsePath("annotations"))
	if annotationsVal.Exists() {
		annotations, err := l.extractStringMap(annotationsVal)
		if err == nil {
			metadata.Annotations = annotations
		}
	}

	return metadata, nil
}

// extractTransformers extracts transformers from CUE value
func (l *Loader) extractTransformers(value cue.Value) (map[string]*Transformer, error) {
	transformers := make(map[string]*Transformer)

	iter, err := value.Fields()
	if err != nil {
		return nil, fmt.Errorf("failed to iterate transformers: %w", err)
	}

	for iter.Next() {
		fqn := iter.Selector().String()
		transformerVal := iter.Value()

		transformer, err := l.extractTransformer(transformerVal, fqn)
		if err != nil {
			return nil, fmt.Errorf("failed to extract transformer %s: %w", fqn, err)
		}

		transformers[fqn] = transformer
	}

	return transformers, nil
}

// extractTransformer extracts a single transformer from CUE value
func (l *Loader) extractTransformer(value cue.Value, fqn string) (*Transformer, error) {
	transformer := &Transformer{
		Schema: value,
	}

	// Extract metadata
	metadata, err := l.extractTransformerMetadata(value, fqn)
	if err != nil {
		return nil, fmt.Errorf("failed to extract transformer metadata: %w", err)
	}
	transformer.Metadata = metadata

	// Extract resources
	resourcesVal := value.LookupPath(cue.ParsePath("resources"))
	if resourcesVal.Exists() {
		resources, err := l.extractStringList(resourcesVal)
		if err != nil {
			return nil, fmt.Errorf("failed to extract resources: %w", err)
		}
		transformer.Resources = resources
	}

	// Extract traits
	traitsVal := value.LookupPath(cue.ParsePath("traits"))
	if traitsVal.Exists() {
		traits, err := l.extractStringList(traitsVal)
		if err != nil {
			return nil, fmt.Errorf("failed to extract traits: %w", err)
		}
		transformer.Traits = traits
	}

	// Extract policies
	policiesVal := value.LookupPath(cue.ParsePath("policies"))
	if policiesVal.Exists() {
		policies, err := l.extractStringList(policiesVal)
		if err != nil {
			return nil, fmt.Errorf("failed to extract policies: %w", err)
		}
		transformer.Policies = policies
	}

	// Extract transform function
	transformVal := value.LookupPath(cue.ParsePath("#transform"))
	if transformVal.Exists() {
		transformer.Transform = transformVal
	}

	return transformer, nil
}

// extractTransformerMetadata extracts transformer metadata from CUE value
func (l *Loader) extractTransformerMetadata(value cue.Value, fqn string) (TransformerMetadata, error) {
	metadata := TransformerMetadata{
		FQN:         fqn,
		Labels:      make(map[string]string),
		Annotations: make(map[string]string),
	}

	metadataVal := value.LookupPath(cue.ParsePath("metadata"))
	if !metadataVal.Exists() {
		return metadata, fmt.Errorf("transformer metadata not found")
	}

	// Extract name
	nameVal := metadataVal.LookupPath(cue.ParsePath("name"))
	if nameVal.Exists() {
		name, err := nameVal.String()
		if err != nil {
			return metadata, fmt.Errorf("invalid transformer name: %w", err)
		}
		metadata.Name = name
	}

	// Extract apiVersion
	apiVersionVal := metadataVal.LookupPath(cue.ParsePath("apiVersion"))
	if apiVersionVal.Exists() {
		apiVersion, err := apiVersionVal.String()
		if err == nil {
			metadata.APIVersion = apiVersion
		}
	}

	// Extract description
	descVal := metadataVal.LookupPath(cue.ParsePath("description"))
	if descVal.Exists() {
		desc, err := descVal.String()
		if err == nil {
			metadata.Description = desc
		}
	}

	// Extract labels
	labelsVal := metadataVal.LookupPath(cue.ParsePath("labels"))
	if labelsVal.Exists() {
		labels, err := l.extractStringMap(labelsVal)
		if err == nil {
			metadata.Labels = labels
		}
	}

	// Extract annotations
	annotationsVal := metadataVal.LookupPath(cue.ParsePath("annotations"))
	if annotationsVal.Exists() {
		annotations, err := l.extractStringMap(annotationsVal)
		if err == nil {
			metadata.Annotations = annotations
		}
	}

	return metadata, nil
}

// extractStringList extracts a list of strings from CUE value
func (l *Loader) extractStringList(value cue.Value) ([]string, error) {
	iter, err := value.List()
	if err != nil {
		return nil, fmt.Errorf("value is not a list: %w", err)
	}

	var result []string
	for iter.Next() {
		str, err := iter.Value().String()
		if err != nil {
			return nil, fmt.Errorf("list element is not a string: %w", err)
		}
		result = append(result, str)
	}

	return result, nil
}

// extractStringMap extracts a map of strings from CUE value
func (l *Loader) extractStringMap(value cue.Value) (map[string]string, error) {
	result := make(map[string]string)

	iter, err := value.Fields()
	if err != nil {
		return nil, fmt.Errorf("value is not a struct: %w", err)
	}

	for iter.Next() {
		key := iter.Selector().String()
		val, err := iter.Value().String()
		if err != nil {
			return nil, fmt.Errorf("map value is not a string: %w", err)
		}
		result[key] = val
	}

	return result, nil
}

// computeDeclaredDefinitions computes all definitions of a specific type across all transformers
func (l *Loader) computeDeclaredDefinitions(provider *Provider, defType string) []string {
	seen := make(map[string]bool)
	var result []string

	for _, transformer := range provider.Transformers {
		var defs []string
		switch defType {
		case "resources":
			defs = transformer.Resources
		case "traits":
			defs = transformer.Traits
		case "policies":
			defs = transformer.Policies
		}

		for _, def := range defs {
			if !seen[def] {
				seen[def] = true
				result = append(result, def)
			}
		}
	}

	return result
}

// computeProviderHash computes a content-based hash for the provider
func (l *Loader) computeProviderHash(provider *Provider) string {
	h := sha256.New()

	// Hash metadata
	io.WriteString(h, provider.Metadata.Name)
	io.WriteString(h, provider.Metadata.Version)
	io.WriteString(h, provider.Metadata.Description)

	// Hash transformer FQNs (sorted for determinism)
	for _, fqn := range sortedKeys(provider.Transformers) {
		io.WriteString(h, fqn)
		io.WriteString(h, provider.Transformers[fqn].Hash)
	}

	return fmt.Sprintf("%x", h.Sum(nil))
}

// computeTransformerHash computes a content-based hash for a transformer
func (l *Loader) computeTransformerHash(transformer *Transformer) string {
	h := sha256.New()

	// Hash metadata
	io.WriteString(h, transformer.Metadata.FQN)
	io.WriteString(h, transformer.Metadata.Name)
	io.WriteString(h, transformer.Metadata.APIVersion)

	// Hash declarations
	for _, resource := range transformer.Resources {
		io.WriteString(h, resource)
	}
	for _, trait := range transformer.Traits {
		io.WriteString(h, trait)
	}
	for _, policy := range transformer.Policies {
		io.WriteString(h, policy)
	}

	return fmt.Sprintf("%x", h.Sum(nil))
}

// sortedKeys returns sorted keys from a map
func sortedKeys(m map[string]*Transformer) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	// Note: Using a simple append order for now
	// TODO: Add proper sorting if determinism is critical
	return keys
}

// LoadFromDirectory loads all providers from a directory
func (l *Loader) LoadFromDirectory(dir string) ([]*Provider, error) {
	var providers []*Provider

	// Walk directory looking for provider files
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-CUE files
		if info.IsDir() || filepath.Ext(path) != ".cue" {
			return nil
		}

		// Try to load provider
		provider, err := l.LoadFromPath(path)
		if err != nil {
			// Not all CUE files are providers, so skip errors
			return nil
		}

		providers = append(providers, provider)
		return nil
	})

	if err != nil {
		return nil, &ProviderError{
			Stage:   "loading",
			Message: fmt.Sprintf("failed to walk directory: %s", dir),
			Cause:   err,
		}
	}

	if len(providers) == 0 {
		return nil, &ProviderError{
			Stage:   "loading",
			Message: fmt.Sprintf("no providers found in directory: %s", dir),
		}
	}

	return providers, nil
}
