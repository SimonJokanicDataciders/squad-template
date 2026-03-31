# Creating a New Stack Preset

This directory is a **ready-to-customize** template for creating stack-specific presets. All files contain real structure and guidance — replace the `<!-- Replace -->` comments with your project's actual conventions and code examples.

## Quick Start

```bash
# 1. Copy this directory
cp -r stacks/_template stacks/your-stack-name

# 2. Fill in YOUR conventions (see checklist below)

# 3. Apply to any project
~/squad-template/init.sh ~/your-project --stack your-stack-name
```

## Customization Checklist

### Agent Charters (`agents/*.charter.md`) — ~30 min per agent
- [ ] Replace `<!-- Replace -->` comments with your actual stack info
- [ ] Add your code conventions to Guardrails sections
- [ ] Add your anti-patterns to "What NEVER to Do" sections
- [ ] Set the reference implementation path
- [ ] Adjust model preferences if needed

### Skill Bundles (`skills/*.md`) — ~1 hour per bundle
- [ ] Replace project structure with YOUR actual directory layout
- [ ] Add REAL code examples from your reference implementation
- [ ] Fill in entity/service/endpoint/component patterns with actual code
- [ ] Document your ORM conventions, migration rules, test patterns
- [ ] Update key commands table

### Routing (`routing.md`) — ~15 min
- [ ] Verify work types match your project
- [ ] Add/remove rows for your specific needs
- [ ] Add stack-specific routing overrides if needed

### Ceremonies (`ceremonies.md`) — ~15 min
- [ ] Adjust trigger conditions for your stack
- [ ] Add stack-specific ceremony triggers (e.g., "database migration present")
- [ ] Set file/line thresholds for PR review

### Instructions (`instructions/language.instructions.md`) — ~15 min
- [ ] Replace generic conventions with YOUR language-specific rules
- [ ] Add formatting, naming, and style conventions

### Optional: Cast Names (`cast.conf`) — 5 min
- [ ] Create `cast.conf` if you want custom agent names
- [ ] Format: `role=castname` (e.g., `lead=architect`, `backend=builder`)

## What Makes a Good Skill Bundle

The difference between generic and effective:

**Generic (useless):** "Follow best practices for error handling"

**Effective:** "All endpoint handlers wrap async operations in try/catch. Catch specific exceptions first (ValidationException → 400, NotFoundException → 404), then catch Exception → 500 with structured logging via ILogger."

**Rules:**
1. Embed actual code patterns from YOUR codebase, not generic advice
2. Include a complete code example for every pattern (entity, service, endpoint, test)
3. Show the EXACT imports, class structure, and method signatures
4. Document what NEVER to do with specific examples of what goes wrong
5. Start `failure-patterns.md` empty — add real failures as you discover them during agent work

## After Setup: Benchmark

1. Pick a simple feature (e.g., add a CRUD entity with tests)
2. Run Squad: `copilot --agent squad`
3. Give the task and observe how agents perform
4. Note failures → add to `failure-patterns.md`
5. Note convention violations → tighten charter guardrails
6. Repeat for 2-3 features until the pipeline is clean

## Time Investment

| Item | Time | Frequency |
|------|------|-----------|
| Fill in charters | ~2 hours | Once per stack |
| Write skill bundles | ~4 hours | Once per stack |
| Customize routing/ceremonies | ~30 min | Once per stack |
| Document failure patterns | ~15 min per pattern | Ongoing |
| **Total setup** | **~8 hours** | **Amortizes at 3-4 features** |
