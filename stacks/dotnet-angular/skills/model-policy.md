---
name: "cap-template-model-policy"
description: "Local model preference policy for CAP.Template Squad evaluation sessions"
domain: "workflow"
confidence: "medium"
source: "manual"
---

## Context

Use this skill when running local Squad experiments where the human prefers cheap or fast models, especially `gpt-4.1`.

Primary reference files:

- `.squad/config.json`
- `.github/agents/squad.agent.md`
- `SQUAD_LOCAL_TRIAL_SUMMARY.md`

## Patterns

- Prefer `gpt-4.1` for local CAP.Template Squad trials unless a human explicitly asks for a different model.
- Keep `.squad/config.json` aligned with that preference:
  - `defaultModel`
  - `agentModelOverrides`
- At session start, restate the preferred model in natural language when practical so the coordinator has both config and prompt-level guidance.
- Treat model choice as **observed behavior**, not just desired configuration:
  - save terminal evidence
  - note when internal agents ignore the requested model
  - record the actual model seen in outputs

## Examples

- Good fit:
  - local cost-conscious evaluation
  - validating whether the Squad coordinator honors config
  - documenting model drift between requested and observed behavior

## Anti-Patterns

- Do not assume the config guarantee is working without evidence.
- Do not quietly mix models during a controlled local evaluation.
- Do not describe the model policy as solved while the coordinator still shows different models in practice.

## Session Model Recommendation

**Use `gpt-4.1` as the session model — not `claude-haiku-4.5` or similar short-context models.**

Rationale:
- The coordinator prompt alone (`squad.agent.md`) consumes approximately 40K tokens after slimming.
- `claude-haiku-4.5` has a 64K context window — barely enough for the coordinator alone, with almost nothing left for agent charters, history, skill files, and conversation history.
- `gpt-4.1` has 128K+ context — sufficient to hold the coordinator, multiple agent charters inlined at spawn time, decision history, and active conversation context simultaneously.
- Running on haiku risks silent context truncation that causes the coordinator to lose routing rules, miss section content, or produce incoherent responses mid-session.

The current `.squad/config.json` reflects this: `"defaultModel": "gpt-4.1"`.

## Coordinator vs Agent Model Architecture

The Squad runtime uses a two-tier model architecture that the config cannot fully control:

- **Coordinator model:** Always assigned by the Copilot runtime. Observed in Phase 1 as `claude-sonnet-4.6` regardless of what `.squad/config.json` specifies. There is no mechanism to override the coordinator model from within the Squad config or from a prompt instruction.
- **Spawned agent model:** The `defaultModel` and `agentModelOverrides` in `.squad/config.json` apply only to agents that are spawned via the `task` tool. These settings are honored when the coordinator passes an explicit `model` parameter in the task invocation.
- **To force gpt-4.1 on agents:** Pass `model: "gpt-4.1"` explicitly when invoking the task tool. Do not rely on config alone — treat it as a default hint, not a guarantee.
- **Evidence:** `SQUAD_MODEL_RETEST_OUTPUT.md` recorded the coordinator self-identifying as `claude-sonnet-4.6` in the model table, with the note: "my model cannot be self-overridden regardless of .squad/config.json."
