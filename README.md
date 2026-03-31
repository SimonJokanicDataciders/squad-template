# Squad Template

Reusable template for bootstrapping production-quality [Squad](https://github.com/bradygaster/squad) teams on any project.

Replaces the default `squad init` (127 files of generic scaffolding) with an optimized engine and pre-built stack presets containing real domain knowledge.

> **Important: Model Requirement**
>
> Multi-agent model selection (opus for architect, sonnet for code agents, haiku for docs) **only works with GPT-5.1 HIGH** as the Copilot CLI model. This is the only model that properly caches premium requests across agent spawns.
>
> With any other CLI model, the coordinator cannot route models per-agent — all agents will default to whatever single model the CLI was opened with. If you're seeing all agents use `gpt-4.1` or the same model regardless of charter preferences, switch to GPT-5.1 HIGH.

## Quick Start

```bash
# 1. Clone this template repo
git clone <your-repo-url> ~/squad-template

# 2. Bootstrap your project (must be a git repo)
~/squad-template/init.sh ~/my-project --stack dotnet-angular

# 3. Start Squad
cd ~/my-project
copilot --agent squad
```

## What's Inside

```
squad-template/
├── core/                    # Universal Squad engine (every project)
│   ├── .github/agents/      #   Optimized coordinator (800 lines)
│   ├── .copilot/skills/     #   10 coordinator modules
│   ├── .squad/              #   Pre-seeded wisdom, templates, casting
│   └── .github/workflows/   #   GitHub Actions for triage/labels
│
├── stacks/                  # Stack-specific presets
│   ├── dotnet-angular/      #   .NET 10 + Angular 21 (from CAP Template)
│   │   ├── agents/          #     6 agent charter references
│   │   ├── skills/          #     22 embedded knowledge bundles
│   │   ├── routing.md       #     Pre-filled routing table
│   │   └── ceremonies.md    #     Quality gates with stack triggers
│   └── _template/           #   Blank preset for new stacks
│
├── docs/                    # Setup guides
│   ├── ARCHITECTURE.md      #   How the template works
│   └── CUSTOMIZATION_GUIDE.md  # Creating new stack presets
│
└── init.sh                  # Bootstrap script
```

## Why Not Just `squad init`?

| Aspect | `squad init` | This Template |
|--------|-------------|---------------|
| Files created | 127 (mostly empty) | ~40 meaningful |
| Agent charters | "Collaborate with team" | Embedded domain knowledge, guardrails, skill loading |
| Skills | 28 generic | Stack-specific conventions + failure patterns |
| Routing | Placeholders | Precise phase-to-agent mapping |
| Wisdom | Empty | Pre-seeded with battle-tested patterns |
| Coordinator | 21,600 lines (default) | 800 lines (optimized, on-demand modules) |
| Auto-proceed | No (asks "ready?" between phases) | Yes (autonomous pipeline) |
| Context overhead | Loads everything | Tiered: core always + on-demand by task |

## Creating a New Stack Preset

1. Copy `stacks/_template/` to `stacks/{your-stack}/`
2. Fill in agent charters with your conventions and guardrails
3. Write skill bundles with embedded domain knowledge
4. Customize routing and ceremonies
5. Run a benchmark, document failures

See `docs/CUSTOMIZATION_GUIDE.md` for the full walkthrough.

## Architecture

The template uses a 3-tier separation:

- **Core** (Tier 1) — Universal orchestration: coordinator, workflows, wisdom, drop-box pattern. Copy to every project verbatim.
- **Stack Preset** (Tier 2) — Stack-specific knowledge: coding conventions, testing patterns, reference implementations. Pick one per project.
- **Per-Project** (Tier 3) — Generated at runtime: team roster, cast names, decisions, session history. Created by Squad's Init Mode.
