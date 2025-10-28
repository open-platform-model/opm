package supabase

import (
	elements "github.com/open-platform-model/elements/core"
)

#components: {
	// PostgreSQL Database - Core data layer
	db: {
		#metadata: {
			name: "db"
			labels: {
				component:      "database"
				tier:           "data"
				"storage.type": "postgresql"
			}
			annotations: {
				"backup.enabled": "true"
			}
		}

		elements.#SimpleDatabase

		simpleDatabase: {
			engine:   "postgres"
			version:  "15"
			dbName:   "postgres"
			username: "postgres"
			password: values.database.password
			persistence: {
				enabled: true
				size:    values.database.storageSize
			}
		}
	}

	// Kong API Gateway - Routes all API requests
	kong: {
		#metadata: {
			name: "kong"
			labels: {
				component: "api-gateway"
				tier:      "edge"
			}
			annotations: {
				"metrics.enabled": "true"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "kong"
				image: "kong:2.8.1"
				ports: {
					http: {
						name:       "http"
						targetPort: 8000
						protocol:   "TCP"
					}
					https: {
						name:       "https"
						targetPort: 8443
						protocol:   "TCP"
					}
				}
				env: {
					KONG_DATABASE: {
						name:  "KONG_DATABASE"
						value: "off"
					}
					KONG_DECLARATIVE_CONFIG: {
						name:  "KONG_DECLARATIVE_CONFIG"
						value: "/var/lib/kong/kong.yml"
					}
					KONG_DNS_ORDER: {
						name:  "KONG_DNS_ORDER"
						value: "LAST,A,CNAME"
					}
					KONG_PLUGINS: {
						name:  "KONG_PLUGINS"
						value: "request-transformer,cors,key-auth,acl,basic-auth"
					}
				}
			}
		}
	}

	// GoTrue Auth Service - Handles authentication
	auth: {
		#metadata: {
			name: "auth"
			labels: {
				component: "auth"
				tier:      "application"
			}
			annotations: {
				"service.type": "authentication"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "auth"
				image: "supabase/gotrue:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 9999
						protocol:   "TCP"
					}
				}
				env: {
					GOTRUE_API_HOST: {
						name:  "GOTRUE_API_HOST"
						value: "0.0.0.0"
					}
					GOTRUE_API_PORT: {
						name:  "GOTRUE_API_PORT"
						value: "9999"
					}
					GOTRUE_DB_DRIVER: {
						name:  "GOTRUE_DB_DRIVER"
						value: "postgres"
					}
					GOTRUE_SITE_URL: {
						name:  "GOTRUE_SITE_URL"
						value: values.auth.siteUrl
					}
					GOTRUE_URI_ALLOW_LIST: {
						name:  "GOTRUE_URI_ALLOW_LIST"
						value: values.auth.allowList
					}
					GOTRUE_JWT_SECRET: {
						name:  "GOTRUE_JWT_SECRET"
						value: values.jwt.secret
					}
					GOTRUE_JWT_EXP: {
						name:  "GOTRUE_JWT_EXP"
						value: "3600"
					}
				}
			}
		}
	}

	// PostgREST - Auto-generated REST API
	rest: {
		#metadata: {
			name: "rest"
			labels: {
				component: "rest-api"
				tier:      "application"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "rest"
				image: "postgrest/postgrest:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 3000
						protocol:   "TCP"
					}
				}
				env: {
					PGRST_DB_URI: {
						name:  "PGRST_DB_URI"
						value: "postgresql://postgres:\(values.database.password)@db:5432/postgres"
					}
					PGRST_DB_SCHEMAS: {
						name:  "PGRST_DB_SCHEMAS"
						value: "public,storage,graphql_public"
					}
					PGRST_DB_ANON_ROLE: {
						name:  "PGRST_DB_ANON_ROLE"
						value: "anon"
					}
					PGRST_JWT_SECRET: {
						name:  "PGRST_JWT_SECRET"
						value: values.jwt.secret
					}
				}
			}
		}
	}

	// Realtime - WebSocket subscriptions
	realtime: {
		#metadata: {
			name: "realtime"
			labels: {
				component: "realtime"
				tier:      "application"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "realtime"
				image: "supabase/realtime:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 4000
						protocol:   "TCP"
					}
				}
				env: {
					PORT: {
						name:  "PORT"
						value: "4000"
					}
					DB_HOST: {
						name:  "DB_HOST"
						value: "db"
					}
					DB_PORT: {
						name:  "DB_PORT"
						value: "5432"
					}
					DB_USER: {
						name:  "DB_USER"
						value: "postgres"
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: values.database.password
					}
					DB_NAME: {
						name:  "DB_NAME"
						value: "postgres"
					}
					DB_SSL: {
						name:  "DB_SSL"
						value: "false"
					}
					JWT_SECRET: {
						name:  "JWT_SECRET"
						value: values.jwt.secret
					}
				}
			}
		}
	}

	// Storage - File storage API
	storage: {
		#metadata: {
			name: "storage"
			labels: {
				component: "storage"
				tier:      "application"
			}
			annotations: {
				"storage.backend": "file"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "storage"
				image: "supabase/storage-api:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 5000
						protocol:   "TCP"
					}
				}
				env: {
					ANON_KEY: {
						name:  "ANON_KEY"
						value: values.jwt.anonKey
					}
					SERVICE_KEY: {
						name:  "SERVICE_KEY"
						value: values.jwt.serviceKey
					}
					POSTGREST_URL: {
						name:  "POSTGREST_URL"
						value: "http://rest:3000"
					}
					PGRST_JWT_SECRET: {
						name:  "PGRST_JWT_SECRET"
						value: values.jwt.secret
					}
					DATABASE_URL: {
						name:  "DATABASE_URL"
						value: "postgresql://postgres:\(values.database.password)@db:5432/postgres"
					}
					STORAGE_BACKEND: {
						name:  "STORAGE_BACKEND"
						value: "file"
					}
					FILE_STORAGE_BACKEND_PATH: {
						name:  "FILE_STORAGE_BACKEND_PATH"
						value: "/var/lib/storage"
					}
				}
			}
		}
	}

	// Studio - Web UI dashboard
	studio: {
		#metadata: {
			name: "studio"
			labels: {
				component: "dashboard"
				tier:      "web"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "studio"
				image: "supabase/studio:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 3000
						protocol:   "TCP"
					}
				}
				env: {
					SUPABASE_URL: {
						name:  "SUPABASE_URL"
						value: values.studio.publicUrl
					}
					STUDIO_PG_META_URL: {
						name:  "STUDIO_PG_META_URL"
						value: "http://meta:8080"
					}
					SUPABASE_ANON_KEY: {
						name:  "SUPABASE_ANON_KEY"
						value: values.jwt.anonKey
					}
					SUPABASE_SERVICE_KEY: {
						name:  "SUPABASE_SERVICE_KEY"
						value: values.jwt.serviceKey
					}
				}
			}
		}
	}

	// Functions - Edge runtime for serverless functions
	functions: {
		#metadata: {
			name: "functions"
			labels: {
				component: "edge-functions"
				tier:      "application"
			}
		}

		elements.#StatelessWorkload

		statelessWorkload: {
			container: {
				name:  "functions"
				image: "supabase/edge-runtime:latest"
				ports: {
					http: {
						name:       "http"
						targetPort: 9000
						protocol:   "TCP"
					}
				}
				env: {
					JWT_SECRET: {
						name:  "JWT_SECRET"
						value: values.jwt.secret
					}
					SUPABASE_URL: {
						name:  "SUPABASE_URL"
						value: values.studio.publicUrl
					}
					SUPABASE_ANON_KEY: {
						name:  "SUPABASE_ANON_KEY"
						value: values.jwt.anonKey
					}
					SUPABASE_SERVICE_ROLE_KEY: {
						name:  "SUPABASE_SERVICE_ROLE_KEY"
						value: values.jwt.serviceKey
					}
				}
			}
		}
	}
}
