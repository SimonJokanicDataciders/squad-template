# Squad Infrastructure Integration

> Load this when user asks about Kubernetes, autoscaling, rate limiting, or machine capabilities.

---

## Machine Capabilities

Squad can be configured to respect the host machine's capabilities — CPU, memory, and concurrency limits. This prevents over-spawning agents on constrained hardware.

### Capability Detection

On session start, the coordinator may optionally check:

```bash
# Check available CPUs
nproc  # Linux/macOS
Get-WmiObject -Class Win32_Processor | Select NumberOfCores  # Windows

# Check available memory
free -m  # Linux
vm_stat  # macOS
```

Store detected capabilities in session state. Use them to cap parallel agent spawns:
- **Low-memory machines (<4GB available):** Max 2 parallel agents
- **Standard machines (4-16GB):** Max 4 parallel agents (default)
- **High-memory machines (>16GB):** Max 8 parallel agents

### Cooperative Rate Limiting

When multiple sessions run simultaneously (e.g., VS Code + CLI), they share the platform's API rate limits. The coordinator applies cooperative rate limiting to avoid exhausting the quota:

**Rules:**
- Check `.squad/state/rate-limit.json` before spawning (if it exists)
- If another session wrote a rate limit warning in the last 60 seconds, back off for 30 seconds
- After spawning, write current timestamp to `.squad/state/last-spawn.json`
- If spawning fails with a rate limit error, wait 30 seconds and retry once before falling back to next model in chain

**Rate limit file format (`.squad/state/rate-limit.json`):**
```json
{
  "last_limit_hit": "2025-01-15T10:30:00Z",
  "session_id": "abc123",
  "backoff_until": "2025-01-15T10:30:30Z"
}
```

---

## Ralph Circuit Breaker

Ralph's work-check loop has a built-in circuit breaker to prevent runaway loops:

**Circuit breaker triggers:**
- More than 20 consecutive rounds with no progress (no issues closed, no PRs merged)
- 3 consecutive agent failures on the same work item
- Rate limit errors on 3 consecutive spawns

**When circuit breaker trips:**
1. Stop the loop
2. Report: `"⚠️ Ralph: Circuit breaker tripped after {N} rounds. Pausing. Say 'Ralph, go' to resume."`
3. Enter idle-watch mode (do not fully stop — just pause active looping)
4. Log the event to `.squad/log/`

**Resetting the circuit breaker:**
- User says "Ralph, go" or "Ralph, reset" → reset counter, resume loop
- User says "Ralph, idle" → full stop (circuit breaker not relevant)

---

## KEDA Scaler Integration

When Squad is deployed with Kubernetes Event-Driven Autoscaling (KEDA), it can scale agent runners based on queue depth.

### Overview

KEDA watches the Squad work queue (GitHub issue labels, or a dedicated message queue) and scales Kubernetes jobs to process work:

- **Scale trigger:** Number of `squad` labeled issues with no `squad:{member}` assignment
- **Scale target:** Copilot agent runner deployments or Squad job runners
- **Scale down:** After queue drains, scale to zero (no idle compute cost)

### KEDA ScaledJob Configuration

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: squad-agent-runner
spec:
  jobTargetRef:
    template:
      spec:
        containers:
        - name: squad-runner
          image: ghcr.io/your-org/squad-runner:latest
  triggers:
  - type: github
    metadata:
      owner: "{repo-owner}"
      repo: "{repo-name}"
      labelName: "squad"
      targetIssueCount: "1"
```

### Coordinator Behavior with KEDA

When KEDA is active:
- The coordinator does NOT spawn long-running background agents for issue work
- Instead, it writes work items to the queue and lets KEDA-triggered runners pick them up
- Use `squad watch` to monitor queue depth and KEDA scaling events
- Check `.squad/config.json` for `keda.enabled: true` to activate this mode

### Kubernetes Integration

Squad can write state to a Kubernetes ConfigMap for cross-pod visibility:

```bash
# Write current team state to ConfigMap
kubectl create configmap squad-state \
  --from-file=team.md=.squad/team.md \
  --from-file=decisions.md=.squad/decisions.md \
  --dry-run=client -o yaml | kubectl apply -f -
```

This allows multiple runner pods to share the same team configuration without a shared filesystem.

### Machine Capabilities for Kubernetes

When running in a Kubernetes pod, resource limits from the pod spec define the capability profile:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2"
```

Map these to Squad's capability tiers:
- Memory limit < 1GB → low-memory mode (max 2 parallel agents)
- Memory limit 1-4GB → standard mode (max 4 parallel agents)
- Memory limit > 4GB → high-memory mode (max 8 parallel agents)
