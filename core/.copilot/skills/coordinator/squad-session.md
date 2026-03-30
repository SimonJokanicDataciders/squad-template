# Squad Session Management

> Load this when user asks about session recovery, session management, or client compatibility.

---

## Session Recovery

When a session is interrupted (crash, timeout, network loss) or the user returns after a long absence, the coordinator performs session recovery.

### Recovery Trigger Signals

- User explicitly asks: "what happened?", "catch me up", "status", "what did the team do?"
- The coordinator detects a different user than the one in the most recent session log
- The user returns after an absence of > 2 hours (check last session log timestamp)

### Recovery Procedure

1. **Scan orchestration logs** — read `.squad/orchestration-log/` for entries newer than the last session log in `.squad/log/`
2. **Summarize** — present a brief summary: who worked, what they did, key decisions made
3. **Keep it short** — 2-3 sentences. The user can dig into logs and decisions if they want the full picture
4. **Check open work** — are there unfinished tasks? Draft PRs? Assigned but unstarted issues?
5. **Resume or handoff** — offer to continue where the team left off

**Recovery summary format:**
```
📋 Since your last session ({relative time} ago):
- {AgentName} completed {work item}
- {AgentName} is partway through {work item} — {status}
- {N} decisions were recorded

{If open work exists:} Open: {brief list}. Want me to pick these up?
```

### Session Persistence

Session state that persists across sessions (in `.squad/` files):
- `decisions.md` — all team decisions, accumulated
- `agents/*/history.md` — each agent's learnings and context
- `orchestration-log/` — record of every agent spawn
- `log/` — session summaries
- `identity/now.md` — what the team was last focused on (coordinator updates this)
- `identity/wisdom.md` — high-value cross-session learnings

Session state that does NOT persist (in-memory only):
- Ralph's active/idle status and loop state
- Current response mode selection
- Context cache (team.md, routing.md, registry.json)

### Identity Files

**`.squad/identity/now.md`** — Current focus. The coordinator reads this on session start to know where the team left off, and updates it when focus shifts.

Format:
```markdown
# Current Focus

**As of:** {ISO timestamp}
**Requested by:** {user name}
**Focus:** {1-2 sentence description of what the team is working on}
**Active agents:** {comma-separated names of agents with open work}
```

**`.squad/identity/wisdom.md`** — Cross-session learnings that are too important to bury in history.md. Agents write here for things the whole team (including future sessions) should know.

Format:
```markdown
# Team Wisdom

## {Topic}
**Learned:** {date}
**By:** {agent name}
{The insight — specific, actionable}
```

---

## Client Compatibility Detection

Squad runs on multiple Copilot surfaces. The coordinator MUST detect its platform and adapt spawning behavior accordingly. See `docs/scenarios/client-compatibility.md` for the full compatibility matrix.

### Platform Detection

Before spawning agents, determine the platform by checking available tools:

1. **CLI mode** — `task` tool is available → full spawning control. Use `task` with `agent_type`, `mode`, `model`, `description`, `prompt` parameters. Collect results via `read_agent`.

2. **VS Code mode** — `runSubagent` or `agent` tool is available → conditional behavior. Use `runSubagent` with the task prompt. Drop `agent_type`, `mode`, and `model` parameters. Multiple subagents in one turn run concurrently (equivalent to background mode). Results return automatically — no `read_agent` needed.

3. **Fallback mode** — neither `task` nor `runSubagent`/`agent` available → work inline. Do not apologize or explain the limitation. Execute the task directly.

If both `task` and `runSubagent` are available, prefer `task` (richer parameter surface).

### VS Code Spawn Adaptations

When in VS Code mode, the coordinator changes behavior in these ways:

- **Spawning tool:** Use `runSubagent` instead of `task`. The prompt is the only required parameter — pass the full agent prompt (charter, identity, task, hygiene, response order) exactly as you would on CLI.
- **Parallelism:** Spawn ALL concurrent agents in a SINGLE turn. They run in parallel automatically. This replaces `mode: "background"` + `read_agent` polling.
- **Model selection:** Accept the session model. Do NOT attempt per-spawn model selection or fallback chains — they only work on CLI. In Phase 1, all subagents use whatever model the user selected in VS Code's model picker.
- **Scribe:** Cannot fire-and-forget. Batch Scribe as the LAST subagent in any parallel group. Scribe is light work (file ops only), so the blocking is tolerable.
- **Launch table:** Skip it. Results arrive with the response, not separately. By the time the coordinator speaks, the work is already done.
- **`read_agent`:** Skip entirely. Results return automatically when subagents complete.
- **`agent_type`:** Drop it. All VS Code subagents have full tool access by default. Subagents inherit the parent's tools.
- **`description`:** Drop it. The agent name is already in the prompt.
- **Prompt content:** Keep ALL prompt structure — charter, identity, task, hygiene, response order blocks are surface-independent.

### Feature Degradation Table

| Feature | CLI | VS Code | Degradation |
|---------|-----|---------|-------------|
| Parallel fan-out | `mode: "background"` + `read_agent` | Multiple subagents in one turn | None — equivalent concurrency |
| Model selection | Per-spawn `model` param (4-layer hierarchy) | Session model only (Phase 1) | Accept session model, log intent |
| Scribe fire-and-forget | Background, never read | Sync, must wait | Batch with last parallel group |
| Launch table UX | Show table → results later | Skip table → results with response | UX only — results are correct |
| SQL tool | Available | Not available | Avoid SQL in cross-platform code paths |
| Response order bug | Critical workaround | Possibly necessary (unverified) | Keep the block — harmless if unnecessary |

### SQL Tool Caveat

The `sql` tool is **CLI-only**. It does not exist on VS Code, JetBrains, or GitHub.com. Any coordinator logic or agent workflow that depends on SQL (todo tracking, batch processing, session state) will silently fail on non-CLI surfaces. Cross-platform code paths must not depend on SQL. Use filesystem-based state (`.squad/` files) for anything that must work everywhere.

---

## Constraint Budget Tracking

**On-demand reference:** Read `.squad/templates/constraint-tracking.md` for the full constraint tracking format, counter display rules, and example session when constraints are active.

**Core rules:**
- Format: `📊 Clarifying questions used: 2 / 3`
- Update counter each time consumed; state when exhausted
- If no constraints active, do not display counters
- Constraint state is session-scoped — does not persist across sessions

---

## Session Catch-Up (Lazy Loading)

Do NOT scan logs on every session start. Only provide a catch-up summary when:
- The user explicitly asks ("what happened?", "catch me up", "status", "what did the team do?")
- The coordinator detects a different user than the one in the most recent session log

When triggered:
1. Scan `.squad/orchestration-log/` for entries newer than the last session log in `.squad/log/`.
2. Present a brief summary: who worked, what they did, key decisions made.
3. Keep it to 2-3 sentences. The user can dig into logs and decisions if they want the full picture.
