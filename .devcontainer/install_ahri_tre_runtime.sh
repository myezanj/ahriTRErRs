#!/usr/bin/env bash
set -euo pipefail

release_tag="${AHRI_TRE_RELEASE_TAG:-v0.8.3}"
release_repository="${AHRI_TRE_RELEASE_REPOSITORY:-myezanj/ahri-tre-rs}"
install_dir="${AHRI_TRE_RUNTIME_ROOT:-/opt/ahri-tre-runtime}"
allow_latest_fallback="${AHRI_TRE_ALLOW_LATEST_FALLBACK:-1}"
runtime_optional="${AHRI_TRE_RUNTIME_OPTIONAL:-0}"
local_runtime_cache_dir="${AHRI_TRE_RUNTIME_CACHE_DIR:-/tmp/ahri-tre-runtime-cache}"
local_runtime_archive="${AHRI_TRE_RUNTIME_LOCAL_ARCHIVE:-}"
local_runtime_checksum="${AHRI_TRE_RUNTIME_LOCAL_CHECKSUM:-}"

case "$(uname -m)" in
  x86_64 | amd64)
    target="x86_64-unknown-linux-gnu"
    ;;
  aarch64 | arm64)
    target="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "unsupported AHRI TRE runtime architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

api_url="https://api.github.com/repos/${release_repository}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

release_json="${tmp_dir}/release.json"
release_tag_effective="${release_tag}"
archive_asset_name=""
archive_asset_id=""
archive_asset_url=""
checksum_asset_name=""
checksum_asset_id=""
checksum_asset_url=""

is_truthy() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES | on | ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_cache_path() {
  local path="$1"

  if [ -z "${path}" ]; then
    return 0
  fi

  if [ "${path#/}" != "${path}" ]; then
    printf '%s' "${path}"
  else
    printf '%s/%s' "${local_runtime_cache_dir}" "${path}"
  fi
}

try_install_local_runtime() {
  local archive_path=""
  local checksum_path=""

  if [ -n "${local_runtime_archive}" ]; then
    archive_path="$(resolve_cache_path "${local_runtime_archive}")"
    if [ ! -f "${archive_path}" ]; then
      cat >&2 <<EOF
configured local runtime archive was not found: ${archive_path}
Either stage the file under .devcontainer/runtime or unset AHRI_TRE_RUNTIME_LOCAL_ARCHIVE.
EOF
      exit 1
    fi
  else
    archive_path="$(find "${local_runtime_cache_dir}" -maxdepth 1 -type f \( -name "ahri-tre-*-${target}.tar" -o -name "ahri-tre-*-${target}.tar.gz" -o -name "ahri-tre-*-${target}.tgz" \) | sort | head -n1 || true)"
    if [ -z "${archive_path}" ]; then
      return 1
    fi
  fi

  if [ -n "${local_runtime_checksum}" ]; then
    checksum_path="$(resolve_cache_path "${local_runtime_checksum}")"
    if [ ! -f "${checksum_path}" ]; then
      cat >&2 <<EOF
configured local runtime checksum was not found: ${checksum_path}
Either stage the file under .devcontainer/runtime or unset AHRI_TRE_RUNTIME_LOCAL_CHECKSUM.
EOF
      exit 1
    fi
  elif [ -f "${archive_path}.sha256" ]; then
    checksum_path="${archive_path}.sha256"
  elif [ -f "${archive_path}.sha256sum" ]; then
    checksum_path="${archive_path}.sha256sum"
  fi

  if [ -n "${checksum_path}" ]; then
    (
      cd "$(dirname "${archive_path}")"
      sha256sum -c "$(basename "${checksum_path}")"
    )
  else
    cat >&2 <<EOF
warning: no checksum file found for local runtime archive $(basename "${archive_path}"); skipping checksum verification
EOF
  fi

  rm -rf "${install_dir}"
  mkdir -p "${install_dir}"
  tar -xf "${archive_path}" --strip-components=1 -C "${install_dir}"

  test -x "${install_dir}/bin/ahri-tre"
  test -x "${install_dir}/bin/ahri-tred"
  test -f "${install_dir}/share/ahri-tre/manifest.json"

  cat >&2 <<EOF
installed AHRI TRE runtime from local archive: ${archive_path}
EOF
  return 0
}

curl_release_json() {
  local endpoint="$1"
  local output="$2"
  local http_code

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    http_code="$(curl -sS -L \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api_url}${endpoint}" \
      -o "${output}" \
      -w "%{http_code}" || true)"

    if [ "${http_code}" = "200" ]; then
      return 0
    fi

    if [ "${http_code}" = "401" ] || [ "${http_code}" = "403" ]; then
      cat >&2 <<EOF
warning: GITHUB_TOKEN was rejected by GitHub API (${http_code}); retrying unauthenticated release lookup
EOF
    fi
  else
    http_code="000"
  fi

  http_code="$(curl -sS -L \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${api_url}${endpoint}" \
    -o "${output}" \
    -w "%{http_code}" || true)"

  [ "${http_code}" = "200" ]
}

resolve_release_metadata() {
  if curl_release_json "/releases/tags/${release_tag}" "${release_json}"; then
    release_tag_effective="${release_tag}"
    return 0
  fi

  if [ "${allow_latest_fallback}" = "1" ] || [ "${allow_latest_fallback}" = "true" ]; then
    if curl_release_json "/releases/latest" "${release_json}"; then
      release_tag_effective="$(jq -er '.tag_name' "${release_json}")"
      cat >&2 <<EOF
warning: unable to resolve AHRI TRE release tag ${release_tag}; falling back to latest release ${release_tag_effective}
EOF
      return 0
    fi
  fi

  cat >&2 <<EOF
failed to read AHRI TRE runtime release metadata for ${release_tag}
Set GITHUB_TOKEN to a token that can read ${release_repository} releases, set AHRI_TRE_RELEASE_TAG to an existing release, or allow latest fallback with AHRI_TRE_ALLOW_LATEST_FALLBACK=1.
Set AHRI_TRE_RELEASE_REPOSITORY if your runtime artifacts are published in a different repository.
Alternatively stage a runtime archive in ${local_runtime_cache_dir} (or set AHRI_TRE_RUNTIME_LOCAL_ARCHIVE/AHRI_TRE_RUNTIME_LOCAL_CHECKSUM).
EOF
  return 1
}

resolve_asset_metadata() {
  archive_asset_name="$(jq -er --arg target "${target}" '.assets[] | select(.name | test("^ahri-tre-.*-" + $target + "\\.(tar|tar\\.gz|tgz)$")) | .name' "${release_json}" | head -n1)" || {
    cat >&2 <<EOF
release ${release_tag_effective} does not contain a runtime archive asset for target ${target}
EOF
    return 1
  }

  archive_asset_id="$(jq -er --arg name "${archive_asset_name}" '.assets[] | select(.name == $name) | .id' "${release_json}")"
  archive_asset_url="$(jq -er --arg name "${archive_asset_name}" '.assets[] | select(.name == $name) | .browser_download_url' "${release_json}")"

  checksum_asset_name="$(jq -er --arg archive "${archive_asset_name}" '.assets[] | select(.name == ($archive + ".sha256") or .name == ($archive + ".sha256sum")) | .name' "${release_json}" | head -n1)" || {
    cat >&2 <<EOF
release ${release_tag_effective} does not contain a checksum asset for ${archive_asset_name}
EOF
    return 1
  }

  checksum_asset_id="$(jq -er --arg name "${checksum_asset_name}" '.assets[] | select(.name == $name) | .id' "${release_json}")"
  checksum_asset_url="$(jq -er --arg name "${checksum_asset_name}" '.assets[] | select(.name == $name) | .browser_download_url' "${release_json}")"
}

download_asset() {
  local name="$1"
  local asset_id="$2"
  local asset_url="$3"
  local output="$4"

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/octet-stream" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api_url}/releases/assets/${asset_id}" \
      -o "${output}"
  else
    curl -fsSL "${asset_url}" -o "${output}"
  fi
}

if try_install_local_runtime; then
  exit 0
fi

if ! resolve_release_metadata; then
  if is_truthy "${runtime_optional}"; then
    cat >&2 <<EOF
warning: AHRI TRE runtime could not be resolved from GitHub; continuing without runtime because AHRI_TRE_RUNTIME_OPTIONAL=${runtime_optional}
EOF
    exit 0
  fi
  exit 1
fi

if ! resolve_asset_metadata; then
  if is_truthy "${runtime_optional}"; then
    cat >&2 <<EOF
warning: AHRI TRE runtime assets are unavailable for ${release_tag_effective}; continuing without runtime because AHRI_TRE_RUNTIME_OPTIONAL=${runtime_optional}
EOF
    exit 0
  fi
  exit 1
fi

download_asset "${archive_asset_name}" "${archive_asset_id}" "${archive_asset_url}" "${tmp_dir}/${archive_asset_name}" || {
  if is_truthy "${runtime_optional}"; then
    cat >&2 <<EOF
warning: failed to download AHRI TRE runtime archive ${archive_asset_name}; continuing without runtime because AHRI_TRE_RUNTIME_OPTIONAL=${runtime_optional}
EOF
    exit 0
  fi
  cat >&2 <<EOF
failed to download AHRI TRE runtime archive asset: ${archive_asset_name}
If ${release_repository} is private, set GITHUB_TOKEN in the environment used to rebuild the devcontainer.
EOF
  exit 1
}

download_asset "${checksum_asset_name}" "${checksum_asset_id}" "${checksum_asset_url}" "${tmp_dir}/${checksum_asset_name}" || {
  if is_truthy "${runtime_optional}"; then
    cat >&2 <<EOF
warning: failed to download AHRI TRE runtime checksum ${checksum_asset_name}; continuing without runtime because AHRI_TRE_RUNTIME_OPTIONAL=${runtime_optional}
EOF
    exit 0
  fi
  cat >&2 <<EOF
failed to download AHRI TRE runtime checksum asset: ${checksum_asset_name}
If ${release_repository} is private, set GITHUB_TOKEN in the environment used to rebuild the devcontainer.
EOF
  exit 1
}

cd "${tmp_dir}"
sha256sum -c "${checksum_asset_name}"

rm -rf "${install_dir}"
mkdir -p "${install_dir}"
tar -xf "${archive_asset_name}" --strip-components=1 -C "${install_dir}"

test -x "${install_dir}/bin/ahri-tre"
test -x "${install_dir}/bin/ahri-tred"
test -f "${install_dir}/share/ahri-tre/manifest.json"
