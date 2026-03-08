# Adversarial Reasoning Playbook

Use this playbook for the extra `deep` pass after the structured review.

## Inputs

- In-scope Solidity files or the bundle created by `bash scripts/build-audit-input.sh ...`.
- The persistent policy in `AGENTS.md`.
- The final markdown structure in `templates/audit-report-template.md`.

## Process

1. Assume there is at least one exploit path and keep changing perspective until you either prove the path is blocked or confirm it.
2. Review privilege transitions, accounting state machines, external call boundaries, token edge cases, initialization and upgrade flows, emergency paths, and any settlement logic that moves user funds.
3. Look for multi-step exploit paths, composability failures, griefing loops, delayed insolvency, or latent invariant breaks that are easy to miss in a pattern-only pass.
4. Apply the finding gate as soon as a candidate appears. If the exploit path is not concrete, drop it.
5. Score surviving findings with the confidence rules from `AGENTS.md`.
6. Emit confirmed findings directly in final report format, or `No findings.` if nothing survives.

## Output Rules

- Stay concrete. Name the attacker-controlled entry point, the state transition, and the impact.
- Do not keep broad speculation, trust assumptions, or governance complaints unless they become a real exploit path.
- Prefer a smaller set of defensible findings over a larger set of vague possibilities.
