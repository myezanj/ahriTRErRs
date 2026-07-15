#!/usr/bin/env bash
set -euo pipefail

mount_tre_lake_if_configured() {
  local lake_src="${TRE_TEST_LAKE_PATH_WINDOWS:-}"
  local lake_dst="${TRE_TEST_LAKE_PATH:-}"
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

  sudo mkdir -p "${lake_dst}"

  local uid gid
  uid="$(id -u)"
  gid="$(id -g)"

  if sudo mount -t cifs "${lake_src}" "${lake_dst}" \
      -o "username=${samba_user},password=${samba_pass},vers=3.0,uid=${uid},gid=${gid},file_mode=0664,dir_mode=0775,noperm"; then
    echo "[INFO] TRE Samba mount successful: ${lake_src} -> ${lake_dst}."
  else
    echo "[WARN] TRE Samba mount failed: ${lake_src} -> ${lake_dst}."
  fi
}

mount_tre_lake_if_configured

exec sleep infinity
