# Integrating Squad Into Your Project

> **Note:** This is NOT the official [Squad](https://github.com/bradygaster/squad) installation.
> This is an optimized variant with custom coordinator, per-agent model routing, auto-proceed pipeline,
> self-validation, and language-specific rules. Repository: [SimonJokanicDataciders/squad-template](https://github.com/SimonJokanicDataciders/squad-template)

---

## Prerequisites

1. **GitHub Copilot** with agent mode enabled
2. **CLI model: GPT-5.1 HIGH** — set this in your Copilot CLI settings before starting. Other models will work but all agents will use the same model instead of routing per agent (opus/sonnet/haiku).
3. **Git repository** — your project must already be a git repo (`git init`). Squad stores its configuration in files that are tracked by git.

---

## Step 1: Clone the template (once)

```bash
git clone https://github.com/SimonJokanicDataciders/squad-template.git ~/squad-template
```

---

## Step 2: Install Squad

### Existing project

```bash
# Auto-detect your tech stack and apply matching preset/seeds (recommended)
~/squad-template/init.sh ~/path/to/project --auto

# Or specify a stack preset explicitly (use this if you know the preset name)
~/squad-template/init.sh ~/path/to/project --stack dotnet-angular

# See available presets and seeds
~/squad-template/init.sh --help
```

> **`--auto` vs `--stack`:** Use `--auto` if you're not sure — it scans your project's config files (package.json, *.csproj, pyproject.toml, etc.) and picks the best match automatically. Use `--stack` only if you know exactly which preset you want.

### New project from scratch

```bash
mkdir ~/my-project
cd ~/my-project
git init
~/squad-template/init.sh ~/my-project --auto
```

### What happens?

The script adds **only new directories** (`.squad/`, `.github/agents/`, `.copilot/`) — your existing source code, configs, and dependencies are **never** touched:

```
your-project/
├── .github/agents/squad.agent.md     ← Coordinator (the brain)
├── .github/instructions/             ← Coding standards (auto-detected)
├── .copilot/skills/                  ← Agent knowledge + coordinator modules
├── .squad/
│   ├── agents/                       ← 6 agent charters with model routing
│   ├── config.json                   ← Model preferences per agent
│   ├── team.md                       ← Team roster
│   ├── routing.md                    ← Work routing rules
│   ├── project-map.md                ← Detected project structure
│   └── seeds/                        ← 15 tech stack seeds
└── (existing code unchanged)
```

---

## Step 3: Start Squad

```bash
cd ~/path/to/project
copilot --agent squad
```

To skip all approval prompts (file creation, terminal commands, installs), use yolo mode:

```bash
copilot --agent squad --yolo
```

> **When to use `--yolo`:** On test projects, greenfield apps, or when you trust Squad to run autonomously. Don't use it on production codebases without reviewing the output first — you can always `git diff` after the run.

---

## Step 4: Give it a task

Squad works best when your prompt is specific about **what** you want but leaves the **how** to the agents. Here's how to write effective prompts:

### Prompt structure

```
[What to build/fix/analyze]
[Key requirements — entities, endpoints, pages, constraints]
[Which patterns to follow — reference existing code if possible]
[What the output should include — tests, docs, migrations]
```

Example:
```
Add a new Inventory feature.
Entity with Id, ProductId, Quantity, Warehouse, LastUpdated.
CRUD endpoints at /api/inventory, Angular list + form page.
Follow the WeatherForecasts pattern in src/Domain/WeatherForecasts/.
Include unit tests, integration tests, and EF Core migration.
```

The more specific your requirements, the fewer follow-up questions the coordinator will ask — and the fewer premium requests you'll use.

### For existing projects

Tell Squad what you want and point it to existing patterns:

```
Create a complete [feature name] feature with:
- [Entity/model] with [key fields and constraints]
- [Backend: endpoints, services, database changes]
- [Frontend: pages, components, forms]
- [Tests: unit + integration covering the new feature]
Follow the existing [reference feature] pattern in [path/to/reference].
```

Example (.NET + Angular project):
```
Create a complete OrderItem feature with:
- OrderItem entity with Id, ProductName, Quantity, Price, CreatedAt
- CRUD endpoints at /api/order-items with DTOs
- Angular list + detail + form components
- xUnit unit tests and integration tests
Follow the existing WeatherForecasts pattern in src/Paso.Cap.Domain/WeatherForecasts/.
```

Other common tasks:

```
Fix the [bug description] in [file or area].
Analyze the root cause, implement the fix,
and write a test that prevents regression.
```

Example:
```
Fix the null reference exception in src/Domain/OrderService.cs
when calling GetById with a non-existent ID.
Analyze the root cause, implement the fix,
and write a test that prevents regression.
```

```
Review [file/PR/recent changes] for quality, security,
and convention violations. Prioritize by severity.
```

```
Analyze the project structure and create an overview
of all features, endpoints, and components.
```

### For new projects

Describe your tech stack and the features you want. Squad will scaffold everything:

```
Create a [framework] + [language] application with:
- [Data model] with [key fields]
- [API layer] with CRUD endpoints
- [Frontend] with [key pages/components]
- [Database] with migrations
- [Tests] with [test framework]
```

Example:
```
Create an ASP.NET Core + Angular application with:
- Product entity with Id, Name, Price, Category, IsActive
- CRUD endpoints at /api/products with filtering by category
- Angular product list page with sorting and a create/edit form
- EF Core with initial migration
- xUnit tests for service + integration tests for endpoints
```

> **Tip:** You don't need to specify which agent handles what — the coordinator routes automatically. Focus on describing the end result, not the implementation steps.

### What makes a good prompt

| Do | Don't |
|---|---|
| Name your entities, fields, and endpoints | Say "build something cool" |
| Reference existing patterns in the codebase | Assume agents know your conventions |
| List all the pieces you want (API + UI + tests) | Ask for one piece at a time |
| Mention constraints (auth required, specific DB, etc.) | Leave critical requirements implicit |
| Let agents decide the implementation approach | Micromanage each agent's steps |

---

## Updating

When the squad-template repository gets updates:

```bash
cd ~/squad-template && git pull
~/squad-template/init.sh ~/path/to/project --upgrade
```

**Updated:** Coordinator prompt, skills, workflows, seeds, failure patterns

**Preserved:** team.md, agent charters, histories, config.json, routing.md, decisions.md

---

## .gitignore

Squad files belong in the repo (team shares the configuration). Add these to `.gitignore`:

```gitignore
# Squad runtime files (don't commit)
.squad/orchestration-log/
.squad/log/
.squad/agents/*/status.md
```

Everything else (`.squad/`, `.github/agents/`, `.copilot/skills/`) **must be committed**.

---

## Customization (optional, improves quality)

### Adjust agent charters (~30 min)

Open `.squad/agents/*/charter.md` and replace the `<!-- Replace -->` comments:
- Stack info (e.g., "Python 3.12, FastAPI, SQLAlchemy")
- Reference implementation paths (e.g., "src/features/items/")
- Project-specific guardrails

### Document failure patterns (ongoing)

When an agent makes a mistake:

1. Note what went wrong
2. Add it to `.copilot/skills/failure-patterns.md`
3. The agent will **never** make that mistake again

---

## Troubleshooting

**"Custom agent 'squad' not found"**
→ You're in the wrong directory. `cd` into your project where `.github/agents/squad.agent.md` exists.

**All agents use the same model (e.g., gpt-4.1)**
→ Switch CLI model to **GPT-5.1 HIGH**. Only this model routes models per agent.

**"Read (Checking agent X) → Failed"**
→ Normal — agent sessions expire quickly. Squad automatically checks files on disk. No action needed.

**Agent asks "Would you like to proceed?" / "What's your priority?"**
→ Should not happen with the optimized version. Run `init.sh --upgrade` to get the latest coordinator.

**Build fails with wrong commands (e.g., `dotnet build` on a React project)**
→ Run `init.sh --upgrade` — newer version auto-detects project type.

---

## FAQ

**Can Squad break existing code?**
No. `init.sh` only adds new files in `.squad/`, `.github/`, and `.copilot/`.

**Do I need to use all 6 agents?**
No. Squad automatically uses only the agents relevant to the task.

**Does Squad work with multiple developers?**
Yes. The `.squad/` files are committed and shared. Each developer runs `copilot --agent squad` locally.

**What happens if I run `init.sh` twice?**
Existing files (team.md, routing.md, charters) are not overwritten.

**How many premium requests does Squad cost?**
1-3 premium requests per feature (vs. ~30 with standard Copilot). See `docs/PREMIUM-REQUEST-COMPARISON.md`.

**What languages are supported?**
Currently: C#/.NET, TypeScript/JavaScript, Python. More languages can be added via `stacks/_template/`. 15 tech seeds are pre-installed (React, Angular, FastAPI, Express, Prisma, xUnit, Vitest, etc.).

---

## Checklist

- [ ] `~/squad-template` cloned
- [ ] CLI model set to GPT-5.1 HIGH
- [ ] `init.sh --auto` run on the project
- [ ] `copilot --agent squad` starts without "agent not found" error
- [ ] First test prompt successful (e.g., "Analyze the project structure")
- [ ] `.squad/` and `.copilot/` files committed
- [ ] Team informed
