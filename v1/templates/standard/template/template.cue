package main

import (
	core "opm.dev/core@v1"
)

// Template metadata - will be removed during init
// This file is used by OPM CLI to display template information
core.#TemplateDefinition

metadata: {
	apiVersion:  "templates.opm.dev/core@v1"
	name:        "Standard"
	category:    "module"
	description: "A template that fits most use-cases with clear separation between module definition, components, and values."
	level:       "intermediate"
	useCase:     "Production applications, team projects (3-10 components)"
}
