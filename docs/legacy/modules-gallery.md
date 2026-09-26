# Module Gallery

A guided tour through four real OPM modules. Each one solves a concrete problem, and the snippets here are real — you can find the full sources in the [open-platform-model/modules](https://github.com/open-platform-model/modules) repo.

## cert-manager — wrapping a familiar operator

[`cert_manager/`](https://github.com/open-platform-model/modules/tree/main/cert_manager) packages cert-manager — the de facto TLS certificate manager for Kubernetes — as an OPM module. It deploys the controller, the webhook, the cainjector, all six CRDs, and the full RBAC stack (ten ClusterRoles plus three namespace Roles).

```cue
metadata: {
    name:             "cert-manager"
    version:          "0.1.0"
    defaultNamespace: "cert-manager"
}

#config: {
    image: schemas.#Image & {
        repository: string | *"ghcr.io/cert-manager"
        tag:        string | *"v1.13.0"
    }
    controller: {
        logLevel: int & >=1 & <=10 | *2
        replicas: int & >=1 | *1
    }
    webhook: { ... }
    cainjector: { ... }
}
```

Why it matters: most infrastructure on Kubernetes is a controller + its webhook + its RBAC. This module shows the boilerplate-heavy shape reduced to one schema, with per-component log levels, replica counts, and resource limits exposed as first-class values.

## metallb — the smallest useful infrastructure module

[`metallb/`](https://github.com/open-platform-model/modules/tree/main/metallb) is the bare-metal LoadBalancer. It deploys a Deployment (controller), a DaemonSet (speaker, one per node), the CRDs, and the RBAC.

```cue
#config: {
    image: schemas.#Image & {
        repository: string | *"quay.io/metallb/controller"
        tag:        string | *"v0.15.3"
    }
    controller: {
        logLevel: "debug" | *"info" | "warn" | "error"
        replicas: int & >=1 | *1
    }
    speaker: {
        logLevel: "debug" | *"info" | "warn" | "error"
        memberlistKey: schemas.#Secret & {
            $secretName: "memberlist"
            $dataKey:    "secretkey"
        }
    }
}
```

Why it matters: small and representative. The `schemas.#Secret` reference is worth looking at — OPM creates and manages the Kubernetes Secret automatically; the end-user just supplies the value. That is a pattern you will see in every module that needs credentials.

## jellyfin — a real stateful consumer app

[`jellyfin/`](https://github.com/open-platform-model/modules/tree/main/jellyfin) is a media server. It is a single-container stateful application with persistent storage, optional NFS mounts for a media library, optional HTTPRoute ingress, optional structured logging, and optional K8up-based backup to S3.

```cue
#config: {
    image: schemas.#Image & {
        repository: string | *"linuxserver/jellyfin"
        tag:        string | *"latest"
    }
    port: int & >0 & <=65535 | *8096

    storage: {
        config: #storageVolume & {
            mountPath: *"/config" | string
            type:      *"pvc" | "emptyDir" | "nfs"
            size:      string | *"10Gi"
        }
        media?: [Name=string]: #storageVolume
    }

    httpRoute?: {
        hostnames: [...string]
        gatewayRef?: { name: string, namespace: string }
    }

    backup?: {
        schedule: *"0 2 * * *" | string
        s3: { endpoint: string, bucket: string, ... }
        retention: { keepDaily: *7 | int, ... }
    }
}
```

Why it matters: this is what a real application module looks like — typed constraints on the port, a reusable local `#storageVolume` definition, optional features (`httpRoute?`, `backup?`) that disappear when absent, and a Gateway API integration for ingress.

## clickstack — composition across services

[`clickstack/`](https://github.com/open-platform-model/modules/tree/main/clickstack) is the HyperDX observability stack. It stitches together HyperDX (UI/API), a MongoDB replica set, a ClickHouse cluster with Keeper, and an OpenTelemetry Collector. It depends on four other modules (`mongodb_operator`, `clickhouse_operator`, `otel_collector`, `cert_manager`) being installed first, then emits custom resources against those operators.

```cue
#config: {
    releaseName: string | *"clickstack"

    image: schemas.#Image & { ... }

    mongodb: {
        members:     int & >=1 | *3
        version:     string | *"6.0.5"
        storageSize: string | *"10Gi"
    }
    clickhouse: {
        shards:      int & >=1 | *1
        replicas:    int & >=1 | *1
        storageSize: string | *"100Gi"
    }
    keeper: { replicas: int & >=1 | *3, storageSize: string | *"5Gi" }
    otel:   { image: schemas.#Image & { ... }, replicas: int & >=1 | *1 }

    mongodbPassword:       schemas.#Secret & { $dataKey: "MONGODB_PASSWORD", ... }
    clickhousePassword:    schemas.#Secret & { $dataKey: "CLICKHOUSE_PASSWORD", ... }
    hyperdxApiKey:         schemas.#Secret & { $dataKey: "HYPERDX_API_KEY", ... }
}
```

Why it matters: a single `#config` drives four cooperating workloads and a fan of shared secrets. This is the kind of composition that gets gnarly with Helm subcharts; in CUE it stays flat, typed, and validated.

## More

The repo also ships modules for GPU workloads, backup automation, object storage, VM management, game streaming, and a Minecraft server fleet. A few worth knowing about:

- [`k8up/`](https://github.com/open-platform-model/modules/tree/main/k8up) — Kubernetes-native backup automation operator
- [`sealed_secrets/`](https://github.com/open-platform-model/modules/tree/main/sealed_secrets) — git-safe secret encryption
- [`garage/`](https://github.com/open-platform-model/modules/tree/main/garage) — self-hosted S3-compatible storage
- [`otel_collector/`](https://github.com/open-platform-model/modules/tree/main/otel_collector) — OpenTelemetry operator
- [`wolf/`](https://github.com/open-platform-model/modules/tree/main/wolf) — GPU game streaming (advanced; DinD, multi-user)
- [`mc_java_fleet/`](https://github.com/open-platform-model/modules/tree/main/mc_java_fleet) — multi-server Minecraft fleet with shared hostname routing (advanced; 780 lines)
- [`ch_vmm/`](https://github.com/open-platform-model/modules/tree/main/ch_vmm) — Cloud Hypervisor VM manager (advanced; 9 CRDs, webhooks)

Browse the full list at [open-platform-model/modules](https://github.com/open-platform-model/modules) and the reusable authoring patterns in [`DESIGN_PATTERNS.md`](https://github.com/open-platform-model/modules/blob/main/DESIGN_PATTERNS.md).

## Next steps

- [Getting Started](getting-started.md) — scaffold and deploy your first module
- [Module and ModuleRelease](concepts/module-and-release.md) — the ownership model behind every `#config` you just read
- [CLI](cli.md) — how to build, apply, and inspect any of these modules
