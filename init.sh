#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
STACK=""
AUTO_DETECT=false
UPGRADE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --stack) STACK="$2"; shift 2 ;;
    --auto) AUTO_DETECT=true; shift ;;
    --upgrade) UPGRADE=true; shift ;;
    -h|--help)
      echo "Usage: ./init.sh <target-dir> [OPTIONS]"
      echo ""
      echo "Bootstrap a project with the optimized Squad template."
      echo ""
      echo "Arguments:"
      echo "  <target-dir>              Path to your project (must be a git repo)"
      echo ""
      echo "Options:"
      echo "  --stack <preset-name>     Apply a specific stack preset (e.g., dotnet-angular)"
      echo "  --auto                    Auto-detect tech stack and apply matching seeds"
      echo "  --upgrade                 Update existing Squad setup (preserves team/decisions/history)"
      echo ""
      echo "Available presets:"
      ls -1 "$SCRIPT_DIR/stacks/" | grep -v '^_' | grep -v 'seeds' 2>/dev/null || echo "  (none yet — use _template to create one)"
      echo ""
      echo "Available seeds:"
      ls -1 "$SCRIPT_DIR/stacks/seeds/" 2>/dev/null | sed 's/.seed.md//' || echo "  (none)"
      echo ""
      echo "Examples:"
      echo "  ./init.sh ~/my-project --stack dotnet-angular    # Use full preset"
      echo "  ./init.sh ~/my-project --auto                    # Auto-detect and apply seeds"
      echo "  ./init.sh ~/my-project --upgrade                 # Update existing setup"
      echo "  ./init.sh ~/my-project                           # Core only, no stack preset"
      exit 0
      ;;
    *) TARGET="$1"; shift ;;
  esac
done

# Validate
if [[ -z "$TARGET" ]]; then
  echo "Usage: ./init.sh <target-dir> [--stack <preset-name>]"
  echo "Run ./init.sh --help for more info."
  exit 1
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: Directory '$TARGET' does not exist."
  exit 1
fi

if [[ ! -d "$TARGET/.git" ]]; then
  echo "Error: '$TARGET' is not a git repository. Run 'git init' first."
  exit 1
fi

# Handle --upgrade: update core files without overwriting customizations
if [[ "$UPGRADE" == true ]]; then
  if [[ ! -d "$TARGET/.squad" ]]; then
    echo "Error: No existing Squad setup found. Use init.sh without --upgrade first."
    exit 1
  fi

  echo "================================================"
  echo "  Squad Template Upgrade"
  echo "================================================"
  echo "  Target: $TARGET"
  echo ""
  echo "  Updating: coordinator, skills, workflows, seeds"
  echo "  Preserving: team.md, decisions, agent histories, config"
  echo "================================================"
  echo ""

  # Update coordinator prompt (always overwrite — it's the engine)
  cp "$SCRIPT_DIR/core/.github/agents/squad.agent.md" "$TARGET/.github/agents/"
  echo "  ✓ Coordinator prompt updated"

  # Update coordinator skills (always overwrite)
  cp "$SCRIPT_DIR/core/.copilot/skills/coordinator/"*.md "$TARGET/.copilot/skills/coordinator/" 2>/dev/null || true
  echo "  ✓ Coordinator skills updated"

  # Update workflows (don't overwrite customized ones)
  for wf in "$SCRIPT_DIR/core/.github/workflows/"*.yml; do
    [ -f "$wf" ] && cp -n "$wf" "$TARGET/.github/workflows/" 2>/dev/null || true
  done
  echo "  ✓ Workflows updated (new only)"

  # Update seeds
  if [ -d "$SCRIPT_DIR/stacks/seeds" ]; then
    mkdir -p "$TARGET/.squad/seeds"
    cp "$SCRIPT_DIR/stacks/seeds/"*.seed.md "$TARGET/.squad/seeds/" 2>/dev/null || true
    echo "  ✓ Seeds updated"
  fi

  # Update shared failure patterns
  if [ -d "$SCRIPT_DIR/shared" ]; then
    cp "$SCRIPT_DIR/shared/"*.md "$TARGET/.copilot/skills/" 2>/dev/null || true
    echo "  ✓ Shared failure patterns updated"
  fi

  # Update identity templates (wisdom patterns, session state format)
  cp "$SCRIPT_DIR/core/.squad/identity/"*.md "$TARGET/.squad/identity/" 2>/dev/null || true
  cp "$SCRIPT_DIR/core/.squad/session-state.md" "$TARGET/.squad/" 2>/dev/null || true
  echo "  ✓ Identity templates updated"

  echo ""
  echo "  Upgrade complete. Preserved: team.md, decisions, agent charters,"
  echo "  agent histories, config.json, routing.md, ceremonies.md"
  echo ""
  exit 0
fi

# Auto-detect tech stack when --auto is used or no --stack specified
detect_stack() {
  local dir="$1"
  DETECTED_TECHS=""
  MATCHED_SEEDS=""
  SUGGESTED_PRESET=""

  # Detect technologies from config files
  [ -f "$dir/package.json" ] && DETECTED_TECHS="$DETECTED_TECHS node"
  [ -f "$dir/tsconfig.json" ] && DETECTED_TECHS="$DETECTED_TECHS typescript"
  [ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ] && DETECTED_TECHS="$DETECTED_TECHS vite"
  [ -f "$dir/angular.json" ] && DETECTED_TECHS="$DETECTED_TECHS angular"
  [ -f "$dir/next.config.js" ] || [ -f "$dir/next.config.ts" ] || [ -f "$dir/next.config.mjs" ] && DETECTED_TECHS="$DETECTED_TECHS nextjs"
  ls "$dir"/*.csproj >/dev/null 2>&1 && DETECTED_TECHS="$DETECTED_TECHS dotnet"
  ls "$dir"/*.sln >/dev/null 2>&1 && DETECTED_TECHS="$DETECTED_TECHS dotnet"
  [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ] && DETECTED_TECHS="$DETECTED_TECHS python"
  [ -f "$dir/go.mod" ] && DETECTED_TECHS="$DETECTED_TECHS go"
  [ -f "$dir/Cargo.toml" ] && DETECTED_TECHS="$DETECTED_TECHS rust"
  [ -f "$dir/Gemfile" ] && DETECTED_TECHS="$DETECTED_TECHS ruby"
  [ -f "$dir/composer.json" ] && DETECTED_TECHS="$DETECTED_TECHS php"

  # Detect from package.json dependencies
  if [ -f "$dir/package.json" ]; then
    grep -q '"react"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS react"
    grep -q '"vue"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS vue"
    grep -q '"express"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS express"
    grep -q '"fastify"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS fastify"
    grep -q '"vitest"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS vitest"
    grep -q '"jest"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS jest"
    grep -q '"tailwindcss"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS tailwind"
    grep -q '"prisma"' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS prisma"
    grep -q '"@angular' "$dir/package.json" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS angular"
  fi

  # Detect from Python config
  if [ -f "$dir/pyproject.toml" ]; then
    grep -q 'fastapi' "$dir/pyproject.toml" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS fastapi"
    grep -q 'pytest' "$dir/pyproject.toml" 2>/dev/null && DETECTED_TECHS="$DETECTED_TECHS pytest"
  fi

  DETECTED_TECHS=$(echo "$DETECTED_TECHS" | xargs | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

  # Match against available seeds
  if [ -d "$SCRIPT_DIR/stacks/seeds" ]; then
    for seed_file in "$SCRIPT_DIR/stacks/seeds/"*.seed.md; do
      [ -f "$seed_file" ] || continue
      seed_name=$(basename "$seed_file" .seed.md)
      for tech in $DETECTED_TECHS; do
        if [[ "$seed_name" == *"$tech"* ]] || [[ "$tech" == *"$seed_name"* ]]; then
          MATCHED_SEEDS="$MATCHED_SEEDS $seed_name"
          break
        fi
      done
    done
    MATCHED_SEEDS=$(echo "$MATCHED_SEEDS" | xargs)
  fi

  # Suggest preset based on detected stack
  if echo "$DETECTED_TECHS" | grep -q "dotnet" && echo "$DETECTED_TECHS" | grep -q "angular"; then
    SUGGESTED_PRESET="dotnet-angular"
  fi
}

# Run auto-detection if --auto or no --stack given (and project has source files)
if [[ "$AUTO_DETECT" == true && -z "$STACK" ]]; then
  detect_stack "$TARGET"

  echo "================================================"
  echo "  Stack Auto-Detection"
  echo "================================================"
  echo "  Detected: ${DETECTED_TECHS:-nothing}"
  echo "  Matching seeds: ${MATCHED_SEEDS:-none}"
  echo "  Suggested preset: ${SUGGESTED_PRESET:-none}"
  echo "================================================"
  echo ""

  if [[ -n "$SUGGESTED_PRESET" && -d "$SCRIPT_DIR/stacks/$SUGGESTED_PRESET" ]]; then
    echo "  → Applying preset: $SUGGESTED_PRESET"
    STACK="$SUGGESTED_PRESET"
  elif [[ -n "$MATCHED_SEEDS" ]]; then
    echo "  → No full preset found. Matching seeds will be available"
    echo "    for Bootstrap Mode when Squad starts."
  else
    echo "  → No matching presets or seeds found."
    echo "    Squad will use Bootstrap Mode to generate conventions from your first prompt."
  fi
  echo ""
fi

# If no --stack and no --auto, detect stack and show hint
if [[ -z "$STACK" && "$AUTO_DETECT" == false ]]; then
  detect_stack "$TARGET"
  if [[ -n "$DETECTED_TECHS" ]]; then
    echo "================================================"
    echo "  Detected tech: $DETECTED_TECHS"
    if [[ -n "$SUGGESTED_PRESET" ]]; then
      echo "  Tip: use --stack $SUGGESTED_PRESET for full preset"
    fi
    if [[ -n "$MATCHED_SEEDS" ]]; then
      echo "  Tip: use --auto to apply matching seeds ($MATCHED_SEEDS)"
    fi
    echo "  Continuing with core only..."
    echo "================================================"
    echo ""
  fi
fi

# Get user info for placeholder replacement
USER_NAME=$(cd "$TARGET" && git config user.name 2>/dev/null || echo "Developer")
PROJECT_NAME=$(basename "$TARGET")
INIT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "================================================"
echo "  Squad Template Init"
echo "================================================"
echo "  Project:  $PROJECT_NAME"
echo "  Target:   $TARGET"
echo "  User:     $USER_NAME"
echo "  Stack:    ${STACK:-none (core only)}"
echo "================================================"
echo ""

# Standard agent roster — all projects get these 6 agents
AGENTS="lead backend frontend tester scribe ralph"

# Step 1: Copy core files
echo "1/6  Copying core engine..."

# Create full directory structure including ALL agent dirs
mkdir -p "$TARGET/.github/agents" "$TARGET/.github/workflows"
mkdir -p "$TARGET/.copilot/skills/coordinator"
mkdir -p "$TARGET/.squad/identity" "$TARGET/.squad/templates"
mkdir -p "$TARGET/.squad/decisions/inbox" "$TARGET/.squad/casting"
mkdir -p "$TARGET/.squad/orchestration-log" "$TARGET/.squad/log" "$TARGET/.squad/skills"

for agent in $AGENTS; do
  mkdir -p "$TARGET/.squad/agents/$agent"
done

# Copy core files
cp -n "$SCRIPT_DIR/core/.gitattributes" "$TARGET/.gitattributes" 2>/dev/null || true
cp "$SCRIPT_DIR/core/.github/agents/squad.agent.md" "$TARGET/.github/agents/"
[ -f "$SCRIPT_DIR/core/.copilot/mcp-config.json" ] && cp "$SCRIPT_DIR/core/.copilot/mcp-config.json" "$TARGET/.copilot/" || true
cp "$SCRIPT_DIR/core/.copilot/skills/coordinator/"*.md "$TARGET/.copilot/skills/coordinator/" 2>/dev/null || true

# Squad state files
cp -n "$SCRIPT_DIR/core/.squad/config.json" "$TARGET/.squad/config.json" 2>/dev/null || true
cp "$SCRIPT_DIR/core/.squad/session-state.md" "$TARGET/.squad/"
cp "$SCRIPT_DIR/core/.squad/identity/"*.md "$TARGET/.squad/identity/"
cp "$SCRIPT_DIR/core/.squad/templates/"*.md "$TARGET/.squad/templates/" 2>/dev/null || true
cp "$SCRIPT_DIR/core/.squad/casting/"*.json "$TARGET/.squad/casting/" 2>/dev/null || true

# Copy stack seeds (curated guardrails for common tech stacks)
if [ -d "$SCRIPT_DIR/stacks/seeds" ]; then
  mkdir -p "$TARGET/.squad/seeds"
  cp "$SCRIPT_DIR/stacks/seeds/"*.seed.md "$TARGET/.squad/seeds/" 2>/dev/null || true
fi

# Copy shared company-wide failure patterns (inherited by all projects)
if [ -d "$SCRIPT_DIR/shared" ]; then
  cp "$SCRIPT_DIR/shared/"*.md "$TARGET/.copilot/skills/" 2>/dev/null || true
fi

# Workflows (don't overwrite existing)
for wf in "$SCRIPT_DIR/core/.github/workflows/"*.yml; do
  [ -f "$wf" ] && cp -n "$wf" "$TARGET/.github/workflows/" 2>/dev/null || true
done

echo "     Done."

# Step 2: Create agent charters and histories for ALL agents
echo "2/6  Creating agent charters and histories..."

for agent in $AGENTS; do
  # Copy charter from core (generic functional charters for all roles)
  if [ -f "$SCRIPT_DIR/core/.squad/agents/$agent/charter.md" ]; then
    cp "$SCRIPT_DIR/core/.squad/agents/$agent/charter.md" "$TARGET/.squad/agents/$agent/charter.md"
  fi

  # Copy learning protocol if it exists (auto-discovery instructions)
  if [ -f "$SCRIPT_DIR/core/.squad/agents/$agent/learn.md" ]; then
    cp "$SCRIPT_DIR/core/.squad/agents/$agent/learn.md" "$TARGET/.squad/agents/$agent/learn.md"
  fi

  # Create empty history.md if it doesn't exist
  if [[ ! -f "$TARGET/.squad/agents/$agent/history.md" ]]; then
    cat > "$TARGET/.squad/agents/$agent/history.md" << HIST_EOF
# $agent — History

## Project Context
Project: $PROJECT_NAME

## Learnings
<!-- Append entries below. -->
HIST_EOF
  fi
done

echo "     Created charters + histories for: $AGENTS"

# Step 3: Create team.md, routing.md, ceremonies.md, decisions.md
echo "3/6  Creating team configuration..."

# team.md — pre-populated roster so coordinator skips Init Mode
if [[ ! -f "$TARGET/.squad/team.md" ]]; then
  cat > "$TARGET/.squad/team.md" << TEAM_EOF
# Squad Team

> $PROJECT_NAME

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Squad | Coordinator | Routes work, enforces handoffs and reviewer gates. |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
| Lead | Architect | .squad/agents/lead/charter.md | 🏗️ Active |
| Backend | Backend Dev | .squad/agents/backend/charter.md | 🔧 Active |
| Frontend | Frontend Dev | .squad/agents/frontend/charter.md | ⚛️ Active |
| Tester | QA / Tester | .squad/agents/tester/charter.md | 🧪 Active |
| Scribe | Session Logger | .squad/agents/scribe/charter.md | 📋 Silent |
| Ralph | Work Monitor | .squad/agents/ralph/charter.md | 🔄 Monitor |

## Project Context

- **Project:** $PROJECT_NAME
- **Created:** $(date +%Y-%m-%d)
TEAM_EOF
fi

# routing.md — always create from template if missing
if [[ ! -f "$TARGET/.squad/routing.md" ]]; then
  cat > "$TARGET/.squad/routing.md" << 'ROUTE_EOF'
# Work Routing

How to decide who handles what.

## Delivery Flow

```
design → plan → implement / frontend / database → lint → test
    → integration-test → review → build → deploy → monitor
         ↑                                              ↓
      scaffold (optional)               document (parallel)
```

## Routing Table

| Work Type | SDLC Phase | Route To | Examples |
|-----------|-----------|----------|----------|
| Architecture, domain model | design | Lead | System design, API contracts, data model |
| Task decomposition, commit strategy | plan | Lead | Breaking work into steps, ordering |
| Backend services, endpoints | implement | Backend | API routes, business logic, data access |
| Database schema, migrations | database | Backend | Schema changes, seed data |
| UI components, user flows | frontend | Frontend | Pages, forms, components, styling |
| File scaffolding | scaffold | Frontend | Generate boilerplate, project structure |
| Lint, formatting, static analysis | lint | Tester | Code style, linting rules |
| Unit and component tests | test | Tester | Unit tests, mocks, assertions |
| Integration and e2e tests | integration-test | Tester | API tests, browser tests |
| PR review, quality gates | review | Tester | Code review, approval |
| API docs, README, decision capture | document | Scribe | Documentation, changelogs |
| Session logging | — | Scribe | Automatic — never needs routing |

## Routing Principles

1. **Eager routing** — pick the most specific agent
2. **Fan-out on multi-domain** — parallel when independent
3. **Anticipate downstream** — queue related work proactively
4. **Doc-impact check** — user-facing changes trigger Scribe
5. **Security-impact check** — auth/secrets changes need review
6. **Fallback cascade** — project rules → universal → ask human
7. **Ceremony awareness** — check triggers before dispatching
ROUTE_EOF
fi

# ceremonies.md — always create from template if missing
if [[ ! -f "$TARGET/.squad/ceremonies.md" ]]; then
  cat > "$TARGET/.squad/ceremonies.md" << 'CERE_EOF'
# Ceremonies

Structured team meetings triggered automatically or on request.

---

## Design Review

- **Trigger:** auto
- **When:** before
- **Condition:** Multi-agent task involving 2+ agents modifying shared systems, or task introduces a new architectural pattern
- **Facilitator:** Lead
- **Participants:** All relevant agents
- **Status:** enabled

### Agenda
1. Review task and requirements
2. Agree on interfaces and contracts
3. Identify risks and edge cases
4. Assign action items

### Gate
- Produce a design.brief before implementation
- Blocking concerns resolved or accepted with documented risk

---

## Retrospective

- **Trigger:** auto
- **When:** after
- **Condition:** Build failure, test failure, or reviewer rejection
- **Facilitator:** Lead
- **Participants:** All involved agents
- **Status:** enabled

### Agenda
1. What happened? (facts only)
2. Root cause analysis
3. What should change?
4. Action items for next iteration
CERE_EOF
fi

# decisions.md
if [[ ! -f "$TARGET/.squad/decisions.md" ]]; then
  cat > "$TARGET/.squad/decisions.md" << 'DECISIONS_EOF'
# Squad Decisions

## Active Decisions

No decisions recorded yet.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
DECISIONS_EOF
fi

echo "     Done."

# Step 4: Apply stack preset (if specified)
if [[ -n "$STACK" ]]; then
  STACK_DIR="$SCRIPT_DIR/stacks/$STACK"
  if [[ ! -d "$STACK_DIR" ]]; then
    echo ""
    echo "Error: Stack preset '$STACK' not found."
    echo "Available presets:"
    ls -1 "$SCRIPT_DIR/stacks/" | grep -v '^_' 2>/dev/null || echo "  (none)"
    exit 1
  fi

  echo "4/6  Applying stack preset: $STACK"

  # Copy skills (stack-specific knowledge bundles)
  if [[ -d "$STACK_DIR/skills" ]]; then
    cp "$STACK_DIR/skills/"*.md "$TARGET/.copilot/skills/" 2>/dev/null || true
  fi

  # Override routing and ceremonies with stack-specific versions
  [[ -f "$STACK_DIR/routing.md" ]] && cp "$STACK_DIR/routing.md" "$TARGET/.squad/"
  [[ -f "$STACK_DIR/ceremonies.md" ]] && cp "$STACK_DIR/ceremonies.md" "$TARGET/.squad/"

  # Copy common rules (universal coding standards)
  if [[ -d "$SCRIPT_DIR/stacks/rules/common" ]]; then
    mkdir -p "$TARGET/.github/instructions"
    cp "$SCRIPT_DIR/stacks/rules/common/"*.md "$TARGET/.github/instructions/" 2>/dev/null || true
    echo "     Copied common rules (coding-style, security, testing, git-workflow)"
  fi

  # Copy language-specific rules based on detected tech stack
  if [[ -n "$DETECTED_TECHS" ]]; then
    for tech in $DETECTED_TECHS; do
      case "$tech" in
        dotnet) lang_dir="csharp" ;;
        typescript|angular|react|vue|nextjs|node) lang_dir="typescript" ;;
        python|fastapi) lang_dir="python" ;;
        *) lang_dir="" ;;
      esac
      if [[ -n "$lang_dir" && -d "$SCRIPT_DIR/stacks/rules/$lang_dir" ]]; then
        cp "$SCRIPT_DIR/stacks/rules/$lang_dir/"*.md "$TARGET/.github/instructions/" 2>/dev/null || true
        echo "     Copied $lang_dir rules"
      fi
    done
  fi

  # Copy instructions
  if [[ -d "$STACK_DIR/instructions" ]]; then
    mkdir -p "$TARGET/.github/instructions"
    cp "$STACK_DIR/instructions/"* "$TARGET/.github/instructions/" 2>/dev/null || true
  fi

  # Override agent charters with stack-specific versions
  # Map preset charter names → agent directory names (zsh-compatible)
  charter_map() {
    case "$1" in
      architect) echo "lead";;
      backend)   echo "backend";;
      frontend)  echo "frontend";;
      qa)        echo "tester";;
      docs)      echo "scribe";;
      ops)       echo "ralph";;
      *)         echo "$1";;
    esac
  }

  if [[ -d "$STACK_DIR/agents" ]]; then
    for preset_file in "$STACK_DIR/agents/"*.charter.md; do
      [ -f "$preset_file" ] || continue
      basename_no_ext=$(basename "$preset_file" .charter.md)
      target_agent=$(charter_map "$basename_no_ext")
      if [[ -d "$TARGET/.squad/agents/$target_agent" ]]; then
        cp "$preset_file" "$TARGET/.squad/agents/$target_agent/charter.md"
        echo "     Upgraded charter: $target_agent (from $basename_no_ext.charter.md)"
      fi
    done
  fi

  # Apply cast name mapping (rename agent directories to stack-specific names)
  if [[ -f "$STACK_DIR/cast.conf" ]]; then
    echo "     Applying cast names..."
    while IFS='=' read -r role cast; do
      # Skip comments and empty lines
      [[ "$role" =~ ^#.*$ || -z "$role" ]] && continue
      role=$(echo "$role" | tr -d ' ')
      cast=$(echo "$cast" | tr -d ' ')

      # Skip if role and cast are the same (no rename needed)
      [[ "$role" == "$cast" ]] && continue

      # Rename agent directory from role name to cast name
      if [[ -d "$TARGET/.squad/agents/$role" && ! -d "$TARGET/.squad/agents/$cast" ]]; then
        mv "$TARGET/.squad/agents/$role" "$TARGET/.squad/agents/$cast"
        echo "     Renamed agent: $role → $cast"
      fi
    done < "$STACK_DIR/cast.conf"

    # Regenerate team.md with cast names
    echo "     Regenerating team.md with cast names..."
    MEMBERS_TABLE=""
    while IFS='=' read -r role cast; do
      [[ "$role" =~ ^#.*$ || -z "$role" ]] && continue
      role=$(echo "$role" | tr -d ' ')
      cast=$(echo "$cast" | tr -d ' ')
      display_name="$(echo "$cast" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
      case "$role" in
        lead)     role_label="Architect";      status_emoji="🏗️ Active" ;;
        backend)  role_label="Backend Dev";    status_emoji="🔧 Active" ;;
        frontend) role_label="Frontend Dev";   status_emoji="⚛️ Active" ;;
        tester)   role_label="QA / Tester";    status_emoji="🧪 Active" ;;
        scribe)   role_label="Session Logger"; status_emoji="📋 Silent" ;;
        ralph)    role_label="Work Monitor";   status_emoji="🔄 Monitor" ;;
        *)        role_label="$role";          status_emoji="🔧 Active" ;;
      esac
      MEMBERS_TABLE="$MEMBERS_TABLE| $display_name | $role_label | .squad/agents/$cast/charter.md | $status_emoji |
"
    done < "$STACK_DIR/cast.conf"

    cat > "$TARGET/.squad/team.md" << CAST_TEAM_EOF
# Squad Team

> $PROJECT_NAME

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Squad | Coordinator | Routes work, enforces handoffs and reviewer gates. |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
${MEMBERS_TABLE}
## Project Context

- **Project:** $PROJECT_NAME
- **Created:** $(date +%Y-%m-%d)
CAST_TEAM_EOF
    echo "     Team roster updated with cast names."
  fi

  echo "     Done."
else
  echo "4/6  No stack preset — using generic agent charters."
  echo "     Customize charters in .squad/agents/*/charter.md for your tech stack."

  # Still copy common rules and detected language rules even without a stack preset
  if [[ -d "$SCRIPT_DIR/stacks/rules/common" ]]; then
    mkdir -p "$TARGET/.github/instructions"
    cp "$SCRIPT_DIR/stacks/rules/common/"*.md "$TARGET/.github/instructions/" 2>/dev/null || true
    echo "     Copied common rules (coding-style, security, testing, git-workflow)"
  fi

  if [[ -n "$DETECTED_TECHS" ]]; then
    for tech in $DETECTED_TECHS; do
      case "$tech" in
        dotnet) lang_dir="csharp" ;;
        typescript|angular|react|vue|nextjs|node) lang_dir="typescript" ;;
        python|fastapi) lang_dir="python" ;;
        *) lang_dir="" ;;
      esac
      if [[ -n "$lang_dir" && -d "$SCRIPT_DIR/stacks/rules/$lang_dir" ]]; then
        mkdir -p "$TARGET/.github/instructions"
        cp "$SCRIPT_DIR/stacks/rules/$lang_dir/"*.md "$TARGET/.github/instructions/" 2>/dev/null || true
        echo "     Copied $lang_dir rules"
      fi
    done
  fi
fi

# Step 5: Generate project map (scan actual file structure)
echo "5/6  Scanning project structure..."

SOURCE_COUNT=$(find "$TARGET" -maxdepth 4 -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
     -o -name "*.py" -o -name "*.cs" -o -name "*.go" -o -name "*.rs" \
     -o -name "*.java" -o -name "*.rb" -o -name "*.php" \
     -o -name "*.vue" -o -name "*.svelte" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' \
  -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null | wc -l | tr -d ' ')

if [[ "$SOURCE_COUNT" -gt 0 ]]; then
  # Detect tech stack from config files
  DETECTED_STACK=""
  [ -f "$TARGET/package.json" ] && DETECTED_STACK="$DETECTED_STACK Node.js"
  [ -f "$TARGET/tsconfig.json" ] && DETECTED_STACK="$DETECTED_STACK TypeScript"
  [ -f "$TARGET/vite.config.ts" ] || [ -f "$TARGET/vite.config.js" ] && DETECTED_STACK="$DETECTED_STACK Vite"
  [ -f "$TARGET/angular.json" ] && DETECTED_STACK="$DETECTED_STACK Angular"
  [ -f "$TARGET/next.config.js" ] || [ -f "$TARGET/next.config.ts" ] && DETECTED_STACK="$DETECTED_STACK Next.js"
  ls "$TARGET"/*.csproj >/dev/null 2>&1 && DETECTED_STACK="$DETECTED_STACK .NET"
  ls "$TARGET"/*.sln >/dev/null 2>&1 && DETECTED_STACK="$DETECTED_STACK .NET"
  [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/requirements.txt" ] && DETECTED_STACK="$DETECTED_STACK Python"
  [ -f "$TARGET/go.mod" ] && DETECTED_STACK="$DETECTED_STACK Go"
  [ -f "$TARGET/Cargo.toml" ] && DETECTED_STACK="$DETECTED_STACK Rust"
  DETECTED_STACK=$(echo "$DETECTED_STACK" | xargs)

  # Get file tree
  FILE_TREE=$(find "$TARGET" -maxdepth 4 -type f \
    -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' \
    -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/.squad/*' \
    -not -path '*/.copilot/*' -not -path '*/.github/*' \
    -not -name '*.lock' -not -name 'package-lock.json' \
    2>/dev/null | sed "s|$TARGET/||" | sort)

  DIR_COUNT=$(echo "$FILE_TREE" | sed 's|/[^/]*$||' | sort -u | wc -l | tr -d ' ')

  # Get npm scripts if package.json exists
  SCRIPTS_TABLE=""
  if [ -f "$TARGET/package.json" ]; then
    SCRIPTS_TABLE=$(python3 -c "
import json, sys
try:
    pkg = json.load(open('$TARGET/package.json'))
    scripts = pkg.get('scripts', {})
    for k, v in scripts.items():
        print(f'| \`npm run {k}\` | \`{v}\` |')
except: pass
" 2>/dev/null)
  fi

  cat > "$TARGET/.squad/project-map.md" << PMAP_EOF
# Project Map

> Auto-generated by init.sh on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
> Re-scan by coordinator when structure changes significantly.

## Tech Stack (detected)

$DETECTED_STACK

## File Structure

\`\`\`
$FILE_TREE
\`\`\`

## Stats

- **Source files:** $SOURCE_COUNT
- **Directories:** $DIR_COUNT

## Key Commands

| Command | Description |
|---------|-------------|
$SCRIPTS_TABLE

## Notes

- This map reflects the project at bootstrap time.
- The coordinator will refresh it when agents create significant new files.
- Agents MUST read this file before starting work to understand the actual project layout.
PMAP_EOF

  echo "     Scanned $SOURCE_COUNT source files across $DIR_COUNT directories."
  echo "     Stack: ${DETECTED_STACK:-unknown}"
  echo "     Written: .squad/project-map.md"
else
  echo "     No source files detected — project map will be generated on first session."
fi

echo "     Done."

# Step 6: Replace placeholders
echo "6/6  Replacing placeholders..."

find "$TARGET/.squad" "$TARGET/.github/agents" "$TARGET/.copilot" \
  -type f \( -name "*.md" -o -name "*.json" \) 2>/dev/null | while read -r f; do
  if grep -q '{{PROJECT_NAME}}\|{{USER_NAME}}\|{{INIT_TIMESTAMP}}' "$f" 2>/dev/null; then
    sed -i.bak \
      -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      -e "s/{{USER_NAME}}/$USER_NAME/g" \
      -e "s/{{INIT_TIMESTAMP}}/$INIT_TIMESTAMP/g" \
      "$f"
    rm -f "$f.bak"
  fi
done

echo "     Done."

# Summary
TOTAL_FILES=$(find "$TARGET/.squad" "$TARGET/.github/agents" "$TARGET/.copilot" -type f 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "================================================"
echo "  Squad template applied successfully!"
echo "================================================"
echo ""
echo "  Files:    $TOTAL_FILES"
if [[ -n "$STACK" && -f "$SCRIPT_DIR/stacks/$STACK/cast.conf" ]]; then
  CAST_LIST=$(grep -v '^#' "$SCRIPT_DIR/stacks/$STACK/cast.conf" | grep -v '^$' | cut -d= -f2 | tr -d ' ' | awk '{print toupper(substr($0,1,1)) substr($0,2)}' | paste -sd', ' -)
  echo "  Team:     $CAST_LIST"
else
  echo "  Team:     Lead, Backend, Frontend, Tester, Scribe, Ralph"
fi
echo "  Routing:  .squad/routing.md"
echo "  Charters: .squad/agents/*/charter.md"
echo ""
echo "  The team is READY — no Init Mode needed."
echo "  Start working: copilot --agent squad"
echo ""
if [[ -n "$STACK" ]]; then
echo "  Stack preset '$STACK' applied with specialized"
echo "  charters and ${TOTAL_FILES} skill bundles."
echo ""
else
echo "  Customize for your tech stack:"
echo "    1. Edit .squad/agents/*/charter.md with your conventions"
echo "    2. Create skill bundles in .copilot/skills/"
echo "    3. Document failures in .copilot/skills/failure-patterns.md"
fi
echo ""
