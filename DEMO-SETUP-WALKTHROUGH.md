# RHACS Demo Setup Walkthrough
## Complete End-to-End Configuration Guide

**Session:** Zero-Trust AI: Safeguarding Agentic AI Workloads  
**Demo:** Block AI Workload Container Escape Attempt  
**Duration:** 3-4 minutes  

---

## Prerequisites Checklist

✅ **Infrastructure:**
- [x] OpenShift cluster: `dc-04-28-riding`
- [x] RHACS Central: https://dc0429findstudiedturn.demos.rox.systems/login
- [x] Admin credentials: `admin` / `qOUGnbzUDUPjy9LI6t4EAkaUY`
- [x] Sensor deployed and connected
- [x] Admission controller running (3 pods)

✅ **Demo Files Ready:**
```bash
~/Projects/claude/team_reporting/demo/
├── 01-namespace.yaml
├── 02-ai-agent-deployment.yaml
├── 03-compromised-agent-deployment.yaml
├── demo-script.sh
├── README.md
├── PRESENTER-CHEATSHEET.md
├── DEMO-FLOW-DIAGRAM.md
└── RHACS-POLICY-CONFIGURATION.md
```

---

## Part 1: RHACS UI Configuration (15-20 minutes)

### Step 1.1: Access RHACS Central

1. Open browser: https://dc0429findstudiedturn.demos.rox.systems/login
2. Login:
   - Username: `admin`
   - Password: `qOUGnbzUDUPjy9LI6t4EAkaUY`
3. Accept any first-time setup prompts

### Step 1.2: Verify Cluster Health

**Navigate:** Platform Configuration → Clusters

**Verify:**
- Cluster Name: `dc-04-28-riding`
- Status: Green checkmark (HEALTHY)
- Sensor: Connected
- Admission Controller: Enabled

**If not healthy:**
```bash
# Check sensor
oc get pods -n stackrox -l app=sensor
oc logs -n stackrox -l app=sensor --tail=50

# Check admission-control
oc get pods -n stackrox -l app=admission-control
```

### Step 1.3: Configure Policy 1 - Privileged Container

**Navigate:** Platform Configuration → Policy Management

1. **Search box:** Type `privileged`
2. **Find policy:** "Privileged Container"
3. **Click** policy name
4. **Actions** → **Edit policy**
5. **Scroll to:** "Policy Behavior" section
6. **Configure enforcement:**
   - Lifecycle stage: ✅ **Deploy** (should already be checked)
   - Response method:
     - ✅ **Inform**
     - ✅ **Enforce on Deploy** ← **CRITICAL: Enable this**
7. **Save**

**Confirmation:** Policy badge should now show "ENFORCED" in deploy stage

---

### Step 1.4: Configure Policy 2 - Host PID/IPC/Network

**Search:** `host network`

1. **Find:** "Host PID/IPC/Network Namespace" (or similar)
2. **Edit policy**
3. **Policy Behavior:**
   - ✅ **Inform**
   - ✅ **Enforce on Deploy**
4. **Save**

---

### Step 1.5: Configure Policy 3 - Linux Capabilities

**Search:** `capabilities`

1. **Find:** "Dangerous Linux Capabilities" or "Linux Capabilities"
2. **Edit policy**
3. **Verify policy criteria includes:**
   - SYS_ADMIN
   - NET_ADMIN
   - SYS_PTRACE
4. **Policy Behavior:**
   - ✅ **Inform**
   - ✅ **Enforce on Deploy**
5. **Save**

---

### Step 1.6: Configure Policy 4 - Mount Host Path

**Search:** `mount` or `hostpath`

1. **Find:** "Mount Host Path" or "HostPath Volume"
2. **Edit policy**
3. **Policy Behavior:**
   - ✅ **Inform**
   - ✅ **Enforce on Deploy**
4. **Save**

---

### Step 1.7: Verify All Policies

**Navigate:** Platform Configuration → Policy Management

**Filter:** Enforcement: "Enforced"

**Verify these policies show "ENFORCED" badge:**
- ✅ Privileged Container
- ✅ Host PID/IPC/Network Namespace
- ✅ Linux Capabilities (Dangerous)
- ✅ Mount Host Path

---

## Part 2: OpenShift Cluster Configuration (5 minutes)

### Step 2.1: Configure Demo Namespace Permissions

The demo namespace needs permissive SCC so RHACS policies (not OpenShift SCC) are the enforcement layer.

**Already configured:**
```bash
# ServiceAccount with privileged SCC access
oc get rolebinding ai-agent-sa-privileged -n ai-workload-demo

# Should show:
# NAME                      ROLE                       AGE
# ai-agent-sa-privileged    Role/use-privileged-scc    <age>
```

**If missing:**
```bash
cd ~/Projects/claude/team_reporting/demo
oc apply -f /tmp/demo-privileged-scc.yaml
```

### Step 2.2: Verify RHACS Components

```bash
# All should be Running
oc get pods -n stackrox

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# admission-control-XXXXX              1/1     Running   0          <age>
# admission-control-XXXXX              1/1     Running   0          <age>
# admission-control-XXXXX              1/1     Running   0          <age>
# sensor-XXXXX                         1/1     Running   0          <age>
# collector-XXXXX (DaemonSet)          3/3     Running   0          <age>
```

### Step 2.3: Verify Webhook Registration

```bash
oc get validatingwebhookconfiguration stackrox

# Should show:
# NAME        WEBHOOKS   AGE
# stackrox    2          <age>
```

---

## Part 3: Demo Dry Run (5 minutes)

### Step 3.1: Deploy Legitimate AI Agent

```bash
cd ~/Projects/claude/team_reporting/demo

# Clean slate
oc delete namespace ai-workload-demo 2>/dev/null || true
sleep 5

# Create namespace
oc apply -f 01-namespace.yaml

# Deploy legitimate agent
oc apply -f 02-ai-agent-deployment.yaml

# Wait for pod
oc wait --for=condition=available --timeout=60s \
  deployment/ai-agent -n ai-workload-demo

# Verify
oc get pods -n ai-workload-demo
```

**Expected:** `ai-agent-XXXXX` pod shows `1/1 Running`

---

### Step 3.2: Test RHACS Blocking

```bash
# This should be BLOCKED by RHACS
oc apply -f 03-compromised-agent-deployment.yaml
```

**Expected Output (SUCCESS - RHACS BLOCKING):**
```
Error from server: admission webhook "policyeval.stackrox.io" denied the request: 
The deployment violates the following policies:
- Privileged Container
- Host PID/IPC/Network Namespace
- Dangerous Linux Capabilities
- Mount Host Path
```

**If deployment succeeds (NOT BLOCKED):**

❌ **Problem:** RHACS policies not enforcing

**Debug:**
1. Check admission controller logs:
   ```bash
   oc logs -n stackrox -l app=admission-control --tail=100 | grep -i "ai-agent-compromised"
   ```

2. Return to **Part 1** and verify "Enforce on Deploy" is enabled for all policies

3. Check admission controller is receiving settings:
   ```bash
   oc logs -n stackrox -l app=admission-control --tail=50 | grep "settings"
   ```
   
   Should see: "Received and propagated updated admission controller settings"

---

### Step 3.3: View Violations in RHACS UI

1. **Navigate:** Violations (left sidebar)
2. **Should see violations for:**
   - Deployment: `ai-agent-compromised`
   - Namespace: `ai-workload-demo`
   - Multiple policies violated
3. **Click violation** to see:
   - Risk score: CRITICAL
   - Enforcement: Deployment blocked
   - YAML showing the violations
   - Timeline

**If no violations appear:**
- The deployment was blocked BEFORE it reached RHACS
- Check OpenShift events:
  ```bash
  oc get events -n ai-workload-demo --sort-by='.lastTimestamp' | tail -10
  ```

---

## Part 4: Demo Day Preparation

### The Night Before

✅ **Verify access:**
```bash
# Can you login?
open "https://dc0429findstudiedturn.demos.rox.systems/login"

# Cluster access?
oc whoami
# Should show: cluster-admin

# RHACS components?
oc get pods -n stackrox
# All should be Running
```

✅ **Test the demo end-to-end:**
```bash
cd ~/Projects/claude/team_reporting/demo
./demo-script.sh
```

✅ **Check policy enforcement:**
- Login to RHACS UI
- Verify 4 key policies show "ENFORCED"

✅ **Prepare browser tabs:**
- Tab 1: RHACS UI (logged in) - Violations view
- Tab 2: RHACS UI - Network Graph
- Tab 3: Google Slides presentation

---

### 30 Minutes Before Presentation

1. **Clean up any previous runs:**
   ```bash
   oc delete namespace ai-workload-demo 2>/dev/null || true
   ```

2. **Verify RHACS is healthy:**
   ```bash
   oc get pods -n stackrox
   ```
   All should be Running/Ready

3. **Pre-deploy legitimate agent:**
   ```bash
   oc apply -f 01-namespace.yaml
   oc apply -f 02-ai-agent-deployment.yaml
   ```

4. **Open RHACS UI** in browser (stay logged in)

5. **Increase terminal font size:**
   - CMD + (multiple times)
   - Audience should be able to read clearly

6. **Test microphone and screen sharing**

---

## Part 5: Demo Execution (3-4 minutes)

### Script Flow

**Use:** `PRESENTER-CHEATSHEET.md` for detailed talking points

**Quick flow:**

1. **Show legitimate AI agent running (30s)**
   ```bash
   oc get pods -n ai-workload-demo
   ```
   Say: "Normal AI inference agent, serving predictions..."

2. **Explain attack scenario (20s)**
   Say: "Malicious prompt injection compromises the agent. It attempts container escape..."

3. **Attempt compromised deployment (60s)**
   ```bash
   oc apply -f 03-compromised-agent-deployment.yaml
   ```
   
   **RHACS BLOCKS IT:**
   ```
   Error from server: admission webhook "policyeval.stackrox.io" denied the request
   ```
   
   Say: "RHACS detected and blocked multiple violations before the pod could start"

4. **Show RHACS UI (45s)**
   - Switch to browser
   - Navigate to Violations
   - Show violation details
   - Point out: Risk score, policies violated, enforcement action

5. **Wrap up (20s)**
   Say: "Zero-trust for AI workloads. Automated enforcement. Complete audit trail."

---

## Troubleshooting Guide

### Issue: Demo cluster shows "Unhealthy"

**Possible causes:**
- Sensor disconnected
- Admission controller down

**Quick fix:**
```bash
# Restart sensor
oc delete pod -n stackrox -l app=sensor
sleep 15
oc get pods -n stackrox

# Restart admission-control
oc delete pods -n stackrox -l app=admission-control
sleep 15
oc get pods -n stackrox
```

---

### Issue: Compromised deployment not blocked

**Possible causes:**
1. Policies in INFORM mode only
2. Admission controller not running
3. OpenShift SCC blocking before RHACS

**Debug steps:**
```bash
# Check policies
# Login to RHACS UI → Policy Management
# Verify "Enforce on Deploy" is enabled

# Check admission controller
oc get pods -n stackrox -l app=admission-control
# Should show 3/3 Running, 1/1 Ready

# Check webhook
oc get validatingwebhookconfiguration stackrox
# Should exist with 2 webhooks

# Check recent logs
oc logs -n stackrox -l app=admission-control --tail=50
```

**Quick fix:**
```bash
# Re-enable enforcement (manual in UI)
# Or restart admission-control
oc delete pods -n stackrox -l app=admission-control
```

---

### Issue: Can't access RHACS UI

**Possible causes:**
- Demo instance expired
- Network connectivity

**Check:**
```bash
curl -k https://dc0429findstudiedturn.demos.rox.systems/login
# Should return HTML, not error

# Check if instance is still running
# Contact demo provisioner if down
```

**Backup plan:**
- Use screenshots from `DEMO-FLOW-DIAGRAM.md`
- Show policies in diagram form
- Explain what WOULD happen

---

## Backup Demo Plan

**If live demo fails:**

1. **Show presentation slides** with attack diagram
2. **Show RHACS UI screenshots** (take these beforehand):
   - Policy Management page showing ENFORCED policies
   - Violations page with blocked deployment
   - Network Graph showing legitimate AI agent
3. **Explain the flow** using `DEMO-FLOW-DIAGRAM.md`:
   - Step 1: Normal deployment allowed
   - Step 2: Malicious deployment blocked
   - Step 3: Violations logged
4. **Show demo files** to audience:
   ```bash
   # Show the legitimate YAML
   cat 02-ai-agent-deployment.yaml | grep -A 10 "securityContext"
   
   # Show the malicious YAML
   cat 03-compromised-agent-deployment.yaml | grep -A 20 "securityContext"
   ```

---

## Post-Demo Cleanup

```bash
# Delete demo namespace
oc delete namespace ai-workload-demo

# Verify cleanup
oc get namespace ai-workload-demo
# Should show: Error from server (NotFound)

# Leave RHACS running for Q&A
```

---

## Key Demo Files Reference

```bash
# All demo files
ls -lh ~/Projects/claude/team_reporting/demo/

# Quick reference
cat ~/Projects/claude/team_reporting/demo/PRESENTER-CHEATSHEET.md

# Visual diagrams
cat ~/Projects/claude/team_reporting/demo/DEMO-FLOW-DIAGRAM.md

# Policy configuration
cat ~/Projects/claude/team_reporting/demo/RHACS-POLICY-CONFIGURATION.md
```

---

## Contact Information for Help

**Demo Instance Support:**
- Check demo provisioner documentation
- Demo instances typically expire after 4-8 hours

**RHACS Documentation:**
- https://docs.openshift.com/acs/

**Emergency Contacts:**
- [Add your Red Hat contacts here]

---

## Success Criteria

✅ **Demo is ready when:**
- [ ] Can login to RHACS UI
- [ ] Cluster shows HEALTHY
- [ ] 4 policies show "ENFORCED" badge
- [ ] Legitimate AI agent deploys successfully
- [ ] Compromised deployment is BLOCKED with clear error message
- [ ] Violations appear in RHACS UI
- [ ] Terminal font size is readable for audience
- [ ] Browser tabs are prepared
- [ ] Demo runs in under 4 minutes

---

**Last Updated:** 2026-04-29  
**Demo Instance:** dc0429findstudiedturn.demos.rox.systems  
**Cluster:** dc-04-28-riding  
**Ready for:** Red Hat Summit 2026
