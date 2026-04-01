# Squad Template

Your AI development team, ready in 60 seconds.

This template replaces the default `squad init` (127 generic files) with an optimized engine that gives your agents real domain knowledge, auto-proceeds through the pipeline, and routes the right model to the right agent.

> **Model Requirement:** Multi-agent model routing (opus for architect, sonnet for code, haiku for docs) **only works with GPT-5.1 HIGH** as the Copilot CLI model. With any other model, all agents default to the CLI's single model.

---

## Getting Started

### 1. Clone this repo

```bash
git clone <your-repo-url> ~/squad-template
```

### 2. Bootstrap your project

Pick the method that fits your situation:

```bash
# Auto-detect your tech stack and apply matching preset/seeds automatically
~/squad-template/init.sh ~/my-project --auto

# Or specify a stack preset explicitly
~/squad-template/init.sh ~/my-project --stack dotnet-angular

# Or just the core engine (no stack-specific conventions)
~/squad-template/init.sh ~/my-project
```

### 3. Start Squad

```bash
cd ~/my-project
copilot --agent squad
```

That's it. Your project now has 6 AI agents ready to work.

---

## Works on Any Project

`init.sh` adds Squad files alongside your existing code — it never modifies your source files.

```bash
# New project
mkdir ~/my-app && cd ~/my-app && git init
~/squad-template/init.sh ~/my-app --auto

# Existing project with thousands of files
~/squad-template/init.sh ~/work/existing-api --auto

# Already have Squad? Update without losing your customizations
~/squad-template/init.sh ~/my-project --upgrade
```

---

## CLI Reference

| Command | What it does |
|---------|-------------|
| `init.sh <dir>` | Core engine only (generic agents, no stack preset) |
| `init.sh <dir> --auto` | Auto-detect tech stack, apply matching preset or seeds |
| `init.sh <dir> --stack <name>` | Apply a specific stack preset (e.g., `dotnet-angular`) |
| `init.sh <dir> --upgrade` | Update coordinator, skills, workflows — preserves team, decisions, history |
| `init.sh --help` | Show all options, available presets, and seeds |

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

The coordinator runs the full pipeline autonomously:

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

It then matches against available presets and 15 built-in seeds (React, Express, FastAPI, .NET, Angular, Prisma, xUnit, Vitest, and more).

---

## Project Structure

```
squad-template/
├── core/                    # Universal engine (copied to every project)
│   ├── .github/agents/      #   Coordinator prompt (~1200 lines, on-demand modules)
│   ├── .copilot/skills/     #   11 coordinator skill modules
│   ├── .squad/              #   Wisdom, templates, casting, config
│   └── .github/workflows/   #   GitHub Actions for triage/labels
│
├── stacks/                  # Stack-specific presets
│   ├── dotnet-angular/      #   .NET 10 + Angular 21 (22 skill bundles, 6 charters)
│   ├── _template/           #   Ready-to-customize template for new stacks
│   └── seeds/               #   15 lightweight tech seeds (React, FastAPI, etc.)
│
├── shared/                  # Cross-project failure patterns
├── docs/                    # Architecture docs, customization guide
└── init.sh                  # Bootstrap / upgrade script
```

---

## Why Not Just `squad init`?

| | `squad init` | This Template |
|---|---|---|
| **Files** | 127 (mostly empty) | ~40 meaningful |
| **Agent charters** | "Collaborate with team" | Embedded conventions, guardrails, model preferences |
| **Skills** | 28 generic | Stack-specific patterns + failure prevention |
| **Routing** | Placeholders | Precise phase-to-agent mapping |
| **Wisdom** | Empty | Pre-seeded with battle-tested patterns |
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

The `_template/` directory contains ready-to-customize files with `<!-- Replace -->` markers showing exactly what to fill in. See `stacks/_template/README.md` for a full checklist with time estimates.

---

## Architecture

Three tiers, each more specific:

1. **Core** — Universal orchestration (coordinator, workflows, wisdom). Identical across all projects.
2. **Stack Preset** — Tech-specific knowledge (coding conventions, test patterns, failure prevention). One per project.
3. **Per-Project** — Generated at runtime (team roster, cast names, decisions, session history). Unique to each project.
