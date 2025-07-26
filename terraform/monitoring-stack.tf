# Monitoring Stack VM (PVE Node A)
resource "proxmox_vm_qemu" "vice_monitoring" {
  name        = "vice-monitoring"
  desc        = "VICE Monitoring Stack - Prometheus, Grafana, Alertmanager"
  target_node = var.pve_node_a
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 4
  sockets     = 1
  memory      = 8192
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.10/24,gw=172.16.20.1"
  
  # Storage configuration
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  scsi0 = "local-lvm:32,format=raw"
  
  # Network configuration
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init configuration
  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")

  # Lifecycle hooks
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Wait for VM to be ready
  provisioner "remote-exec" {
    inline = [
      "echo 'VM is ready'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose",
      "sudo usermod -aG docker vice"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.10"
    }
  }
}

# Node Exporter VM (for PVE Node A monitoring)
resource "proxmox_vm_qemu" "vice_node_exporter_a" {
  name        = "vice-node-exporter-a"
  desc        = "Node Exporter for PVE Node A"
  target_node = var.pve_node_a
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 1
  sockets     = 1
  memory      = 1024
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.11/24,gw=172.16.20.1"
  
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  scsi0 = "local-lvm:8,format=raw"
  
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")
} 