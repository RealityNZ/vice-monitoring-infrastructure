terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Provider for PVE Node A
provider "proxmox" {
  alias               = "pve_node_a"
  pm_api_url          = var.pve_api_url
  pm_api_token_id     = var.pve_token_id
  pm_api_token_secret = var.pve_token_secret
  pm_tls_insecure     = true
}

# Provider for PVE Node B (using same token as Node A since clustered)
provider "proxmox" {
  alias               = "pve_node_b"
  pm_api_url          = var.pve_api_url_b
  pm_api_token_id     = var.pve_token_id
  pm_api_token_secret = var.pve_token_secret
  pm_tls_insecure     = true
}

# Variables
variable "pve_api_url" {
  description = "Proxmox VE API URL"
  type        = string
  default     = "https://172.16.20.100:8006/api2/json"
}

variable "pve_token_id" {
  description = "Proxmox VE API Token ID"
  type        = string
  sensitive   = true
}

variable "pve_token_secret" {
  description = "Proxmox VE API Token Secret"
  type        = string
  sensitive   = true
}

variable "pve_api_url_b" {
  description = "Proxmox VE API URL for Node B"
  type        = string
  default     = "https://172.16.20.200:8006/api2/json"
}

variable "pve_token_id_b" {
  description = "Proxmox VE API Token ID for Node B"
  type        = string
  sensitive   = true
}

variable "pve_token_secret_b" {
  description = "Proxmox VE API Token Secret for Node B"
  type        = string
  sensitive   = true
}

variable "pve_node_a" {
  description = "PVE Node A hostname"
  type        = string
  default     = "pve-node-a"
}

variable "pve_node_b" {
  description = "PVE Node B hostname"
  type        = string
  default     = "pve-node-b"
}

variable "vice_network" {
  description = "VICE network CIDR"
  type        = string
  default     = "172.16.20.0/24"
}

variable "monitoring_network" {
  description = "Monitoring network CIDR"
  type        = string
  default     = "172.20.0.0/16"
} 