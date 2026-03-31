# Ceremonies

Structured team meetings triggered automatically or on request.

---

## Design Review

- **Trigger:** auto
- **When:** before implementation
- **Condition:** Any of:
  - Multi-agent task involving 2+ agents modifying shared systems
  - Feature touches 3+ architectural layers (API + database + frontend)
  - Work introduces a new architectural pattern not in existing codebase
  - Breaking changes to existing APIs or database schemas
  - New infrastructure or deployment changes
  - risk_tier is high or critical
- **Facilitator:** Lead
- **Participants:** All relevant agents (Backend for feasibility, Frontend for UI impact, Ralph for security)
- **Status:** enabled

### Agenda
1. Review task and requirements
2. Agree on interfaces, contracts, and file structure
3. Identify risks, edge cases, and migration concerns
4. Define success criteria and handoff artifacts
5. Assign action items with clear ownership

### Gate
- Produce a design handoff artifact before implementation begins
- Blocking concerns resolved or accepted with documented risk
- All interface contracts agreed and documented

### Checklist
- [ ] Requirements are clear and complete
- [ ] Interfaces/contracts defined for cross-agent handoffs
- [ ] Data model validated (entities, relationships, constraints)
- [ ] Security implications assessed
- [ ] Rollback strategy identified if applicable
- [ ] Performance impact considered
- [ ] Breaking changes documented

---

## PR Review Ceremony

- **Trigger:** auto
- **When:** before merge
- **Condition:** Any of:
  - 10+ files touched in a single PR
  - 400+ lines changed
  - Security-sensitive code (auth, CORS, secrets, permissions)
  - Database migrations present
  - Infrastructure or deployment changes
  - New external dependencies added
- **Facilitator:** Tester
- **Participants:** Ralph (security), Scribe (documentation)
- **Status:** enabled

### Agenda
1. Review all changed files for correctness and conventions
2. Check test coverage for new/changed functionality
3. Verify security implications (no exposed secrets, proper auth)
4. Validate documentation updates
5. Approve or request changes with specific file:line references

### Gate
- All review findings addressed or accepted with risk documentation
- Tests pass and coverage meets threshold
- No unresolved security concerns

---

## Retrospective

- **Trigger:** auto
- **When:** after
- **Condition:** Build failure, test failure, reviewer rejection, or production incident
- **Facilitator:** Lead
- **Participants:** All involved agents
- **Status:** enabled

### Agenda
1. What happened? (facts only, with timestamps)
2. Root cause analysis (5 whys)
3. What went well?
4. What should change?
5. Action items for next iteration
6. Update failure-patterns.md if applicable
