package main

import (
	core "opm.dev/core@v1"
)

// Template metadata - will be removed during init
// This file is used by OPM CLI to display template information
core.#TemplateDefinition

metadata: {
	apiVersion:  "templates.opm.dev/core@v1"
	name:        "Simple"
	category:    "module"
	description: "A single-file template for learning OPM and quick prototypes. Everything defined inline for simplicity."
	level:       "beginner"
	useCase:     "Learning, demos, quick experiments"
}
