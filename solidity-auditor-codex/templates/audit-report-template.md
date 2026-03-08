# Security Review - <ContractName or repo name>

---

## Scope

|                                  |                                                        |
| -------------------------------- | ------------------------------------------------------ |
| **Mode**                         | `default` / `deep` / `targeted`                        |
| **Files reviewed**               | `File1.sol`, `File2.sol`, `File3.sol`                  |
| **Confidence threshold (1-100)** | `75`                                                   |

---

## Findings

[95] **1. <Title>**

`ContractName.functionName` | Confidence: 95

**Description**
<One short sentence describing the exploitable pattern and impact>

**Fix**

```diff
- vulnerable line(s)
+ fixed line(s)
```

---

[82] **2. <Title>**

`ContractName.functionName` | Confidence: 82

**Description**
<One short sentence describing the exploitable pattern and impact>

**Fix**

```diff
- vulnerable line(s)
+ fixed line(s)
```

---

## Findings List

| # | Confidence | Title |
|---|---|---|
| 1 | [95] | <title> |
| 2 | [82] | <title> |
|   |   | **Below Confidence Threshold** |
| 3 | [75] | <title> |
| 4 | [60] | <title> |

---

> This review was performed by an AI assistant. AI analysis cannot prove the absence of vulnerabilities. Human review, monitoring, and defense-in-depth are still required.

## Rules

- Sort findings by confidence, highest first.
- Keep below-threshold findings in the report, but omit the `Fix` section for them.
- Draft findings directly in this structure instead of rewriting them later.
