# Demo Flow Diagram

## Visual Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    RHACS Container Escape Demo                   │
│                         (3-4 minutes)                             │
└─────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │   START     │
                              └──────┬──────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  Step 1: Setup Environment     │
                    │  • Create namespace            │
                    │  • Verify RHACS running        │
                    └────────────────┬───────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  Step 2: Deploy Good Agent     │
                    │                                │
                    │  ┌──────────────────┐          │
                    │  │   AI Agent Pod   │          │
                    │  │  ✓ Non-root      │          │
                    │  │  ✓ No host access│          │
                    │  │  ✓ Limited caps  │          │
                    │  └──────────────────┘          │
                    │         Status: RUNNING         │
                    └────────────────┬───────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  Step 3: Attack Scenario       │
                    │  "Prompt injection compromise" │
                    └────────────────┬───────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  Step 4: Deploy Bad Agent      │
                    │                                │
                    │  ┌──────────────────┐          │
                    │  │  Malicious Pod   │          │
                    │  │  ✗ privileged=true│         │
                    │  │  ✗ hostPID=true  │          │
                    │  │  ✗ SYS_ADMIN cap │          │
                    │  │  ✗ hostPath mount│          │
                    │  └──────────────────┘          │
                    └────────────────┬───────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │     RHACS Admission Control    │
                    │                                │
                    │    ╔════════════════════╗      │
                    │    ║  POLICY VIOLATION  ║      │
                    │    ╚════════════════════╝      │
                    │                                │
                    │  ✓ Privilege escalation        │
                    │  ✓ Host namespace access       │
                    │  ✓ Dangerous capabilities      │
                    │  ✓ Host path mount             │
                    │                                │
                    │    ENFORCEMENT: BLOCK 🚫       │
                    └────────────────┬───────────────┘
                                     │
                    ┌────────────────▼───────────────┐
                    │  Step 5: Show RHACS UI         │
                    │  • Violation details           │
                    │  • Risk score (CRITICAL)       │
                    │  • Audit trail                 │
                    │  • Network graph               │
                    └────────────────┬───────────────┘
                                     │
                              ┌──────▼──────┐
                              │   SUCCESS   │
                              │ Attack      │
                              │  Blocked!   │
                              └─────────────┘
```

---

## Attack vs Defense Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Container Escape Attack Vectors                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┬──────────────────┬───────────────────────┐
│   Attack Technique      │   What It Does   │  RHACS Defense        │
├─────────────────────────┼──────────────────┼───────────────────────┤
│ privileged: true        │ Full host access │ ✓ Blocked at admit    │
│                         │ Disable seccomp  │   time                │
├─────────────────────────┼──────────────────┼───────────────────────┤
│ hostPID: true           │ See host procs   │ ✓ Policy violation    │
│                         │ Kill processes   │   triggered           │
├─────────────────────────┼──────────────────┼───────────────────────┤
│ hostNetwork: true       │ Sniff traffic    │ ✓ Admission webhook   │
│                         │ Port hijacking   │   denies              │
├─────────────────────────┼──────────────────┼───────────────────────┤
│ SYS_ADMIN capability    │ Mount filesys    │ ✓ Capability policy   │
│                         │ Load kernel mod  │   enforced            │
├─────────────────────────┼──────────────────┼───────────────────────┤
│ hostPath: /             │ Read host files  │ ✓ Volume mount        │
│                         │ Write to host    │   restriction         │
└─────────────────────────┴──────────────────┴───────────────────────┘
```

---

## RHACS Defense Layers

```
┌──────────────────────────────────────────────────────────────┐
│                  Zero-Trust AI Protection                     │
└──────────────────────────────────────────────────────────────┘

    Layer 3: Runtime Monitoring
    ┌─────────────────────────────────────┐
    │  • Process execution monitoring     │
    │  • Network flow analysis            │
    │  • Behavioral anomaly detection     │
    │  • Auto-remediation (scale to 0)    │
    └─────────────────────────────────────┘
                    ▲
                    │
    Layer 2: Admission Control (Demo Focus)
    ┌─────────────────────────────────────┐
    │  • Policy evaluation at deploy      │
    │  • Webhook blocks violations        │
    │  • Immediate enforcement            │
    │  • Audit log generation             │
    └─────────────────────────────────────┘
                    ▲
                    │
    Layer 1: Build-Time Scanning
    ┌─────────────────────────────────────┐
    │  • Image vulnerability scan         │
    │  • Signature verification           │
    │  • SBOM analysis                    │
    │  • CI/CD integration                │
    └─────────────────────────────────────┘
```

---

## Normal vs Compromised Workload

```
┌───────────────────────────────────────────────────────────────┐
│              Normal AI Agent (ALLOWED)                         │
└───────────────────────────────────────────────────────────────┘

apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true           ✓ Not running as root
      containers:
      - name: ai-agent
        securityContext:
          allowPrivilegeEscalation: false  ✓ Cannot escalate
          capabilities:
            drop: [ALL]              ✓ Minimal capabilities
          readOnlyRootFilesystem: false    ✓ App filesystem only

        Status: ✅ DEPLOYED SUCCESSFULLY


┌───────────────────────────────────────────────────────────────┐
│         Compromised AI Agent (BLOCKED)                         │
└───────────────────────────────────────────────────────────────┘

apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      hostPID: true                  ✗ Access host processes
      hostNetwork: true              ✗ Access host network
      containers:
      - name: compromised-agent
        securityContext:
          privileged: true           ✗ Full host access
          runAsUser: 0               ✗ Running as root
          capabilities:
            add:
              - SYS_ADMIN            ✗ Dangerous capability
              - NET_ADMIN            ✗ Network control
        volumeMounts:
        - name: host-root
          mountPath: /host           ✗ Host filesystem
      volumes:
      - name: host-root
        hostPath:
          path: /                    ✗ Root of host

        Status: 🚫 BLOCKED BY RHACS
```

---

## Timeline of Attack & Defense

```
Time    Event                                    RHACS Action
────────────────────────────────────────────────────────────────
T+0     Legitimate AI agent deployed             ✓ Allowed
        • Normal security context
        • Limited capabilities
        • No host access

T+60    AI agent running normally                ✓ Monitored
        • Serving inference requests
        • Expected network connections
        • Baseline behavior established

T+90    Malicious prompt injection received      ⚠ External event
        • Agent logic compromised
        • Attempts redeployment with
          escalated privileges

T+91    Compromised deployment attempted         🚨 DETECTED
        • Webhook intercepts request
        • Policy evaluation triggered
        • Multiple violations found:
          - privileged=true
          - hostPID=true
          - SYS_ADMIN capability
          - hostPath mount

T+92    Admission webhook denies deployment      ✅ BLOCKED
        • Deployment rejected
        • Violation logged
        • Alert generated
        • Original workload still running

T+93    Security team notified                   📧 Alert sent
        • Violation details
        • Risk assessment
        • Recommended actions

        ────────────────────────────
        Attack contained in <2 seconds
        Zero impact to production
        Full audit trail preserved
```

---

## Policy Enforcement Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Kubernetes API Server                                          │
│                                                                  │
│  oc apply -f compromised-agent.yaml                             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  RHACS Admission Controller (Webhook)                           │
│                                                                  │
│  1. Receive deployment request                                  │
│  2. Extract security context                                    │
│  3. Evaluate against policies:                                  │
│     ┌──────────────────────────────────────┐                   │
│     │ Policy: Privileged Container         │                   │
│     │ Condition: privileged == true        │                   │
│     │ Result: ✗ VIOLATED                   │                   │
│     └──────────────────────────────────────┘                   │
│     ┌──────────────────────────────────────┐                   │
│     │ Policy: Host Namespace Access        │                   │
│     │ Condition: hostPID == true           │                   │
│     │ Result: ✗ VIOLATED                   │                   │
│     └──────────────────────────────────────┘                   │
│     ┌──────────────────────────────────────┐                   │
│     │ Policy: Dangerous Capabilities       │                   │
│     │ Condition: SYS_ADMIN in caps.add     │                   │
│     │ Result: ✗ VIOLATED                   │                   │
│     └──────────────────────────────────────┘                   │
│                                                                  │
│  4. Enforcement decision: DENY                                  │
│  5. Log violation to Central                                    │
│  6. Return error to API server                                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Response to User                                                │
│                                                                  │
│  Error from server: admission webhook "policyeval.stackrox.io"  │
│  denied the request: The deployment violates 3 policies         │
│                                                                  │
│  Status: DEPLOYMENT BLOCKED                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Demo Success Indicators

```
✅ Checklist for Successful Demo
┌─────────────────────────────────────────────────────┐
│ □ Legitimate AI agent deploys without issue         │
│ □ Agent is accessible (curl test succeeds)          │
│ □ Compromised deployment is BLOCKED                 │
│ □ Error message clearly shows policy violation      │
│ □ RHACS UI shows violation details                  │
│ □ Audience can see terminal output clearly          │
│ □ Demo completes in 3-4 minutes                     │
│ □ Key message delivered: "Zero-trust for AI"        │
└─────────────────────────────────────────────────────┘
```

---

## Reference: Key RHACS Concepts

```
┌──────────────────────────────────────────────────────────────┐
│ Concept              │ Description                           │
├──────────────────────┼───────────────────────────────────────┤
│ Admission Control    │ Evaluate deployments before creation │
│                      │ Webhook intercepts API requests       │
├──────────────────────┼───────────────────────────────────────┤
│ Policy               │ Security rule with conditions         │
│                      │ Can INFORM or ENFORCE                 │
├──────────────────────┼───────────────────────────────────────┤
│ Violation            │ Policy breach detection               │
│                      │ Logged with full context              │
├──────────────────────┼───────────────────────────────────────┤
│ Enforcement Action   │ Response to violation:                │
│                      │ • Fail deployment                     │
│                      │ • Scale to zero                       │
│                      │ • Alert only                          │
├──────────────────────┼───────────────────────────────────────┤
│ Network Graph        │ Visual map of pod communication       │
│                      │ Shows allowed vs blocked flows        │
└──────────────────────┴───────────────────────────────────────┘
```
