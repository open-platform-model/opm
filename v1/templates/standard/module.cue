package standard

import (
	core "opm.dev/core@v1"
	// units_workload "opm.dev/units/workload@v1"
	// units_storage "opm.dev/units/storage@v1"
	// traits_workload "opm.dev/traits/workload@v1"
)

// Standard Template: Separated Module and Values
// ===============================================
// This template is ideal for:
// - Medium applications (3-10 components)
// - Team projects with clear separation of concerns
// - When values need to be shared or reused
//
// Structure:
// - module.cue: ModuleDefinition + components (this file)
// - values.cue: Value schema (separate file)
//
// CUE automatically unifies both files in the same package.

// Declare this as a ModuleDefinition
core.#ModuleDefinition

// Module metadata
metadata: {
	apiVersion:  "opm.dev/modules/core@v1"
	name:        "StandardApp"
	version:     "1.0.0"
	description: "Standard web application with database"
}

// Note: Components are defined in components.cue
// CUE will automatically unify the #components field from components.cue with this ModuleDefinition

// Note: Value schema is defined in values.cue
// CUE will automatically unify the #values field from values.cue with this ModuleDefinition
