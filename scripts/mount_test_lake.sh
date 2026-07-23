#!/bin/bash
# Mount test lake from SMB share - //DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre

set -e

MOUNT_POINT="/mnt/test_lake/pilot_tre"
SMB_SOURCE="//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre"
CREDS_FILE="/root/.smbcredentials"

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
LAKE_USER=$(grep "^LAKE_USER=" /workspaces/ahriTRErRs/.env | cut -d'=' -f2 | tr -d '"')
LAKE_PASSWORD=$(grep "^LAKE_PASSWORD=" /workspaces/ahriTRErRs/.env | cut -d'=' -f2 | tr -d '"')

if [ -z "$LAKE_USER" ] || [ -z "$LAKE_PASSWORD" ]; then
  echo "✗ Error: LAKE_USER or LAKE_PASSWORD not found in .env"
  exit 1
fi

echo "📋 Configuration:"
echo "   Source:      $SMB_SOURCE"
echo "   Mount Point: $MOUNT_POINT"
echo "   Credentials: $LAKE_USER (from .env)"
echo ""

# Create credentials file (secure: 600 permissions)
if [ ! -f "$CREDS_FILE" ]; then
  echo "🔐 Creating secure credentials file..."
  sudo tee "$CREDS_FILE" > /dev/null <<EOF
username=$LAKE_USER
password=$LAKE_PASSWORD
EOF
  sudo chmod 600 "$CREDS_FILE"
  echo "✓ Credentials file created: $CREDS_FILE (600)"
else
  echo "✓ Credentials file already exists"
fi

# Mount the share
echo "🔗 Mounting SMB share..."
sudo mount -t cifs "$SMB_SOURCE" "$MOUNT_POINT" \
  -o credentials="$CREDS_FILE",uid=1000,gid=1000,file_mode=0755,dir_mode=0755 2>/dev/null && \
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
