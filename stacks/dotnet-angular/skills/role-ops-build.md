---
name: "cap-template-role-ops-build"
description: "Build domain module for Ralph — NUKE build system, Docker, migration bundles, versioning. Load only when task involves build concerns."
domain: "operations/build"
confidence: "high"
source: "split from cap-template-role-operations.md"
---

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

## Build Checklist

- [ ] `dotnet build` succeeds with zero warnings
- [ ] `dotnet test` passes all tests
- [ ] Docker image builds successfully
- [ ] Migration bundle creates without errors
- [ ] Artifacts placed in correct output directory
- [ ] Version numbers correct for the environment
