---
name: "failure-patterns-global"
description: "Company-wide failure patterns — inherited by ALL new projects"
domain: "cross-cutting"
confidence: "high"
source: "observed"
updated: "2026-03-30"
---

# Global Failure Patterns

These patterns were observed across multiple projects and apply to ALL Squad teams.
New projects inherit this file via init.sh → `.copilot/skills/failure-patterns-global.md`.

When you discover a NEW failure pattern in any project, add it here AND push back
to the squad-template repo so all future projects benefit.

---

## All Agents — Universal Anti-Patterns

### 1. Hallucinated Method Names

**What happened:** Agents cite methods that don't exist in the codebase.
**Correction:** Always `grep` or `find` to verify a method exists before referencing it.
**Mitigation:** Every method cited MUST be verified by search. Include file:line references.

### 2. Agent Session Expiry

**What happened:** `read_agent` fails because agent sessions expire after ~2 minutes.
**Correction:** Write results to `status.md` and orchestration log IMMEDIATELY.
**Mitigation:** Never rely on `read_agent` as the only way to get results. Always check `status.md` first.

### 3. Parallel Spawn of Dependent Agents

**What happened:** Frontend spawned while Backend was still creating endpoints. Frontend couldn't find the endpoints.
**Correction:** Serialize agents with file dependencies. Inline completed results into dependent agent prompts.
**Mitigation:** ALWAYS check: does Agent B need files from Agent A? If yes, serialize.

### 4. 3+ Parallel Agents Cause API Errors

**What happened:** Spawning 3+ agents simultaneously causes transient errors.
**Correction:** Max 2 agents per batch. Split into batches if more needed.
**Mitigation:** Hard limit: 2 parallel agents per batch.

### 5. "Would You Like..." Loops

**What happened:** Coordinator asks user for confirmation between phases, wasting time and money.
**Correction:** Auto-proceed through all phases. Only stop on repeated failures or ambiguous scope.
**Mitigation:** BANNED PHRASES list in coordinator. Never present menus.

### 6. Trusting Sync Output as Authoritative Review

**What happened:** Multi-agent sync collaboration produced well-formatted but factually wrong code review.
**Correction:** Always verify claims against source code. Cite file:line.
**Mitigation:** Sync output is ideation aid, NOT authoritative. Always verify.

---

## Implementation Agents — Code Anti-Patterns

### 7. New Files Without Registration

**What happened:** Agent created endpoint handler but forgot to register it in the router/app.
**Correction:** Every new handler/component MUST have a corresponding registration.
**Mitigation:** Checklist item: "Is the new code registered/imported where it needs to be?"

### 8. Unnecessary Dependencies

**What happened:** Agent added a package that was already available transitively.
**Correction:** Only add packages when the build actually fails with a missing type.
**Mitigation:** Check existing dependencies before adding new ones.

### 9. Code Without Build Verification

**What happened:** Agent wrote code but never ran build/test. Errors found much later.
**Correction:** Run build + test after every implementation phase.
**Mitigation:** Coordinator auto-runs build/test validation after each implementation agent completes.

### 10. Parallel Database Queries on Shared Connection/Context

**What happened:** Agent optimized by running multiple database queries in parallel using `Task.WhenAll`, `Promise.all`, or `asyncio.gather`, but all queries shared the same database connection/session/context. Most ORMs (EF Core, SQLAlchemy, Prisma in some modes) are NOT thread-safe per connection.

**Correction:** Run queries sequentially on the same connection. If parallelism is truly needed, create a separate connection/session per parallel task.

**Mitigation:**
- **WRONG:** `await Promise.all([db.query(...), db.query(...)])` on same connection
- **CORRECT:** `const a = await db.query(...); const b = await db.query(...);` (sequential)
- This applies to: EF Core DbContext, SQLAlchemy Session, Prisma in some transaction modes, Django ORM connections

### 11. Frontend Build Walks Into Backend Output Directories

**What happened:** In a mixed frontend+backend repo, the frontend build tool (TypeScript compiler, Vite, Webpack) walked into the backend's build output directories (e.g., `obj/`, `bin/`, `target/`, `__pycache__/`) and tried to process those files, causing build failures.

**Correction:** Frontend build configuration must explicitly exclude backend build output directories.

**Mitigation:**
- Add backend output dirs to frontend's exclude config (tsconfig, vite.config, webpack.config)
- Common excludes: `obj/`, `bin/`, `target/`, `dist/`, `build/`, `__pycache__/`, `.gradle/`
- Check this whenever a new backend project is added to a repo that also has a frontend

### 12. Environment Setup Taking >10 Minutes

**What happened:** The coordinator spent 45+ minutes retrying `dotnet restore`, `npm install`, or Docker startup instead of reporting the issue to the user.

**Correction:** If any environment command doesn't complete within 10 minutes, stop and report. The user can fix their environment faster than the coordinator can guess.

**Mitigation:** Set a mental time budget of 10 minutes for environment tasks. After that: stop, report what's wrong, suggest the fix, and ask the user to resolve it.

### 13. Wrong Database Provider

**What happened:** The coordinator assumed PostgreSQL but the project was configured for SQL Server (or vice versa), causing connection failures.

**Correction:** Always check the actual code (`UseSqlServer` vs `UseNpgsql` vs `UseSqlite`) before starting database containers or constructing connection strings. Never guess.

**Mitigation:** Pre-flight check: `grep -r "UseSqlServer\|UseNpgsql\|UseSqlite" src/` to detect the configured provider.

---

<!-- Add new patterns below. Use sequential numbering. -->
<!-- After adding, push to squad-template repo: shared/failure-patterns-global.md -->
