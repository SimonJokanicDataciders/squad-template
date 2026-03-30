---
name: "squad-artifacts"
description: "Multi-agent artifact format, raw output rules, and constraint budget tracking for Squad"
domain: "coordinator"
---

## Multi-Agent Artifact Format

When multiple agents contribute to a final result, assemble the output using this structure:

### Assembly Structure

```
## Result

{Assembled, synthesized output — written by the Coordinator}

---

## Appendix: Agent Outputs

### {Agent A} — {task summary}

{Verbatim output from Agent A — no edits, no summarization}

---

### {Agent B} — {task summary}

{Verbatim output from Agent B — no edits, no summarization}
```

### Assembly Rules

- **Assembled result goes at top.** The Coordinator synthesizes and presents first.
- **Raw outputs go below in appendix.** Never omit raw agent outputs from multi-agent work — they are the audit trail.
- **Never edit raw agent outputs.** Paste verbatim. Correcting, polishing, or trimming raw output destroys evidence and violates the reviewer protocol.
- **Include termination condition** in the assembled result header when a constraint budget was active (e.g., "Budget exhausted after 3 rounds — final state below").
- **Include reviewer verdicts** when any reviewer participated. Show: agent reviewed, verdict (APPROVED / REJECTED), and any required follow-up.
- **Constraint budgets (if active):** Show as `Budget: {used}/{total} rounds remaining` in the assembled result header. Update on every round. When budget hits 0, stop and assemble final state.

### Diagnostic Format

When a multi-agent run fails or produces unexpected output, append a `## Diagnostics` section after the appendix:

```
## Diagnostics

| Agent | Status | Files produced | Notes |
|-------|--------|----------------|-------|
| {Name} | ✅ / ⚠️ / ❌ | {list} | {silent success / error / timeout} |
```

### Raw Agent Output Format Rules

Every spawned agent MUST end its response with:
1. All tool calls complete
2. A plain-text summary as FINAL output (2-3 sentences)
3. No tool calls after the summary

The Coordinator collects this final text as the "raw agent output" for assembly. If an agent's response is empty (silent success), use filesystem verification to confirm work was done (see After Agent Work in the coordinator core).

### Constraint Budget Tracking

Constraint budgets apply when the user sets a limit on rounds, retries, or agent invocations for a specific task.

**Tracking rules:**
- Initialize budget at task start: record `{total}` allowed rounds
- Decrement by 1 after each agent batch for the constrained task
- Display remaining budget in every post-work summary: `Budget: {remaining}/{total}`
- At 0: assemble final state, present to user, do NOT spawn more agents for this task
- Budget is task-scoped — it does not carry over to other tasks in the session
- If the user says "stop after X tries" or "max N rounds", treat as a constraint budget
