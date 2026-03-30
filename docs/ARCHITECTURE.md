# Architecture

## 3-Tier Separation

### Tier 1: Core Engine (universal)

The optimized coordinator prompt at `.github/agents/squad.agent.md` is the brain. It was reduced from 21,600 lines (default) to 800 lines through:

1. **On-demand module loading** — 10 coordinator modules in `.copilot/skills/coordinator/` are only read when keywords trigger them (e.g., "init", "cast", "issue", "mesh")
2. **Removed redundancy** — merged duplicate sections, eliminated verbose examples
3. **Preserved all behavior** — same bootstrap protocol, model selection, parallel fan-out, failure recovery, reviewer lockout

Key optimizations embedded in the coordinator:
- **Bootstrap in 1 turn** — reads 10 files in parallel on session start
- **Charter inlining** — pastes charters into spawn prompts (eliminates 4-5 agent self-reads, enables 96% prompt caching)
- **Auto-proceed** — never asks "ready to proceed?" between phases
- **Max 2 parallel agents** — prevents transient API errors from 3+ spawns
- **Failure collaboration** — after 2 failures, spawns a different agent to help

### Tier 2: Stack Presets (per tech stack)

Stack presets contain the actual domain knowledge that makes agents effective:

- **Agent charters** — guardrails, coding conventions, skill loading protocols
- **Skill bundles** — embedded patterns, code examples, reference implementations
- **Routing tables** — precise mapping of work types to agents
- **Ceremonies** — quality gate triggers specific to the stack
- **Failure patterns** — documented failures and mitigations

**Tiered loading**: Each agent has a core bundle (always loaded, ~250 lines) and on-demand modules (loaded only when relevant). This saves 70-80% context overhead vs loading everything.

### Tier 3: Per-Project (generated at runtime)

Created by Squad's Init Mode when you first run `copilot --agent squad`:

- `team.md` — roster with cast names from a fictional universe
- `agents/{name}/charter.md` — per-agent identity (you paste guardrails from Tier 2 charters)
- `agents/{name}/history.md` — personal learnings (append-only)
- `decisions.md` — shared decision log (append-only, union merge)
- `casting/` — persistent name registry

## Key Patterns

### Drop-Box Pattern

Agents never write directly to `decisions.md`. Instead:
1. Each agent writes to `.squad/decisions/inbox/{agent-name}-{slug}.md`
2. Scribe merges inbox into `decisions.md` and clears inbox
3. No file conflicts on parallel writes

### Union Merge

`.gitattributes` configures `merge=union` for append-only files:
- `decisions.md`, `agents/*/history.md`, `log/**`, `orchestration-log/**`
- This makes parallel branching and worktree-based development safe

### Session State Persistence

Agent sessions expire quickly. The coordinator writes results to:
- `.squad/orchestration-log/` — per-agent change logs (immediate, before Scribe)
- `.squad/session-state.md` — completed/pending/blocked status
- These survive context compaction and session expiry

### Model Selection Hierarchy

4 layers, first match wins:
1. **Persistent config** — `config.json` (survives sessions)
2. **Session directive** — "use opus for this session"
3. **Charter preference** — agent's preferred model
4. **Task-aware auto** — code → Sonnet, docs → Haiku, vision → Opus
