# Documentation Style Guide — OPM

Inherits all rules from the [workspace STYLE.md](../../STYLE.md). This file adds opm-specific conventions.

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
| Glossary | `docs/glossary.md` | **Canonical** — single source of truth for all OPM terms |
| Architecture docs | `docs/` root | Internal architecture and analysis |
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
- Every CUE or YAML snippet must be self-contained and runnable, or clearly marked as a partial excerpt.
- Bad: "Modules have a `#values` field that accepts typed configuration."
- Good:

```cue
// A module that accepts a replica count
#Module: {
    #values: {
        replicas: int | *3
    }
}
```

"The `#values` field defines the configuration interface for your module. End-users supply concrete values; the `*3` sets a sane default."

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

When referencing other repos' docs:
- Use relative paths from the workspace root: `[CLI docs](../cli/docs/)`.
- Or use GitHub URLs: `https://github.com/open-platform-model/cli`.

## What to Omit

- CUE schema internals (belongs in `catalog/docs/`).
- CLI flag references (belongs in `cli/docs/`).
- Controller operation procedures (belongs in `opm-operator/docs/`).
- Hugo site content (belongs in `opmodel.dev/`).
