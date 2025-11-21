package main

import (
	core "opm.dev/core@v1"
)

// Template metadata - will be removed during init
// This file is used by OPM CLI to display template information
core.#TemplateDefinition

metadata: {
	apiVersion:  "templates.opm.dev/core@v1"
	name:        "Advanced"
	category:    "module"
	description: "A multi-package template for complex applications with component and scope organization in subdirectories."
	level:       "advanced"
	fileCount:   9
	useCase:     "Large-scale applications, platform engineering, multiple teams"
}
