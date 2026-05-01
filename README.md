# RHACS Demo: Block AI Workload Escape Attempt

**Duration:** 3-4 minutes  
**Cluster:** `api.dc-04-28-riding.8d4w.p1.openshiftapps.com:6443`  
**RHACS Central:** https://dc0429findstudiedturn.demos.rox.systems/login  
**Admin Password:** `qOUGnbzUDUPjy9LI6t4EAkaUY`  
**Demo Type:** Live detection and blocking of container escape attempts

---

## 🚀 Quick Start

**New to this demo? Start here:**

1. **[QUICK-START.md](QUICK-START.md)** - 5-minute setup guide
2. **[DEMO-SETUP-WALKTHROUGH.md](DEMO-SETUP-WALKTHROUGH.md)** - Complete configuration
3. **[PRESENTER-CHEATSHEET.md](PRESENTER-CHEATSHEET.md)** - Presentation day guide

**RHACS Central UI:** https://dc0429findstudiedturn.demos.rox.systems/login (admin / qOUGnbzUDUPjy9LI6t4EAkaUY)

---

## Overview

This demo shows how **Red Hat Advanced Cluster Security (RHACS)** detects and blocks a compromised AI agent attempting container escape through privilege escalation.

### Attack Scenario

An AI agent receives a malicious prompt injection that causes it to attempt:
- Privilege escalation to root
- Access to host PID namespace
- Mounting host filesystem
- Adding dangerous Linux capabilities (SYS_ADMIN, NET_ADMIN, SYS_PTRACE)

### RHACS Response

RHACS detects and blocks the escape attempt using:
- Admission control policies
- Runtime behavioral monitoring
- Policy enforcement at deployment time
- Automated remediation (scale to zero)

---

## Prerequisites

### 1. Cluster Access
Ensure you're connected to the OpenShift cluster:
```bash
oc whoami
# Should return: cluster-admin
```

### 2. RHACS Installation
Verify RHACS is installed and running:
```bash
oc get deployment central -n stackrox
oc get deployment sensor -n stackrox
```

If RHACS is not installed, install it via Operator Hub:
```bash
# Install RHACS Operator
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhacs-operator
  namespace: rhacs-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: rhacs-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

### 3. RHACS Policies Configuration

**Option A: Use RHACS UI (Recommended for Demo)**

1. Access RHACS Central:
   ```bash
   oc get route central -n stackrox -o jsonpath='{.spec.host}'
   ```

2. Navigate to **Platform Configuration → Policy Management**

3. Enable and enforce these policies:
   - **"Privileged Container"** → Set to ENFORCE
   - **"HostPath Mount"** → Set to ENFORCE
   - **"Host PID/IPC/Network Namespace"** → Set to ENFORCE
   - **"Linux Capabilities"** → Set to ENFORCE (block SYS_ADMIN, NET_ADMIN, SYS_PTRACE)

4. Create a new Policy (optional - for AI-specific branding):
   - Name: "AI Workload - Container Escape Protection"
   - Scope: namespace=`ai-workload-demo`
   - Lifecycle: Deploy-time
   - Policy Criteria:
     - Privileged = true
     - Host PID = true
     - Host Network = true
     - Capabilities: SYS_ADMIN, NET_ADMIN, SYS_PTRACE
   - Enforcement: **Fail deployment, Scale to zero**

**Option B: Apply Policies via CLI (Advanced)**

The policies are defined in `04-rhacs-policies.yaml` but RHACS policies are typically managed via the API or UI. For this demo, use the UI method above.

---

## Demo Files

```
demo/
├── 01-namespace.yaml                    # Creates demo namespace and SA
├── 02-ai-agent-deployment.yaml          # Legitimate AI agent workload
├── 03-compromised-agent-deployment.yaml # Malicious workload (will be blocked)
├── 04-rhacs-policies.yaml              # RHACS policy definitions (reference)
├── demo-script.sh                       # Automated demo script
└── README.md                            # This file
```

---

## Running the Demo

### Automated Demo (Recommended)

```bash
cd demo
chmod +x demo-script.sh
./demo-script.sh
```

The script will:
1. Create the demo namespace
2. Deploy legitimate AI agent
3. Attempt to deploy compromised agent
4. Show RHACS blocking the attack
5. Display violation details
6. Offer cleanup

### Manual Demo Steps

#### Step 1: Setup Environment

```bash
# Create namespace
oc apply -f 01-namespace.yaml

# Verify namespace created
oc get namespace ai-workload-demo
```

#### Step 2: Deploy Legitimate AI Agent

```bash
# Deploy the AI agent
oc apply -f 02-ai-agent-deployment.yaml

# Wait for deployment
oc wait --for=condition=available --timeout=60s \
  deployment/ai-agent -n ai-workload-demo

# Verify it's running
oc get pods -n ai-workload-demo

# Test the agent
POD=$(oc get pod -n ai-workload-demo -l app=ai-agent -o jsonpath='{.items[0].metadata.name}')
oc exec $POD -n ai-workload-demo -- curl -s http://localhost:8080
```

**Expected Output:**
```json
{"status": "AI Agent Running", "mode": "inference"}
```

#### Step 3: Show the Attack

**Presenter Script:**
> "Now, imagine this AI agent receives a malicious prompt injection. The compromised agent attempts to escape its container by escalating privileges and accessing the host system. Let's see what happens..."

#### Step 4: Attempt Compromised Deployment

```bash
# Try to deploy compromised agent
oc apply -f 03-compromised-agent-deployment.yaml
```

**Expected Result (if RHACS is enforcing):**
```
Error from server: admission webhook "policyeval.stackrox.io" denied the request: 
The deployment violates the following policies:
- AI Workload - Container Escape Protection
- Privileged Container
- Host PID/IPC/Network Namespace
```

**Presenter Script:**
> "RHACS detected and blocked the escape attempt before it could execute! The admission webhook prevented the malicious deployment from ever starting."

#### Step 5: Show RHACS Dashboard

1. Get RHACS URL:
   ```bash
   oc get route central -n stackrox -o jsonpath='{.spec.host}'
   ```

2. Navigate to **Violations** view

3. Show the violation details:
   - Violated policies
   - Deployment details
   - Risk score
   - Enforcement action taken

4. Navigate to **Network Graph** (optional):
   - Show legitimate AI agent connections
   - Show isolation of blocked workload

#### Step 6: Explain the Policies

**Key points to highlight:**

1. **Defense in Depth:**
   - Multiple policies caught different aspects of the attack
   - Privilege escalation, host access, capabilities, volume mounts

2. **Zero-Trust Enforcement:**
   - Never trust, always verify
   - Even "internal" workloads are restricted

3. **Automated Response:**
   - No manual intervention needed
   - Instant blocking at admission time
   - Would also scale to zero if deployed

4. **Compliance & Audit:**
   - Complete audit trail
   - Violation records preserved
   - Meets regulatory requirements

---

## Troubleshooting

### Issue: RHACS allows the malicious deployment

**Cause:** Policies not in enforcement mode

**Fix:**
1. Access RHACS Central UI
2. Go to Platform Configuration → Policy Management
3. Find the violated policies
4. Click each policy → Edit
5. Under "Response Method" enable **"Inform and enforce"**
6. Save changes
7. Re-run the demo

### Issue: Can't access RHACS Central

**Cause:** Route not exposed

**Fix:**
```bash
# Check if route exists
oc get route central -n stackrox

# If not, create it
oc create route passthrough central \
  --service=central -n stackrox
```

### Issue: Deployment succeeds but doesn't block

**Cause:** Admission controller webhook not configured

**Fix:**
```bash
# Verify admission controller
oc get validatingwebhookconfiguration | grep stackrox

# Restart sensor
oc rollout restart deployment/sensor -n stackrox
```

---

## Demo Talking Points

### Opening (30 seconds)
> "Today we're seeing AI agents moving from simple chatbots to autonomous systems that interact with critical infrastructure. But what happens when an AI agent gets compromised through prompt injection? Let me show you how RHACS protects against container escape attempts."

### During Legitimate Deployment (30 seconds)
> "Here's a standard AI inference agent running in our cluster. It's serving predictions, talking to APIs—normal operations. RHACS sees this as expected behavior."

### Before Attack (20 seconds)
> "But now, imagine a malicious prompt tricks this agent into attempting privilege escalation. It tries to break out of its container and access the host system."

### During Block (45 seconds)
> "Watch what happens... RHACS immediately blocks the deployment. It detected multiple violations: privilege escalation, host namespace access, dangerous capabilities. The admission webhook prevented this compromised workload from ever starting. No manual intervention, instant protection."

### Wrap-up (45 seconds)
> "This is zero-trust in action for AI workloads. We verify every deployment, enforce least-privilege, and automatically block escape attempts. The entire event is logged for compliance. This is how we protect autonomous AI in production."

---

## Cleanup

```bash
# Delete demo namespace
oc delete namespace ai-workload-demo

# Verify cleanup
oc get namespace ai-workload-demo
# Should return: Error from server (NotFound)
```

---

## Next Steps

After the demo, suggest:

1. **Expand to Runtime Protection:**
   - Show process monitoring
   - Network flow visualization
   - Anomaly detection

2. **Supply Chain Security:**
   - Image signature verification
   - Vulnerability scanning
   - SBOM analysis

3. **Integration with SPIFFE/SPIRE:**
   - Workload identity verification
   - mTLS between agents and APIs

4. **MCP Gateway Security:**
   - Tool authorization
   - Guardrails for prompt injection
   - Audit logging

---

## Additional Resources

- **RHACS Documentation:** https://docs.openshift.com/acs/
- **Policy Examples:** https://github.com/stackrox/contributions
- **MITRE ATT&CK for Containers:** https://attack.mitre.org/matrices/enterprise/containers/
- **Summit Session Deck:** `1XOaviEHtGiQXsUUbjnPIPafdz5mF7zeGq722VcKw_Ac`

---

## Support

For issues or questions:
- RHACS Support: https://access.redhat.com/products/red-hat-advanced-cluster-security-for-kubernetes
- Community: https://www.redhat.com/en/technologies/cloud-computing/openshift/advanced-cluster-security-kubernetes
