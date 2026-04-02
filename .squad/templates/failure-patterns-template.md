---
name: "failure-patterns"
description: "Documented failure modes observed during agent work, with mitigations"
domain: "cross-cutting"
confidence: "high"
source: "observation"
---

# Failure Patterns

Documented failures observed during agent work. Each pattern includes what went wrong and how to prevent it.

<!-- Add new patterns as they are discovered. Format below. -->

## All Agents — Pre-Submission Checklist

- [ ] Every method cited exists in source (verified by search)
- [ ] Every access modifier matches actual declaration
- [ ] Every return value traced through actual code path
- [ ] Every file path cited exists and was read
- [ ] Every line number referenced matches content
- [ ] No method "summarized" without reading full implementation

## Implementation Agents — Pre-Completion Checklist

- [ ] Build passes after changes
- [ ] No unnecessary package references added (check if already transitive)
- [ ] All new files are properly registered/imported where needed

---

<!-- ## 1. {Pattern Name}

**What happened:** {description of the failure}
**Root cause:** {why it happened}
**Mitigation:** {how to prevent it}
**Checklist:**
- [ ] {verification step}
-->
