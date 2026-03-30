# Ceremonies

Structured team meetings triggered automatically or on request.

---

## Design Review

- **Trigger:** auto
- **When:** before
- **Condition:** Multi-agent task involving 2+ agents modifying shared systems
<!-- TODO: Add project-specific triggers. Examples:
- Work introduces a new architectural pattern
- Feature touches 3+ architectural layers
- Breaking changes to APIs or schemas
- Database migration altering existing tables
-->
- **Facilitator:** {Lead}
- **Participants:** All relevant agents
- **Status:** enabled

### Agenda
1. Review task and requirements
2. Agree on interfaces and contracts
3. Identify risks and edge cases
4. Assign action items

### Gate
- Produce a design.brief artifact before implementation
- Blocking concerns resolved or accepted with documented risk

---

## Retrospective

- **Trigger:** auto
- **When:** after
- **Condition:** Build failure, test failure, or reviewer rejection
- **Facilitator:** {Lead}
- **Participants:** All involved agents
- **Status:** enabled

### Agenda
1. What happened? (facts only)
2. Root cause analysis
3. What should change?
4. Action items for next iteration
