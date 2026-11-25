# Verify rules of this repo

OpenSpec never writes this file; `openspec update` leaves it alone. The rules add to the
generated `openspec-verify-change` skill. Apply them in the same verify run and put their
findings in the same report.

## Checks

1. **The code review.** Load the `idea-to-code:code-review` skill once in each verify run. It reviews the diff against the repo's written standards and a smell baseline. A breach of a written standard is a finding. A smell that cites no written rule is a lead.
2. **The check for unasked work.** Read the diff that the code review read. A requirement, a scenario, a task or a Done when line must ask for each behaviour that the diff adds. Each miss is a finding.

## Task Hygiene (part of Completeness)

- Flag any task that is a delivery operation: committing, pushing, branching, opening/merging PRs, tagging, cutting releases, commit-message or PR-body hygiene checks.
- Add WARNING: "Delivery-operation task: <description>: remove it rather than checking it off; delivery happens under the repo's normal git workflow".
- Exception: skip this check when the change's stated deliverable is itself a release or publishing operation; there those steps are the implementation.

## Issue ids

Number the issues by level: CRITICAL as C1, C2; WARNING as W1, W2; SUGGESTION as S1, S2.
