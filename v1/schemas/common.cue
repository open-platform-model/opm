package schemas

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Common Schemas
/////////////////////////////////////////////////////////////////

// Labels and annotations schema
#LabelsAnnotationsSchema: [string]: string | int | bool | [string | int | bool]

// Name schema with length constraints
#NameSchema: string & strings.MinRunes(1) & strings.MaxRunes(254)

// Semantic version schema
#VersionSchema: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"
