#!/usr/bin/env bash
set -euo pipefail

mount_tre_lake_if_configured() {
  local lake_src="${TRE_TEST_LAKE_PATH_WINDOWS:-}"
  local lake_dst="${TRE_TEST_LAKE_PATH:-}"
  local samba_domain="${SAMBA_DOMAIN:-}"
  local samba_user="${SAMBA_USERNAME:-}"
  local samba_pass="${SAMBA_PASSWORD:-}"

  if [[ -z "${lake_src}" || -z "${lake_dst}" || -z "${samba_user}" || -z "${samba_pass}" ]]; then
    echo "[INFO] TRE Samba mount skipped: missing TRE_TEST_LAKE_PATH_WINDOWS/TRE_TEST_LAKE_PATH/SAMBA_USERNAME/SAMBA_PASSWORD."
    return 0
  fi

  if mountpoint -q "${lake_dst}"; then
    echo "[INFO] TRE Samba mount already present at ${lake_dst}."
    return 0
  fi

  local as_root=""
  if [[ "$(id -u)" -eq 0 ]]; then
    as_root=""
  elif command -v sudo >/dev/null 2>&1; then
    as_root="sudo"
  else
    echo "[WARN] TRE Samba mount skipped: requires root privileges or sudo."
    return 0
  fi

  ${as_root} mkdir -p "${lake_dst}"

  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"

  # Ensure mount.cifs is present; install cifs-utils when missing.
  if ! command -v mount.cifs >/dev/null 2>&1; then
    echo "[INFO] mount.cifs not found. Installing cifs-utils..."
    ${as_root} apt-get update >/dev/null 2>&1 || true
    if ! ${as_root} apt-get install -y --no-install-recommends cifs-utils >/dev/null 2>&1; then
      echo "[WARN] Unable to install cifs-utils automatically."
      return 0
    fi
  fi

  local auth_opts
  auth_opts="username=${samba_user},password=${samba_pass}"
  if [[ -n "${samba_domain}" ]]; then
    auth_opts="domain=${samba_domain},${auth_opts}"
  fi

  local smb_host smb_ip
  smb_host="$(echo "${lake_src}" | sed -E 's#^//([^/]+)/.*#\1#')"
  echo "[INFO] Preflight: resolving ${smb_host}..."
  smb_ip="$(getent hosts "${smb_host}" | awk '{print $1}' | head -n1 || true)"
  if [[ -z "${smb_ip}" ]]; then
    echo "[WARN] DNS resolution failed for ${smb_host}."
    return 0
  fi
  echo "[INFO] Resolved ${smb_host} -> ${smb_ip}."

  echo "[INFO] Preflight: checking TCP/445 to ${smb_ip}..."
  local smb_port
  smb_port=""
  if timeout 5 bash -c "</dev/tcp/${smb_ip}/445" 2>/dev/null; then
    smb_port="445"
  elif timeout 5 bash -c "</dev/tcp/${smb_ip}/139" 2>/dev/null; then
    smb_port="139"
    echo "[INFO] TCP/445 unreachable; using TCP/139."
  else
    echo "[WARN] Cannot reach ${smb_ip} on TCP 445 or 139."
    return 0
  fi

  if [[ "${smb_port}" = "139" ]]; then
    auth_opts="${auth_opts},port=139"
  fi

  if ${as_root} mount -t cifs "${lake_src}" "${lake_dst}" \
      -o "${auth_opts},vers=3.0,uid=${uid},gid=${gid},file_mode=0664,dir_mode=0775,noperm"; then
    echo "[INFO] TRE Samba mount successful: ${lake_src} -> ${lake_dst}."
  else
    echo "[WARN] TRE Samba mount failed: ${lake_src} -> ${lake_dst}."
  fi
}

mount_tre_lake_if_configured

exec sleep infinity
