package common

import (
	opm "github.com/open-platform-model/core"
)

#KubernetesProvider: opm.#Provider & {
	#metadata: {
		name:        "kubernetes"
		description: "Kubernetes Provider with common transformers"
		version:     "1.0.0"
		minVersion:  "1.20.0"

		// Labels for provider categorization and compatibility
		// Example: {"core.opm.dev/format": "kubernetes"}
		labels: {
			"core.opm.dev/format": "kubernetes"
		}
	}

	transformers: {
		"k8s.io/api/apps/v1.Deployment":            #DeploymentTransformer
		"k8s.io/api/apps/v1.StatefulSet":           #StatefulSetTransformer
		"k8s.io/api/core/v1.PersistentVolumeClaim": #PersistentVolumeClaimTransformer
	}
}
