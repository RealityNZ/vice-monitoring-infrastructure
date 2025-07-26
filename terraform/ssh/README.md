# SSH Keys for Terraform

This directory contains SSH keys used by Terraform to provision and configure VMs on Proxmox VE.

## Files

- `vice-monitoring` - Private SSH key for VM access (sensitive, do not commit)
- `vice-monitoring.pub` - Public SSH key for VM access
- `pve-root` - Private SSH key for PVE root access (sensitive, do not commit)
- `pve-root.pub` - Public SSH key for PVE root access

## Setup Instructions

1. **Generate SSH Key Pairs** (if not already done):
   ```bash
   # For VM access
   ssh-keygen -t rsa -b 4096 -f vice-monitoring -C "vice@monitoring"
   
   # For PVE root access
   ssh-keygen -t rsa -b 4096 -f pve-root -C "root@pve"
   ```

2. **Replace Placeholder Files**:
   - Replace the content of `vice-monitoring.pub` with your actual public key
   - Replace the content of `vice-monitoring` with your actual private key
   - Replace the content of `pve-root.pub` with your actual public key
   - Replace the content of `pve-root` with your actual private key

3. **Set Proper Permissions** (Linux/WSL):
   ```bash
   chmod 600 vice-monitoring
   chmod 644 vice-monitoring.pub
   chmod 600 pve-root
   chmod 644 pve-root.pub
   ```

4. **Add Public Key to VMs**:
   The public key will be automatically injected into VMs via cloud-init.

## Security Notes

- The private key file is in `.gitignore` and should never be committed to version control
- Keep the private key secure and restrict access to authorized personnel only
- Consider using SSH agent forwarding or key management solutions for production environments 