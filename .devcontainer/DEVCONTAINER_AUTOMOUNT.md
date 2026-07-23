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
SAMBA_USERNAME="njabulo.myeza"
SAMBA_PASSWORD="your_password_here"
```

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
```

## Troubleshooting

### Mount fails in container

**Common causes:**
1. Network not accessible to SMB server
2. Credentials in `.env` are incorrect
3. Container doesn't have required permissions

**Check:**
```bash
# Inside container
env | grep SAMBA
env | grep TRE_TEST_LAKE_PATH
mount | grep test_lake
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
