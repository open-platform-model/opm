# The docs bundle

Covers how this repo's pages become the `opm` docs bundle, how the bundle is published as `edge`
and per release, and how a released page is fixed. The commands are in `AGENTS.md`.

## How it works

`docs-kit.cue` declares one bundle, `opm`: the pages under `docs/site/`, placed in a site
version's `/docs/` tree. The publish workflow of docs-kit publishes it to
`ghcr.io/open-platform-model/docs/opm`.

- The docs workflow checks every pull request (`Docs / check`, plus the offline pin check) and
  publishes each push to `main` as `edge`.
- The release workflow publishes each release's bundle in the run that merged the release PR.
- Preview with `task docs:bundle` (pages land in `out/opm/content/`) or in a browser with the
  `serve` command of the installed docs tool. "Edit this page" links the file on `main`.
- opmodel.dev reads opm's released versions from their bundles. A page change on `main` reaches a
  released site version only through a release or a revision.

## Publish a missed release

A release without a bundle (a skipped publish job) is published by hand:

```bash
gh workflow run docs.yml --ref main -f mode=release -f tag=vX.Y.Z
```

## Fix a released page

Land a Markdown-only commit on `main`, then dispatch a revision with the 40-hex sha of that commit:

```bash
gh workflow run docs.yml --ref main -f mode=revision -f tag=vX.Y.Z -f fix=<40-hex sha>
```

Revisions are dispatched by hand (issue 22).

## Move the docs-kit pin

`.opm-docs-version` and every docs-kit publish workflow ref in the workflows name the same docs-kit release.
They move in one PR, after opmodel.dev runs that release. `task docs:pins:check` refuses a
mismatch.

## Pitfalls

- Moving one pin and not the others: the offline pin check fails.
- Bumping the pin before opmodel.dev runs that release: the site cannot read the bundle.
- Expecting a `main` page change on a released version: it needs a release or a revision.
- A revision commit that touches more than Markdown.

## Check before you finish

- [ ] `task docs:bundle:check` passes.
- [ ] All docs-kit refs name one release.
- [ ] A fix to a released page has a revision dispatched.
