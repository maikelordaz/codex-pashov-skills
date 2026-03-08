# Usage

Use `solidity-auditor-codex` for fast Solidity security reviews while developing.

## Skill Modes

```bash
# Full in-scope repo review
/solidity-auditor-codex

# Full repo plus an extra adversarial pass
/solidity-auditor-codex deep

# Target specific files
/solidity-auditor-codex src/Vault.sol
/solidity-auditor-codex src/Vault.sol src/Router.sol

# Write the final markdown report
/solidity-auditor-codex --file-output
```

## Helper Commands

```bash
# Discover in-scope files and helper paths
bash scripts/discover-solidity-files.sh --repo-root . --json

# Build a reusable audit bundle for a repo-wide review
bash scripts/build-audit-input.sh --repo-root . --mode default

# Build a bundle with one attack-vector pack in scope
bash scripts/build-audit-input.sh --repo-root . --mode deep --attack-vectors attack-vectors-1.md

# Write a finished report from stdin
cat final-report.md | bash scripts/write-audit-report.sh --repo-root .
```

## Notes

- The default scope skips `interfaces/`, `lib/`, `mocks/`, `test/`, `*.t.sol`, `*Test*.sol`, and `*Mock*.sol`.
- The skill works best on smaller modules. For large codebases, review one subsystem at a time.
- `deep` mode improves coverage, but it is still not a substitute for a human audit.
