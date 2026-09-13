#!/bin/bash
# command: ./cutover_test.sh <alb-dns-name> [duration-seconds] [sleep-seconds]
set -u

ALB_DNS="${1:?Usage: $0 <alb-dns-name> [duration-seconds] [sleep-seconds]}"
DURATION="${2:-120}"
SLEEP="${3:-0.2}"

URL="http://${ALB_DNS}/"
END=$((SECONDS + DURATION))
success=0
fail=0
declare -A version_counts
last_version=""

echo "Hitting $URL for ${DURATION}s ..."
echo "time,http_code,version"

while [ $SECONDS -lt $END ]; do
  ts=$(date +%H:%M:%S)
  code=$(curl -s -o /tmp/cutover_resp.html -w "%{http_code}" --max-time 3 "$URL")

  if [ "$code" == "200" ]; then
    version=$(grep -oE 'version: [A-Za-z0-9.\-]+' /tmp/cutover_resp.html | head -1)
    success=$((success + 1))
    version_counts["$version"]=$(( ${version_counts["$version"]:-0} + 1 ))
    if [ "$version" != "$last_version" ]; then
      echo "$ts,$code,$version   <-- transition"
      last_version="$version"
    fi
  else
    fail=$((fail + 1))
    echo "$ts,$code,REQUEST_FAILED"
  fi

  sleep "$SLEEP"
done

echo ""
echo "======== SUMMARY ========"
echo "Successful requests: $success"
echo "Failed requests:     $fail"
echo "Breakdown by version:"
for k in "${!version_counts[@]}"; do
  echo "  $k => ${version_counts[$k]} requests"
done
