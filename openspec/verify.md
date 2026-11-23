# Verify rules of this repo

OpenSpec never writes this file; `openspec update` leaves it alone. The rules add to the
generated `openspec-verify-change` skill. Apply them in the same verify run and put their
findings in the same report.

## Task Hygiene (part of Completeness)

- Flag any task that is a delivery operation other than a section-closing commit: pushing, branching, opening/merging PRs, tagging, cutting releases, commit-message or PR-body hygiene checks.
- Add WARNING: "Delivery-operation task: <description>: remove it rather than checking it off; delivery past the section commit happens under the repo's normal git workflow".
- A section-closing commit task (the last checkbox of a `## N.` section, naming a Conventional Commit) is satisfied when that commit exists in `git log`; add WARNING "Section without a commit task: <heading>" for any `## N.` section that lacks one.
- Exception: skip this check when the change's stated deliverable is itself a release or publishing operation; there those steps are the implementation.

## Issue ids

Number the issues by level: CRITICAL as C1, C2; WARNING as W1, W2; SUGGESTION as S1, S2.
