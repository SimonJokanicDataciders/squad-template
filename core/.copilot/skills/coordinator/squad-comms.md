# Squad External Communications

> Load this when user asks about external communications, community responses, or public messaging.

---

## External Communications & PAO Workflow

Squad supports structured external communication workflows for community engagement, public messaging, and developer relations content.

### PAO (Public Affairs Officer) Workflow

When Squad has a DevRel, Writer, or Communications role on the team, external communications follow the PAO workflow:

**Trigger signals:**
- "draft a response to this issue/tweet/post"
- "reply to the community about X"
- "write a blog post / announcement / changelog"
- "respond to this feedback"
- "craft an external message"

**PAO workflow steps:**
1. **Route to the writer/DevRel agent** — spawn with the PAO template (see below)
2. **Review gate** — external communications ALWAYS go through a review before publishing. Route to Lead or a human reviewer.
3. **Humanize pass** — apply humanizer patterns (see below) before finalizing
4. **Publish or hand off** — deliver the final draft to the user for publishing, or publish via MCP tools if configured

### PAO Spawn Template

```
agent_type: "general-purpose"
model: "claude-haiku-4.5"
mode: "background"
description: "📝 {WriterAgent}: Draft external communication"
prompt: |
  You are {Name}, the {Role} on this project.

  YOUR CHARTER: {charter}
  TEAM ROOT: {team_root}

  **Requested by:** {current user name}

  TASK: Draft an external communication.

  TYPE: {blog post | community response | changelog | announcement | tweet/X | release notes}
  AUDIENCE: {developers | end users | community | press}
  TONE: {friendly | professional | technical | casual}
  CONTEXT: {what this is about}
  KEY POINTS: {bullet list of must-include points}
  WORD LIMIT: {if specified}

  Apply humanizer patterns (see below).

  OUTPUT: The draft text only. No meta-commentary.

  HUMANIZER PATTERNS to apply:
  - Write like a human, not a press release
  - Use "we" when referring to the team, "you" for the reader
  - Lead with value, not process
  - Avoid: "excited to announce", "thrilled to share", "leverage", "utilize"
  - Prefer: specific, concrete language over vague superlatives
  - Contractions are fine ("we're", "you'll", "it's")
  - Acknowledge tradeoffs honestly — don't oversell

  ⚠️ RESPONSE ORDER: After ALL tool calls, write the draft as FINAL output.
```

### Humanizer Patterns

Apply these rules to any externally-facing content:

**Do use:**
- Short sentences (avg < 20 words)
- Active voice ("We fixed" not "The bug was fixed")
- Concrete specifics ("reduced load time by 40%" not "significant improvement")
- "we" for team references, "you" for reader
- Plain English alternatives to jargon

**Avoid:**
- Buzzword openers: "excited to announce", "thrilled to share", "proud to introduce"
- Passive voice overuse
- Vague superlatives: "best-in-class", "cutting-edge", "game-changing"
- Corporate jargon: "leverage", "utilize", "synergy", "paradigm shift"
- Hedging everything: "potentially", "may or may not", excessive caveats

**Community response template structure:**
```
[Acknowledge the specific thing raised]
[What we did or why we made this choice]
[What this means for them]
[Next steps or call to action, if any]
```

### Community Response Templates

**Bug report response:**
```
Thanks for the report! This is [confirmed/under investigation/a known issue].

[What it affects and when]
[Fix status: in next release / workaround available / being investigated]
[ETA if known]

[Workaround if available]
```

**Feature request response:**
```
[Acknowledge the use case specifically]

[Current state: planned / considering / not on roadmap / shipped in X]
[If not planned: why, and what alternatives exist]
[If planned: rough timeline or tracking link]
```

**Breaking change announcement:**
```
## What's changing
[Specific thing changing, not vague "improvements"]

## Why
[Real reason — performance, correctness, simplicity — not "we think this is better"]

## What you need to do
[Exact migration steps, not "update your code"]

## Timeline
[Deprecation date if applicable]
[Support period for old behavior]
```

### Review Gate for External Comms

External communications MUST be reviewed before publishing. The coordinator:
1. Spawns the writer agent (background)
2. Collects the draft
3. Presents it to the user for review: *"Here's the draft from {WriterAgent}. Want me to refine anything before you publish?"*
4. Does NOT publish automatically unless explicitly told to

If the repo has a human reviewer configured (see Human Team Members), route to them first.
