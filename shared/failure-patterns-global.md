---
name: "failure-patterns-global"
description: "Company-wide failure patterns — inherited by ALL new projects"
domain: "cross-cutting"
confidence: "high"
source: "observed"
updated: "2026-03-30"
---

# Global Failure Patterns

These patterns were observed across multiple projects and apply to ALL Squad teams.
New projects inherit this file via init.sh → `.copilot/skills/failure-patterns-global.md`.

When you discover a NEW failure pattern in any project, add it here AND push back
to the squad-template repo so all future projects benefit.

---

## All Agents — Universal Anti-Patterns

### 1. Hallucinated Method Names

**What happened:** Agents cite methods that don't exist in the codebase.
**Correction:** Always `grep` or `find` to verify a method exists before referencing it.
**Mitigation:** Every method cited MUST be verified by search. Include file:line references.

### 2. Agent Session Expiry

**What happened:** `read_agent` fails because agent sessions expire after ~2 minutes.
**Correction:** Write results to `status.md` and orchestration log IMMEDIATELY.
**Mitigation:** Never rely on `read_agent` as the only way to get results. Always check `status.md` first.

### 3. Parallel Spawn of Dependent Agents

**What happened:** Frontend spawned while Backend was still creating endpoints. Frontend couldn't find the endpoints.
**Correction:** Serialize agents with file dependencies. Inline completed results into dependent agent prompts.
**Mitigation:** ALWAYS check: does Agent B need files from Agent A? If yes, serialize.

### 4. 3+ Parallel Agents Cause API Errors

**What happened:** Spawning 3+ agents simultaneously causes transient errors.
**Correction:** Max 2 agents per batch. Split into batches if more needed.
**Mitigation:** Hard limit: 2 parallel agents per batch.

### 5. "Would You Like..." Loops

**What happened:** Coordinator asks user for confirmation between phases, wasting time and money.
**Correction:** Auto-proceed through all phases. Only stop on repeated failures or ambiguous scope.
**Mitigation:** BANNED PHRASES list in coordinator. Never present menus.

### 6. Trusting Sync Output as Authoritative Review

**What happened:** Multi-agent sync collaboration produced well-formatted but factually wrong code review.
**Correction:** Always verify claims against source code. Cite file:line.
**Mitigation:** Sync output is ideation aid, NOT authoritative. Always verify.

---

## Implementation Agents — Code Anti-Patterns

### 7. New Files Without Registration

**What happened:** Agent created endpoint handler but forgot to register it in the router/app.
**Correction:** Every new handler/component MUST have a corresponding registration.
**Mitigation:** Checklist item: "Is the new code registered/imported where it needs to be?"

### 8. Unnecessary Dependencies

**What happened:** Agent added a package that was already available transitively.
**Correction:** Only add packages when the build actually fails with a missing type.
**Mitigation:** Check existing dependencies before adding new ones.

### 9. Code Without Build Verification

**What happened:** Agent wrote code but never ran build/test. Errors found much later.
**Correction:** Run build + test after every implementation phase.
**Mitigation:** Coordinator auto-runs build/test validation after each implementation agent completes.

---

<!-- Add new patterns below. Use sequential numbering. -->
<!-- After adding, push to squad-template repo: shared/failure-patterns-global.md -->
