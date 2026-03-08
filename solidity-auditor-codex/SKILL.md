---
name: solidity-auditor-codex
description: Security review skill for Solidity contracts and protocols. Use when Codex needs to audit a Solidity repo, check a contract for exploitable bugs, review smart contracts for security issues, or produce a structured findings report. Supports default full-repo scans, `deep` multi-pass reviews, and targeted scans of specific `.sol` files.
---

# Solidity Auditor

Audit Solidity code for ways to steal funds, lock funds, grief users, or break core protocol invariants.

## Invocation

Use one of these modes:

- Default: audit all in-scope Solidity files.
- `deep`: audit all in-scope Solidity files, then add an explicit adversarial reasoning pass.
- `file1.sol file2.sol ...`: audit only the specified Solidity files.

Honor `--file-output` only when the user explicitly asks for a markdown report file. Otherwise, keep output in the terminal.

## Scope Rules

Apply these exclusions in every mode unless the user explicitly overrides them:

- Skip directories `interfaces/`, `lib/`, `mocks/`, and `test/`.
- Skip files matching `*.t.sol`, `*Test*.sol`, and `*Mock*.sol`.

If the user passes file paths, treat those files as the scope. Otherwise use `scripts/discover-solidity-files.sh` to discover `.sol` files and resolve the skill-local helper paths without any glob lookup.

If no in-scope Solidity files remain after filtering, stop and say so clearly.

## Workflow

1. Determine the audit scope and enumerate the Solidity files to review.
2. Apply the persistent reporting policy from `AGENTS.md` before deciding that any issue is reportable.
3. Run a first-pass review for theft, fund lock, griefing, accounting errors, access control failures, reentrancy, unsafe token interactions, upgrade mistakes, and broken invariants.
4. Run a second pass for cross-function, cross-contract, and state-machine issues. In `deep` mode, make this pass slower and more adversarial: look for multi-step exploit paths, composability failures, privilege-boundary mistakes, and attack chains that need setup.
5. Use sequential multi-pass analysis. Do not assume Claude sub-agents, model pinning, `run_in_background`, Bash-only commands, or Unix-only temp paths.
6. Deduplicate findings by root cause, keep the higher-confidence version, sort highest confidence first, and renumber sequentially.

## Report Contract

Produce findings directly in their final markdown form. Do not generate raw notes that need a second rewrite pass.

- Output to the terminal by default.
- Write a markdown file only when `--file-output` is explicitly requested.
- When writing a file, use `assets/findings/{project-name}-pashov-ai-audit-report-{timestamp}.md`.
- Include a scope section with the mode, reviewed files, and confidence threshold.
- Insert a `Below Confidence Threshold` separator row in the findings summary table.
- Omit the `Fix` section for findings below the confidence threshold.

If no findings survive the reporting gate, state that no reportable findings were found.

## Operating Notes

- Skip the source banner. It is presentation-only and currently encoding-corrupted.
- Treat any version check as optional and non-blocking. Use `bash scripts/check-version.sh --check-remote` only when that extra check is worth the latency.
- For codebases above roughly `2500` lines of Solidity, prefer reviewing module-by-module over one giant pass.
- AI review is strongest on concrete exploit patterns and weaker on broad specification reasoning. `deep` mode improves coverage, but it does not replace a human audit.
