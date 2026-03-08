# Redesign Notes

This document records the behavior changes required to make the original `solidity-auditor` workflow portable to Codex.

## Deep Mode Redesign

The source skill depended on five parallel workers, explicit model pinning, and Claude-only agent orchestration. The migrated skill does not preserve that execution model.

The Codex-native replacement is a serial, script-assisted workflow:

1. Discover the in-scope Solidity files with `bash scripts/discover-solidity-files.sh`.
2. Optionally build a reusable audit bundle with `bash scripts/build-audit-input.sh`.
3. Run one structured vector-scan pass per attack-vector pack under `docs/attack-vectors/`.
4. In `deep` mode, run one additional adversarial pass using `docs/worker-playbooks/adversarial-reasoning.md`.
5. Merge, deduplicate, sort by confidence, and emit the final report directly in the template format.

This keeps the broad audit intent while removing dependencies on:

- Claude Agent tool calls
- parallel sub-agents
- per-pass model selection
- `run_in_background`
- Claude-specific read choreography

## Execution Guidance

Treat the migrated workflow as one Codex agent doing multiple deliberate passes, not a coordinator dispatching hidden workers.

- For broad pattern coverage, process `attack-vectors-1.md` through `attack-vectors-4.md` sequentially.
- For `deep` mode, run the adversarial pass after the structured vector passes.
- Use `build-audit-input.sh` when a stable bundle helps with repeated review or handoff between passes.
- Keep findings in final report format as soon as they survive the reporting gate.

## Asset Behavior Decisions

Two source behaviors were intentionally narrowed instead of reimplemented as hidden automation.

### `assets/docs`

`assets/docs` is a manual context directory.

- Place local design docs, invariant notes, and plain-English protocol explanations there.
- Read only the files that are relevant to the current review.
- Treat URL list files as operator notes only. They are not fetched automatically by the migrated skill.

### `assets/findings`

`assets/findings` is an archive and output directory.

- Generated markdown reports may be written there when `--file-output` is requested.
- External or historical audit reports may also be stored there.
- Previous findings are not re-verified automatically on every run.
- If carry-forward review is desired, read the relevant prior report manually, re-check each issue against the current code, and only then mark it as still present.

## Tradeoff Summary

The migration keeps deterministic helpers, the report contract, the attack-vector corpus, and the deep-review intent. It intentionally drops hidden orchestration and undocumented automation promises in favor of explicit, inspectable workflow steps.
