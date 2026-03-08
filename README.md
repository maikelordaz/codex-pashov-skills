# Codex Pashov Skills

This repository contains a Codex-native migration of the Pashov Claude skill from:

- `https://github.com/pashov/skills.git`

The current migrated skill is:

- `solidity-auditor-codex`

Repository URL:

- `https://github.com/maikelordaz/codex-pashov-skills.git`

## Clone The Repo

```bash
git clone https://github.com/maikelordaz/codex-pashov-skills.git
cd codex-pashov-skills
```

## Install The Skill

Codex loads local skills from `~/.codex/skills`.

Install the migrated skill like this:

```bash
mkdir -p ~/.codex/skills
cp -r codex-skills/solidity-auditor-codex ~/.codex/skills/
```

After installing, restart Codex so it reloads the skill list.

## Use The Skill In The CLI

Open the Solidity repo you want to audit, then start Codex in that repo:

```bash
cd /path/to/your-solidity-repo
codex
```

Inside Codex, invoke the skill with one of these prompts:

```text
/solidity-auditor-codex
/solidity-auditor-codex deep
/solidity-auditor-codex src/Vault.sol
/solidity-auditor-codex src/Vault.sol src/Router.sol
/solidity-auditor-codex deep --file-output
```

What each mode does:

- Default: audits all in-scope Solidity files.
- `deep`: adds a slower adversarial pass.
- File paths: audits only the specified Solidity files.
- `--file-output`: asks the skill to write a markdown report instead of keeping output only in chat.

Default exclusions:

- `interfaces/`
- `lib/`
- `mocks/`
- `test/`
- `*.t.sol`
- `*Test*.sol`
- `*Mock*.sol`

## Use The Skill In The VS Code Extension

Install the skill the same way first:

```bash
mkdir -p ~/.codex/skills
cp -r codex-skills/solidity-auditor-codex ~/.codex/skills/
```

Then reload VS Code so the extension picks up the new skill:

1. Open the Command Palette with `Ctrl+Shift+P`.
2. Run `Developer: Reload Window`.

After the reload, open the Codex chat in the repo you want to audit and invoke the skill directly in the chat window.

Plain-text invocation:

```text
Use solidity-auditor-codex on this repo.
Use solidity-auditor-codex in deep mode and focus on src/Vault.sol.
Use solidity-auditor-codex and write the final report to a markdown file.
```

Slash-style invocation, if your extension build supports it:

```text
/solidity-auditor-codex
/solidity-auditor-codex deep
/solidity-auditor-codex src/Vault.sol
/solidity-auditor-codex --file-output
```

If slash-style invocation does not trigger the skill in your chat window, use the exact skill name in plain text. That is the most reliable fallback.

## Optional Helper Commands

If you want to run the bundled bash helpers manually from a target repo, use the installed skill path explicitly:

```bash
cd /path/to/your-solidity-repo

bash ~/.codex/skills/solidity-auditor-codex/scripts/discover-solidity-files.sh --repo-root . --json
bash ~/.codex/skills/solidity-auditor-codex/scripts/build-audit-input.sh --repo-root . --mode default
bash ~/.codex/skills/solidity-auditor-codex/scripts/build-audit-input.sh --repo-root . --mode deep --attack-vectors attack-vectors-1.md
cat final-report.md | bash ~/.codex/skills/solidity-auditor-codex/scripts/write-audit-report.sh --repo-root . --output-path ./audit-report.md
```

## Notes

- This is a Codex version of the original Pashov Claude skill, not a direct Claude-runtime port.
- The workflow is bash-oriented and avoids PowerShell-specific commands.
- `deep` mode improves coverage, but it does not replace a human audit.
