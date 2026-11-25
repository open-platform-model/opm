This file is a copy of the OPM workspace master, `opm-rules.md`. Change it only there, then run the copy task: an edit made in a repo is overwritten by the next copy. The `## Text rules` section and the `## Written standards` section are not in this file: each repo guide holds its own.

## Commit rules

- Form: Conventional Commits, `type(scope): description`.
- Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `style`, `ci`, `build`, `perf`, `revert`, `deps`.
- Scope: a scope always. Leave it out only when the change spans the whole repo, such as a repo-wide docs or CI change. A scope is more important than a type for a later reader, so make it clear. When the repo guide names the scopes in use, pick one of them.
- Subject: lowercase, imperative mood, no period at the end, under 72 characters.
- Body: no body. A body is only for an unusual case: a subtle reason that the diff does not show, or context that would otherwise be lost. A breaking change in the repos that squash with a blank message puts its footer in the pull request body, not in a commit body (see `Breaking footer:`).
- Tests commit: `test(<scope>): <what the tests cover>`.

## Release rules

Most OPM repos release with release-please. It cuts a release whenever the changelog it generates is not empty, so the type of a commit decides whether a release happens. The repos differ, so each point that differs has a table by repo name.

- Release tool: release-please, running as the `opm-release-please` GitHub App, in `core`, `library`, `catalog_opm`, `cli`, `opm-controller`, `opm-portal`, `opm`, `docs-kit` and `modules`. `opmodel.dev`, `enhancements`, `opm-suite-installer` and `.github` have no release tool, so no commit type in them releases anything and the type follows the kind of edit.
- Releases: the type follows what ships, not the kind of edit. In the nine release-tool repos, `feat`, `fix`, `perf` and `revert` release everywhere. A type marked in the table releases too. `chore`, `test`, `ci`, `build` and `style` never release, unless the commit is breaking: a `!` in the title releases with any type.

  | Repo | Also releases |
  | --- | --- |
  | `core`, `catalog_opm`, `modules` | nothing more |
  | `library`, `cli`, `opm-controller`, `opm-portal` | `deps` and `refactor` |
  | `docs-kit` | `deps` and `refactor`, except in its `cobradump` package |
  | `opm` | `docs` |

  `docs` is hidden in every release-tool repo except `opm`.
- Title check: the check of a pull request title refuses a bare `deps` type in `cli` and `library`, and the `style` type in `cli` and `opm-portal`. Write `fix(deps)` in place of a bare `deps`. No other repo has a title check.
- Typing: the type follows what ships. (1) A dependency or pin bump takes the type of its pin class, from the table in `Pin classes:` under `## Cascade rules`. (2) Never use `chore` for a bump, and never mix a shipped bump and a test bump in one commit. One exception: in the rolling `deps/cascade` bot pull request, the shipped bump and the edits that ride it (`What rides a cascade pull request:`) squash together as one `fix(deps)` commit. (3) A Dependabot pull request keeps its title (see `Dependabot:`). (4) The commit that records the owner gates of a change ships nothing, so give it a type that never releases. (5) Pick the type of a slice commit and of a fix commit of a build the same way, by what the commit makes the release tool ship.
- Squash commit: the host settings of each repo decide what the squash commit holds.

  | Repo | Squash title | Squash message |
  | --- | --- | --- |
  | `core`, `library`, `catalog_opm`, `cli`, `opm-controller`, `opm-portal`, `opm`, `docs-kit`, `modules`, `.github` | the pull request title | blank |
  | `opmodel.dev`, `enhancements`, `opm-suite-installer` | the commit title, or the pull request title for one commit | the commit messages |

  A blank message only empties the default: a footer in the pull request body or in a branch commit never reaches the default branch. A message given at merge time does reach it, with its footers (see `Breaking footer:`). Squash is the only merge method in every repo.
- Breaking footer: in the ten repos with a blank squash message, a breaking change is `!` in the pull request title. Its exact `BREAKING CHANGE:` footer goes in a fenced block in the Notes section of the pull request body. Search the footer for `@` before the merge. The merge passes the same text as the squash message, `gh pr merge <n> --squash --body-file <file>`; otherwise the footer never reaches the default branch. In `opmodel.dev`, `enhancements` and `opm-suite-installer` nothing releases, so `!` and the footer are for a reader only, and the footer may stand in a commit body.
- Body traps: no body line that reaches the default branch may start, at column 0, with an identifier followed by `(`, such as `word(`. When the `(` does not close on that line, or the parentheses nest, release-please drops the whole commit, footer included. A column-0 body line in header form (`fix(x): ...`) counts as a commit of its own. Both traps bite any message that reaches the default branch of a release-tool repo, such as a message given at merge time. The repos that squash with the commit messages have no release tool, so nothing there reads the bodies.
- Forced version: in the nine release-tool repos a forced version is `release-as` on the package in `release-please-config.json`, set by a normal pull request and removed by the next pull request once that release is cut, because it pins every later release while it stays. A `Release-As:` footer in a pull request body or a branch commit never reaches the default branch under a blank squash message. release-please opens a release pull request only for a releasable commit. So the pull request that sets `release-as` carries a releasable title type (`fix` or `feat`), or lands together with or after a releasable commit that is not yet released. In `catalog_opm` the carrier must also change a file under `src/`, because release-please counts only commits under the package path. The four repos with no release tool have nothing to force.
- Prerelease line: to move a prerelease line, for example from alpha to beta, flipping `prerelease-type` in `release-please-config.json` is required but does nothing alone, because the next release still counts on the old line. Move the version with `release-as` (for example `"release-as": "1.0.0-beta.1"`) on the package, landed by a normal pull request with a releasable carrier, as `Forced version:` says. Remove it in the next pull request once that release is cut. For general availability, set `prerelease` to false. The next releasable commit that changes the package then drops the suffix (`X.Y.Z-beta.N` becomes `X.Y.Z`) with no `release-as`. A pull request that only flips this setting with a hidden type opens no release pull request, so each package needs a visible carrier commit, in dependency order.
- Tags: tags are immutable. Never move, delete or re-create a tag under `refs/tags/`, in any repo, and never tag by hand: release-please creates every tag, and the org rulesets `tags-create-app-only` and `tags-immutable` refuse a hand-pushed or changed tag. A version-named OCI tag on the registry (`vX.Y.Z`) is never overwritten either. A commit that landed in the wrong release is not fixed by re-tagging. Land the fix as a releasable commit so release-please cuts the next version. A Go module adds a `retract` for the bad version. A CUE or OCI artifact publishes the next version. Never repair an old release.
- Release branches: release branches are policy only until their automation lands. No repo supports them yet, so create none and fix forward on the default branch. Once they exist, a backport for a released minor is a pull request into its `release/<tag-prefix>vX.Y` branch, cut by the automated action and never by hand. The same holds for a fix to the authored `docs/site/` pages of `catalog_opm`, because the site reads them from git.
- Publishing: CI publishes. Publish nothing by hand: not a CUE module under `opmodel.dev/*`, not a container image, not a docs bundle, not a release. A publish to a local registry is allowed only when the owner asks for it in the current prompt.
- Docs fixes: a docs-only fix cuts no release in `core`, `catalog_opm`, `library`, `opm-controller`, `cli` and `opm-portal`, and does cut one in `opm`. The public docs site reads docs bundles, and a push to the default branch publishes only the `edge` bundle. So a fix reaches the site with a release or with a docs revision. A `cli` fix ships with the next `cli` release. A `core`, `library` or `opm-controller` fix ships once a `cli` release pins a version that carries it. Either can ship sooner as a docs revision that the owner dispatches by hand (the `docs.yml` workflow, `mode=revision`, `fix=<40-hex sha>`) of the exact version that the site shows. The `fix` commit changes only Markdown or only comments; a `cli` help text is a Go string and needs a release. The `catalog_opm` Catalogs tab works the same way per minor release. A fix to its authored `docs/site/` pages is built from git: from its release branch once one exists, else from the default branch while that branch still releases that minor, else from the tag.

## Cascade rules

When one OPM repo releases, each repo that pins it must move its pins. The release cascade does this with bots. Each release wakes its downstream repos. Each of them keeps at most one open bot pull request on the branch `deps/cascade` that moves its pins. The cascade never auto-merges: who merges is in `## Merge rule`.

- Cascade repos: `core`, `catalog_opm`, `library`, `opm-controller` and `cli`. `core` only sends: it pins nothing that OPM owns, so it has no receiver. The other four receive. No other repo is in the cascade.
- Release order: the repos release in tiers. A repo releases only after every repo it ships against has released.

  | Tier | Repos | Ships against |
  | --- | --- | --- |
  | 0 | `core` | nothing that OPM owns |
  | 1 | `catalog_opm` and `library`, in parallel | `core` |
  | 2 | `opm-controller` | `library` |
  | 3 | `cli` | `library`, the controller module `opmodel.dev/modules/opm_controller`, the opm catalog and `core` (templates) |

  `catalog_opm` and `library` do not depend on each other for anything they ship. The cascade stops at `cli`.
- Outside the cascade: `modules` and `opm-suite-installer` are leaves, and so is `opm-portal`. No bot moves a pin in a leaf. `modules` moves its pins with the workspace tasks `task deps:update` and `task deps:pins:opm-cli`, never by a hand edit of `cue.mod/module.cue`. `opm-suite-installer` and `opm-portal` are in no pin task yet, so their pins move by a hand-made pull request, typed by the pin class. The `opm-portal` Go module requires no OPM Go module, and its Dependabot config ignores `github.com/open-platform-model/*`. `opm` releases on its own train: it ships against nothing that OPM owns, and no repo pins it, so it has no notify job and no receiver.
- Backward edges: `catalog_opm` and `opm-controller` install the opm CLI in CI and release jobs. That pin is a release-tool pin. It never cuts a release, so the loop ends.
- Published only: never bump a pin to a version that is not published. Published means the registry serves it: GHCR for a CUE module, `proxy.golang.org` for a Go module, a non-draft release for the controller and the opm CLI. A git tag alone is not enough. A pin never moves backwards: when the newest tag is not published yet, the pin stays. Where a repo pins a catalog and `core` together, `core` moves to the version that catalog pins. `library` differs: `core` in its test modules equals `DefaultSchemaModule`, which moves first, under `need-human-review` (see `Glue:`).
- Pin classes: what a pin is for decides the type of its bump.

  | Class | Meaning | Type | Releases |
  | --- | --- | --- | --- |
  | shipped | Users receive it: `go.mod`, the `cue.mod` of a published module or catalog, `DefaultSchemaModule` in `library`, the controller pin in `internal/controller/pin.go` of `cli` with the CRDs embedded from it, the template modules under `templates/` in `cli` | `fix(deps)` | yes |
  | test | Only tests, samples, examples or the dev harness use it: `test/fixtures/*`, `tests/fixtures/*`, `config/samples/*`, `hack/*`, `examples/*`, `testdata/*`, the test `cue.mod` files under `modules/` in `library` | `test(fixtures)` | no |
  | frozen | A test keeps an old version on purpose (see `.cascade-frozen` in `Cascade files:`) | never moved | no |
  | release-tool | A tool that CI or a release job installs, such as the opm CLI in `.opm-cli-version` or a version literal in a CI workflow; a bad one can block a publish | `ci(deps)` | no |

  A cascade pull request that moves only test pins is `test(fixtures)`, and one that moves only the opm CLI pin is `ci(deps)`. Third-party pins (`CUE_VERSION`, the kind node image, Flux, `cue.dev/x/k8s.io@v0`) are outside the cascade. It never moves them.
- Bump type: type a downstream bump by what changes for the users of the downstream repo, not by what changed upstream. The class table gives the default. A shipped `fix(deps)` cuts a patch release, or the next `beta.N` on a beta line. A human retitles the pull request to `feat(deps)` when the users gain something from the new upstream, and adds `!` (`fix(deps)!:`) when the bump breaks them. The label `deps-cascade:breaking` appears when an upstream changelog in the bump has a "BREAKING CHANGES" section. The label asks for a retitle and decides nothing.
- Raise only: the bot never lowers a type and never drops a `!`. Once a human retitles a cascade pull request, the bot keeps that title. When the bot computes a higher type, it comments once and leaves the title. Never lower the type of a cascade pull request to make it pass.
- Beta lines: while a repo releases `X.0.0-beta.N` (`core`, `library`, `opm-controller`, `cli`), every releasing type, `!` included, moves it to the next `beta.N`.
- Never `!` in `catalog_opm`: it is a stable 4.x line. `feat(deps)` cuts a minor release, and `!` makes release-please propose 5.0.0 while the module path stays `opmodel.dev/catalogs/opm@v4`. Do not add `!` to its cascade pull request, even under `deps-cascade:breaking`.
- New major: the bot never crosses a new major, such as `opmodel.dev/core@v3` or `opmodel.dev/catalogs/opm@v5`. It reports "new major available". The crossing is an ordinary hand-made pull request that changes the import paths and fixes what breaks.
- What rides a cascade pull request: the shipped bump, and test, fixture or release-tool edits. Nothing else rides it. A human may push fix commits to `deps/cascade`, and the bot keeps them. Never change a file under `.github/workflows/` on `deps/cascade`: the bot then stops and adds `deps-cascade:conflict`. Move the CUE CLI pins of `cli` and `opm-controller`, which live in workflows, in a separate `ci(deps)` pull request after the cascade pull request merges.
- Red CI: add `deps-cascade:hold`, push fix commits to `deps/cascade`, then remove the label. The label means a human is pushing, and the bot leaves that pull request alone. Commit subjects stay Conventional, but they never reach the default branch.
- Conflict: on `deps-cascade:conflict`, run `git merge origin/main` locally (never a rebase), resolve it, push, and remove the label.
- Broken upstream: when the new upstream breaks this repo, land a `.cascade-hold` entry (see `Cascade files:`) on the default branch by pull request, then close the cascade pull request. Closing alone lasts only until the next receiver run, at most one day.
- Glue: on `need-human-review` (a `library` bump of `DefaultSchemaModule`, always labelled), check the kernel glue against the new `core` before the merge.
- Stop switches an agent may use: the label `deps-cascade:hold` on one pull request (see `Red CI:`), and a `.cascade-hold` entry (see `Broken upstream:`). Only the owner sets the others: the repo variable `CASCADE_DRY_RUN` (the receiver pushes nothing unless it is `false`), the repo variable `CASCADE_NOTIFY=off` (the releases of an upstream stop dispatching), disabling `deps-cascade.yml`, and suspending the cascade App. Never set them unless the owner asks in the current prompt.
- G1, release-pin gate: a step in the required job of release pull requests in `catalog_opm`, `library`, `opm-controller`, `cli` and `opm-portal`. It fails on a Go `replace`, a pseudo-version or untagged OPM Go pin, a `-0.dev.` pin in a shipped `cue.mod`, and a tracked `cue.mod/local-module.cue`. In `cli` it also fails on a controller module pin that the registry does not serve, and on a `PinnedControllerVersion` that is not the controller release of that module. G1 also fails a release pull request whose docs bundles are missing. Never merge a release pull request past a red G1, and never add one of these pins to a shipped file.
- G2 and G3: commit statuses on the head of a release pull request in `catalog_opm`, `library`, `opm-controller` and `cli`. `cascade/freshness` (G2) flags a shipped pin that is behind the newest published upstream, unless a hold in date holds it. `cascade/settled` (G3) flags an upstream that has an open `fix(deps)` or `feat(deps)` cascade pull request, or a pending release pull request with a merged `fix(deps)` cascade. Both are warnings, not required checks: a problem posts `success` with a description that starts with `WARN:`, and a clean result starts with `ok:`. On an ordinary pull request both read `n/a`. They refresh when the release pull request head moves.
- E2E: `E2E (kind, embedded operator)` is a required check in `cli`. It runs on `cli` pull requests that touch `internal/controller/` or `templates/`, on cascade pull requests, and on every release pull request. A red E2E on a release pull request stops the merge.
- Dependabot: a Dependabot pull request merged with no message squashes to its title alone, so check only the title type. A Dependabot bump of a third-party Go module keeps its `build(deps)` title, which cuts no release. Retitle it `fix(deps)` only when it must ship now. A `cuelang.org/go` or `cuelabs.dev/go/oci/ociregistry` pull request belongs only in `library`, because `cuelang.org/go` moves only through a `library` release. In `cli` and `opm-controller`, close it and add the missing `gomod` ignore. Close or hold any Dependabot pull request there whose `go.mod` diff moves `cuelang.org/go` transitively. In `library`, `TestHoistedForm_Clean` in the closedness canary must pass. If `TestTriggerForm_StillFails` goes red, upstream fixed the regression: follow the instructions of that test before the merge, and never edit the test to pass unless the matrix run shows only a reworded diagnostic. The CUE CLI pins in `cue.yml` and `cascade-task.yml` move in the same `library` pull request. As a `build(deps)` pull request it cuts no release, so `cli` and `opm-controller` receive it with the next `library` release. Dependabot never moves a `.github` cascade reference: the repo `dependabot.yml` ignores `open-platform-model/.github*`.
- Cascade files: three files at the repo root steer the cascade. A repo without a file behaves as if it were empty.
  - `.opm-cli-version`: one line, the opm CLI tag that CI and the release job install, in `catalog_opm` and `opm-controller` (see `Backward edges:`). A repo whose CI reads it must keep it. Its bump is `ci(deps)`.
  - `.cascade-frozen`: pins that a test keeps old on purpose, in `library`, `cli` and `opm-controller`. Each entry has a `path`, the frozen `pins` and a one sentence `reason`. The bot never moves a frozen pin, and G2 ignores it. A version literal that no test resolves from a registry is not a pin and needs no entry.
  - `.cascade-hold`: shipped pins that must not move past a `max` version for now. Each entry has a `pin`, a `max`, a `reason` and an `expires` date. The bot stops the pin at `max`, and G2 accepts it while the hold is in date. After `expires` the hold lapses. A hold is a decision with a deadline, not a mute button.

## Pull request rules

- Word cap: 250.
- Not counted: fenced code, URLs, trailer lines (`Spec-Impact: none`, `Co-Authored-By: ...`) and the breaking footer block.
- Style: ASD-STE100 Simplified Technical English. Short sentences: at most 20 words in a step the reviewer must do, at most 25 elsewhere. One idea per sentence, one topic per paragraph. Active voice, simple tenses. One meaning per word, no idioms. No hedging: no `should`, `may`, `might`, `could` or `probably`; state the fact or the condition. No contractions, no `e.g.`, `i.e.` or `etc.`. Describe the change, not the author. Code, paths, commands and identifiers in backticks, quoted error text, fenced code, URLs and trailer lines stay as they are.
- Required lines: a pull request that delivers a task line of an enhancement entry names that line in the body, as `Delivers NNNN, task X.Y.`. In `core`, a pull request that changes a `*.cue` file and not `SPEC.md` carries the trailer line `Spec-Impact: none`, with a reason.
- Exempt: a body that release-please, Dependabot or the cascade bot writes.

A body never holds a list of the commits, a "Not in this change" section unless someone asked, a list of tests or gates (name a test only when the reviewer must act on it), a file-by-file walkthrough, a restatement of the title, a summary of what the code plainly does, or a generated checklist. When a change needs more than the cap, the explanation belongs in a design document, an enhancement entry or an OpenSpec change: link it.

## Merge rule

Every merge is a plain squash, `gh pr merge <n> --squash --match-head-commit <sha>`, where the sha is the head that the merger saw green. Never use `--admin`: it also skips the required checks. Never merge past a red or missing required check. A breaking footer is passed as `Breaking footer:` says.

The owner merges every pull request, apart from three cases:

1. Own pull request: the agent merges a pull request that it opened when every required check is green, verify has passed, every review finding on the pull request is closed, the title and the body keep the text rules, the title type does not release in that repo (see `Releases:`), and the title has no `!`.
2. Release-please pull request: the agent merges it when all of these hold:
   - The pull request lists the change that merged. A hidden `ci` or `chore` commit never refreshes it.
   - Every required check is green.
   - Its tier is next in the order of `Release order:`. Merge tier by tier.
   - `cascade/freshness` and `cascade/settled` are green on the current head, without a `WARN:`, or the agent knows the reason. The per-PR `Cascade gates` run refreshes them whenever the head moves. If they are still missing on the current head, run `gh workflow run deps-cascade.yml -R open-platform-model/<repo> --ref main -f gates_only=true`.
   - Every commit on the pull request comes from the release bot, or is the identity-advance commit of `catalog_opm` (`chore: advance opm identity.Version to <version>`). Check it with:

     ```bash
     gh pr view <N> -R open-platform-model/<repo> --json commits \
       --jq '.commits[] | .oid[0:7] + " " + (.authors | map(.login) | join(",")) + " " + .messageHeadline'
     ```

     Any other commit, a cascade bot commit included, means the head is not what release-please wrote: do not merge, and find out who pushed it. The `release-please--*` branches have no ruleset, and both App keys can push to them.
   - In `catalog_opm`, the pull request has gained the identity-advance commit. Wait for it before the merge.

   Before the next tier, the agent confirms the tag and the published artifact of this tier.
3. The owner's word: the owner tells the agent to merge one named pull request that would wait for the owner. That word covers that pull request only.

A cascade pull request (the bot pull request on `deps/cascade`) releases, so the owner merges it, or the agent on the owner's word (case 3). The agent prepares it: it reads the diff and the body (the moved pins, the warnings, and the labels `need-human-review` and `deps-cascade:breaking`), handles red CI, a conflict or a broken upstream as `## Cascade rules` says, and tells the owner when every required check is green.

## Decision records

- ADR folder: `adr/` where it exists. It exists in `library`, `cli`, `opm-controller` and `opm`. An ADR is named with a three-digit number and a slug, `001-slug.md`, and the new number is the highest in the folder plus one. The form is `adr/TEMPLATE.md`, else the form of the newest ADR.
- Decision home: a repo with no `adr/` folder writes an ADR-sized decision, on the owner's yes and at once, into the place in this table, in that place's form. A decision is never only in the design of a change, because that is archived with the change. When the change design has a Durable decisions section, also list the decision there.

  | Repo | Decision home |
  | --- | --- |
  | `core` | `SPEC.md`, where the rationale of the constraint is |
  | `catalog_opm` | a file under `docs/` or `references/`, declared in the Durable decisions section of the change design |
  | `opm-portal` | `docs/DESIGN.md` |
  | `docs-kit` | the Decisions table of `DESIGN.md` |
  | `modules` | `DESIGN_PATTERNS.md`, or a file under `references/` |
  | `opmodel.dev` | a file under `references/`, `CONSTITUTION.md`, `README.md` or a contributor note, declared in the Durable decisions section of the change design |
  | `opm-suite-installer` | `FINDINGS.md` |
  | `enhancements` | the enhancement entry itself |
  | `.github` | a file under `references/` |
- Cross-repo decisions: a decision that binds more than one repo is not an ADR. When it shapes a major feature, it goes into an entry of the `enhancements` repo of the same organisation. A smaller change that touches several repos is tracked by one issue in the `.github` repo of the organisation. Either way it is not written into this repo: name it to the owner as an open next step. An ADR may record this repo's own rule that follows from it.
