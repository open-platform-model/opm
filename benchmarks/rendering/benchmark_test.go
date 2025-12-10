package rendering

import (
	"testing"
	"time"

	"cuelang.org/go/cue"
)

// Benchmark loading and processing Simple module (2 components) with ModuleDefinition (blueprints)
func BenchmarkRenderModuleDefinition_Simple(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModuleDefinition("simple")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module definition
		module, err := loader.ExtractModule(val, "simpleModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// Benchmark loading and processing Simple module (2 components) with Module (compiled)
func BenchmarkRenderModule_Simple(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModule("simple")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module
		module, err := loader.ExtractModule(val, "simpleModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// Benchmark loading and processing Moderate module (4 components) with ModuleDefinition (blueprints)
func BenchmarkRenderModuleDefinition_Moderate(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModuleDefinition("moderate")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module definition
		module, err := loader.ExtractModule(val, "moderateModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// Benchmark loading and processing Moderate module (4 components) with Module (compiled)
func BenchmarkRenderModule_Moderate(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModule("moderate")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module
		module, err := loader.ExtractModule(val, "moderateModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// --- Stage Breakdown Benchmarks ---

// Benchmark ONLY the loading stage (Simple ModuleDefinition)
func BenchmarkStage_Load_Simple_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModuleDefinition("simple")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the loading stage (Simple Module compiled)
func BenchmarkStage_Load_Simple_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModule("simple")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the loading stage (Moderate ModuleDefinition)
func BenchmarkStage_Load_Moderate_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModuleDefinition("moderate")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the loading stage (Moderate Module compiled)
func BenchmarkStage_Load_Moderate_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModule("moderate")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Simple ModuleDefinition)
func BenchmarkStage_Extract_Simple_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModuleDefinition("simple")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "simpleModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Simple Module compiled)
func BenchmarkStage_Extract_Simple_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModule("simple")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "simpleModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Moderate ModuleDefinition)
func BenchmarkStage_Extract_Moderate_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModuleDefinition("moderate")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "moderateModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Moderate Module compiled)
func BenchmarkStage_Extract_Moderate_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModule("moderate")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "moderateModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}

// --- Scaling Tests ---

// Test function to validate modules can be loaded correctly
func TestModuleLoading(t *testing.T) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		t.Fatalf("failed to create loader: %v", err)
	}

	tests := []struct {
		name           string
		moduleName     string
		fieldName      string
		expectedComps  int
		isDefinition   bool
	}{
		{
			name:          "Simple ModuleDefinition",
			moduleName:    "simple",
			fieldName:     "simpleModuleDefinition",
			expectedComps: 2,
			isDefinition:  true,
		},
		{
			name:          "Simple Module",
			moduleName:    "simple",
			fieldName:     "simpleModule",
			expectedComps: 2,
			isDefinition:  false,
		},
		{
			name:          "Moderate ModuleDefinition",
			moduleName:    "moderate",
			fieldName:     "moderateModuleDefinition",
			expectedComps: 4,
			isDefinition:  true,
		},
		{
			name:          "Moderate Module",
			moduleName:    "moderate",
			fieldName:     "moderateModule",
			expectedComps: 4,
			isDefinition:  false,
		},
		{
			name:          "Large ModuleDefinition",
			moduleName:    "large",
			fieldName:     "largeModuleDefinition",
			expectedComps: 12,
			isDefinition:  true,
		},
		{
			name:          "Large Module",
			moduleName:    "large",
			fieldName:     "largeModule",
			expectedComps: 12,
			isDefinition:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			start := time.Now()

			var val cue.Value
			var err error

			if tt.isDefinition {
				val, err = loader.LoadModuleDefinition(tt.moduleName)
			} else {
				val, err = loader.LoadModule(tt.moduleName)
			}

			if err != nil {
				t.Fatalf("failed to load module: %v", err)
			}

			loadTime := time.Since(start)
			t.Logf("Load time: %v", loadTime)

			start = time.Now()
			module, err := loader.ExtractModule(val, tt.fieldName)
			if err != nil {
				t.Fatalf("failed to extract module: %v", err)
			}

			components, err := loader.ExtractComponents(module)
			if err != nil {
				t.Fatalf("failed to extract components: %v", err)
			}

			extractTime := time.Since(start)
			t.Logf("Extract time: %v", extractTime)

			if len(components) != tt.expectedComps {
				t.Errorf("expected %d components, got %d", tt.expectedComps, len(components))
			}

			// Validate each component
			for name, comp := range components {
				if err := comp.Err(); err != nil {
					t.Errorf("component %s has errors: %v", name, err)
				}
			}

			t.Logf("Total time: %v", loadTime+extractTime)
		})
	}
}

// Benchmark loading and processing Large module (12 components) with ModuleDefinition (blueprints)
func BenchmarkRenderModuleDefinition_Large(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModuleDefinition("large")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module definition
		module, err := loader.ExtractModule(val, "largeModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// Benchmark loading and processing Large module (12 components) with Module (compiled)
func BenchmarkRenderModule_Large(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Load module
		val, err := loader.LoadModule("large")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}

		// Extract module
		module, err := loader.ExtractModule(val, "largeModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		// Extract components (this forces CUE unification)
		components, err := loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}

		// Access each component to ensure full unification
		for _, comp := range components {
			if err := comp.Err(); err != nil {
				b.Fatalf("component has errors: %v", err)
			}
		}
	}
}

// Benchmark ONLY the loading stage (Large ModuleDefinition)
func BenchmarkStage_Load_Large_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModuleDefinition("large")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the loading stage (Large Module compiled)
func BenchmarkStage_Load_Large_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := loader.LoadModule("large")
		if err != nil {
			b.Fatalf("failed to load module: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Large ModuleDefinition)
func BenchmarkStage_Extract_Large_ModuleDefinition(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModuleDefinition("large")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "largeModuleDefinition")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}

// Benchmark ONLY the extraction stage (Large Module compiled)
func BenchmarkStage_Extract_Large_Module(b *testing.B) {
	loader, err := NewModuleLoader("modules")
	if err != nil {
		b.Fatalf("failed to create loader: %v", err)
	}

	// Pre-load module once
	val, err := loader.LoadModule("large")
	if err != nil {
		b.Fatalf("failed to load module: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		module, err := loader.ExtractModule(val, "largeModule")
		if err != nil {
			b.Fatalf("failed to extract module: %v", err)
		}

		_, err = loader.ExtractComponents(module)
		if err != nil {
			b.Fatalf("failed to extract components: %v", err)
		}
	}
}
