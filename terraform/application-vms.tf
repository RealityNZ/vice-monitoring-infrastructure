# VICE Application VMs on PVE Node B
resource "proxmox_vm_qemu" "vice_bot_one" {
  name        = "vice-bot-one"
  desc        = "VICE Discord Bot Instance One"
  target_node = var.pve_node_b
  provider    = proxmox.pve_node_b
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 2
  sockets     = 1
  memory      = 4096
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.20/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
    slot    = 0
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")

  # Provision Discord Bot
  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up Vice Bot One'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose python3 python3-pip",
      "sudo usermod -aG docker vice",
      "mkdir -p /home/vice/vice-bot-one"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.20"
    }
  }
}

resource "proxmox_vm_qemu" "vice_bot_two" {
  name        = "vice-bot-two"
  desc        = "VICE Discord Bot Instance Two"
  target_node = var.pve_node_b
  provider    = proxmox.pve_node_b
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 2
  sockets     = 1
  memory      = 4096
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.21/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
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
      "echo 'Setting up Vice Bot Two'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose python3 python3-pip",
      "sudo usermod -aG docker vice",
      "mkdir -p /home/vice/vice-bot-two"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.21"
    }
  }
}

resource "proxmox_vm_qemu" "vice_as01" {
  name        = "vice-as01"
  desc        = "VICE Application Server One"
  target_node = var.pve_node_b
  provider    = proxmox.pve_node_b
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 4
  sockets     = 1
  memory      = 8192
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.30/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "40G"
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
      "echo 'Setting up AS01'",
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose nginx",
      "sudo usermod -aG docker vice"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.30"
    }
  }
}

resource "proxmox_vm_qemu" "vice_node_exporter_b" {
  name        = "vice-node-exporter-b"
  desc        = "Node Exporter for PVE Node B monitoring"
  target_node = var.pve_node_b
  provider    = proxmox.pve_node_b
  clone       = "ubuntu-22.04-template"
  full_clone  = true
  cores       = 1
  sockets     = 1
  memory      = 1024
  agent       = 1
  os_type     = "cloud-init"
  ipconfig0   = "ip=172.16.20.31/24,gw=172.16.20.1"

  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "8G"
    slot    = 0
  }

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  ciuser = "vice"
  sshkeys = file("${path.module}/ssh/vice-monitoring.pub")

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Node Exporter VM is ready'",
      "sudo apt update",
      "sudo apt install -y docker.io",
      "sudo usermod -aG docker vice"
    ]

    connection {
      type        = "ssh"
      user        = "vice"
      private_key = file("${path.module}/ssh/vice-monitoring")
      host        = "172.16.20.31"
    }
  }
} 