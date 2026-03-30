---
name: "cap-template-role-ops-deploy"
description: "Deploy domain module for Ralph — CI/CD pipeline, Pulumi IaC, Azure OIDC, environment promotion. Load only when task involves deployment concerns."
domain: "operations/deploy"
confidence: "high"
source: "split from cap-template-role-operations.md"
---

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

## Deployment Checklist

- [ ] All tests pass on `main` branch
- [ ] Migration bundle built and tested locally
- [ ] Pulumi stack outputs match expected configuration
- [ ] OIDC credentials configured in GitHub environment secrets
- [ ] Environment protection rules set for Staging and Production
- [ ] Health checks respond on `/health` and `/alive`
- [ ] Application Insights receiving telemetry

See also: `cap-template-role-ops-secure.md` for OIDC authentication details.
