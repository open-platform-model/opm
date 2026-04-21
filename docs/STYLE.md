# Documentation Style Guide — OPM

Inherits all rules from the workspace-level `STYLE.md`. This file adds opm-specific conventions.

## Audience

**End-users and newcomers to Open Platform Model.** This repo is the home for user-facing documentation: quickstarts, conceptual guides, and worked examples. Readers may be developers encountering OPM for the first time, or teams evaluating whether to adopt it.

## Tone

- **Welcoming and example-driven.** Start with what the user can do, then explain why.
- **Progressive disclosure.** Introduce concepts in the order a user encounters them. Don't front-load all the theory.
- Avoid jargon without definition. When a term has an entry in the glossary, link to it on first use.
- Celebrate small wins: a complete, runnable example is worth more than a perfect taxonomy.

## Document Types in This Repo

| Type | Location | Purpose |
|------|----------|---------|
| Documentation index | `docs/index.md` | Persona-based routing into the rest of `docs/` |
| Getting started | `docs/getting-started.md` | First-touch walkthrough for newcomers |
| Concepts | `docs/concepts/` | The model, explained in prose + example |
| Component docs | `docs/cli.md`, `docs/operator.md` | What the CLI and operator are, at newcomer level |
| Module gallery | `docs/modules-gallery.md` | Showcase of real modules |
| Comparisons | `docs/opm-vs-helm.md` | Framing for evaluators |
| Glossary | `docs/glossary.md` | **Canonical** — single source of truth for all OPM terms |
| Analysis | `docs/analysis/` | Older research notes, kept for reference |
| Specs | `specs/` | Internal specifications (not user-facing) |
| Benchmarks | `benchmarks/` | Performance data |

## Quickstarts and Guides

User-facing guides follow this structure:

1. **What you'll build** — one sentence describing the end result.
2. **Prerequisites** — bulleted list of what the reader needs before starting.
3. **Steps** — numbered procedure.
4. **What just happened** — brief explanation of what the steps did and why.
5. **Next steps** — links to related docs.

## Example-First Writing

- Show the example before the explanation. Let the reader see what they're working toward.
- Every CUE snippet must be self-contained and compile against real OPM imports, or be clearly marked as a partial excerpt.
- Prefer lifting snippets from the `opm module init` templates (`cli/internal/templates/`) or real modules under `modules/` so drift with the code is low.
- Bad: "Modules have a `#config` field that accepts typed configuration."
- Good:

```cue
import m "opmodel.dev/core/v1alpha1/module@v1"

// A module that accepts a scaling count
m.#Module

metadata: {
    modulePath: "example.com/modules"
    name:       "my-service"
    version:    "0.1.0"
}

#config: {
    scaling: int & >=1 | *3
}
```

"The `#config` field defines the configuration contract for your module. End-users supply concrete values in a ModuleRelease; the `*3` sets a sane default, and the `>=1` constraint rejects invalid overrides at build time."

## Concept Introductions

When introducing a new concept (Module, ModuleRelease, Provider, etc.):
1. One sentence definition.
2. One concrete example.
3. Link to the glossary or a deeper reference.

Do not introduce more than two new concepts per section.

## Glossary Maintenance

`docs/glossary.md` is the **canonical glossary for the entire workspace**. When adding a term:
- Add it to the appropriate table (CUE-specific Terms or OPM Workflow Terms) or add a new Persona section.
- Keep definitions to 1–2 sentences.
- Include a CUE example snippet if the term has a concrete code representation.
- Do not duplicate this glossary in other repos; link to it instead.

## Cross-References

- **Within this repo**: use relative paths — `[Glossary](glossary.md)`, `[Concepts Overview](concepts/overview.md)`.
- **To other repos**: use GitHub URLs, never workspace-local relative paths. Readers consume these docs on GitHub and in cloned forks where sibling repos may not be present.
  - File: `https://github.com/open-platform-model/<repo>/blob/main/<path>`
  - Directory: `https://github.com/open-platform-model/<repo>/tree/main/<path>`
  - Repo root: `https://github.com/open-platform-model/<repo>`
- **Repo list**: `catalog`, `cli`, `opm-operator`, `modules`, `opm`, `opmodel.dev`, `orca`, `releases`.

## What to Omit

- CUE schema internals (belongs in `catalog/docs/`).
- CLI flag references (belongs in `cli/docs/`).
- Controller operation procedures (belongs in `opm-operator/docs/`).
- Hugo site content (belongs in `opmodel.dev/`).
