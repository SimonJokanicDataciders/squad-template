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

**Pattern:** Detect project type before running ANY build or test commands.
**Context:** Running `dotnet build` on a React project or `npm test` on a .NET project wastes time and confuses the user. Always check package.json / *.csproj / pyproject.toml first.

**Pattern:** Install dependencies before building or testing.
**Context:** `npm run build` fails if `node_modules/` doesn't exist. `dotnet build` fails without restore. Always ensure dependencies are installed first.

**Pattern:** Referenced files (@file) are task specifications — parse and execute immediately.
**Context:** When a user says "read @stress-test.md and execute", the coordinator should parse the file, extract all requirements, and begin spawning agents. Never summarize it back and ask "what should I do?"

**Pattern:** Honor model overrides from user's task specification.
**Context:** If stress-test.md says "use claude-opus-4-6", pass that model explicitly in every spawn. The user's task spec overrides config.json defaults.

**Pattern:** Read project-map.md before starting work.
**Context:** Skill bundles describe conventions; project-map.md describes what actually exists. Agents need both to work effectively.

**Pattern:** Agents must self-validate before handing off.
**Context:** In stress tests, 5 validation rounds were needed because agents handed off code with TypeScript errors, lint failures, and dependency mismatches. Each agent should run `npm run build` or equivalent BEFORE marking work as done. The coordinator should only run final validation once, not fix-loop 5 times.

**Pattern:** Use log redirection for long-running shell commands.
**Context:** `npm run build && npm test && npm run build-storybook` in one TTY shell appears hung because Vite's spinner doesn't emit stdout. Use `command >/tmp/log.log 2>&1; echo $?` to capture output and exit codes cleanly. Never chain 5+ commands in a single interactive shell.

**Pattern:** Sub-agents work well for phased implementation — don't over-formalize.
**Context:** Dallas spawned 4 sub-agents for different implementation phases and it worked. The `## Sub-Agent Capability` section in charters is sufficient. Don't add more sub-agent orchestration structure — it increases coordinator prompt size without clear benefit.

## Anti-Patterns

**Anti-pattern:** Trusting Squad sync output as authoritative code review.
**Why:** Agents hallucinate method names, access modifiers, and return values even when told to read specific files.

**Anti-pattern:** Assuming .squad/config.json controls the coordinator model.
**Why:** Config only affects spawned agents. Coordinator model is controlled by Copilot runtime.

**Anti-pattern:** Asking "What's your priority?" or "What feature should the team start with?" after reading a task file.
**Why:** The task file IS the instruction. Parse it and execute. Asking the user to repeat themselves is the #1 velocity killer.

**Anti-pattern:** Running build commands without checking project type.
**Why:** Stack-specific charters may reference .NET commands, but the actual project could be React. Always detect first.

**Anti-pattern:** Blocking on read_agent failures.
**Why:** Agent sessions expire quickly. read_agent failing does NOT mean the agent failed — it means the session expired. Check status.md and output files on disk instead. Never halt progress because of a read_agent failure.

**Anti-pattern:** Omitting the model parameter when spawning agents.
**Why:** If model is omitted, the platform picks its own default (often gpt-4.1 free tier). Always pass the model explicitly — even for claude-sonnet-4.6. The user expects the model they configured, not a silent fallback.
