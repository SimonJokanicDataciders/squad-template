---
name: "cap-template-role-ops-monitor"
description: "Monitor domain module for Ralph — OpenTelemetry, instrumentation patterns, health checks, Aspire dashboard. Load only when task involves observability concerns."
domain: "operations/monitor"
confidence: "high"
source: "split from cap-template-role-operations.md"
---

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

## Monitor Checklist

- [ ] `ActivitySource` created for new feature domain
- [ ] Key operations have activities with meaningful tags
- [ ] Exceptions recorded with `AddException()` and `SetStatus(Error)`
- [ ] Logging uses structured parameters (not interpolation)
- [ ] All OTel packages on same minor version
- [ ] Health checks respond correctly
