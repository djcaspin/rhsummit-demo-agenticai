# Presenter Cheat Sheet: RHACS Container Escape Demo

**Session:** Zero-Trust AI: Safeguarding Agentic AI Workloads  
**Duration:** 3-4 minutes  
**Cluster:** dc-04-28-riding

---

## Pre-Demo Checklist

- [ ] Connected to cluster: `oc whoami` → cluster-admin
- [ ] RHACS Central accessible: `oc get route central -n stackrox -o jsonpath='{.spec.host}'`
- [ ] RHACS UI open in browser (have it ready in a tab)
- [ ] Policies in ENFORCE mode (check RHACS UI → Policy Management)
- [ ] Terminal ready with demo directory: `cd ~/Projects/claude/team_reporting/demo`
- [ ] Font size increased for audience visibility

---

## Quick Demo Flow (3 min)

### 1. Setup (30 sec)
```bash
# Create namespace
oc apply -f 01-namespace.yaml
```
**Say:** "Setting up isolated namespace for our AI workload..."

---

### 2. Deploy Legitimate Agent (45 sec)
```bash
# Deploy good agent
oc apply -f 02-ai-agent-deployment.yaml
oc get pods -n ai-workload-demo -w
```
**Say:** "Here's a standard AI inference agent—serving predictions, normal operations. RHACS sees this as expected behavior."

---

### 3. Attack Scenario (20 sec)
**Say:** "Now imagine this agent receives a malicious prompt injection. The compromised agent tries to:
- Escalate to root privileges
- Access the host PID namespace  
- Mount the host filesystem
- Escape the container

Let's see what happens..."

---

### 4. Deploy Compromised Agent (60 sec)
```bash
# This should FAIL
oc apply -f 03-compromised-agent-deployment.yaml
```

**Expected Output:**
```
Error from server: admission webhook "policyeval.stackrox.io" denied the request
```

**Say:** "RHACS blocked it instantly! The admission webhook detected multiple violations before the workload could start:
- Privilege escalation attempt ✓ BLOCKED
- Host namespace access ✓ BLOCKED  
- Dangerous capabilities ✓ BLOCKED
- Host filesystem mount ✓ BLOCKED"

---

### 5. Show RHACS Dashboard (45 sec)
Switch to RHACS UI browser tab

**Navigate:** Violations → Latest violation

**Say:** "Here's the complete picture:
- Risk score: CRITICAL
- Policies violated: 4
- Action taken: Deployment blocked
- Full audit trail preserved

This is zero-trust for AI workloads. No manual intervention needed—automated enforcement."

---

### 6. Wrap-up (20 sec)
**Say:** "Key takeaway: We're extending zero-trust principles to autonomous AI agents. Every workload is verified, least-privilege enforced, escape attempts blocked automatically."

---

## Backup Demo (If Primary Fails)

If RHACS doesn't block the deployment:

### Plan B: Show Violations in Dry-Run Mode

```bash
# Get the deployment
oc get deployment ai-agent-compromised -n ai-workload-demo

# Show it in RHACS UI
```

**Say:** "The deployment went through because the policy is in INFORM mode for this demo. In production, you'd set this to ENFORCE. Let me show you what RHACS detected..."

Navigate to Violations in RHACS UI and show:
- The violation details
- Risk assessment
- What WOULD have been blocked

**Recovery:** "In a production environment, this would have been blocked. Let me show you the enforcement configuration..."

---

## Command Quick Reference

### Check RHACS Status
```bash
oc get deployment central -n stackrox
oc get route central -n stackrox -o jsonpath='{.spec.host}'
```

### Check Pods
```bash
oc get pods -n ai-workload-demo
oc get pods -n ai-workload-demo -l app=ai-agent
```

### View Logs
```bash
POD=$(oc get pod -n ai-workload-demo -l app=ai-agent -o jsonpath='{.items[0].metadata.name}')
oc logs $POD -n ai-workload-demo
```

### Cleanup
```bash
oc delete namespace ai-workload-demo
```

### Emergency Reset
```bash
# If something goes wrong, clean up and restart
oc delete namespace ai-workload-demo --force --grace-period=0
# Wait 10 seconds
oc apply -f 01-namespace.yaml
```

---

## Key Talking Points

### Opening
✓ "AI agents are moving from chatbots to autonomous systems"  
✓ "What happens when prompt injection compromises an agent?"  
✓ "RHACS protects against container escape attempts"

### During Demo
✓ "Multiple security layers—defense in depth"  
✓ "Automated enforcement—no human in the loop"  
✓ "Complete audit trail for compliance"

### Technical Points
✓ "Admission webhook blocks at deploy time"  
✓ "Would also scale to zero if runtime detected"  
✓ "Integrates with SPIFFE/SPIRE for identity"

### Business Value
✓ "Protects against Day 0 attacks"  
✓ "Reduces mean time to respond (MTTR)"  
✓ "Meets compliance requirements (SOC2, PCI-DSS, HIPAA)"

---

## Common Questions & Answers

**Q: What if the attack happens at runtime, not deploy time?**  
A: RHACS also monitors runtime behavior. If a process tries privilege escalation at runtime, RHACS detects the anomaly and can kill the pod or isolate it via network policies.

**Q: Can attackers bypass this by using a "good" image first, then modifying at runtime?**  
A: Runtime monitoring catches that. RHACS baselines normal behavior and alerts on deviations like unexpected process execution or network connections.

**Q: How does this integrate with CI/CD?**  
A: RHACS has build-time scanning. It can fail CI builds that violate policies, preventing bad images from ever reaching the registry.

**Q: Performance impact?**  
A: Negligible. Admission webhooks add <100ms to deployment time. Runtime monitoring uses eBPF with <1% CPU overhead.

**Q: What about false positives?**  
A: Policies are tunable. You can scope by namespace, labels, or specific workloads. RHACS learns baselines to reduce noise.

---

## Troubleshooting During Demo

### Terminal frozen
- Have backup terminal window ready
- Have commands pre-typed in notes

### Network lag
- Pre-stage pods before demo
- Have screenshots of expected output ready

### Can't remember command
- This cheat sheet!
- `history | grep oc`

### Audience can't see terminal
- `CMD +` to increase font size
- Switch to full-screen terminal

### RHACS UI won't load
- Have screenshots prepared
- Describe what you would show: "In the violations view, you'd see..."

---

## Time Management

| Section | Target | Buffer |
|---------|--------|--------|
| Setup | 0:30 | Can skip if pre-done |
| Legit deploy | 0:45 | Can speed up with --wait=false |
| Attack intro | 0:20 | Critical - don't skip |
| Attack demo | 1:00 | Core demo - allocate time |
| RHACS UI | 0:45 | Can shorten if running late |
| Wrap-up | 0:20 | Essential - leave time |
| **Total** | **3:40** | |

---

## Success Criteria

✅ Audience understands the attack vector  
✅ Clear demonstration of RHACS blocking attack  
✅ Connection made to presentation (Pillar 3)  
✅ Key takeaway delivered: "Zero-trust for AI workloads"

---

## Post-Demo

- Cleanup namespace: `oc delete namespace ai-workload-demo`
- Offer to share demo files with attendees
- Direct questions to Technology Neighborhood booth
- Mention additional demos available (supply chain, SPIRE integration)

---

**Good luck! You've got this! 🚀**
