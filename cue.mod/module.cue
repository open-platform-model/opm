module: "github.com/open-platform-model/opm@v0"
language: {
	version: "v0.14.2"
}
source: {
	kind: "git"
}
deps: {
	"github.com/open-platform-model/core@v0": {
		v:       "v0.1.0"
		default: true
	}
	"github.com/open-platform-model/elements@v0": {
		v:       "v0.1.0"
		default: true
	}
}
