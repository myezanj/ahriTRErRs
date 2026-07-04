#!/usr/bin/env bash
set -euo pipefail

release_tag="${AHRI_TRE_RELEASE_TAG:-v0.8.3}"
version="${release_tag#v}"
install_dir="${AHRI_TRE_RUNTIME_ROOT:-/opt/ahri-tre-runtime}"

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

asset="ahri-tre-${version}-${target}.tar"
base_url="https://github.com/AHRIORG/ahri-tre-rs/releases/download/${release_tag}"
api_url="https://api.github.com/repos/AHRIORG/ahri-tre-rs"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

resolve_asset_id() {
  local name="$1"
  local release_json="${tmp_dir}/release.json"

  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${api_url}/releases/tags/${release_tag}" \
    -o "${release_json}" || {
      cat >&2 <<EOF
failed to read AHRI TRE runtime release metadata for ${release_tag}
Set GITHUB_TOKEN to a token that can read AHRIORG/ahri-tre-rs releases, or set AHRI_TRE_RELEASE_TAG to an existing release.
EOF
      return 1
    }

  jq -er --arg name "${name}" '.assets[] | select(.name == $name) | .id' "${release_json}" || {
    cat >&2 <<EOF
AHRI TRE runtime release ${release_tag} does not contain asset ${name}
Check AHRI_TRE_RELEASE_TAG or update the installer asset naming convention.
EOF
    return 1
  }
}

download_asset() {
  local name="$1"
  local output="$2"

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    local asset_id
    asset_id="$(resolve_asset_id "${name}")"

    curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/octet-stream" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api_url}/releases/assets/${asset_id}" \
      -o "${output}"
  else
    curl -fsSL "${base_url}/${name}" -o "${output}" || {
      cat >&2 <<EOF
failed to download AHRI TRE runtime asset: ${base_url}/${name}
If AHRIORG/ahri-tre-rs or ${release_tag} is private, set GITHUB_TOKEN in the environment used to rebuild the devcontainer.
EOF
      return 1
    }
  fi
}

download_asset "${asset}" "${tmp_dir}/${asset}"
download_asset "${asset}.sha256" "${tmp_dir}/${asset}.sha256"

cd "${tmp_dir}"
sha256sum -c "${asset}.sha256"

rm -rf "${install_dir}"
mkdir -p "${install_dir}"
tar -xf "${asset}" --strip-components=1 -C "${install_dir}"

test -x "${install_dir}/bin/ahri-tre"
test -x "${install_dir}/bin/ahri-tred"
test -f "${install_dir}/share/ahri-tre/manifest.json"
