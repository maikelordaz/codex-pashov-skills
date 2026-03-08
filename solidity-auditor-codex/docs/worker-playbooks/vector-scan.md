# Vector Scan Playbook

Use this playbook when you want structured coverage against one attack-vector pack.

## Inputs

- The bundle created by `bash scripts/build-audit-input.sh ...`.
- One selected file from `docs/attack-vectors/`.
- The persistent policy in `AGENTS.md`.
- The final markdown structure in `templates/audit-report-template.md`.

## Process

1. Read the selected attack-vector pack and classify every vector into `Skip`, `Borderline`, or `Survive`.
2. Keep a vector in `Borderline` only when you can name the concrete function where the concept appears and describe the exploit path in one sentence.
3. For every surviving vector, trace the full external entry point to state change to impact path.
4. Apply the finding gate and confidence scoring from `AGENTS.md` immediately. Drop failed candidates instead of keeping weak notes.
5. If two confirmed findings compound each other, mention that interaction in the higher-confidence finding.
6. Emit findings directly in final report format. Do not produce an intermediate note format.

## Output Rules

- Prefer complete coverage over speed, but do not invent vectors that are not grounded in the code.
- Focus on theft, fund lock, griefing, broken accounting, broken invariants, unsafe integrations, and privilege-boundary failures.
- If no vectors survive the gate, say `No findings.` and stop.
