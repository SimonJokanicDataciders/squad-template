---
name: "cap-template-role-operations"
description: "Operations, release, security, and triage bundle for Ralph in the local CAP.Template Squad"
domain: "operations"
confidence: "high"
source: "manual"
---

> **DEPRECATED:** This monolithic bundle has been split into on-demand modules. Use `cap-template-role-ops-core.md` plus domain modules (`ops-build`, `ops-deploy`, `ops-monitor`, `ops-secure`). This file is retained for reference only.

## Context

Use this bundle when `Ralph` is triaging work, assessing build/release concerns, checking security-sensitive changes, or validating monitoring/operations impact. This bundle embeds the full knowledge from the CAP.Template build, deploy, monitor, and secure agents so Ralph can operate without reading the original `.github/` files.

## NUKE Build System

### Build Architecture

**Build files:** `build/` directory (partial class pattern)

```
build/
  Build.cs              -- Main entry, parameters, solution reference
  Build.Core.cs         -- Restore, Compile, Test, Publish targets
  Build.Database.cs     -- BuildMigrations, MigrateDev/Staging/Prod
  Build.Docker.cs       -- Docker image build & push
  Build.Deployment.cs   -- Azure App Service deployment
  Build.Setup.cs        -- Pulumi setup, environment configuration
  Build.Angular.cs      -- Angular build orchestration
  PulumiHelper.cs       -- Pulumi CLI wrapper
  Models/               -- Configuration, DeploymentEnvironment, DockerImage
```

### Build Target Dependency Graph

```
Restore
  -> Compile
    -> Test
    -> BuildDev -> DeployDev
    -> BuildStaging -> DeployStaging
    -> BuildProd -> DeployProd
  -> BuildMigrations
    -> MigrateDev / MigrateStaging / MigrateProd
  -> BuildDockerImage -> PushDockerImage

ProvisionDev / ProvisionStaging / ProvisionProd (parallel, independent)
```

### Common Build Commands

```bash
# Local development
./build.cmd Restore          # Restore NuGet packages
./build.cmd Compile          # Build solution
./build.cmd Test             # Run all tests

# Environment builds
./build.cmd BuildDev         # Build for development
./build.cmd BuildStaging     # Build for staging
./build.cmd BuildProd        # Build for production

# Database
./build.cmd BuildMigrations  # Create portable migration bundle

# Docker
./build.cmd BuildDockerImage # Build Docker images
./build.cmd PushDockerImage  # Push to ACR

# Infrastructure
./build.cmd ProvisionDev     # Provision Azure resources (Dev)

# Deployment
./build.cmd DeployDev        # Deploy to Dev environment
```

### Docker Multi-Stage Build

```dockerfile
# From src/Paso.Cap.Web/Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
# Restore -> Build -> Publish -> Runtime image
```

### Migration Bundle Workflow

```bash
# 1. Build the migration bundle
dotnet ef migrations bundle \
  --project src/Paso.Cap.Domain \
  --startup-project src/Paso.Cap.Web \
  -o artifacts/migrations/efbundle \
  --force --self-contained \
  --target-runtime linux-x64

# 2. Execute against target database
./efbundle -- "Server=...;Database=...;..."
```

### Version Management

```csharp
// From Build.cs
static readonly string AssemblyVersion =
    Environment.GetEnvironmentVariable("VersionFormat")?.Replace("{0}", "0").Until("-")
    ?? $"0.0.1.{timestamp}";  // Fallback: date-based version

static readonly string PackageVersion =
    Environment.GetEnvironmentVariable("PackageVersion") ?? AssemblyVersion + "-local";
```

## Deployment Pipeline

### Pipeline Structure

**Pipeline file:** `.github/workflows/ci.yml`
**Trigger:** `push` to `main`

```
Dev Environment:
  Restore -> Provision -> Build -> Test -> Migrate -> Deploy

Staging Environment (after Dev succeeds):
  Restore -> Provision -> Build -> Migrate -> Deploy

Production Environment (after Staging succeeds):
  Restore -> Provision -> Build -> Migrate -> Deploy
```

**Key differences per environment:**
- **Dev:** Runs tests, auto-migration also available via `DatabaseInitializer`
- **Staging:** No tests (already passed in Dev), migration via bundle
- **Production:** No tests, migration via bundle, environment protection rules

### Deployment Approval Rules

- Dev: automatic on push to main
- Staging: automatic after Dev succeeds
- Production: requires environment protection rules (explicit human approval)
- Never deploy to Prod without Staging passing first
- Manual deployments require explicit ask-first

### Azure Authentication (OIDC)

```yaml
# Required permissions in ci.yml
permissions:
  id-token: write   # For Azure OIDC
  contents: read

# GitHub Secrets needed per environment:
# AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
# AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_KEY (for Pulumi state)
# PULUMI_CONFIG_PASSPHRASE
```

No stored service principal secrets -- OIDC only.

### Migration Strategy in Cloud

```
1. Stop App Service (prevent conflicts)
2. Execute migration bundle against production DB
3. Start App Service with new version
4. Health check verification
```

### Pulumi Infrastructure

**Stack file:** `src/Paso.Cap.Infrastructure/AppStack.cs`
**Stacks:** `development`, `staging`, `production`

Resources provisioned per environment:
- Resource Group
- Log Analytics + Application Insights
- App Service Plan + Web App
- SQL Server or PostgreSQL database
- Azure Container Registry
- Firewall rules

### Deployment Commands

```bash
# Manual deployment (via NUKE)
./build.cmd DeployDev
./build.cmd DeployStaging
./build.cmd DeployProd

# Infrastructure provisioning
./build.cmd ProvisionDev
./build.cmd ProvisionStaging
./build.cmd ProvisionProd

# Check GitHub Actions
gh workflow view ci.yml
gh run list --workflow=ci.yml
gh run view <run-id> --log
```

## Observability and Monitoring

### OpenTelemetry Setup

**Backend configuration:** `src/Paso.Cap.Web/Infrastructure/TelemetryExtensions.cs`
- Tracing: ASP.NET Core, HTTP client, gRPC instrumentation
- Metrics: ASP.NET Core, HTTP client, runtime metrics
- Logging: Structured with formatted messages
- Export: OTLP protocol to collector sidecar

**Frontend configuration:** `src/Paso.Cap.Angular/src/` (OpenTelemetry browser SDK)
- Trace context propagation via W3C headers
- Auto-instrumentation: document-load, fetch

**Collector:** `src/Paso.Cap.Infrastructure/OpenTelemetryCollector/Dockerfile`

### Instrumentation Patterns

**ActivitySource per domain area:**
```csharp
public sealed class OrderService {
    private static readonly ActivitySource ActivitySource = new("Paso.Cap.Orders");

    public async Task<OrderDto> GetById(Guid id, CancellationToken ct) {
        using var activity = ActivitySource.StartActivity("GetOrderById", ActivityKind.Internal);
        activity?.SetTag("order.id", id);
        // ...
    }
}
```

**Exception recording:**
```csharp
activity?.AddException(ex);
activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
```

**Structured logging (mandatory):**
```csharp
// Correct -- named parameters for structured logging
_logger.LogInformation("Order {OrderId} created for customer {CustomerName}", order.Id, dto.CustomerName);

// Wrong -- string interpolation (not structured!)
_logger.LogInformation($"Order {order.Id} created");
```

**Custom metrics:**
```csharp
private static readonly Meter Meter = new("Paso.Cap.Orders");
private static readonly Counter<long> OrdersCreated = Meter.CreateCounter<long>("orders.created");
OrdersCreated.Add(1, new KeyValuePair<string, object?>("order.type", orderType));
```

### Health Checks

Configured in `WebServiceExtensions.cs`:
- `/health` -- all checks
- `/alive` -- readiness only

### Aspire Dashboard (Local Dev)

```bash
dotnet run --project src/Paso.Cap.AppHost
# Dashboard: https://localhost:15888
# View: Traces, Metrics, Logs, Resources
```

## Security

### Exception Handling Strategy (StatusCodeSelector)

**Configured in:** `src/Paso.Cap.Web/Infrastructure/WebServiceExtensions.cs`

```csharp
app.UseExceptionHandler(new ExceptionHandlerOptions {
    StatusCodeSelector = ex => ex switch {
        EntityNotFoundException => StatusCodes.Status404NotFound,
        ArgumentException       => StatusCodes.Status400BadRequest,
        ConcurrencyException    => StatusCodes.Status409Conflict,
        NotImplementedException => StatusCodes.Status501NotImplemented,
        _                       => StatusCodes.Status500InternalServerError
    }
});
```

**Pattern:** Throw domain exceptions in service layer, let the global handler map to HTTP status codes. Never return raw HTTP status codes from services.

**Custom exceptions in `src/Paso.Cap.Shared/`:**
- `EntityNotFoundException` -> 404
- `ConcurrencyException` -> 409

### Security Action Classes

**Code Security:**
- No hardcoded secrets, connection strings, or API keys
- Input validated at service entry points with `ArgumentException`
- Domain exceptions used (not raw HTTP status codes)
- `ConcurrencyException` caught from `DbUpdateConcurrencyException`
- No `FromSqlRaw` with string interpolation (SQL injection risk)

**API Security:**
- `ProblemDetails` enabled (RFC 7807) via `builder.Services.AddProblemDetails()`
- Exception details not leaked to clients in production
- Request timeouts via `UseRequestTimeouts()`
- CORS not set to `AllowAnyOrigin` with credentials
- `[Authorize]` on protected endpoints when auth configured

**Frontend Security:**
- No `innerHTML` with user-controlled data (XSS)
- No `bypassSecurityTrustHtml/Script/Url` usage
- No API keys in `environment.ts`
- HTTPS enforced for all API calls

**Infrastructure Security:**
- OIDC for Azure authentication (not stored service principal secrets)
- Database firewall rules configured per environment
- Pulumi secrets encrypted with passphrase
- GitHub Secrets used for CI/CD (not committed to repo)

**Data Security:**
- Immutable records prevent accidental mutation
- Read-only collections in DTOs
- Nullable reference types enabled (null safety)
- `is null` / `is not null` pattern (not `== null`)

### Secrets Management

| Secret Type | Where | How |
|-------------|-------|-----|
| Database passwords | Pulumi config | `pulumi config set --secret` |
| Azure credentials | GitHub Secrets | OIDC (no stored secrets) |
| Connection strings | `appsettings.json` | Only dev defaults; production via environment variables |
| API keys | Never in code | Environment variables or Azure Key Vault |

## CAP.Template Project Structure Reference

```
src/
  Paso.Cap.Web/            -- ASP.NET host, endpoints, middleware
  Paso.Cap.Domain/         -- Domain entities, EF Core DbContext
  Paso.Cap.Shared/         -- Shared DTOs, custom exceptions (EntityNotFoundException, ConcurrencyException)
  Paso.Cap.Angular/        -- Angular frontend
  Paso.Cap.AppHost/        -- .NET Aspire orchestration host (Aspire 13.x)
  Paso.Cap.Infrastructure/ -- Pulumi IaC (AppStack.cs), OTel Collector
build/                     -- NUKE build system (partial class pattern)
docs/                      -- Architecture documentation
.github/workflows/ci.yml   -- CI/CD pipeline
```

## Operational Checklists

### Build Checklist
- [ ] `dotnet build` succeeds with zero warnings
- [ ] `dotnet test` passes all tests
- [ ] Docker image builds successfully
- [ ] Migration bundle creates without errors
- [ ] Artifacts placed in correct output directory
- [ ] Version numbers correct for the environment

### Deployment Checklist
- [ ] All tests pass on `main` branch
- [ ] Migration bundle built and tested locally
- [ ] Pulumi stack outputs match expected configuration
- [ ] OIDC credentials configured in GitHub environment secrets
- [ ] Environment protection rules set for Staging and Production
- [ ] Health checks respond on `/health` and `/alive`
- [ ] Application Insights receiving telemetry

### Monitor Checklist
- [ ] `ActivitySource` created for new feature domain
- [ ] Key operations have activities with meaningful tags
- [ ] Exceptions recorded with `AddException()` and `SetStatus(Error)`
- [ ] Logging uses structured parameters (not interpolation)
- [ ] All OTel packages on same minor version
- [ ] Health checks respond correctly

### Security Checklist
- [ ] No hardcoded secrets, connection strings, or API keys
- [ ] Input validated at service entry points
- [ ] Domain exceptions used (not raw HTTP status codes in services)
- [ ] `ConcurrencyException` caught from `DbUpdateConcurrencyException`
- [ ] `ProblemDetails` enabled for standardized error responses
- [ ] OIDC for Azure authentication
- [ ] Database firewall rules configured

## Patterns

- Join the task when work touches CI/local build, deployment flow, security-sensitive configuration, observability, or release readiness
- Treat GitHub workflows and infrastructure as authoritative in the real repository, even if local Squad generates parallel artifacts
- Separate safe local evaluation from external actions: local reads/writes are fine; external or production-impacting actions require explicit human approval
- Capture operation-sensitive risks clearly so they are visible before a local experiment is mistaken for a production-ready workflow
- Support `Ripley` with triage and route build, deploy, secure, and monitor concerns early

## Artifact Schema

When producing operations artifacts, use this structure:

```yaml
artifact:
  type: operations.assessment
  agent: ralph
  scope: build | deploy | monitor | secure | triage
  risk_level: low | medium | high | critical
  files_reviewed:
    - path: "relative/path"
      concern: "description"
  checklist_result:
    passed: []
    failed: []
    skipped: []
  approval_required: true | false
  summary: "One-line description"
  open_risks: []
```

## Handoff Requirements

- **From Ripley (triage):** Receive work items touching build/deploy/monitor/secure; assess risk and route
- **From Fenster (backend):** Review CI impact, auth changes, runtime configuration
- **From Hockney (review):** Validate release readiness, security findings
- **To Scribe:** Provide operational findings for documentation in `docs/build-project.md` or `docs/infrastructure-project.md`
- **To any agent:** Always include risk level, checklist results, and whether human approval is required

## Boundaries

- **Always do:** Restore before compile, test before deploy, use NUKE targets (not raw dotnet CLI for CI), use OIDC, verify health checks, throw domain exceptions, validate inputs
- **Ask first:** Changing target dependency graph, modifying Docker base images, manual deployments, skipping environments, changing OIDC config, adding new exception types, changing CORS policy, adding new metrics instruments, changing OTel exporter config
- **Never do:** Skip Restore, deploy without testing, hardcode paths (use `AbsolutePath`), push to ACR without building first, deploy to Prod without Staging, store Azure credentials as secrets (use OIDC), hardcode secrets, return stack traces to clients, use `FromSqlRaw` with interpolation, disable HTTPS, log PII, use string interpolation for logs, mix OTel package versions, perform external/production-impacting actions without explicit approval

## Anti-Patterns

- Do not treat generated local Squad workflows as approved replacements for the repository's GitHub workflows.
- Do not perform external, deployment, or production-impacting actions without explicit approval.
- Do not hide security-sensitive implications inside a generic review summary.
- Do not skip the Dev -> Staging -> Prod promotion chain.
- Do not store service principal secrets; always use OIDC.

---

## Quick-Reference: When Ralph Should Join Early and Common Pairings

*(Merged from cap-template-operations-delivery.md)*

### When Ralph Should Join Early
- Any work touching CI/build, deployment, observability, or security-sensitive config
- When release readiness, rollback, or explicit human approval is in question
- On changes to OIDC, Pulumi, health checks, or exception handling
- When cross-cutting risk or triage is needed (pair with Ripley)

### Common Pairings
- **Ripley:** Triage, risk routing, early build/deploy/security review
- **Fenster:** CI/auth/runtime config, backend changes
- **Hockney:** Release readiness, security review
- **Scribe:** Document operational findings for build/infrastructure docs

### Operations Assessment Checklist Reminder
Always use the operational checklists (build, deploy, monitor, security) from the sections above for every assessment.
Record `operations.assessment` artifacts with scope, risk_level, checklist results, and approval_required flag.
