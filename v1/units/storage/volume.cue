package storage

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
)

//////////////////////////////////////////////////////////////////
//// Volume Unit Definition
/////////////////////////////////////////////////////////////////

#VolumesUnit: close(core.#UnitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/units/storage@v1"
		name:        "Volumes"
		description: "A volume definition for workloads"
		labels: {
			"core.opm.dev/category":    "storage"
			"core.opm.dev/persistence": "true"
		}
	}

	// OpenAPIv3-compatible schema defining the structure of the volume spec
	#spec: volumes: [volumeName=string]: schemas.#VolumeSchema & {name: string | *volumeName}
})

#Volumes: close(core.#ComponentDefinition & {
	#units: {(#VolumesUnit.metadata.fqn): #VolumesUnit}
})
