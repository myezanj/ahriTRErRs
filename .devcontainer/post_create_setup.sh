#!/usr/bin/env bash
# Post-create setup for devcontainer: ensures TRE automount and R dependencies
set -euo pipefail

echo "📦 Running devcontainer post-create setup..."

# Ensure test lake mount point exists and is accessible
ensure_test_lake_mount() {
  local lake_src="${TRE_TEST_LAKE_PATH_WINDOWS:-}"
  local lake_dst="${TRE_TEST_LAKE_PATH:-}"
  local samba_domain="${SAMBA_DOMAIN:-}"
  local samba_user="${SAMBA_USERNAME:-}"
  local samba_pass="${SAMBA_PASSWORD:-}"

  if [[ -z "${lake_src}" || -z "${lake_dst}" || -z "${samba_domain}" || -z "${samba_user}" || -z "${samba_pass}" ]]; then
    echo "[INFO] TRE Samba mount skipped: missing required environment variables"
    echo "       - TRE_TEST_LAKE_PATH_WINDOWS: ${lake_src:-unset}"
    echo "       - TRE_TEST_LAKE_PATH: ${lake_dst:-unset}"
    echo "       - SAMBA_DOMAIN: ${samba_domain:-unset}"
    echo "       - SAMBA_USERNAME: ${samba_user:-unset}"
    echo "       - SAMBA_PASSWORD: ${samba_pass:-unset}"
    return 0
  fi

  if mountpoint -q "${lake_dst}" 2>/dev/null; then
    echo "✓ TRE Samba mount already present at ${lake_dst}"
    return 0
  fi

  echo "🔗 Setting up TRE Samba mount..."
  
  # Determine if we need sudo
  local as_root=""
  if [[ "$(id -u)" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      as_root="sudo"
    else
      echo "[WARN] TRE Samba mount skipped: requires root privileges"
      return 0
    fi
  fi

  # Create mount point
  ${as_root} mkdir -p "${lake_dst}"

  # Get current user/group IDs
  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"

  # Create credentials file securely
  local creds_file="/root/.smbcredentials"
  if [[ ! -f "${creds_file}" ]]; then
    echo "🔐 Creating SMB credentials file..."
    ${as_root} tee "${creds_file}" > /dev/null <<EOF
username=${samba_user}
password=${samba_pass}
EOF
    ${as_root} chmod 600 "${creds_file}"
  fi

  # Attempt mount
  if ${as_root} mount -t cifs "${lake_src}" "${lake_dst}" \
      -o "username=${samba_domain}\\${samba_user},password=${samba_pass},vers=3.0,uid=${uid},gid=${gid},file_mode=0664,dir_mode=0775,noperm" \
      2>/dev/null; then
    echo "✓ TRE Samba mount successful"
    echo "  Source: ${lake_src}"
    echo "  Destination: ${lake_dst}"
    echo "  Domain: ${samba_domain}"
  else
    echo "[WARN] TRE Samba mount failed (this is normal in some environments)"
    echo "       Ensure network connectivity to ${lake_src}"
    echo "       Run manually: sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh"
    return 0
  fi
}

# Setup R dependencies
setup_r_dependencies() {
  echo "📚 Installing R dependencies..."
  R -q -f /workspaces/ahriTRErRs/tools/ensure_dependencies.R
}

# Main execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ensure_test_lake_mount
setup_r_dependencies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Devcontainer setup complete"
