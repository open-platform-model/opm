# OPM repository guide

Landing project for Open Platform Model: the published site pages, legacy pages, design notes and
ADRs. It is the canonical home of the workspace glossary. The public docs site lives in
`opmodel.dev/`, which assembles this repo's pages with those of the other repos. The pages are
Markdown; the only build is the docs bundle.

## Branch model

`main` is the only long-lived branch. Every change lands on it by PR.

## Rules

- `CONSTITUTION.md` is the principle source. It supersedes this file on conflict.
- Follow Semantic Versioning and Conventional Commits. The usual scope is `site`, for pages under
  `docs/site/`: `docs(site): ...`.
- Pages follow `docs/STYLE.md`. Read it before you write or edit any doc.
- The glossary in `docs/legacy/glossary.md` is canonical for the whole workspace until the site
  glossary replaces it. Other repos link to it and do not copy terms. A new term gets a
  one-sentence definition, an optional CUE snippet and the right table.
- Cite an enhancement as `Enhancement NNNN` beside the reason in words: never the id alone, and
  never a decision or question number. On a site page, link it as `[Title](/enhancements/NNNN/)`
  with the entry's current title.
- Update the layout below when you add a folder.

## Releases

- release-please keeps a release PR open on `main`, run as the release App. Merging it tags
  `vX.Y.Z` and creates the GitHub Release.
- The repo is on a beta line: each release advances the beta number.
- `feat`, `fix`, `perf`, `revert` and `docs` release. `docs` releases here, unlike the other repos,
  because the docs are this repo's product. `chore`, `ci`, `build`, `test`, `style` and `refactor`
  never release.
- Never write a `Release-As:` footer. Squash merges drop the body, so it never reaches `main`.
- The old CUE tags (`core/v1.0.4` and so on) predate this line and are left alone.

## Layout

```text
adr/                Architecture decision records and their template
docs/site/          Published pages; opmodel.dev assembles them by section
docs/legacy/        v0 pages, unpublished; source material until replaced
docs/analysis/      Research notes
docs/presentations/ Slide decks
.github/workflows/  Release (release-please, docs publish) and docs bundle check
.github/CODEOWNERS  Owner review on CI, task and release config paths
.tasks/             Install the pinned opm-docs, check the pins
docs-kit.cue        Declares the opm docs bundle
Taskfile.yml        Docs bundle tasks
```

## Commands

| Command | Description |
| --- | --- |
| `task docs:bundle` | Build the opm docs bundle of the work tree into `out/opm/` (a local preview of edge) |
| `task docs:bundle:check` | Check the docs-kit pins agree, then build and lint the bundle without writing `out/` |
| `task docs:pins:check` | Refuse a docs-kit `publish.yml` ref that names another release than `.opm-docs-version` (offline) |
| `task tools:opm-docs` | Install or reuse `.bin/opm-docs`, the checksum-verified docs-kit release `.opm-docs-version` names |
| `task check` | The docs bundle check |

@CONTEXT.md
