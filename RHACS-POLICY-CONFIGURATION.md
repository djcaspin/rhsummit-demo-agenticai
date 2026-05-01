# RHACS Policy Configuration Guide

**Demo Instance:** https://dc0429findstudiedturn.demos.rox.systems/login  
**Admin Password:** `qOUGnbzUDUPjy9LI6t4EAkaUY`  
**Cluster:** dc-04-28-riding

---

## Quick Access

```bash
# RHACS Central URL
https://dc0429findstudiedturn.demos.rox.systems/login

# Login credentials
Username: admin
Password: qOUGnbzUDUPjy9LI6t4EAkaUY
```

---

## Step 1: Access RHACS Central UI

1. Open browser and navigate to: https://dc0429findstudiedturn.demos.rox.systems/login
2. Enter credentials:
   - **Username:** `admin`
   - **Password:** `qOUGnbzUDUPjy9LI6t4EAkaUY`
3. Click **Log in**

---

## Step 2: Verify Cluster Connection

1. Navigate to **Platform Configuration → Clusters**
2. Verify cluster **dc-04-28-riding** shows:
   - Status: **HEALTHY** (green checkmark)
   - Sensor Status: **Connected**
   - Admission Controller: **Enabled**

If not healthy, troubleshoot:
```bash
# Check sensor pod
oc get pods -n stackrox -l app=sensor

# Check admission-control pods
oc get pods -n stackrox -l app=admission-control

# Check sensor logs
oc logs -n stackrox -l app=sensor --tail=50
```

---

## Step 3: Configure Policies for Demo

### Required Policies to Enable (ENFORCE Mode)

Navigate to **Platform Configuration → Policy Management**

#### Policy 1: Privileged Container
- **Search:** Type "privileged" in the search box
- **Find:** "Privileged Container"
- **Click:** Policy name to open details
- **Edit:** Click **Actions → Edit**
- **Enable Enforcement:**
  - Scroll to **Policy Behavior** section
  - Toggle **Inform and enforce** (enforcement at Deploy time)
  - Under **Response method:**
    - ✅ **Inform**
    - ✅ **Enforce on Deploy**
- **Save:** Click **Save**

**What it blocks:**
```yaml
securityContext:
  privileged: true  # ❌ BLOCKED
```

---

#### Policy 2: Host Network
- **Search:** "host network"
- **Find:** "Host Network" policy
- **Enable Enforcement:**
  - Inform and enforce
  - Enforce on Deploy
- **Save**

**What it blocks:**
```yaml
spec:
  hostNetwork: true  # ❌ BLOCKED
```

---

#### Policy 3: Host PID/IPC Namespace
- **Search:** "host pid" or "host namespace"
- **Find:** "Host PID/IPC/Network Namespace" policy
- **Enable Enforcement:**
  - Inform and enforce
  - Enforce on Deploy
- **Save**

**What it blocks:**
```yaml
spec:
  hostPID: true      # ❌ BLOCKED
  hostIPC: true      # ❌ BLOCKED
  hostNetwork: true  # ❌ BLOCKED
```

---

#### Policy 4: Linux Capabilities (Dangerous)
- **Search:** "capabilities"
- **Find:** "Dangerous Linux Capabilities"
- **Enable Enforcement:**
  - Inform and enforce
  - Enforce on Deploy
- **Save**

**What it blocks:**
```yaml
securityContext:
  capabilities:
    add:
      - SYS_ADMIN   # ❌ BLOCKED
      - NET_ADMIN   # ❌ BLOCKED
      - SYS_PTRACE  # ❌ BLOCKED
```

---

#### Policy 5: Mount Host Path
- **Search:** "mount" or "hostpath"
- **Find:** "Mount Host Path" or "HostPath Volume Mount"
- **Enable Enforcement:**
  - Inform and enforce
  - Enforce on Deploy
- **Save**

**What it blocks:**
```yaml
volumes:
  - name: host-root
    hostPath:
      path: /  # ❌ BLOCKED
```

---

## Step 4: Alternative - Create Custom AI Workload Policy

For a demo-specific policy:

1. Navigate to **Platform Configuration → Policy Management**
2. Click **Create Policy** (top right)
3. **Policy Details:**
   - **Name:** "AI Workload - Container Escape Protection"
   - **Severity:** Critical
   - **Categories:** Select:
     - Privilege Escalation
     - Container Escape
   - **Description:**
     ```
     Detects and blocks AI workloads attempting container escape through 
     privilege escalation, host namespace access, or dangerous capabilities.
     ```

4. **Policy Behavior:**
   - **Lifecycle stages:** Deploy
   - **Response method:** 
     - ✅ Inform
     - ✅ Enforce on Deploy
   - **Enable enforcement:** ✅ ON

5. **Policy Criteria:**
   
   Click **Add policy section** → **Add policy field**
   
   Add these criteria (use OR logic):
   
   - **Privileged Container** = `true`
   - **Host PID** = `true`
   - **Host Network** = `true`
   - **Host IPC** = `true`
   - **Add Capabilities** contains `SYS_ADMIN`
   - **Add Capabilities** contains `NET_ADMIN`
   - **Add Capabilities** contains `SYS_PTRACE`
   - **Volume Type** = `HostPath`

6. **Policy Scope (Optional - for demo only):**
   - Click **Add scope**
   - **Namespace:** `ai-workload-demo`
   - This limits policy to only the demo namespace

7. **Save Policy**

---

## Step 5: Verify Policy Enforcement

### Test from CLI

```bash
# Attempt to deploy compromised workload
cd ~/Projects/claude/team_reporting/demo
oc delete deployment ai-agent-compromised -n ai-workload-demo 2>/dev/null || true
oc apply -f 03-compromised-agent-deployment.yaml
```

**Expected Output (RHACS BLOCKING):**
```
Error from server: admission webhook "policyeval.stackrox.io" denied the request: 
The deployment violates the following policies:
- Privileged Container
- Host PID/IPC/Network Namespace  
- Dangerous Linux Capabilities
- Mount Host Path
```

**If deployment succeeds:**
- Policies are still in INFORM mode only
- Return to Step 3 and verify "Enforce on Deploy" is enabled
- Check admission controller logs:
  ```bash
  oc logs -n stackrox -l app=admission-control --tail=100
  ```

---

## Step 6: View Violations in RHACS UI

After attempting the compromised deployment:

1. Navigate to **Violations** (left sidebar)
2. You should see violations for:
   - Policy: "Privileged Container"
   - Policy: "Host PID/IPC/Network Namespace"
   - Policy: "Dangerous Linux Capabilities"
   - Deployment: `ai-agent-compromised`
   - Namespace: `ai-workload-demo`
   - Cluster: `dc-04-28-riding`

3. Click on a violation to see:
   - **Violation Details**
   - **Deployment YAML** showing the violations
   - **Enforcement Action:** Deployment blocked
   - **Risk Score:** CRITICAL
   - **Timeline** of the violation

---

## Step 7: Explore Network Graph (Optional)

1. Navigate to **Network Graph** (left sidebar)
2. **Filter by namespace:** `ai-workload-demo`
3. You should see:
   - ✅ `ai-agent` (legitimate workload) - Running
   - ❌ `ai-agent-compromised` - Blocked/Not present
   - Network connections from `ai-agent`

---

## Policy Summary Table

| Policy Name | What It Blocks | Demo Attack Vector |
|-------------|----------------|-------------------|
| **Privileged Container** | `privileged: true` | Full host access |
| **Host Network** | `hostNetwork: true` | Network sniffing |
| **Host PID** | `hostPID: true` | See/kill host processes |
| **Host IPC** | `hostIPC: true` | Shared memory access |
| **Dangerous Capabilities** | SYS_ADMIN, NET_ADMIN, SYS_PTRACE | Kernel operations |
| **Mount Host Path** | `hostPath: /` | File system escape |

---

## Troubleshooting

### Issue: Policies show violations but don't block

**Cause:** Policy enforcement is OFF or set to INFORM only

**Fix:**
1. Go to Policy Management
2. Find the policy
3. Edit → Policy Behavior
4. Enable "Inform and enforce"
5. Check "Enforce on Deploy"
6. Save

---

### Issue: Admission controller not evaluating deployments

**Cause:** Admission controller pods not running or not connected to sensor

**Fix:**
```bash
# Check admission controller status
oc get pods -n stackrox -l app=admission-control

# Should see 3/3 Running, 1/1 Ready
# If not:
oc delete pods -n stackrox -l app=admission-control

# Wait for recreation
sleep 20
oc get pods -n stackrox -l app=admission-control
```

---

### Issue: Webhook not registered

**Check:**
```bash
oc get validatingwebhookconfiguration stackrox
```

**Should show:**
```
NAME        WEBHOOKS   AGE
stackrox    2          <age>
```

**Fix if missing:**
```bash
# Restart sensor
oc delete pod -n stackrox -l app=sensor
```

---

### Issue: Sensor not connecting to Central

**Check sensor logs:**
```bash
oc logs -n stackrox -l app=sensor --tail=50
```

**Look for:**
- ✅ "Connected to Central"
- ❌ "Failed to connect" or "TLS handshake failed"

**Fix:**
```bash
# Verify secrets exist
oc get secret tls-cert-sensor -n stackrox
oc get secret sensor-tls -n stackrox

# If missing, regenerate init bundle (see main README.md)
```

---

## Demo Day Checklist

**Before the presentation:**

- [ ] Access RHACS UI: https://dc0429findstudiedturn.demos.rox.systems/login
- [ ] Verify cluster shows HEALTHY
- [ ] Verify 5 key policies are in ENFORCE mode
- [ ] Delete any existing compromised deployment:
  ```bash
  oc delete deployment ai-agent-compromised -n ai-workload-demo
  ```
- [ ] Verify legitimate AI agent is running:
  ```bash
  oc get pods -n ai-workload-demo -l app=ai-agent
  ```
- [ ] Have RHACS UI open in browser tab (logged in)
- [ ] Have demo script ready: `~/Projects/claude/team_reporting/demo/demo-script.sh`

**During demo:**

1. Show legitimate AI agent running
2. Explain the attack scenario
3. Attempt compromised deployment → **BLOCKED**
4. Switch to RHACS UI
5. Show violations and policy details
6. Show network graph

---

## Quick Commands Reference

```bash
# Access RHACS Central URL
echo "https://dc0429findstudiedturn.demos.rox.systems/login"

# Show admin password
echo "qOUGnbzUDUPjy9LI6t4EAkaUY"

# Check all RHACS pods
oc get pods -n stackrox

# Run automated demo
cd ~/Projects/claude/team_reporting/demo
./demo-script.sh

# Manual demo steps
oc apply -f 01-namespace.yaml
oc apply -f 02-ai-agent-deployment.yaml
oc apply -f 03-compromised-agent-deployment.yaml  # Should be BLOCKED

# View violations via CLI (if roxctl configured)
roxctl -e dc0429findstudiedturn.demos.rox.systems:443 \
  -p qOUGnbzUDUPjy9LI6t4EAkaUY \
  central whoami

# Cleanup
oc delete namespace ai-workload-demo
```

---

## Additional Resources

- **RHACS Documentation:** https://docs.openshift.com/acs/
- **Policy Examples:** https://github.com/stackrox/contributions/tree/main/policies
- **Demo Repository:** `~/Projects/claude/team_reporting/demo/`
- **Presentation Deck:** https://docs.google.com/presentation/d/1XOaviEHtGiQXsUUbjnPIPafdz5mF7zeGq722VcKw_Ac/

---

**Last Updated:** 2026-04-29  
**Demo Instance Expires:** Check with demo provisioner
