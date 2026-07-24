# Copilot Instructions for ahriTRErRs

## Test Lake Mount Workflow

- Prefer the repository mount script for all manual SMB mounting tasks:
  - `/workspaces/ahriTRErRs/scripts/mount_test_lake.sh`
- Prefer the wrapper helper for user-facing onboarding:
  - `/workspaces/ahriTRErRs/scripts/ensure-mount.sh`

## Required Validation

- After mount operations, always validate required lake content with:
  - `/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh /mnt/test_lake/pilot_tre`
- A mount is not considered usable unless validation passes.

## Overmount Behavior

- The path `/mnt/test_lake/pilot_tre` may already be mounted as a non-CIFS filesystem.
- If that happens and required content is missing, use controlled overmount behavior:
  - `ALLOW_OVERMOUNT_CIFS=1 sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh`

## Network Diagnostics

- Use preflight checks before declaring credential problems:
  - DNS resolution for `DBN-Pure-Nas-01.ahri.org`
  - TCP reachability on SMB ports `445` then `139`
- If both ports are blocked, report it as network/routing/firewall, not script failure.

## Devcontainer Notes

- Devcontainer startup and post-create scripts already include mount preflight checks.
- The Compose network is pinned to `172.30.0.0/16` to avoid overlap with NAS IP ranges.
- Compose includes host bind fallback:
  - `${HOST_TEST_LAKE_PATH:-/mnt/test_lake/pilot_tre}:${TRE_TEST_LAKE_PATH:-/mnt/test_lake/pilot_tre}`