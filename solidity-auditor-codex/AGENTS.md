# AGENTS.md

Instructions for Codex when running or maintaining `solidity-auditor-codex`.

## Scope

Apply this policy to every audit run and report generated under this skill folder.

## Finding Gate

Report a finding only if all three checks pass:

1. Trace a concrete attack path from attacker-controlled entry point to state change to loss, griefing outcome, or invariant break.
2. Confirm the attacker can actually reach the entry point after modifiers, role checks, and `msg.sender` restrictions.
3. Confirm no existing guard already blocks the attack path.

Evaluate what the code allows, not what a trusted deployer might choose to do later. Drop any candidate that fails a gate instead of downgrading it into a weak report item.

## Confidence

Confidence measures certainty that the issue is real and exploitable, not severity.

- Start every reportable finding at `100`.
- Deduct `25` if exploitation requires a privileged caller such as an owner, admin, multisig, or governance actor.
- Deduct `20` if the exploit idea is sound but the exact caller -> function -> state change -> outcome path is still partial.
- Deduct `15` if the impact is self-contained and only harms the attacker or their own funds.
- Use the score indicator as `[score]`.
- Treat `75` as the default confidence threshold.
- Keep below-threshold findings in the report, but give them a description only and omit the `Fix` section.

## Do Not Report

- Info-level notes, gas suggestions, naming issues, NatSpec gaps, or redundant comments.
- Intended owner or admin powers such as setting fees, changing parameters, or pausing the system.
- Missing events or weak logging by themselves.
- Centralization complaints without a concrete exploit path.
- Theoretical issues that depend on implausible preconditions.

Treat common ERC20 edge cases such as fee-on-transfer, rebasing, pausing, or blacklisting as valid attack surfaces when the protocol accepts arbitrary tokens.
