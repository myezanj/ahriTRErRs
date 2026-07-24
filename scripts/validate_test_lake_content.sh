#!/bin/bash
# Validate expected content exists in mounted test lake path.

set -euo pipefail

MOUNT_POINT="${1:-/mnt/test_lake/pilot_tre}"

EXPECTED_PATHS=(
  "study_019e39f6_24e3_74fa_88e1_41e6c62fe539"
  "study_019ebd22_a12b_727c_9e64_dad1c3b5af89"
  "__tre_duckdb_stage"
  "study_019e3fde_a71e_7ee3_9f0d_180879bfb42e"
  "study_019e3fe4_eabf_7ebf_a931_972ffa8d38a3"
)

echo "🔎 Validating test lake content at: $MOUNT_POINT"

if [ ! -d "$MOUNT_POINT" ]; then
  echo "✗ Mount path does not exist: $MOUNT_POINT"
  exit 1
fi

missing=0
for path in "${EXPECTED_PATHS[@]}"; do
  if [ -d "$MOUNT_POINT/$path" ]; then
    echo "✓ Found: $path"
  else
    echo "✗ Missing: $path"
    missing=1
  fi
done

if [ $missing -ne 0 ]; then
  echo ""
  echo "✗ Validation failed: one or more required paths are missing"
  echo "  Current directory contents:"
  ls -la "$MOUNT_POINT"
  exit 2
fi

echo ""
echo "✅ Validation passed: all required test lake paths are present"
