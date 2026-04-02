# Squad Template

Your AI development team, ready in 60 seconds.

> **Note:** This is not the official [Squad](https://github.com/bradygaster/squad) setup. This is an optimized template with custom coordinator, per-agent model routing, auto-proceed pipeline, self-validation, and language-specific rules.

---

## Prerequisites

1. **GitHub Copilot** with agent mode enabled
2. **CLI model: GPT-5.1 HIGH** — set this in your Copilot CLI settings. Other models work but all agents will use the same model instead of routing per agent.
3. **Git repository** — your project must be a git repo (`git init`). Squad stores configuration in git-tracked files.

---

## Getting Started

### 1. Clone this repo (once)

```bash
git clone https://github.com/SimonJokanicDataciders/squad-template.git ~/squad-template
```

### 2. Install Squad into your project

```bash
# Auto-detect your tech stack (recommended)
~/squad-template/init.sh ~/my-project --auto

# Or specify a stack preset if you know the name
~/squad-template/init.sh ~/my-project --stack dotnet-angular

# See available presets and seeds
~/squad-template/init.sh --help
```

> **`--auto` vs `--stack`:** Use `--auto` if you're not sure — it scans your config files (package.json, *.csproj, pyproject.toml) and picks the best match. Use `--stack` only if you know exactly which preset you want.

Works on new and existing projects — Squad adds new directories (`.squad/`, `.github/agents/`, `.copilot/`) alongside your code without touching existing files.

### 3. Start Squad

```bash
cd ~/my-project
copilot --agent squad
```

For fully autonomous mode (no approval prompts):

```bash
copilot --agent squad --yolo
```

> **When to use `--yolo`:** On test projects, greenfield apps, or when you trust Squad to run autonomously. Don't use it on production codebases without reviewing the output first — you can always `git diff` after the run.

### 4. Give it a task

Squad works best when your prompt is specific about **what** you want but leaves the **how** to the agents.

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

| Do | Don't |
|---|---|
| Name your entities, fields, and endpoints | Say "build something cool" |
| Reference existing patterns in the codebase | Assume agents know your conventions |
| List all pieces you want (API + UI + tests) | Ask for one piece at a time |
| Mention constraints (auth, specific DB, etc.) | Leave critical requirements implicit |

> **Tip:** You don't need to specify which agent handles what — the coordinator routes automatically.

---

## What You Get

### 6 Agents with Model Routing

| Agent | Role | Model | Cost |
|-------|------|-------|------|
| Lead / Ripley | Architecture, planning, contracts | `claude-opus-4.6` | Premium (3x) |
| Backend / Fenster | API, services, database | `claude-sonnet-4.6` | Standard (1x) |
| Frontend / Dallas | UI, components, styling | `claude-sonnet-4.6` | Standard (1x) |
| Tester / Hockney | Tests, code review, QA | `claude-sonnet-4.6` | Standard (1x) |
| Scribe | Documentation, decisions | `claude-haiku-4.5` | Fast (0.33x) |
| Ralph | Ops, security, triage | `claude-haiku-4.5` | Fast (0.33x) |

### Auto-Proceed Pipeline

```
design → plan → implement → test → document → done
```

No "would you like to proceed?" prompts. No menus. Just results.

### Stack Auto-Detection

When you use `--auto`, the script detects your tech stack from config files:

| File Found | Tech Detected |
|------------|--------------|
| `package.json` | Node.js + dependencies (React, Angular, Express, etc.) |
| `*.csproj` / `*.sln` | .NET |
| `angular.json` | Angular |
| `pyproject.toml` | Python (+ FastAPI, pytest if in dependencies) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `vite.config.*` | Vite |
| `tsconfig.json` | TypeScript |

Matches against available presets and 15 built-in seeds (React, Express, FastAPI, .NET, Angular, Prisma, xUnit, Vitest, and more).

---

## CLI Reference

| Command | What it does |
|---------|-------------|
| `init.sh <dir> --auto` | Auto-detect tech stack, apply matching preset or seeds |
| `init.sh <dir> --stack <name>` | Apply a specific stack preset (e.g., `dotnet-angular`) |
| `init.sh <dir> --upgrade` | Update coordinator, skills, workflows — preserves team, decisions, history |
| `init.sh <dir>` | Core engine only (generic agents, no stack preset) |
| `init.sh --help` | Show all options, available presets, and seeds |

---

## Updating

```bash
cd ~/squad-template && git pull
~/squad-template/init.sh ~/my-project --upgrade
```

**Updated:** Coordinator prompt, skills, workflows, seeds, failure patterns

**Preserved:** team.md, agent charters, histories, config.json, routing.md, decisions.md

---

## Troubleshooting

**"Custom agent 'squad' not found"**
→ You're in the wrong directory. `cd` into your project where `.github/agents/squad.agent.md` exists.

**All agents use the same model (e.g., gpt-4.1)**
→ Switch CLI model to **GPT-5.1 HIGH**. Only this model routes models per agent.

**"Read (Checking agent X) → Failed"**
→ Normal — agent sessions expire quickly. Squad checks files on disk automatically. No action needed.

**Agent asks "Would you like to proceed?"**
→ Run `init.sh --upgrade` to get the latest coordinator with auto-proceed.

**Build fails with wrong commands (e.g., `dotnet build` on a React project)**
→ Run `init.sh --upgrade` — newer version auto-detects project type.

---

## Why Not Just `squad init`?

| | `squad init` | This Template |
|---|---|---|
| **Files** | 127 (mostly empty) | ~40 meaningful |
| **Agent charters** | "Collaborate with team" | Embedded conventions, guardrails, model preferences |
| **Skills** | 28 generic | Stack-specific patterns + failure prevention |
| **Routing** | Placeholders | Precise phase-to-agent mapping |
| **Coordinator** | 21,600 lines (loads everything) | ~1200 lines (tiered: core always + on-demand) |
| **Auto-proceed** | Asks "ready?" between phases | Autonomous pipeline, banned confirmation phrases |
| **Model routing** | Single model for all | Per-agent (opus/sonnet/haiku by role) |
| **Self-validation** | None | Agents run build/lint before handing off |
| **Upgrade path** | None | `--upgrade` preserves customizations |

---

## Adding a New Stack

```bash
# 1. Copy the template (all files have real structure, not empty TODOs)
cp -r ~/squad-template/stacks/_template ~/squad-template/stacks/python-fastapi

# 2. Customize the files (~2-4 hours):
#    agents/*.charter.md  → Your conventions and guardrails
#    skills/*.md           → Real code examples from your project
#    routing.md            → Work type routing
#    cast.conf             → Custom agent names (optional)

# 3. Apply to any project
~/squad-template/init.sh ~/my-project --stack python-fastapi
```

See `stacks/_template/README.md` for a full checklist with time estimates.

---

## Docs

- **[Integration Guide](docs/INTEGRATION-GUIDE.md)** — Detailed setup, prompt examples, .gitignore, customization, FAQ
- **[Premium Request Comparison](docs/PREMIUM-REQUEST-COMPARISON.md)** — Cost analysis: ~30 requests standard vs 1-3 with Squad

## Architecture

Three tiers, each more specific:

1. **Core** — Universal orchestration (coordinator, workflows, wisdom). Identical across all projects.
2. **Stack Preset** — Tech-specific knowledge (coding conventions, test patterns, failure prevention). One per project.
3. **Per-Project** — Generated at runtime (team roster, cast names, decisions, session history). Unique to each project.
