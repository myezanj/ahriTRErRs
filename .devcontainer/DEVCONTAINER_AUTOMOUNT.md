# Devcontainer Auto-Mount Setup

This devcontainer is configured to automatically mount the test lake (TRE Samba share) when the container starts.

## Auto-Mount Configuration

### How It Works

1. **Dockerfile** copies the post-create setup script
2. **devcontainer.json** runs `post_create_setup.sh` as the `postCreateCommand`
3. **post_create_setup.sh** performs:
   - SMB mount setup for test lake
   - R dependency installation
   - Environment verification

### Environment Variables

The mount configuration requires these variables from `.env`:

```bash
TRE_TEST_LAKE_PATH_WINDOWS="//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre"
TRE_TEST_LAKE_PATH="/mnt/test_lake/pilot_tre"
SAMBA_DOMAIN="AHRI"
SAMBA_USERNAME="njabulo.myeza"
SAMBA_PASSWORD="your_password_here"
```

The devcontainer also sets this in VS Code terminal settings:

```bash
ALLOW_OVERMOUNT_CIFS=1
```

This allows controlled CIFS overmount when `/mnt/test_lake/pilot_tre` is already mounted as non-CIFS and required data is missing.

### Mount Details

- **Source**: SMB share from `DBN-Pure-Nas-01.ahri.org`
- **Destination**: `/mnt/test_lake/pilot_tre` (inside container)
- **Credentials**: From `.env` (SAMBA_USERNAME, SAMBA_PASSWORD)
- **Mount Options**:
  - `vers=3.0` - SMB protocol version
  - `uid/gid` - User/group ownership
  - `file_mode=0664` - File permissions
  - `dir_mode=0775` - Directory permissions
  - `noperm` - Don't check permissions on server side

### Security

- Credentials stored in `/root/.smbcredentials` (600 permissions)
- Only readable by root
- Regenerated on each mount if needed
- Never committed to version control

## Running the Devcontainer

### First Time Setup

```bash
# In VS Code:
# 1. Open folder in devcontainer (Ctrl+Shift+P > Dev Containers: Reopen in Container)
# 2. Devcontainer will automatically:
#    - Build the image
#    - Start the container
#    - Run post-create setup (including mount)
#    - Install R dependencies
```

### Manual Mount (if needed)

If the automatic mount fails or you need to remount:

```bash
# Inside the devcontainer
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh

# Verify mount
mount | grep test_lake
ls -la /mnt/test_lake/pilot_tre

# Validate required study/stage folders
/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh /mnt/test_lake/pilot_tre
```

Expected required paths:

- `study_019e39f6_24e3_74fa_88e1_41e6c62fe539`
- `study_019ebd22_a12b_727c_9e64_dad1c3b5af89`
- `__tre_duckdb_stage`
- `study_019e3fde_a71e_7ee3_9f0d_180879bfb42e`
- `study_019e3fe4_eabf_7ebf_a931_972ffa8d38a3`

## Troubleshooting

### Mount fails in container

**Common causes:**
1. Network not accessible to SMB server
2. Credentials in `.env` are incorrect
3. Container doesn't have required permissions
4. A non-CIFS filesystem is already mounted at `/mnt/test_lake/pilot_tre`

**Check:**
```bash
# Inside container
env | grep SAMBA
env | grep TRE_TEST_LAKE_PATH
mount | grep test_lake
/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh /mnt/test_lake/pilot_tre
```

If the mountpoint is non-CIFS and validation fails, run:

```bash
ALLOW_OVERMOUNT_CIFS=1 sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

If SMB ports are blocked inside the container, use host bind fallback by mounting on the Docker host and letting Compose map host path into container:

```yaml
${HOST_TEST_LAKE_PATH:-/mnt/test_lake/pilot_tre}:${TRE_TEST_LAKE_PATH:-/mnt/test_lake/pilot_tre}
```

### Credentials not being read

1. Verify `.env` exists in `.devcontainer/` or root
2. Check `.env` format: `KEY="value"`
3. Ensure no extra whitespace around values

### Container won't start

1. Check Docker logs: `docker compose logs`
2. Verify `.env` syntax (valid KEY=value pairs)
3. Ensure required dependencies are installed

## Files

- **Dockerfile** - Container build configuration (updated)
- **devcontainer.json** - VS Code devcontainer config (updated)
- **post_create_setup.sh** - Initialization script (new)
- **devcontainer_startup.sh** - Container startup script (existing)
- **docker_compose.yml** - Docker Compose configuration

## Updating Configuration

### Change Samba Credentials

1. Edit `.env` with new credentials:
   ```bash
   SAMBA_USERNAME="new_user"
   SAMBA_PASSWORD="new_password"
   ```

2. Rebuild/restart devcontainer:
   ```bash
   # In VS Code: Ctrl+Shift+P > Dev Containers: Rebuild Container
   # Or: docker compose down && docker compose up
   ```

### Change Mount Path

1. Update `.env`:
   ```bash
   TRE_TEST_LAKE_PATH="/new/mount/path"
   ```

2. Ensure the host path or mount point exists
3. Rebuild devcontainer

## See Also

- [Mount scripts documentation](../scripts/MOUNT_SETUP.md)
- [Project README](../../README.md)
- [VS Code Devcontainers Docs](https://code.visualstudio.com/docs/devcontainers/containers)
