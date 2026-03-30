# Squad Distributed Mesh & Cross-Squad Coordination

> Load this when user asks about cross-squad coordination, mesh networking, or multi-machine sync.

---

## Distributed Mesh

Squad supports multi-machine, cross-squad coordination through a distributed mesh model. When multiple Squad instances run on different machines or in different repos, they can share work context and coordinate via a sync mechanism.

### Overview

The mesh allows:
- Multiple machines running Squad instances to share team state
- Cross-squad handoffs (routing work to agents in a different squad)
- Remote zone awareness (knowing what other squads are working on)
- Sync scripts to propagate decisions, logs, and history across machines

### Remote Zones

A "zone" is a Squad instance on a specific machine or in a specific repo. Each zone has:
- A zone ID (typically the machine hostname or repo slug)
- A set of agents with their current work
- A shared `.squad/` state that can be synced

**Zone discovery:** Read `.squad/mesh/zones.json` if it exists. Each entry describes a remote zone:

```json
{
  "zone_id": "machine-name",
  "repo": "owner/repo",
  "last_sync": "2025-01-15T10:30:00Z",
  "agents": ["Ripley", "Dallas"],
  "status": "active"
}
```

### Cross-Squad Coordination

When routing work that spans multiple squads:

1. **Identify the target squad** — which zone has the agents best suited for the work?
2. **Check zone status** — is the remote zone active and reachable?
3. **Handoff package** — prepare a handoff with: task description, relevant context, files to read, expected output format.
4. **Log the handoff** — write to `.squad/mesh/handoffs/{timestamp}-{from-zone}-to-{to-zone}.md`
5. **Await result** — the remote zone picks up the handoff and writes a result file.

### Sync-Mesh Scripts

The `sync-mesh` scripts synchronize `.squad/` state across machines. Use these when running Squad on multiple machines that share a repo:

```bash
# Push local .squad/ state to remote zones
npx @bradygaster/squad-cli mesh sync --push

# Pull .squad/ state from remote zones
npx @bradygaster/squad-cli mesh sync --pull

# Bidirectional sync
npx @bradygaster/squad-cli mesh sync

# Check mesh status
npx @bradygaster/squad-cli mesh status
```

**Sync rules:**
- Append-only files (decisions, history, logs) are always safe to sync — union merge handles conflicts.
- `team.md` and `routing.md` require manual conflict resolution if both sides changed.
- `casting/registry.json` is append-only for new agents — existing entries should not conflict if names are unique.

### Mesh Configuration

Mesh is configured in `.squad/mesh/config.json`:

```json
{
  "enabled": true,
  "zones": [],
  "sync_interval_minutes": 15,
  "auto_sync": false
}
```

- `enabled` — whether mesh coordination is active
- `zones` — list of remote zone connection details
- `sync_interval_minutes` — how often auto-sync runs (if enabled)
- `auto_sync` — whether to sync automatically or require manual trigger

### Graceful Degradation

If the mesh is not configured or remote zones are unreachable:
- Continue working in local-only mode
- Log attempted sync failures to `.squad/log/`
- Notify the user if a cross-squad handoff is requested but the target zone is unreachable
- Never block local work due to mesh unavailability
