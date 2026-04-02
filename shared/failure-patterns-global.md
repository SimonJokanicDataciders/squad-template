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

### 14. Streamlit Page Path Resolution (Relative vs Absolute)

**What happened:** Frontend agent registered Streamlit pages with relative paths (`st.Page("pages/weather.py")`), but Streamlit resolves paths relative to the current working directory, not relative to `app.py`. When the app is launched from the project root, the pages can't be found.

**Correction:** Always resolve page paths relative to `app.py` using `Path(__file__).parent / "pages" / "weather.py"`.

**Mitigation:**
- **WRONG:** `st.Page("pages/weather.py")` or `st.Page("src/pipeline/dashboard/pages/weather.py")`
- **CORRECT:** `st.Page(Path(__file__).parent / "pages" / "weather.py")`
- This applies to ALL multi-page Streamlit apps, not just specific frameworks

### 15. Plotly Datetime Annotation Type Mismatch

**What happened:** Frontend agent used `fig.add_vline(x=forecast_start, annotation_text="Forecast")` where `forecast_start` was a date string. Plotly's internal `shapeannotation.py` tried `sum()` on mixed int+str types, causing `TypeError: unsupported operand type(s) for +: 'int' and 'str'`.

**Correction:** Convert date values to `datetime` objects before passing to Plotly annotation functions. Or use `fig.add_shape()` + `fig.add_annotation()` instead of `add_vline()` with annotations.

**Mitigation:**
- **WRONG:** `fig.add_vline(x="2026-04-01", annotation_text="...")`
- **CORRECT:** `fig.add_vline(x=pd.Timestamp("2026-04-01"), annotation_text="...")` or use `fig.add_shape(type="line", ...)` separately
- This is a known Plotly issue with datetime axes + annotation parameters

### 16. API Returning Nullable Fields Breaking Strict Schemas

**What happened:** Backend agent defined a Pydantic model with `precipitation: float` (non-nullable), but the live API (Open-Meteo) returned `null` for precipitation on some records. The fetcher crashed on real production data despite passing unit tests with mock data.

**Correction:** When consuming external APIs, always assume any numeric field CAN be null unless the API documentation explicitly guarantees non-null. Use `Optional[float]` with a default, or coerce nulls to a sensible default (e.g., `0.0` for precipitation).

**Mitigation:**
- **WRONG:** `precipitation: float` with external API data
- **CORRECT:** `precipitation: float = Field(default=0.0)` with a validator that coerces `None → 0.0`
- Always test fetchers against LIVE API data, not just mocked responses, before marking backend as complete
- This applies to any strict schema (Pydantic, Zod, JSON Schema) consuming external data

### 17. Python Version Mismatch Not Caught by Pre-Flight

**What happened:** Project's `pyproject.toml` specified `requires-python = ">=3.12"`, but the system's default `python3` was Python 3.9. The coordinator spent 10+ minutes diagnosing why `pip install -e .` failed before discovering `python3.12` was available as a separate binary.

**Correction:** Pre-flight must check the Python version against `pyproject.toml`'s `requires-python` field. If the default `python3` doesn't match, scan for specific version binaries (`python3.12`, `python3.11`, etc.).

**Mitigation:**
- Check `requires-python` in `pyproject.toml` during pre-flight
- If mismatch: scan for `python3.{required_version}` binary
- If found: use that binary for the venv (`python3.12 -m venv .venv`)
- If not found: report immediately instead of retrying with wrong version

---

<!-- Add new patterns below. Use sequential numbering. -->
<!-- After adding, push to squad-template repo: shared/failure-patterns-global.md -->
