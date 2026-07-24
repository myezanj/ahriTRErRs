#!/bin/bash
# Convenience wrapper to setup test lake mounting
# This can be sourced or called directly

ensure_test_lake_mounted() {
  local validator="/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh"

  if mount | grep -q "/mnt/test_lake/pilot_tre"; then
    local fs_type
    fs_type="$(findmnt -n -o FSTYPE /mnt/test_lake/pilot_tre 2>/dev/null || echo unknown)"
    echo "✓ Test lake is already mounted (type: $fs_type)"
    if [ -x "$validator" ]; then
      "$validator" "/mnt/test_lake/pilot_tre" || true
    fi
    if [ "$fs_type" = "cifs" ]; then
      return 0
    fi

    echo ""
    echo "⚠ Existing mount is not CIFS. Attempting SMB mount if allowed..."
  fi
  
  echo "🔗 Mounting test lake..."
  if [ -x "/workspaces/ahriTRErRs/scripts/mount_test_lake.sh" ]; then
    ALLOW_OVERMOUNT_CIFS="${ALLOW_OVERMOUNT_CIFS:-0}" sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
    local mount_status=$?
    if [ $mount_status -eq 0 ] && [ -x "$validator" ]; then
      "$validator" "/mnt/test_lake/pilot_tre"
      return $?
    fi
    return $mount_status
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
