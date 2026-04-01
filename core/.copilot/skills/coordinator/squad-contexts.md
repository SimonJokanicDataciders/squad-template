# Squad Contexts — Behavioral Mode Switching

**Load when:** Any task starts. Use to set the right behavioral mode for agents.

---

## Context Detection

Before spawning agents, determine the context from the user's request:

| User Intent | Context | Behavior |
|------------|---------|----------|
| "build", "implement", "add feature", "create", "fix" | **Development** | Write code first, explain after. Prefer working solutions. Run tests after changes. |
| "analyze", "investigate", "understand", "explore", "why" | **Research** | Read widely before concluding. Don't write code until understanding is clear. Document findings. |
| "review", "check", "audit", "evaluate" | **Review** | Read thoroughly before commenting. Prioritize by severity. Suggest fixes, don't just point out problems. |

## Development Context

When agents are in development mode:

- **Priority:** Get it working → Get it right → Get it clean
- **Tools to favor:** Edit, Write for code changes. Bash for running tests/builds.
- **Behavior:** Write code first, explain after. Keep commits atomic. Run build/test after every change.
- **Output:** Code files, then a brief summary of what was created/changed.

## Research Context

When agents are in research/exploration mode:

- **Priority:** Understand before acting
- **Tools to favor:** Read, Grep, Glob for finding code. Bash for checking structure.
- **Behavior:** Read existing code widely before concluding. Ask clarifying questions via decisions inbox. Don't write code until understanding is clear.
- **Output:** Findings first, recommendations second.
- **Process:** Understand the question → Explore relevant code → Form hypothesis → Verify with evidence → Summarize findings

## Review Context

When agents are in review mode:

- **Priority:** Quality, security, maintainability
- **Tools to favor:** Read, Grep, Glob for analysis. Edit only for suggested fixes.
- **Behavior:** Read thoroughly before commenting. Prioritize issues by severity (CRITICAL > HIGH > MEDIUM > LOW). Suggest fixes, don't just point out problems. Check for security vulnerabilities.
- **Output:** Group findings by file, severity first.
- **Review checklist:**
  - [ ] Logic errors and edge cases
  - [ ] Error handling completeness
  - [ ] Security (injection, auth, secrets)
  - [ ] Performance concerns
  - [ ] Test coverage for changes
  - [ ] Code readability and conventions

## Passing Context to Agents

Include the context in the agent's spawn prompt:

```
CONTEXT: {Development | Research | Review}
BEHAVIOR: {brief behavior directive from the matching context above}
```

Agents should adjust their approach based on the context — a Development context agent writes code immediately, while a Research context agent reads and analyzes first.
