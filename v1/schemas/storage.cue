package schemas

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

#VolumeBaseSchema: {
	name!: string
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSchema
	configMap?:       #ConfigMapSchema
	secret?:          #SecretSchema
	...
}

// Volume specification
#VolumeSchema: close(#VolumeBaseSchema & {
	name!: string
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSchema
	configMap?:       #ConfigMapSchema
	secret?:          #SecretSchema
})

// Volume mount specification
#VolumeMountSchema: close(#VolumeBaseSchema & {
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
})

// Persistent claim specification
#PersistentClaimSchema: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}
