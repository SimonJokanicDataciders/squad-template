---
description: Mandatory security checklist and response protocol
---

# Security Rules

## Pre-Commit Security Checklist

Run through this checklist before EVERY commit. If any item fails, do not commit.

- [ ] **No hardcoded secrets** — no API keys, passwords, connection strings, or tokens in source code
- [ ] **All user input validated and sanitized** — never trust data from clients, URLs, headers, or files
- [ ] **SQL/query injection prevention** — use parameterized queries or ORM; never concatenate user input into queries
- [ ] **XSS prevention** — never render raw/unescaped HTML from user input; use framework escaping
- [ ] **CSRF protection** — all state-changing endpoints require anti-forgery tokens or SameSite cookies
- [ ] **Authentication checked** — all protected routes verify identity before processing
- [ ] **Authorization checked** — all protected routes verify the user has permission for the specific resource
- [ ] **Rate limiting** — public-facing endpoints have rate limits to prevent abuse
- [ ] **Error messages are safe** — error responses never leak stack traces, SQL, file paths, or internal details

## Secret Management

```
WRONG:
  const apiKey = "sk-proj-abc123def456";
  const connectionString = "Server=prod-db;Password=hunter2";

CORRECT:
  const apiKey = config.get("EXTERNAL_API_KEY");
  // or
  const apiKey = process.env.EXTERNAL_API_KEY;
  // or (C#)
  var apiKey = configuration["ExternalApi:Key"];
```

Secrets belong in:
- Environment variables
- Secret managers (Azure Key Vault, AWS Secrets Manager, HashiCorp Vault)
- `.env` files that are `.gitignore`-d

## Parameterized Queries

```
WRONG (SQL injection):
  var query = $"SELECT * FROM Users WHERE Id = {userId}";
  var query = `SELECT * FROM users WHERE id = '${userId}'`;

CORRECT (parameterized):
  // C#
  var query = "SELECT * FROM Users WHERE Id = @Id";
  command.Parameters.AddWithValue("@Id", userId);

  // TypeScript (Prisma)
  const user = await prisma.user.findUnique({ where: { id: userId } });

  // Python (SQLAlchemy)
  stmt = select(User).where(User.id == user_id)
```

## XSS Prevention

```
WRONG:
  <div dangerouslySetInnerHTML={{ __html: userComment }} />
  element.innerHTML = userInput;

CORRECT:
  <div>{userComment}</div>
  element.textContent = userInput;
  // If HTML is required, sanitize with DOMPurify:
  <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userComment) }} />
```

## Authentication and Authorization

Every protected endpoint must:
1. Verify the caller's identity (authentication)
2. Verify the caller's permissions for the specific resource (authorization)
3. Return 401 for unauthenticated requests
4. Return 403 for unauthorized requests
5. Never return 404 to hide resource existence from unauthorized users — use 403

## Logging Security

```
WRONG:
  logger.info("Login attempt", { username, password });
  logger.error("DB error", { connectionString, query });

CORRECT:
  logger.info("Login attempt", { username, result: "success" });
  logger.error("DB error", { operation: "UserLookup", errorCode: err.code });
```

Never log: passwords, tokens, API keys, PII (emails, SSNs), full credit card numbers, connection strings.

## Security Response Protocol

When a security vulnerability is discovered:

1. **STOP** — Do not deploy, merge, or continue development on the affected code
2. **SCAN** — Determine the scope: which endpoints, data, and users are affected
3. **FIX** — Patch the vulnerability in a dedicated branch with a focused PR
4. **ROTATE** — If credentials were exposed, rotate them immediately in all environments
5. **REVIEW** — Post-incident review: how did it get in, how do we prevent recurrence

## Dependency Security

- Run `npm audit` / `dotnet list package --vulnerable` / `pip audit` in CI
- Never ignore critical or high severity vulnerabilities
- Pin dependency versions in production
- Review new dependencies before adding them — check maintenance status, download counts, known issues
