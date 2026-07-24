# Test Lake Auto-Mount Setup Guide

## Overview
This directory contains scripts and configurations to auto-mount the test lake from SMB share:
- **Source**: `//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre`
- **Mount Point**: `/mnt/test_lake/pilot_tre`
- **Credentials**: From `.env` (SAMBA_DOMAIN, SAMBA_USERNAME, SAMBA_PASSWORD)
- **Validation**: Required paths enforced via `validate_test_lake_content.sh`

## Option 1: Using mount_test_lake.sh (Recommended for Dev)

This is the safest option for development environments as it:
- Reads credentials from .env dynamically
- Performs DNS and TCP preflight checks (445, then 139)
- Supports controlled overmount for non-CIFS pre-mounted path
- Can be run on-demand
- Provides clear feedback
- Validates required lake content after mount

### Setup:
```bash
chmod +x /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh

# If /mnt/test_lake/pilot_tre is already mounted as non-CIFS:
ALLOW_OVERMOUNT_CIFS=1 sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

### Result:
- Mounts share at `/mnt/test_lake/pilot_tre`
- Verifies mount is active
- Verifies expected directories exist

---

## Option 2: Using /etc/fstab (For Permanent Systems)

This option automatically mounts the share on system startup.

### Setup:

1. **Create credentials file** (run once):
   ```bash
   sudo sh -c 'cat > /root/.smbcredentials << EOF
   username=njabulo.myeza
   password=<password from .env SAMBA_PASSWORD field>
   EOF
   chmod 600 /root/.smbcredentials'
   ```

2. **Add to /etc/fstab**:
   ```bash
   sudo sh -c 'cat >> /etc/fstab << EOF
   //DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre /mnt/test_lake/pilot_tre cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,file_mode=0755,dir_mode=0755 0 0
   EOF'
   ```

3. **Test mount**:
   ```bash
   sudo mount -a
   mount | grep test_lake
   ```

### Verification:
The share will auto-mount on system startup if network is available.

---

## Option 3: Using systemd Mount Unit (For systemd Systems)

This option uses systemd to manage the mount.

### Setup:

1. **Create credentials file** (same as Option 2)

2. **Install mount unit**:
   ```bash
   sudo cp /workspaces/ahriTRErRs/scripts/test-lake-mount.mount /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable test-lake-mount.mount
   ```

3. **Start the mount**:
   ```bash
   sudo systemctl start test-lake-mount.mount
   sudo systemctl status test-lake-mount.mount
   ```

### Advantages:
- Better control over mount timing
- Can retry on failure
- Can be stopped/started independently
- Integrates with systemd

---

## Quick Start (Recommended)

For development, run this once:

```bash
# Make script executable
chmod +x /workspaces/ahriTRErRs/scripts/mount_test_lake.sh

# Run the auto-mount script
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh

# Verify
mount | grep test_lake
```

### VS Code Task Shortcut

Use VS Code tasks for one-command execution:

1. Open Command Palette and run `Tasks: Run Task`
2. Choose `TRE: Mount + Validate Test Lake`
3. Or run `TRE: Validate Test Lake Content`

Workspace task definitions are in:

- `.vscode/tasks.json`
- `.vscode/settings.json`

---

## Verification

After mounting, verify:

```bash
# Check mount status
mount | grep test_lake

# Check accessible
ls -la /mnt/test_lake/pilot_tre/

# Check permissions
stat /mnt/test_lake/pilot_tre

# Validate required test lake paths
/workspaces/ahriTRErRs/scripts/validate_test_lake_content.sh /mnt/test_lake/pilot_tre
```

Expected required paths:

- `study_019e39f6_24e3_74fa_88e1_41e6c62fe539`
- `study_019ebd22_a12b_727c_9e64_dad1c3b5af89`
- `__tre_duckdb_stage`
- `study_019e3fde_a71e_7ee3_9f0d_180879bfb42e`
- `study_019e3fe4_eabf_7ebf_a931_972ffa8d38a3`

## Troubleshooting

**Mount fails with permission error:**
```bash
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

**Network connection unavailable (ports blocked):**
```bash
getent hosts DBN-Pure-Nas-01.ahri.org
nc -zv -w3 DBN-Pure-Nas-01.ahri.org 445
nc -zv -w3 DBN-Pure-Nas-01.ahri.org 139
```

**Path already mounted but not CIFS and missing data:**
```bash
ALLOW_OVERMOUNT_CIFS=1 sudo -E /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

**Network connection unavailable:**
- Check: `host DBN-Pure-Nas-01.ahri.org`
- Check: `nslookup DBN-Pure-Nas-01.ahri.org`

**fstab mount fails at boot:**
```bash
# Remove from fstab if problematic
sudo vim /etc/fstab
# Comment out or remove the test_lake line
# Then use mount_test_lake.sh after system starts
```

---

## See Also

- `mount_test_lake.sh` - Main auto-mount script
- `validate_test_lake_content.sh` - Required lake content validator
- `test-lake-mount.mount` - systemd mount unit
- `fstab-entry.txt` - fstab configuration reference
- `.env` - Credentials configuration
