package schemas

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Network Schemas
/////////////////////////////////////////////////////////////////

// Must start with lowercase letter [a–z],
// end with lowercase letter or digit [a–z0–9],
// and may include hyphens in between.
#IANA_SVC_NAME: string & strings.MinRunes(1) & strings.MaxRunes(15) & =~"^[a-z]([-a-z0-9]{0,13}[a-z0-9])?$"

// Port specification
#PortSchema: {
	// This must be an IANA_SVC_NAME and unique within the pod. Each named port in a pod must have a unique name.
	// Name for the port that can be referred to by services.
	name!: #IANA_SVC_NAME
	// The port that the container will bind to.
	// This must be a valid port number, 0 < x < 65536.
	// If exposedPort is not specified, this value will be used for exposing the port outside the container.
	targetPort!: uint & >=1 & <=65535
	// Protocol for port. Must be UDP, TCP, or SCTP. Defaults to "TCP".
	protocol: *"TCP" | "UDP" | "SCTP"
	// What host IP to bind the external port to.
	hostIP?: string
	// What port to expose on the host.
	// This must be a valid port number, 0 < x < 65536.
	hostPort?: uint & >=1 & <=65535
	// The port that will be exposed outside the container.
	// exposedPort in combination with exposed must inform the platform of what port to map to the container when exposing.
	// This must be a valid port number, 0 < x < 65536.
	exposedPort?: uint & >=1 & <=65535
}

// Expose specification
#ExposeSchema: {
	ports: [portName=string]: #PortSchema & {name: portName}
	type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
}

//////////////////////////////////////////////////////////////////
//// Network Rules Schema (for Network Policies)
//////////////////////////////////////////////////////////////////

#NetworkRuleSchema: {
	ingress?: [...{
		from!: [...] // Component references - keeping flexible for now
		ports?: [...#PortSchema]
	}]
	egress?: [...{
		to!: [...] // Component references - keeping flexible for now
		ports?: [...#PortSchema]
	}]
	denyAll?: bool | *false
}

//////////////////////////////////////////////////////////////////
//// Shared Network Schema
//////////////////////////////////////////////////////////////////

#SharedNetworkSchema: {
	networkConfig: {
		dnsPolicy: *"ClusterFirst" | "Default" | "None"
		dnsConfig?: {
			nameservers: [...string]
			searches: [...string]
			options: [...{
				name:   string
				value?: int
			}]
		}
	}
}
