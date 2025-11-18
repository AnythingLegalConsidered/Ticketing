#!/usr/bin/env bash
set -euo pipefail
# usage: wait-for.sh host:port timeout
target=${1:-}
timeout=${2:-60}
if [ -z "$target" ]; then
  echo "Usage: $0 host:port [timeout]" >&2
  exit 2
fi
host=${target%%:*}
port=${target##*:}
end=$((SECONDS + timeout))
while [ $SECONDS -lt $end ]; do
  if (echo >/dev/tcp/$host/$port) >/dev/null 2>&1; then
    echo "ok"
    exit 0
  fi
  sleep 1
done
echo "timeout" >&2
exit 1
