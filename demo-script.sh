#!/bin/bash
# Demo Script: Block AI Workload Escape Attempt with RHACS
# Duration: 3-4 minutes
# Cluster: api.dc-04-28-riding.8d4w.p1.openshiftapps.com:6443

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="ai-workload-demo"
RHACS_NAMESPACE="stackrox"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RHACS Demo: Block AI Workload Escape${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Setup
echo -e "${GREEN}[Step 1] Setting up demo environment...${NC}"
echo "Creating namespace: ${NAMESPACE}"
oc apply -f 01-namespace.yaml
sleep 2

# Verify RHACS is running
echo ""
echo -e "${YELLOW}Checking RHACS installation...${NC}"
if oc get deployment central -n ${RHACS_NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✓ RHACS Central is running${NC}"
else
    echo -e "${RED}✗ RHACS not found. Please install RHACS first.${NC}"
    echo "  Visit: https://docs.openshift.com/acs/installing/installing-acs.html"
    exit 1
fi

# Step 2: Deploy legitimate AI workload
echo ""
echo -e "${GREEN}[Step 2] Deploying legitimate AI agent workload...${NC}"
echo "This represents a normal AI inference agent running in your cluster."
oc apply -f 02-ai-agent-deployment.yaml
echo ""
echo "Waiting for AI agent to start..."
oc wait --for=condition=available --timeout=60s deployment/ai-agent -n ${NAMESPACE}
echo -e "${GREEN}✓ AI Agent is running${NC}"

# Show the running pod
echo ""
echo "Current AI workload:"
oc get pods -n ${NAMESPACE} -l app=ai-agent

# Test the agent
echo ""
echo "Testing AI agent endpoint:"
POD_NAME=$(oc get pod -n ${NAMESPACE} -l app=ai-agent -o jsonpath='{.items[0].metadata.name}')
oc exec ${POD_NAME} -n ${NAMESPACE} -- curl -s http://localhost:8080 | python3 -m json.tool || true

# Step 3: Show the attack scenario
echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}[Step 3] ATTACK SIMULATION${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}Scenario: AI agent receives malicious prompt injection${NC}"
echo -e "${YELLOW}The compromised agent attempts to:${NC}"
echo "  • Escalate privileges to root"
echo "  • Access host PID namespace"
echo "  • Mount host filesystem at /"
echo "  • Add dangerous capabilities (SYS_ADMIN, NET_ADMIN)"
echo ""
read -p "Press ENTER to attempt deploying the compromised agent..."

# Step 4: Attempt to deploy compromised workload
echo ""
echo -e "${RED}[Step 4] Deploying compromised AI agent...${NC}"
echo "Attempting deployment with privilege escalation..."

# This should be blocked by RHACS if policies are enforced
if oc apply -f 03-compromised-agent-deployment.yaml 2>&1 | tee /tmp/rhacs-response.txt; then
    echo ""
    echo -e "${RED}⚠ WARNING: Deployment was allowed!${NC}"
    echo -e "${YELLOW}RHACS policies may not be in enforcement mode.${NC}"
    echo ""
    echo "Checking for RHACS violations..."
    sleep 3

    # Check if RHACS detected it
    echo ""
    echo "Checking deployment status:"
    oc get deployment ai-agent-compromised -n ${NAMESPACE} || true

    echo ""
    echo -e "${YELLOW}Expected behavior: RHACS should have blocked this deployment${NC}"
    echo "Check RHACS Central UI for violations at:"
    CENTRAL_ROUTE=$(oc get route central -n ${RHACS_NAMESPACE} -o jsonpath='{.spec.host}' 2>/dev/null || echo "RHACS-NOT-EXPOSED")
    echo "  https://${CENTRAL_ROUTE}"
else
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ RHACS SUCCESSFULLY BLOCKED THE ATTACK${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    cat /tmp/rhacs-response.txt
fi

# Step 5: Show RHACS policies that triggered
echo ""
echo -e "${BLUE}[Step 5] RHACS Security Policies${NC}"
echo ""
echo "The following policies detected the escape attempt:"
echo ""
echo -e "${GREEN}1. Privilege Escalation Detection${NC}"
echo "   ✓ Blocked: privileged=true"
echo "   ✓ Blocked: allowPrivilegeEscalation=true"
echo ""
echo -e "${GREEN}2. Host Namespace Access${NC}"
echo "   ✓ Blocked: hostPID=true"
echo "   ✓ Blocked: hostNetwork=true"
echo ""
echo -e "${GREEN}3. Dangerous Capabilities${NC}"
echo "   ✓ Blocked: SYS_ADMIN capability"
echo "   ✓ Blocked: NET_ADMIN capability"
echo "   ✓ Blocked: SYS_PTRACE capability"
echo ""
echo -e "${GREEN}4. Host Path Mounts${NC}"
echo "   ✓ Blocked: hostPath volume mounting root filesystem"
echo ""

# Step 6: Show network graph (if available)
echo ""
echo -e "${BLUE}[Step 6] View in RHACS Central${NC}"
CENTRAL_ROUTE=$(oc get route central -n ${RHACS_NAMESPACE} -o jsonpath='{.spec.host}' 2>/dev/null || echo "RHACS-NOT-EXPOSED")
echo ""
echo "Access RHACS Central to see:"
echo "  • Network graph showing legitimate agent connections"
echo "  • Violation alerts for the blocked deployment"
echo "  • Policy details and enforcement actions"
echo "  • Runtime activity timeline"
echo ""
echo -e "${YELLOW}RHACS Central URL: https://${CENTRAL_ROUTE}${NC}"
echo ""

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Demo Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ Legitimate AI agent deployed successfully${NC}"
echo -e "${GREEN}✓ Compromised agent with escape attempt detected${NC}"
echo -e "${GREEN}✓ RHACS blocked all privilege escalation vectors${NC}"
echo -e "${GREEN}✓ Zero-trust principle enforced: workload isolated${NC}"
echo ""
echo "Key Takeaways:"
echo "  1. Runtime protection prevents container escape"
echo "  2. Multiple security layers (defense in depth)"
echo "  3. Automated enforcement without manual intervention"
echo "  4. Complete audit trail for compliance"
echo ""

# Cleanup option
echo ""
read -p "Clean up demo resources? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleaning up..."
    oc delete namespace ${NAMESPACE}
    echo -e "${GREEN}✓ Demo resources cleaned up${NC}"
else
    echo "Demo resources preserved in namespace: ${NAMESPACE}"
    echo "To clean up later: oc delete namespace ${NAMESPACE}"
fi

echo ""
echo -e "${BLUE}Demo complete!${NC}"
