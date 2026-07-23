#!/bin/bash
# Convenience wrapper to setup test lake mounting
# This can be sourced or called directly

ensure_test_lake_mounted() {
  if mount | grep -q "/mnt/test_lake/pilot_tre"; then
    echo "✓ Test lake is already mounted"
    return 0
  fi
  
  echo "🔗 Mounting test lake..."
  if [ -x "/workspaces/ahriTRErRs/scripts/mount_test_lake.sh" ]; then
    sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
    return $?
  else
    echo "✗ Mount script not found or not executable"
    echo "   Run: chmod +x /workspaces/ahriTRErRs/scripts/mount_test_lake.sh"
    return 1
  fi
}

# If sourced, this function is available
# If called directly, run it
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  ensure_test_lake_mounted
fi
