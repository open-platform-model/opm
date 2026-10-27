# opm: where do I go?

Router only. Facts and rules are in `AGENTS.md`.

| Task | Read first | Then |
| --- | --- | --- |
| Write or edit a site page | `docs/STYLE.md` | `docs/site/` |
| Add or change a glossary term | `docs/STYLE.md` | `docs/legacy/` |
| Start a change (new page, page structure, ADR-sized decision) | `AGENTS.md` | `openspec/config.yaml`, then `.claude/skills/openspec-propose/` |
| Record an architecture decision | `adr/` | `CONSTITUTION.md` |
| Weigh a change against the design principles | `CONSTITUTION.md` | |
| Change the docs bundle, its pins, the publish jobs of either workflow, or the revision flow | `references/docs-bundle.md` | `.github/workflows/`, `.tasks/` |
| Edit the release-please config or the release-PR part of a workflow (not its publish job) | `AGENTS.md` | `.github/workflows/` |
| Pick a commit type or decide whether a change releases | `AGENTS.md` | |
| Write research notes or a slide deck | `docs/STYLE.md` | `docs/analysis/`, `docs/presentations/` |
| Commit, open a PR or write GitHub text | `references/git-text.md` at the workspace root | |
| Cite or deliver an enhancement | `references/enhancements.md` at the workspace root | |
