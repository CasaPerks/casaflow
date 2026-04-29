#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
failures=0
total=0
for test in test-*.sh; do
  [ -e "$test" ] || continue
  total=$((total + 1))
  printf "RUN  %s ... " "$test"
  if bash "$test" > /tmp/casaflow-test-$$.log 2>&1; then
    echo "PASS"
  else
    echo "FAIL"
    sed 's/^/    /' /tmp/casaflow-test-$$.log
    failures=$((failures + 1))
  fi
  rm -f /tmp/casaflow-test-$$.log
done
echo
echo "Tests: $total  Failures: $failures"
[ "$failures" -eq 0 ]
