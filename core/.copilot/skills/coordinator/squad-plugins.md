# Squad Plugin Marketplace

> Load this when user asks about plugins, marketplace, or extending Squad.

---

## Plugin Marketplace

The plugin marketplace allows teams to discover and install skill packs — pre-built agent expertise for specific domains, frameworks, or workflows.

### Overview

Plugins are SKILL.md files that add domain knowledge to an agent's context. They can be:
- Role-specific packs (e.g., "azure-cloud-development" for an Azure DevOps agent)
- Framework packs (e.g., "next-js-patterns" for a React frontend agent)
- Workflow packs (e.g., "gitflow-release" for release management)
- Tool packs (e.g., "terraform-infrastructure" for infra agents)

### Marketplace Configuration

Marketplaces are registered in `.squad/plugins/marketplaces.json`:

```json
{
  "marketplaces": [
    {
      "name": "official",
      "url": "https://github.com/bradygaster/squad-skills",
      "type": "github",
      "description": "Official Squad skill packs"
    },
    {
      "name": "community",
      "url": "https://github.com/squad-community/plugins",
      "type": "github",
      "description": "Community-contributed plugins"
    }
  ]
}
```

### Marketplace Discovery

When adding a team member, or when the user asks to browse plugins:

```bash
# Browse all plugins in a marketplace
squad plugin marketplace browse {marketplace-name}

# Search for plugins matching a domain
squad plugin marketplace search {query}

# Install a specific plugin
squad plugin marketplace install {plugin-name}
```

Or read the marketplace repo's directory listing directly via `gh api` or the GitHub MCP server.

### Plugin Installation Flow

1. **Browse** — list available plugins for the agent's role/domain
2. **Present** — show matching plugins: *"Found '{plugin-name}' in {marketplace} — want me to install it as a skill for {CastName}?"*
3. **Confirm** — wait for user approval before installing
4. **Install** — copy plugin content to `.squad/skills/{plugin-name}/SKILL.md`
5. **Log** — note installation in the agent's `history.md`
6. **Incorporate** — if installing during Add Team Member flow, merge plugin guidance into the agent's charter

### Plugin Structure

A plugin is a SKILL.md file with this structure:

```markdown
# {Plugin Name}

**Domain:** {domain/framework/tool}
**Compatible roles:** {comma-separated roles}
**Version:** {semver}

## What this skill adds

{Brief description of capabilities added}

## Patterns

{Reusable patterns, conventions, examples}

## Anti-patterns

{Common mistakes to avoid}

## References

{Links to docs, examples}
```

### Plugin Marketplace Registration

To register a new marketplace source:

```bash
squad plugin marketplace add --name {name} --url {github-repo-url}
```

This writes to `.squad/plugins/marketplaces.json`. The URL must point to a GitHub repo containing SKILL.md files at the root or in a `skills/` directory.

### Graceful Degradation

- If no marketplaces are configured, skip plugin discovery silently during Add Team Member flow
- If a marketplace URL is unreachable, warn: *"⚠ Couldn't reach {marketplace} — continuing without it"* and continue without blocking the team member addition
- If a plugin fails to install (format error, permissions), warn and continue — the agent works without the plugin

### Skill Confidence Lifecycle

Installed plugins start at `low` confidence. Confidence is bumped by agents:

| Level | Meaning | When |
|-------|---------|------|
| `low` | First observation | Agent noticed a reusable pattern worth capturing |
| `medium` | Confirmed | Multiple agents or sessions independently observed the same pattern |
| `high` | Established | Consistently applied, well-tested, team-agreed |

Confidence bumps when an agent independently validates an existing skill — applies it in their work and finds it correct. If an agent reads a skill, uses the pattern, and it works, that's a confirmation worth bumping.

### Skill-Aware Routing

Before spawning, the coordinator checks `.squad/skills/` for skills relevant to the task domain. If a matching skill exists, it adds to the spawn prompt:

```
Relevant skill: .squad/skills/{name}/SKILL.md — read before starting.
```

This makes earned knowledge (from plugins and from team learning) an active input to routing, not passive documentation.
