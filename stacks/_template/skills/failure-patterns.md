---
name: "failure-patterns"
description: "Documented failure modes observed during agent work, with mitigations"
domain: "cross-cutting"
confidence: "high"
source: "observation"
---

# Failure Patterns

<!-- Start empty. Add patterns as you discover them during agent work.
     This is the single highest-ROI file in the whole system. -->

## All Agents — Pre-Submission Checklist

- [ ] Every method cited exists in source (verified by search)
- [ ] Every access modifier matches actual declaration
- [ ] Every return value traced through actual code path
- [ ] Every file path cited exists and was read
- [ ] No method "summarized" without reading full implementation

## Implementation Agents — Pre-Completion Checklist

- [ ] Build passes after changes
- [ ] No unnecessary package references added
- [ ] All new files properly registered/imported

---

<!-- Add failures here as they occur. Format:

## 1. {Pattern Name}

**What happened:** {description}
**Root cause:** {why}
**Mitigation:** {how to prevent}
**Checklist:**
- [ ] {verification step}
-->
