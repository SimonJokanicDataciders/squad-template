status: done

## Summary

Completed full technical audit of Squad-Template tooling. Findings written to `.squad/analysis/backend-findings.md`.

### Key findings:

**Bugs (P0-P1):**
- Shell operator precedence bug breaks vite/next.config detection (lines 131, 133, 652, 654)
- Corrupted `{skills/coordinator}` directory in `core/.copilot/skills/`
- `session-state.md` always overwritten on re-init (missing `cp -n`, line 268)
- Detection logic duplicated between `detect_stack()` and Step 5 — will diverge

**Architecture gaps:**
- Only `dotnet-angular` ever suggested as preset — no dispatch for others
- No monorepo detection (subdir traversal)
- Seeds never actively applied to charters — passive discovery only
- No `--upgrade` version comparison — always runs unconditionally
- No `.gitignore` management for ephemeral Squad files

**Content gaps:**
- Missing seeds: NestJS, Drizzle, Supabase (high priority), Svelte, tRPC, Docker
- `ralph` and `scribe` missing `learn.md`
- `mcp-config.json` referenced in init.sh but not present in core/
- `dotnet-angular` skills are CAP.Template-specific (hardcoded paths)

**13 prioritized recommendations** in findings file, ranked P0–P3.
