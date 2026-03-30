# Squad Casting System

> Load this when user asks about casting, renaming agents, changing universe, or team composition.

---

## Casting & Persistent Naming

Agent names are drawn from a single fictional universe per assignment. Names are persistent identifiers — they do NOT change tone, voice, or behavior. No role-play. No catchphrases. No character speech patterns. Names are easter eggs: never explain or document the mapping rationale in output, logs, or docs.

### Universe Allowlist

**On-demand reference:** Read `.squad/templates/casting-reference.md` for the full universe table, selection algorithm, and casting state file schemas. Only loaded during Init Mode or when adding new team members.

**Rules (always loaded):**
- ONE UNIVERSE PER ASSIGNMENT. NEVER MIX.
- 15 universes available (capacity 6–25). See reference file for full list.
- Selection is deterministic: score by size_fit + shape_fit + resonance_fit + LRU.
- Same inputs → same choice (unless LRU changes).

### Universe Scoring Algorithm

Selection is deterministic — given the same inputs, you always pick the same universe. Score each universe on three dimensions:

1. **size_fit** — Does the universe have enough characters for the team size? Score 0–10 (10 = perfect fit).
2. **shape_fit** — Does the universe's character archetypes match the team's role structure? Score 0–10.
3. **resonance_fit** — Does the universe match signals from the session context (stack, domain, user preferences)? Score 0–10.
4. **LRU penalty** — Subtract 5 points if this universe was used in the most recent assignment.

Pick the universe with the highest total score. Ties broken by LRU (least recently used wins).

### Name Allocation

After selecting a universe:

1. Choose character names that imply pressure, function, or consequence — NOT authority or literal role descriptions.
2. Each agent gets a unique name. No reuse within the same repo unless an agent is explicitly retired and archived.
3. **Scribe is always "Scribe"** — exempt from casting.
4. **Ralph is always "Ralph"** — exempt from casting.
5. **@copilot is always "@copilot"** — exempt from casting. If the user says "add team member copilot" or "add copilot", this is the GitHub Copilot coding agent. Do NOT cast a name — follow the Copilot Coding Agent Member section instead.
5. Store the mapping in `.squad/casting/registry.json`.
5. Record the assignment snapshot in `.squad/casting/history.json`.
6. Use the allocated name everywhere: charter.md, history.md, team.md, routing.md, spawn prompts.

### Persistent Naming

Once a name is assigned to an agent role in a repo, it is persistent:
- The same agent keeps the same name across all sessions.
- Names survive team member additions and removals.
- Retired agents have their names reserved in registry.json (status: "retired") — names are NOT recycled.
- If an agent is removed and a new agent fills the same role later, the new agent gets a fresh name from the universe.

### Casting Registry

The casting state lives in `.squad/casting/` with three files:

- **`policy.json`** — Universe allowlist, capacity limits, and configuration.
- **`registry.json`** — Persistent agent-to-name mappings. One entry per agent ever cast in this repo.
- **`history.json`** — Universe usage history and assignment snapshots. Append-only.

**registry.json entry format:**
```json
{
  "persistent_name": "Ripley",
  "universe": "Alien",
  "role": "Backend Dev",
  "created_at": "2025-01-15T10:30:00Z",
  "legacy_named": false,
  "status": "active"
}
```

**history.json entry format:**
```json
{
  "assignment_id": "uuid-v4",
  "universe": "Alien",
  "timestamp": "2025-01-15T10:30:00Z",
  "agents": ["Ripley", "Dallas", "Lambert", "Hicks"],
  "reason": "size_fit:8 shape_fit:9 resonance_fit:7"
}
```

### Casting Policy

**On-demand reference:** Read `.squad/templates/casting-reference.md` for the full JSON schema of policy.json.

The casting policy governs:
- Which universes are allowed for this repo (allowlist)
- Which universes are blocked (blocklist)
- Universe capacity ranges
- Whether overflow handling is enabled

### Overflow Handling

If agent_count grows beyond available names mid-assignment, do NOT switch universes. Apply in order:

1. **Diegetic Expansion:** Use recurring/minor/peripheral characters from the same universe.
2. **Thematic Promotion:** Expand to the closest natural parent universe family that preserves tone (e.g., Star Wars OT → prequel characters). Do not announce the promotion.
3. **Structural Mirroring:** Assign names that mirror archetype roles (foils/counterparts) still drawn from the universe family.

Existing agents are NEVER renamed during overflow.

### Migration — Already-Squadified Repos

When `.squad/team.md` exists but `.squad/casting/` does not:

1. **Do NOT rename existing agents.** Mark every existing agent as `legacy_named: true` in the registry.
2. Initialize `.squad/casting/` with default policy.json, a registry.json populated from existing agents, and empty history.json.
3. For any NEW agents added after migration, apply the full casting algorithm.
4. Optionally note in the orchestration log that casting was initialized (without explaining the rationale).

### Adding Team Members (Casting Flow)

If the user says "I need a designer" or "add someone for DevOps":
1. **Allocate a name** from the current assignment's universe (read from `.squad/casting/history.json`). If the universe is exhausted, apply overflow handling (see Overflow Handling above).
2. **Check plugin marketplaces.** If `.squad/plugins/marketplaces.json` exists and contains registered sources, browse each marketplace for plugins matching the new member's role or domain (e.g., "azure-cloud-development" for an Azure DevOps role). Use the CLI: `squad plugin marketplace browse {marketplace-name}` or read the marketplace repo's directory listing directly. If matches are found, present them: *"Found '{plugin-name}' in {marketplace} — want me to install it as a skill for {CastName}?"* If the user accepts, copy the plugin content into `.squad/skills/{plugin-name}/SKILL.md` or merge relevant instructions into the agent's charter. If no marketplaces are configured, skip silently. If a marketplace is unreachable, warn (*"⚠ Couldn't reach {marketplace} — continuing without it"*) and continue.
3. Generate a new charter.md + history.md (seeded with project context from team.md), using the cast name. If a plugin was installed in step 2, incorporate its guidance into the charter.
4. **Update `.squad/casting/registry.json`** with the new agent entry.
5. Add to team.md roster.
6. Add routing entries to routing.md.
7. Say: *"✅ {CastName} joined the team as {Role}."*

### Removing Team Members

If the user wants to remove someone:
1. Move their folder to `.squad/agents/_alumni/{name}/`
2. Remove from team.md roster
3. Update routing.md
4. **Update `.squad/casting/registry.json`**: set the agent's `status` to `"retired"`. Do NOT delete the entry — the name remains reserved.
5. Their knowledge is preserved, just inactive.
