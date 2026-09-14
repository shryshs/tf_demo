#!/bin/bash
# =============================================================================
# Canary rollout: steps through blue/green weight pairs, applying each one via
# Terraform (so state never drifts), then runs the same load-test loop from
# Part 2 to capture the traffic split + error count at that step. Pauses
# between steps so you can eyeball the error rate before continuing.
#
# Usage: ./canary_rollout.sh [test-seconds-per-step] [sleep-between-requests]
# Run this from the envs/root/ folder (where your .tf files + tfvars live).
# =============================================================================
set -euo pipefail

TEST_SECONDS="${1:-30}"
REQ_SLEEP="${2:-0.2}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Each entry: "blue_weight|green_weight|label"
STEPS=(
  "90|10|Step 1 - canary: 10 percent on green"
  "50|50|Step 2 - even split"
  "0|100|Step 3 - full cutover, blue stays warm for rollback"
)

for step in "${STEPS[@]}"; do
  IFS='|' read -r BLUE GREEN LABEL <<< "$step"

  echo ""
  echo "==================================================================="
  echo "$LABEL   (blue=${BLUE}% green=${GREEN}%)"
  echo "==================================================================="

  terraform apply -auto-approve \
    -var="blue_weight=${BLUE}" \
    -var="green_weight=${GREEN}"

  sleep 5

  ALB_DNS=$(terraform output -raw alb_dns_name)

  echo ""
  echo "--- Watching traffic split for ${TEST_SECONDS}s ---"
  "${SCRIPT_DIR}/cutover_test.sh" "$ALB_DNS" "$TEST_SECONDS" "$REQ_SLEEP"

  echo ""
  echo "Check the summary above: split should roughly match ${BLUE}/${GREEN},"
  echo "and 'Fail' should be 0. If it isn't, Ctrl+C now and roll back with:"
  echo "  terraform apply -auto-approve -var=\"blue_weight=100\" -var=\"green_weight=0\""
  read -r -p "Press Enter to continue to the next step... "
done

echo ""
echo "Canary rollout complete: 100% on green, blue is still up for rollback."
