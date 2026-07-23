#!/bin/bash
# Mount test lake from SMB share - //DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre

set -e

MOUNT_POINT="/mnt/test_lake/pilot_tre"
SMB_SOURCE="//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre"
ENV_FILE="/workspaces/ahriTRErRs/.env"

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
if [ ! -f "$ENV_FILE" ]; then
  echo "✗ Error: $ENV_FILE not found"
  exit 1
fi

# Extract credentials from .env
SAMBA_DOMAIN=$(grep "^SAMBA_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')
SAMBA_USERNAME=$(grep "^SAMBA_USERNAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')
SAMBA_PASSWORD=$(grep "^SAMBA_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')

if [ -z "$SAMBA_DOMAIN" ] || [ -z "$SAMBA_USERNAME" ] || [ -z "$SAMBA_PASSWORD" ]; then
  echo "✗ Error: SAMBA_DOMAIN, SAMBA_USERNAME, or SAMBA_PASSWORD not found in .env"
  exit 1
fi

echo "📋 Configuration:"
echo "   Source:      $SMB_SOURCE"
echo "   Mount Point: $MOUNT_POINT"
echo "   Domain:      $SAMBA_DOMAIN"
echo "   Credentials: $SAMBA_DOMAIN\\$SAMBA_USERNAME (from .env)"
echo ""

if ! command -v mount.cifs >/dev/null 2>&1; then
  echo "📦 Installing cifs-utils (mount.cifs)..."
  sudo apt-get update >/dev/null 2>&1 || true
  if ! sudo apt-get install -y --no-install-recommends cifs-utils >/dev/null 2>&1; then
    echo "✗ Failed to install cifs-utils"
    exit 1
  fi
fi

# Mount the share
echo "🔗 Mounting SMB share..."
MOUNT_UID=$(id -u)
MOUNT_GID=$(id -g)
AUTH_OPTS="username=$SAMBA_USERNAME,password=$SAMBA_PASSWORD"
if [ -n "$SAMBA_DOMAIN" ]; then
  AUTH_OPTS="domain=$SAMBA_DOMAIN,$AUTH_OPTS"
fi

SMB_HOST=$(echo "$SMB_SOURCE" | sed -E 's#^//([^/]+)/.*#\1#')
echo "🔎 Preflight: resolving $SMB_HOST..."
SMB_IP=$(getent hosts "$SMB_HOST" | awk '{print $1}' | head -n1 || true)
if [ -z "$SMB_IP" ]; then
  echo "✗ DNS resolution failed for $SMB_HOST"
  exit 1
fi
echo "✓ Resolved $SMB_HOST -> $SMB_IP"

echo "🔎 Preflight: checking TCP/445 to $SMB_IP..."
SMB_PORT=""
if timeout 5 bash -c "</dev/tcp/$SMB_IP/445" 2>/dev/null; then
  SMB_PORT="445"
  echo "✓ TCP/445 reachable"
else
  echo "⚠ TCP/445 unreachable, checking TCP/139..."
  if timeout 5 bash -c "</dev/tcp/$SMB_IP/139" 2>/dev/null; then
    SMB_PORT="139"
    echo "✓ TCP/139 reachable"
  else
    echo "✗ Network check failed: cannot reach $SMB_IP on TCP 445 or 139"
    echo "  This is a connectivity/firewall/routing issue, not script syntax."
    exit 1
  fi
fi

if [ "$SMB_PORT" = "139" ]; then
  AUTH_OPTS="$AUTH_OPTS,port=139"
fi

sudo mount -t cifs "$SMB_SOURCE" "$MOUNT_POINT" \
  -o "$AUTH_OPTS,vers=3.0,uid=$MOUNT_UID,gid=$MOUNT_GID,file_mode=0664,dir_mode=0775,noperm" 2>/dev/null && \
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
