# OPM Elements Reference

This document catalogs the available elements (traits and resources) in the Open Platform Model architecture. Elements are the atomic building blocks that can be composed into components and ultimately assembled into modules.

## Element Architecture

Elements in OPM follow a unified pattern based on the `#Element` foundation:

- **Type**: Either `trait` (behavioral capabilities) or `resource` (infrastructure primitives)
- **Kind**: `primitive`, `composite`, `modifier`, or `custom`
- **Target**: Where applicable - `component`, `scope`, or both
- **Labels**: Systematic organization using labels like `core.opm.dev/category` with values such as workload, data, connectivity, security, observability, governance

All elements inherit from the base `#Element` definition and use the `#ElementBase` pattern for type-safe composition.

## Element Implementation Patterns

### Primitive Element Pattern

All primitive elements follow this structure using the `#ElementBase` pattern:

```cue
// Primitive Trait Example
#Container: #ElementBase & {
    #metadata: #elements: Container: #PrimitiveTrait & {
        description: "Single container primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}
        #schema: #ContainerSpec
    }

    container: #ContainerSpec
}

// Primitive Resource Example
#Volume: #ElementBase & {
    #metadata: #elements: Volume: #PrimitiveResource & {
        description: "Volume storage primitive"
        target: ["component"]
        labels: {"core.opm.dev/category": "data"}
        #schema: #VolumeSpec
    }

    volumes: [string]: #VolumeSpec
}
```

### Composite Element Pattern

Composite elements combine multiple primitive elements:

```cue
#WebService: #ElementBase & {
    #metadata: #elements: WebService: #CompositeTrait & {
        description: "Web service with load balancing and rolling updates"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}

        composes: [#Container, #Expose, #Replicas, #UpdateStrategy]
        #schema: #WebServiceSpec
    }

    webService: #WebServiceSpec
}
```

### Component Composition

Components compose elements through simple embedding:

```cue
web: #Component & {
    #metadata: {
        #id: "web"
        type: "workload"
        workloadType: "stateless"
    }

    // Embed primitive elements
    #Container
    #Volume

    // Configure the elements
    container: {
        image: "nginx:latest"
        ports: http: {containerPort: 80}
    }
    volumes: {
        data: {emptyDir: {}}
    }
}
```

### Module Assembly

Modules group multiple components:

```cue
myApp: #Module & {
    #metadata: {
        #id: "my-app"
        namespace: "production"
    }

    components: {
        web: web  // Reference to component above
        // Additional components...
    }
}
```

## Primitive Traits

Primitive traits provide behavioral capabilities to components.

### Workload Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **Container** | trait | component | Single container runtime | `container: #ContainerSpec` |
| **SidecarContainers** | trait | component | Additional containers as sidecars | `sidecarContainers: [string]: #ContainerSpec` |
| **InitContainers** | trait | component | Pre-start initialization containers | `initContainers: [string]: #ContainerSpec` |
| **EphemeralContainers** | trait | component | Debug/troubleshooting containers | `ephemeralContainers: [string]: #ContainerSpec` |
| **Replicas** | trait | component | Desired instance count | `replicas: #ReplicasSpec` |
| **UpdateStrategy** | trait | component | Rollout and deployment policy | `updateStrategy: #UpdateStrategySpec` |
| **Scheduling** | trait | component | Pod placement constraints | `scheduling: #SchedulingSpec` |
| **Runtime** | trait | component | Container runtime selection | `runtime: #RuntimeSpec` |
| **LifecycleHooks** | trait | component | Container lifecycle hooks | `lifecycle: #LifecycleSpec` |
| **Termination** | trait | component | Graceful shutdown configuration | `termination: #TerminationSpec` |
| **RestartPolicy** | trait | component | Container restart behavior | `restartPolicy: #RestartPolicySpec` |

### Connectivity Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **Expose** | trait | component | Service exposure and networking | `expose: #ExposeSpec` |
| **HTTPRoute** | trait | component, scope | HTTP routing configuration | `httpRoute: #HTTPRouteSpec` |
| **NetworkPolicy** | trait | scope | Network access control policies | `networkPolicy: #NetworkPolicySpec` |
| **ServiceMesh** | trait | scope | Service mesh configuration | `serviceMesh: #ServiceMeshSpec` |
| **TrafficPolicy** | trait | scope | Traffic management and resilience | `trafficPolicy: #TrafficPolicySpec` |
| **DNSPolicy** | trait | scope | DNS configuration | `dnsPolicy: #DNSPolicySpec` |
| **RateLimiting** | trait | component, scope | Request rate limiting | `rateLimit: #RateLimitSpec` |

### Security Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **PodSecurity** | trait | component, scope | Pod security context | `podSecurity: #PodSecuritySpec` |
| **ServiceAccount** | trait | component | Pod identity and authentication | `serviceAccount: #ServiceAccountSpec` |
| **PodSecurityStandards** | trait | scope | Security policy enforcement | `standards: #SecurityStandardsSpec` |
| **AuditPolicy** | trait | scope | Audit logging requirements | `auditPolicy: #AuditPolicySpec` |
| **CompliancePolicy** | trait | scope | Regulatory compliance rules | `compliance: #CompliancePolicySpec` |
| **Sysctls** | trait | component | Kernel parameter configuration | `sysctls: #SysctlsSpec` |

### Governance Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **Priority** | trait | component | Scheduling priority | `priority: #PrioritySpec` |
| **HorizontalAutoscaler** | trait | component | Horizontal pod autoscaling | `horizontalAutoscaler: #HPASpec` |
| **VerticalAutoscaler** | trait | component | Vertical pod autoscaling | `verticalAutoscaler: #VPASpec` |
| **DisruptionBudget** | trait | component | Pod disruption budget | `disruptionBudget: #PDBSpec` |
| **ResourceQuota** | trait | scope | Resource consumption limits | `resourceQuota: #ResourceQuotaSpec` |
| **ResourceLimit** | trait | scope | Resource boundaries | `resourceLimits: #ResourceLimitSpec` |
| **CostAllocation** | trait | scope | Cost tracking and allocation | `costAllocation: #CostAllocationSpec` |

### Observability Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **OTelMetrics** | trait | component | OpenTelemetry metrics export | `otelMetrics: #OTelMetricsSpec` |
| **OTelLogging** | trait | component | OpenTelemetry logging export | `otelLogs: #OTelLogsSpec` |
| **ObservabilityPolicy** | trait | scope | Telemetry collection policies | `observabilityPolicy: #ObservabilityPolicySpec` |

## Primitive Resources

Primitive resources provide infrastructure capabilities to components.

### Data Elements

| Element | Type | Target | Description | Configuration |
|---------|------|--------|-------------|---------------|
| **Volume** | resource | component | Storage volumes and mounts | `volumes: [string]: #VolumeSpec` |
| **ConfigMap** | resource | component | Configuration data | `configMaps: [string]: #ConfigMapSpec` |
| **Secret** | resource | component | Sensitive data | `secrets: [string]: #SecretSpec` |
| **ProjectedVolume** | resource | component | Combined multi-source volumes | `projected: #ProjectedVolumeSpec` |
| **PersistentClaims** | resource | component | Persistent storage claims | `claims: [string]: #PersistentClaimSpec` |
| **BackupPolicy** | resource | scope | Data backup requirements | `backupPolicy: #BackupPolicySpec` |
| **DisasterRecovery** | resource | scope | Disaster recovery policies | `disasterRecovery: #DisasterRecoverySpec` |
| **CachingPolicy** | resource | scope | Data caching strategies | `cachingPolicy: #CachingPolicySpec` |

## Composite Elements

Composite elements combine multiple primitive elements for common patterns:

| Composite | Type | Built from (primitives) | When to use |
| --------- | ---- | ---------------------- | ----------- |
| **WebService** | Trait | Container + Expose + Replicas + UpdateStrategy | Standard web applications needing load balancing and zero-downtime deployments |
| **StatefulService** | Trait | Container + Volume + Replicas + UpdateStrategy + Scheduling | Databases, message queues, or workloads requiring persistent storage |
| **BackgroundWorker** | Trait | Container + Replicas + Scheduling | Queue processors, batch jobs without external exposure |
| **Database** | Trait | Container + InitContainers + Volume + Replicas + UpdateStrategy + Scheduling + ConfigMap + Secret | Database service with full persistence support |

### Composite Element Structure

```cue
#WebService: #ElementBase & {
    #metadata: #elements: WebService: #CompositeTrait & {
        description: "Web service with load balancing and rolling updates"
        target: ["component"]
        labels: {"core.opm.dev/category": "workload"}

        composes: [#Container, #Expose, #Replicas, #UpdateStrategy]
        #schema: #WebServiceSpec
    }

    webService: #WebServiceSpec
}

#WebServiceSpec: {
    name: string
    image: #Image
    ports: #ContainerSpec.ports
    exposed: true
}
```

## Element Schema Specifications

### ContainerSpec (Primitive Trait)

```cue
#ContainerSpec: {
    name: string & strings.MinRunes(1) & strings.MaxRunes(253)

    image: #ImageSchema & {
        repository: _ | *""
        tag:        _ | *""
        digest:     _ | *""
    }

    imagePullSecrets?: [...#SecretSpec]
    command?: [...string]
    args?: [...string]
    workingDir?: string & strings.MaxRunes(1024)
    env?: [string]: {
        name:  string
        value: string
    }
    resources?: #ResourceRequirements
    ports?: [string]: {
        containerPort: int
        protocol?:     "TCP" | "UDP" | *"TCP"
    }
    volumeMounts?: [...#VolumeMount]
}
```

### VolumeSpec (Primitive Resource)

```cue
#VolumeSpec: {
    // Pick one volume type
    emptyDir?: {
        medium?:    *"node" | "memory"
        sizeLimit?: string
    }
    configMap?: #ConfigMapSpec
    secret?: #SecretSpec
    persistentClaim?: #PersistentClaimSpec

    mountPath?: string
}

#VolumeMount: {
    mountPath!: string
    subPath?: string & strings.MaxRunes(1024)
    readOnly?: bool | *false
    volumeMountOptions?: #VolumeMountOptions
}
```

### Common Specifications

```cue
#ExposeSpec: {
    type: "LoadBalancer" | "NodePort" | "ClusterIP" | *"ClusterIP"
    ports: [string]: {
        port: int
        targetPort?: int | *port
        protocol?: "TCP" | "UDP" | *"TCP"
    }
}

#ReplicasSpec: uint | *1

#UpdateStrategySpec: {
    type: *"RollingUpdate" | "Recreate"
    rollingUpdate?: {
        maxSurge?:       uint | *1
        maxUnavailable?: uint | *0
    }
}

#SchedulingSpec: {
    nodeSelector?: [string]: string
    affinity?: {
        nodeAffinity?: {...}
        podAffinity?: {...}
        podAntiAffinity?: {...}
    }
    tolerations?: [...{
        key?: string
        operator?: "Equal" | "Exists" | *"Equal"
        value?: string
        effect?: "NoSchedule" | "PreferNoSchedule" | "NoExecute"
    }]
    topologySpread?: [...{
        maxSkew: int
        topologyKey: string
        whenUnsatisfiable: "DoNotSchedule" | "ScheduleAnyway"
    }]
}

#PodSecuritySpec: {
    fsGroup?: int
    seLinuxOptions?: {
        level?: string
        role?: string
        type?: string
        user?: string
    }
    runAsUser?: int
    runAsGroup?: int
    runAsNonRoot?: bool
}

#ConfigMapSpec: {
    data: [string]: string
}

#SecretSpec: {
    type?: string | *"Opaque"
    data: [string]: string // Base64-encoded values
}
```

### OpenTelemetry Specifications

#### OTelMetricsSpec

```cue
#OTelMetricsSpec: {
    // Which exporter the app SDK should use
    exporter?: *"otlp" | "prometheus" | "none"

    // OTLP settings (used when exporter == "otlp")
    otlp?: #OTLPCommon & {
        // Per-signal override; if unset, use otlp.endpoint
        metricsEndpoint?: string
        temporalityPreference?: *"cumulative" | "delta" | "lowmemory"
        defaultHistogramAggregation?: *"explicit_bucket" | "base2_exponential"
    }

    // Prometheus exposition (used when exporter == "prometheus")
    prometheus?: {
        enableExposition?: bool | *true
        port?: int & >=1 & <=65535 | *9464
        path?: string | *"/metrics"

        scrapeHints?: {
            enable?: bool | *false
            jobName?: string | *"app"
        }
    }
}

#OTLPCommon: {
    endpoint?: string // e.g. "http://otel-collector:4318"
    protocol?: *"grpc" | "http/protobuf"
    headers?: [string]: string

    tls?: {
        insecure?: bool
        caFile?: string
        certFile?: string
        keyFile?: string
    }

    resourceAttrs?: [string]: string
    serviceName?: string
}
```

#### OTelLogsSpec

```cue
#OTelLogsSpec: {
    exporter?: *"otlp" | "console" | "none"

    otlp?: #OTLPCommon & {
        logsEndpoint?: string
    }

    console?: {
        pretty?: bool | *false
        level?: *"info" | "debug" | "warn" | "error"
    }

    bodyFormat?: *"structured" | "json" | "text"
}
```

## Platform Mapping

Elements are designed to be platform-agnostic while providing clear transformation paths:

### Kubernetes Mappings

- **Container** → Pod template `containers[*]`
- **Volume** → `volumes[*]` and PersistentVolumeClaims
- **Expose** → Service resources
- **Replicas** → Deployment `spec.replicas`
- **UpdateStrategy** → Deployment `spec.strategy`
- **PodSecurity** → PodSecurityContext
- **NetworkPolicy** → NetworkPolicy resources
- **ConfigMap** → ConfigMap resources
- **Secret** → Secret resources

### Docker Compose Mappings

- **Container** → `services.<name>`
- **Volume** → top-level `volumes:`
- **Expose** → `ports` and `expose`
- **Replicas** → `deploy.replicas`
- **UpdateStrategy** → `deploy.update_config`
- **ConfigMap** → `configs`
- **Secret** → `secrets`

This element catalog provides the building blocks for composing any cloud-native application while maintaining portability across different deployment platforms.
