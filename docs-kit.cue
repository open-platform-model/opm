// opm's docs bundle (docs-kit docs/contracts.md C6, C15): the authored pages
// under docs/site/, placed in a site version's /docs/ tree. opm owns the
// /docs/ landing (_index.md) and start/_index.md. It is versioned by opm's
// release tags, v1.0.0-beta.1 first (docs-kit DESIGN decisions 17 and 21).
// opm-docs builds it (task docs:bundle, task docs:bundle:check); docs.yml and
// release.yml publish it to ghcr.io/open-platform-model/docs/opm.
bundles: opm: {
	placement: {kind: "docs", root: "/docs/"}
	version: {from: "tag", prefix: "v"}
	sources: [{kind: "markdown", dir: "docs/site"}]
}
