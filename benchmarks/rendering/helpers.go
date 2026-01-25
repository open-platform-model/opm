package rendering

import (
	"fmt"
	"path/filepath"

	"cuelang.org/go/cue"
	"github.com/open-platform-model/opm/cli/pkg/loader"
)

// ModuleLoader handles loading of benchmark modules
type ModuleLoader struct {
	loader       *loader.Loader
	modulesDir   string
}

// NewModuleLoader creates a new module loader for benchmarks
func NewModuleLoader(modulesDir string) (*ModuleLoader, error) {
	// Use local registry for benchmarks
	l, err := loader.NewLoaderWithRegistry("localhost:5000")
	if err != nil {
		return nil, fmt.Errorf("failed to create loader: %w", err)
	}

	return &ModuleLoader{
		loader:     l,
		modulesDir: modulesDir,
	}, nil
}

// LoadModuleDefinition loads a ModuleDefinition (with blueprint references)
func (ml *ModuleLoader) LoadModuleDefinition(moduleName string) (cue.Value, error) {
	moduleDir := filepath.Join(ml.modulesDir, moduleName)
	return ml.loader.LoadModule(moduleDir)
}

// LoadModule loads a Module (pre-compiled, blueprints expanded)
func (ml *ModuleLoader) LoadModule(moduleName string) (cue.Value, error) {
	// For benchmarking, we'll load the module_compiled.cue file
	// which has blueprints already expanded
	modulePath := filepath.Join(ml.modulesDir, moduleName, "module_compiled.cue")
	return ml.loader.LoadFile(modulePath)
}

// ExtractModule extracts a module from a loaded CUE value
// This handles extracting the actual module struct from the package
func (ml *ModuleLoader) ExtractModule(val cue.Value, fieldName string) (cue.Value, error) {
	module := val.LookupPath(cue.ParsePath(fieldName))
	if !module.Exists() {
		return cue.Value{}, fmt.Errorf("module field %s not found", fieldName)
	}
	if err := module.Err(); err != nil {
		return cue.Value{}, fmt.Errorf("module has errors: %w", err)
	}
	return module, nil
}

// ExtractComponents extracts all components from a module
func (ml *ModuleLoader) ExtractComponents(module cue.Value) (map[string]cue.Value, error) {
	componentsField := module.LookupPath(cue.ParsePath("#components"))
	if !componentsField.Exists() {
		return nil, fmt.Errorf("#components field not found")
	}
	if err := componentsField.Err(); err != nil {
		return nil, fmt.Errorf("#components has errors: %w", err)
	}

	components := make(map[string]cue.Value)

	// Iterate over all fields in #components
	iter, err := componentsField.Fields(cue.Definitions(false), cue.Hidden(false), cue.Optional(false))
	if err != nil {
		return nil, fmt.Errorf("failed to iterate components: %w", err)
	}

	for iter.Next() {
		label := iter.Selector().String()
		component := iter.Value()
		components[label] = component
	}

	return components, nil
}

// CountComponents returns the number of components in a module
func (ml *ModuleLoader) CountComponents(module cue.Value) (int, error) {
	components, err := ml.ExtractComponents(module)
	if err != nil {
		return 0, err
	}
	return len(components), nil
}

// ValidateModule performs basic validation on a module
func (ml *ModuleLoader) ValidateModule(module cue.Value) error {
	// Check for CUE errors
	if err := module.Err(); err != nil {
		return fmt.Errorf("module has CUE errors: %w", err)
	}

	// Check for required fields
	metadata := module.LookupPath(cue.ParsePath("metadata"))
	if !metadata.Exists() {
		return fmt.Errorf("module missing metadata field")
	}

	components := module.LookupPath(cue.ParsePath("#components"))
	if !components.Exists() {
		return fmt.Errorf("module missing #components field")
	}

	values := module.LookupPath(cue.ParsePath("#values"))
	if !values.Exists() {
		return fmt.Errorf("module missing #values field")
	}

	return nil
}

// StageTimings tracks timing for different stages
type StageTimings struct {
	LoadTime       int64 // nanoseconds
	ExtractTime    int64 // nanoseconds
	ValidateTime   int64 // nanoseconds
	TotalTime      int64 // nanoseconds
}

// BenchmarkResult contains detailed benchmark results
type BenchmarkResult struct {
	ModuleName      string
	ModuleType      string // "definition" or "compiled"
	ComponentCount  int
	Timings         StageTimings
	AllocatedBytes  int64
	Allocations     int64
}

// GetAbsModulesDir returns the absolute path to the modules directory
func GetAbsModulesDir() (string, error) {
	// Get current working directory
	// In tests, this will be the benchmark directory
	return filepath.Abs("modules")
}
