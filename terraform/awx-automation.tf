# AWX/Ansible Automation VMs
resource "proxmox_vm_qemu" "vice_awx" {
  name        = "vice-awx"
  desc        = "AWX/Ansible Automation Server for VICE Infrastructure"
  target_node = var.pve_node_a
  provider    = proxmox.pve_node_a
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 4
  sockets     = 1
  memory      = 8192
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.40/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "50G"
    slot    = 0
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")

  # Provision AWX/Ansible
  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up AWX/Ansible Automation Server'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose python3 python3-pip git",
      "sudo usermod -aG docker vice",
      "sudo pip3 install ansible awx",
      "mkdir -p /home/vice/awx /home/vice/ansible"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.40"
    }
  }
}

resource "proxmox_vm_qemu" "vice_terraform_backend" {
  name        = "vice-terraform-backend"
  desc        = "Terraform State Backend Server"
  target_node = var.pve_node_a
  provider    = proxmox.pve_node_a
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 2
  sockets     = 1
  memory      = 4096
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.41/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "30G"
    slot    = 0
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up Terraform Backend'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose",
      "sudo usermod -aG docker vice",
      "mkdir -p /home/vice/terraform-backend"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.41"
    }
  }
} 