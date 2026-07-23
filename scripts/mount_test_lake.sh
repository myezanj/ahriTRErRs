#!/bin/bash
# Mount test lake from SMB share - //DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre

set -e

MOUNT_POINT="/mnt/test_lake/pilot_tre"
SMB_SOURCE="//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║      Test Lake Auto-Mount Setup                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Check if already mounted
if mount | grep -q "$MOUNT_POINT"; then
  echo "✓ $MOUNT_POINT is already mounted"
  mount | grep "$MOUNT_POINT"
  exit 0
fi

# Check credentials from .env
if [ ! -f "/workspaces/ahriTRErRs/.env" ]; then
  echo "✗ Error: /workspaces/ahriTRErRs/.env not found"
  exit 1
fi

# Extract credentials from .env
SAMBA_USERNAME=$(grep "^SAMBA_USERNAME=" /workspaces/ahriTRErRs/.env | cut -d'=' -f2 | tr -d '"')
SAMBA_PASSWORD=$(grep "^SAMBA_PASSWORD=" /workspaces/ahriTRErRs/.env | cut -d'=' -f2 | tr -d '"')

if [ -z "$SAMBA_USERNAME" ] || [ -z "$SAMBA_PASSWORD" ]; then
  echo "✗ Error: SAMBA_USERNAME or SAMBA_PASSWORD not found in .env"
  exit 1
fi

echo "📋 Configuration:"
echo "   Source:      $SMB_SOURCE"
echo "   Mount Point: $MOUNT_POINT"
echo "   Credentials: $SAMBA_USERNAME (from .env)"
echo ""

# Mount the share
echo "🔗 Mounting SMB share..."
MOUNT_UID=$(id -u)
MOUNT_GID=$(id -g)
sudo mount -t cifs "$SMB_SOURCE" "$MOUNT_POINT" \
  -o "username=$SAMBA_USERNAME,password=$SAMBA_PASSWORD,vers=3.0,uid=$MOUNT_UID,gid=$MOUNT_GID,file_mode=0664,dir_mode=0775,noperm" 2>/dev/null && \
  echo "✓ Mount successful" || \
  echo "✗ Mount failed (check network connectivity and credentials)"

# Verify mount
if mount | grep -q "$MOUNT_POINT"; then
  echo ""
  echo "✓ Verification: Mount is active"
  mount | grep "$MOUNT_POINT" | awk '{print "   " $0}'
else
  echo "✗ Verification failed: Mount point not active"
  exit 1
fi

echo ""
echo "✅ Test lake is now mounted and ready for use"
