# Outputs for VICE Infrastructure

output "monitoring_stack_ip" {
  description = "IP address of the monitoring stack VM"
  value       = proxmox_vm_qemu.vice_monitoring.default_ipv4_address
}

output "vice_bot_one_ip" {
  description = "IP address of Vice Bot One"
  value       = proxmox_vm_qemu.vice_bot_one.default_ipv4_address
}

output "vice_bot_two_ip" {
  description = "IP address of Vice Bot Two"
  value       = proxmox_vm_qemu.vice_bot_two.default_ipv4_address
}

output "vice_as01_ip" {
  description = "IP address of Vice AS01"
  value       = proxmox_vm_qemu.vice_as01.default_ipv4_address
}

output "awx_server_ip" {
  description = "IP address of AWX/Ansible server"
  value       = proxmox_vm_qemu.vice_awx.default_ipv4_address
}

output "terraform_backend_ip" {
  description = "IP address of Terraform backend server"
  value       = proxmox_vm_qemu.vice_terraform_backend.default_ipv4_address
}

output "node_exporter_a_ip" {
  description = "IP address of Node Exporter for PVE Node A"
  value       = proxmox_vm_qemu.vice_node_exporter_a.default_ipv4_address
}

output "node_exporter_b_ip" {
  description = "IP address of Node Exporter for PVE Node B"
  value       = proxmox_vm_qemu.vice_node_exporter_b.default_ipv4_address
}

output "connection_info" {
  description = "Connection information for all VMs"
  value = {
    monitoring_stack = {
      ip = proxmox_vm_qemu.vice_monitoring.default_ipv4_address
      services = ["Prometheus:9090", "Grafana:3000", "Alertmanager:9093"]
    }
    vice_bot_one = {
      ip = proxmox_vm_qemu.vice_bot_one.default_ipv4_address
      services = ["Discord Bot Instance 1"]
    }
    vice_bot_two = {
      ip = proxmox_vm_qemu.vice_bot_two.default_ipv4_address
      services = ["Discord Bot Instance 2"]
    }
    vice_as01 = {
      ip = proxmox_vm_qemu.vice_as01.default_ipv4_address
      services = ["Application Server", "Nginx:80"]
    }
    awx_server = {
      ip = proxmox_vm_qemu.vice_awx.default_ipv4_address
      services = ["AWX:8052", "Ansible Control"]
    }
    terraform_backend = {
      ip = proxmox_vm_qemu.vice_terraform_backend.default_ipv4_address
      services = ["Terraform State Storage"]
    }
  }
} 