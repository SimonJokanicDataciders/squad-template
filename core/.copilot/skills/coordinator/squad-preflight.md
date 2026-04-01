# Squad Pre-Flight — Environment Checks Before Work

**Load when:** ALWAYS — run these checks in the bootstrap turn, BEFORE spawning any agents.

---

## Why

In stress tests, ~60% of session time was wasted on environment issues discovered mid-pipeline (.NET SDK mismatches, missing Java, wrong database provider, hung restores). Detecting these upfront saves hours.

---

## Pre-Flight Checks

Run ALL of these in ONE parallel turn during bootstrap. Report issues immediately — don't proceed with work if critical checks fail.

```bash
# 1. .NET SDK version (if .NET project)
if ls *.sln *.csproj 2>/dev/null | head -1 >/dev/null 2>&1; then
  echo "DOTNET_SDK:$(dotnet --version 2>/dev/null || echo MISSING)"
  if [ -f global.json ]; then
    echo "GLOBAL_JSON:$(cat global.json | grep -o '"version"[^,]*' | head -1)"
  fi
fi

# 2. Node.js (if Node project)
if [ -f package.json ]; then
  echo "NODE:$(node --version 2>/dev/null || echo MISSING)"
  echo "NPM:$(npm --version 2>/dev/null || echo MISSING)"
  if [ -d node_modules ]; then echo "NODE_MODULES:present"; else echo "NODE_MODULES:missing"; fi
fi

# 3. Python (if Python project)
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  echo "PYTHON:$(python3 --version 2>/dev/null || echo MISSING)"
fi

# 4. Java (needed for OpenAPI generators)
echo "JAVA:$(java -version 2>&1 | head -1 || echo MISSING)"

# 5. Docker
echo "DOCKER:$(docker info >/dev/null 2>&1 && echo RUNNING || echo NOT_RUNNING)"

# 6. Database provider detection (for .NET projects)
if ls *.sln *.csproj 2>/dev/null | head -1 >/dev/null 2>&1; then
  grep -rl "UseSqlServer\|AddSqlServer" src/ 2>/dev/null | head -1 && echo "DB_PROVIDER:SqlServer"
  grep -rl "UseNpgsql\|AddNpgsqlDbContext" src/ 2>/dev/null | head -1 && echo "DB_PROVIDER:PostgreSQL"
fi

# 7. Key ports free
for port in 5000 5043 4200 63564 1433 5432; do
  if lsof -nP -iTCP:$port -sTCP:LISTEN >/dev/null 2>&1; then
    echo "PORT_IN_USE:$port"
  fi
done
```

## Handling Results

### Critical (BLOCK work until resolved)

| Check | Failure | Action |
|-------|---------|--------|
| .NET SDK version doesn't match global.json | Build will fail | Report: "This project requires .NET SDK {version} (from global.json). Install it or set DOTNET_ROOT." |
| Node.js missing on a Node project | Nothing will build | Report: "Install Node.js to continue." |
| Docker not running on a project with docker-compose | Database won't start | Report: "Start Docker Desktop — the project needs containers for the database." |

### Warning (report but continue)

| Check | Failure | Action |
|-------|---------|--------|
| node_modules missing | npm install needed | Auto-run `npm install` before first build |
| Java missing | OpenAPI client generation will fail | Report: "Java is not installed. OpenAPI client generation will be skipped. Install via `brew install openjdk`." |
| Port in use | Service may fail to bind | Report which ports are occupied. May need to stop other processes. |
| DB provider detected | Know which database to start | If SqlServer → use SQL Server/Azure SQL Edge container (port 1433). If PostgreSQL → use Postgres container (port 5432). **Never guess — check the code.** |

### Info (log only)

| Check | Result | Action |
|-------|--------|--------|
| Detected versions | .NET 9.0.203, Node 22, Python 3.12 | Log in session state for debugging |

## Report Format

```
📋 Pre-flight checks:
  ✅ .NET SDK 9.0.203 matches global.json
  ✅ Node.js v22.0.0, npm 10.0.0
  ✅ Docker running
  ⚠️  Java not installed (OpenAPI generation will be skipped)
  ⚠️  node_modules missing — running npm install
  ❌ Port 5043 already in use (PID 12345)
```

## When to STOP and Ask the User

Only stop if:
- SDK version mismatch AND no local install possible
- Docker is required but not running AND user hasn't acknowledged
- Multiple critical issues detected simultaneously

Otherwise: fix what you can (install deps, set env vars), warn about the rest, and proceed.
