# Proxmox VE API Configuration - Node A (172.16.20.100)
pve_api_url = "https://172.16.20.100:8006/api2/json"
pve_token_id = "root@pam!vice-infrastructure"
pve_token_secret = "5941012d-e16b-4f2e-8246-94de80b3a90e"

# Proxmox VE API Configuration - Node B (192.16.20.200)
# Note: We'll need to handle Node B separately or create a different approach
# pve_api_url_b = "https://192.16.20.200:8006/api2/json"
# pve_token_id_b = "root@pam!vice-infrastructure"
# pve_token_secret_b = "664c80f3-f275-4d16-b2d5-47a2dcfebfd6"

# PVE Node Hostnames
pve_node_a = "PR-PVE-01"
pve_node_b = "PR-PVE-02"

# Network Configuration
vice_network = "172.16.20.0/24"
monitoring_network = "172.20.0.0/16"

# Optional: Override default VM specifications
# vice_monitoring_cores = 4
# vice_monitoring_memory = 8192
# vice_monitoring_disk_size = 32

# Optional: Override default bot specifications
# vice_bot_one_cores = 2
# vice_bot_one_memory = 4096
# vice_bot_one_disk_size = 20

# Optional: Override default AWX specifications
# vice_awx_cores = 4
# vice_awx_memory = 8192
# vice_awx_disk_size = 50 