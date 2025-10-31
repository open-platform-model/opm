package v1

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]
#NameType: string & strings.MinRunes(1) & strings.MaxRunes(254)

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// FQN (Fully Qualified Name) format: <repo-path>@v<major>#<Name>
// Example: opm.dev/elements@v1#Container
// Example: github.com/myorg/elements@v1#CustomWorkload
#FQNType: string & =~"^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$"

// Policy target constants
// Defines where a policy can be applied
#PolicyTarget: {
	component: "component"
	scope:     "scope"
}
