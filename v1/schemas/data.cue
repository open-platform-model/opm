package schemas

//////////////////////////////////////////////////////////////////
//// SimpleDatabase Schema
//////////////////////////////////////////////////////////////////

#SimpleDatabaseSchema: close({
	engine!:   "postgres" | "mysql" | "mongodb" | "redis"
	version!:  string
	dbName!:   string
	username!: string
	password!: string
	persistence?: {
		enabled?:      bool | *true
		size?:         string & =~"^[0-9]+[GMT]i$"
		storageClass?: string
	}
})
