# Ceremonies

Team ceremonies that trigger automatically based on context. Ceremonies bring multiple Squad members together for structured collaboration at critical decision points.

---

## Design Review

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before implementation |
| **Enabled** | yes |

### Trigger Conditions

A Design Review is triggered when ANY of these conditions are met:

- Feature touches **3 or more architectural layers** (e.g., domain + API + database + frontend)
- Work introduces a **new pattern** not present in the current codebase
- `risk_tier` is **high** or **critical**
- The change involves **breaking changes** to existing APIs or data schemas
- Multi-agent task involving **2+ agents modifying shared systems**
- **CAP-specific:** EF Core migration altering existing tables
- **CAP-specific:** New Pulumi infrastructure resources

### Participants

| SDLC Agent | Squad Member | Role in Ceremony |
|------------|-------------|-----------------|
| design | **Ripley** | **Lead** — presents architecture proposal, facilitates |
| implement | **Fenster** | Validates feasibility and implementation approach |
| database | **Fenster** | Reviews data model and migration strategy (if DB changes) |
| api-contract | **Fenster** | Reviews API surface changes (if endpoint changes) |
| secure | **Ralph** | Reviews security implications (if auth/data changes) |
| frontend | **Dallas** | Reviews frontend impact (if UI changes) |

### Checklist

- [ ] Requirements are clear and unambiguous
- [ ] Interface contracts between layers are defined
- [ ] Data model and migration path are validated
- [ ] Security implications are identified and addressed
- [ ] Rollback strategy is documented
- [ ] Performance impact is estimated
- [ ] Breaking changes are inventoried with a migration path

### Agenda

1. Review the task and requirements
2. Agree on interfaces and contracts between components
3. Identify risks and edge cases
4. Assign action items

### Gate

- Must produce `design.brief` artifact before implementation begins
- All blocking concerns must be resolved or explicitly accepted with documented risk
- Design decisions must be logged in `.squad/decisions.md`

---

## PR Review Ceremony

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before merge |
| **Enabled** | yes |

### Trigger Conditions

A PR Review Ceremony is triggered when ANY of these conditions are met:

- PR touches **10 or more files**
- PR contains **400 or more lines** changed
- PR modifies **security-sensitive** code (auth, secrets, permissions, data access)
- PR includes **database migrations** that alter existing tables
- **CAP-specific:** Database migration present in PR diff

### Participants

| SDLC Agent | Squad Member | Role in Ceremony |
|------------|-------------|-----------------|
| review | **Hockney** | **Lead** — comprehensive quality review |
| lint | **Hockney** | Code quality and formatting validation |
| test | **Hockney** | Test coverage assessment |
| secure | **Ralph** | Security review (if security-relevant changes) |
| document | **Scribe** | Documentation completeness check (if user-facing changes) |

### Checklist

- [ ] All review checklist items addressed
- [ ] No blocker-severity findings remain unresolved
- [ ] Test coverage is adequate for changed code
- [ ] Security concerns are addressed
- [ ] Documentation is updated for user-facing changes

### Gate

- All **Blocker** findings must be resolved before merge
- **Major** findings must be resolved or explicitly deferred with documented justification
- `review.report` must include ceremony participation record

---

## Post-Incident Retrospective

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after incident resolution |
| **Enabled** | yes |

### Trigger Conditions

A Post-Incident Retrospective is triggered when ANY of these conditions are met:

- After resolution of any **SEV1** or **SEV2** incident
- After any incident involving **data loss** or **security breach**
- When explicitly requested by the team after a notable failure

### Participants

| SDLC Agent | Squad Member | Role in Ceremony |
|------------|-------------|-----------------|
| incident-response | **Ralph** | **Lead** — presents incident timeline and resolution |
| monitor | **Ralph** | Reviews observability gaps and alert effectiveness |
| deploy | **Ralph** | Reviews deployment process (if deployment-related) |
| secure | **Ralph** | Reviews security posture (if security-related) |
| document | **Scribe** | Captures retrospective output and action items |

### Required Output

The retrospective must produce:

1. **Timeline** — minute-by-minute sequence of detection, triage, diagnosis, and resolution
2. **Root cause** — technical and process root cause (not blame)
3. **What went well** — effective responses and tooling
4. **What went wrong** — gaps in detection, communication, or process
5. **Action items** — concrete, assignable tasks with owners and deadlines
6. **Process improvements** — changes to prevent recurrence

### Gate

- Action items must be created as tracked issues
- Monitoring gaps must be addressed by the `monitor` agent (Ralph)
- Process improvements must be logged as decisions in `.squad/decisions.md`

---

## Retrospective (Local Squad)

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | build failure, test failure, or reviewer rejection |
| **Enabled** | yes |

### Trigger Conditions

- Build failure during the delivery flow
- Test failure (unit or integration)
- Reviewer rejection of a PR or artifact

### Participants

All involved Squad members from the failed workflow participate. Facilitated by the lead (coordinator).

### Agenda

1. What happened? (facts only)
2. Root cause analysis
3. What should change?
4. Action items for next iteration

---

## Ceremony Protocol

### Before a Ceremony

1. The coordinator detects that ceremony conditions are met
2. Coordinator informs the user which ceremony is triggered and why
3. Coordinator lists participating Squad members
4. User confirms or overrides (with documented justification)

### During a Ceremony

1. Each participating Squad member reviews the work from its domain perspective
2. Findings are collected with severity classification (Blocker / Major / Minor / Nit)
3. Blocking concerns must be resolved before the ceremony gate is passed
4. All decisions are logged using the standard decision format in `.squad/decisions.md`

### After a Ceremony

1. Ceremony record is included in the phase artifact (e.g., `design.brief` includes design review record)
2. Decisions are logged in `.squad/decisions.md`
3. The coordinator proceeds to the next phase in the delivery flow
