---
name: discussion-validation
description: 'Validate the DOD discussion direction before promotion. Use for checking whether the broad scan covered the right landscape, whether the narrowed focus is justified, and whether candidate decisions fit the original objective, active constraints, invariants, non-goals, and likely drift before updating DECISIONS.yml.'
user-invocable: false
---

# Discussion Validation

## Purpose
Use this skill for Gate A step 2: discussion-validation.
Its job is to perform the pre-promotion audit that confirms the proposed direction is worth making active and that the discussion did not narrow too early.

## Required Inputs
- Discussion ID
- The latest entry in `records/{discussion-id}.md`
- Current target decisions and contracts in `DECISIONS.yml`
- Original objective and requested scope

## Procedure
1. Read the latest discussion result and active constraints.
   Start from the updated record entry, then inspect the current decisions that would be changed or relied on.
2. Check landscape coverage.
   Confirm that the discussion scanned the affected landscape broadly enough to identify the main domains, adjacent concerns, likely interfaces, and omission risks relevant to the current scope.
3. Check whether the narrowed focus is justified.
   Confirm that the chosen focus areas follow from the broad scan rather than from premature locality, and that important exclusions or uncertainties are explicit.
4. Check directional fit.
   Confirm that the candidate direction still serves the original objective and requested scope.
5. Check contract fit.
   Test the candidate direction against active invariants, non-goals, acceptance criteria, and failure criteria.
6. Check for hidden bindings.
   Identify any new independently active rule that would need to be promoted as a new decision or sub-decision instead of staying implicit.
7. Run the default pre-promotion audit.
   Treat audit work here as part of validation: inspect likely drift, missing constraints, overloaded decisions, premature scope growth, and omission risk caused by narrowing too soon.
8. Decide pass or return.
   If the direction is still sound, name the exact decisions that should be promoted or updated. If not, return to discussion and state what must be clarified.

## Guardrails
- Do not promote a conclusion while directional ambiguity remains.
- Do not accept a direction if the broad scan was too shallow to justify the chosen focus.
- Do not skip newly discovered binding constraints; promote them in the same change set when the direction passes.
- Do not turn validation into broad redesign.
- Do not add a third lifecycle phase; keep this as a lightweight pre-promotion checkpoint.

## Completion Criteria
- The candidate direction is either explicitly validated or explicitly rejected.
- The record shows that broad-scan coverage and narrowed focus were both checked.
- Promotion targets are named precisely when validation passes.
- Drift, hidden constraints, and contract gaps are surfaced before `DECISIONS.yml` is edited.