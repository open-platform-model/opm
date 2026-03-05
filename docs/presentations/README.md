# OPM Presentations

Slide decks built with [Marp](https://marp.app/). Each presentation lives in its own numbered subfolder with a `deck.md` and a `demo/` directory for live demo code. Shared assets (diagrams, images) are in `assets/`.

## Structure

```
docs/presentations/
├── assets/                # Shared diagrams and images
├── 001-kickstart/
│   ├── deck.md            # Marp slide deck
│   └── demo/              # Demo code/examples for this talk
└── NNN-name/
    ├── deck.md
    └── demo/
```

## Prerequisites

```bash
brew install marp-cli
```

Chrome, Edge, or Firefox required for PDF/PPTX export.

## Usage

```bash
task list                       # List available presentations
task preview                    # Preview default deck (kickstart)
task preview DECK=kickstart     # Preview a specific deck
task html    DECK=kickstart     # Export to HTML
task pdf     DECK=kickstart     # Export to PDF
task pptx    DECK=kickstart     # Export to PPTX
task diagram                    # Re-render all mermaid diagrams in assets/
```

## Adding a New Presentation

1. Create a folder: `NNN-my-talk/`
2. Add `NNN-my-talk/deck.md` with Marp front matter:
   ```yaml
   ---
   marp: true
   theme: gaia
   paginate: true
   ---
   ```
3. Add `NNN-my-talk/demo/` for any live demo code
4. Reference shared assets with `../assets/image.png`
5. Preview with `task preview DECK=my-talk`

## Editing

- Slides are separated by `---`
- Speaker notes go in `<!-- ... -->` blocks
- Section dividers use `<!-- _class: lead -->`
- Shared images/diagrams go in `assets/`
- Re-render mermaid diagrams with `task diagram`
