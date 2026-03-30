---
last_updated: {{INIT_TIMESTAMP}}
---

# Team Wisdom

Reusable patterns and heuristics learned through work. NOT transcripts — each entry is a distilled, actionable insight.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

**Pattern:** Sync collaboration produces well-formatted but ungrounded output.
**Context:** When two agents sync-review code, the format looks professional but specific claims (method names, visibility, return values) are frequently wrong. Always cite exact file:line references and verify.

**Pattern:** Role bundles should embed knowledge, not reference file paths.
**Context:** Early bundles just pointed to files. Agents performed better when actual rules, patterns, and code examples were embedded directly in skill files.

**Pattern:** Agent sessions expire quickly — write results to disk immediately.
**Context:** `read_agent` fails after short time. Coordinator must write change logs to `.squad/orchestration-log/` immediately after agent completes, before showing results. Session state in `.squad/session-state.md` survives compaction.

**Pattern:** Dependent agents must be serialized, not parallelized.
**Context:** If Agent B needs files that Agent A will create, Agent B must wait. Always serialize agents with file dependencies.

**Pattern:** Inline completed agent's output as facts in dependent agent's prompt.
**Context:** Instead of relying on Agent B reading Agent A's session (which expires), tell Agent B the results directly. Self-contained prompts are reliable; cross-agent session reads are not.

**Pattern:** Maximum 2 agents per parallel batch.
**Context:** Spawning 3+ agents simultaneously causes transient API errors consistently. Split into batches of 2.

**Pattern:** Auto-proceed through the pipeline — never ask "ready to proceed?"
**Context:** Asking the user for permission between phases kills velocity. The coordinator should run analyse → implement → build → test → document autonomously. Only stop on repeated failures or ambiguous scope.

**Pattern:** On repeated failure, collaborate across agents instead of retrying the same agent.
**Context:** A single agent retrying the same approach 3 times won't fix a systemic issue. After 2 failures, spawn a different agent to bring fresh perspective.

## Anti-Patterns

**Anti-pattern:** Trusting Squad sync output as authoritative code review.
**Why:** Agents hallucinate method names, access modifiers, and return values even when told to read specific files.

**Anti-pattern:** Assuming .squad/config.json controls the coordinator model.
**Why:** Config only affects spawned agents. Coordinator model is controlled by Copilot runtime.
