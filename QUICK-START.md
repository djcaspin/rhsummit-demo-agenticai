# RHACS Demo Quick Start Guide
## 5-Minute Setup for Impatient Presenters

---

## 1. Access RHACS (1 minute)


---

## 2. Enable Policies (2 minutes)

**Navigate:** Platform Configuration → Policy Management

**Search and enable these 4 policies:**

| Policy Name | Search Term | Action |
|------------|-------------|--------|
| Privileged Container | `privileged` | Edit → ✅ Enforce on Deploy → Save |
| Host PID/IPC/Network | `host network` | Edit → ✅ Enforce on Deploy → Save |
| Dangerous Linux Capabilities | `capabilities` | Edit → ✅ Enforce on Deploy → Save |
| Mount Host Path | `mount` | Edit → ✅ Enforce on Deploy → Save |

**Each policy:**
1. Click policy name
2. Actions → Edit policy
3. Scroll to "Policy Behavior"
4. Check ✅ **Enforce on Deploy**
5. Click **Save**

---

## 3. Run Demo (2 minutes)

```bash
cd ~/Projects/claude/team_reporting/demo

# Clean start
oc delete namespace ai-workload-demo 2>/dev/null || true

# Deploy legitimate agent
oc apply -f 01-namespace.yaml
oc apply -f 02-ai-agent-deployment.yaml

# Wait for it
oc wait --for=condition=available --timeout=60s \
  deployment/ai-agent -n ai-workload-demo

# Attempt compromised deployment (SHOULD BE BLOCKED)
oc apply -f 03-compromised-agent-deployment.yaml
```

**Expected result:**
```
Error from server: admission webhook "policyeval.stackrox.io" denied the request: 
The deployment violates the following policies:
...
```

---

## 4. Show in UI (30 seconds)

**Navigate:** Violations (left sidebar in RHACS)

You should see:
- Deployment: `ai-agent-compromised`
- Multiple policies violated
- Enforcement: Blocked

---

## Troubleshooting One-Liner

```bash
# If something's wrong, restart admission controllers
oc delete pods -n stackrox -l app=admission-control && sleep 20 && oc get pods -n stackrox
```

---

## That's It!

**For detailed setup:** See `DEMO-SETUP-WALKTHROUGH.md`  
**For presentation tips:** See `PRESENTER-CHEATSHEET.md`  
**For diagrams:** See `DEMO-FLOW-DIAGRAM.md`
