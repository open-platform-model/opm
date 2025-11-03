package advanced

import (
	core "opm.dev/core@v1"
)

// Advanced Template: Multi-File Organization
// ===========================================
// This template is designed for:
// - Large applications (10+ components)
// - Complex component definitions
//
// File Structure:
// - module.cue: Main ModuleDefinition (this file - aggregates everything)
// - components: Component definitions
//   -  api.cue: API component definition
//   -  backend.cue: Backend component definition
//   -  database.cue: Database component definition
// - values.cue: Value schema
// - scopes: Scope definitions
//   - frontend.cue: Frontend scope definition
//   - backend.cue: Backend scope definition
// - scopes.cue: Scope definitions (optional)
//
// All files in the same package are automatically unified by CUE.
// No imports needed between files in the same package!

// Declare this as a ModuleDefinition
core.#ModuleDefinition

// Module metadata
metadata: {
	apiVersion:  "opm.dev/modules/core@v1"
	name:        "AdvancedApp"
	version:     "1.0.0"
	description: "Advanced multi-tier application with complex organization"
}

// Components are defined in components.cue
// CUE automatically unifies the #components field from that file

// Values are defined in values.cue
// CUE automatically unifies the #values field from that file

// Scopes are defined in scopes.cue
// CUE automatically unifies the #scopes field from that file
