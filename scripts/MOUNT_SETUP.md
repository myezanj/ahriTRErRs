# Test Lake Auto-Mount Setup Guide

## Overview
This directory contains scripts and configurations to auto-mount the test lake from SMB share:
- **Source**: `//DBN-Pure-Nas-01.ahri.org/testlake/pilot_tre`
- **Mount Point**: `/mnt/test_lake/pilot_tre`
- **Credentials**: From `.env` (LAKE_USER, LAKE_PASSWORD)

## Option 1: Using mount_test_lake.sh (Recommended for Dev)

This is the safest option for development environments as it:
- Reads credentials from .env dynamically
- Creates credentials file with secure permissions (600)
- Can be run on-demand
- Provides clear feedback

### Setup:
```bash
chmod +x /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
sudo /workspaces/ahriTRErRs/scripts/mount_test_lake.sh
```

### Result:
- Creates `/root/.smbcredentials` (600 permissions)
- Mounts share at `/mnt/test_lake/pilot_tre`
- Verifies mount is active

---

## Option 2: Using /etc/fstab (For Permanent Systems)

This option automatically mounts the share on system startup.

### Setup:

1. **Create credentials file** (run once):
   ```bash
   sudo sh -c 'cat > /root/.smbcredentials << EOF
   username=pgsqladmin
   password=<password from .env LAKE_PASSWORD field>
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
```

## Troubleshooting

**Mount fails with permission error:**
```bash
sudo chmod 600 /root/.smbcredentials
```

**Credentials file doesn't exist:**
```bash
sudo touch /root/.smbcredentials
sudo chmod 600 /root/.smbcredentials
sudo sh -c 'cat >> /root/.smbcredentials << EOF
username=pgsqladmin
password=<password>
EOF'
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
- `test-lake-mount.mount` - systemd mount unit
- `fstab-entry.txt` - fstab configuration reference
- `.env` - Credentials configuration
