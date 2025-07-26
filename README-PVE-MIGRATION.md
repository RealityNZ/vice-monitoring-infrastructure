# VICE Monitoring Infrastructure - PVE Migration

This repository contains the infrastructure automation for migrating the VICE monitoring stack from a single-host Docker Compose setup to a distributed, virtualized environment on Proxmox VE (PVE).

## 🏗️ Architecture Overview

### Current Architecture (Single Host)
- **Host**: `Vice-DB-One`
- **Services**: Prometheus, Grafana, Alertmanager, Discord Bot, Node Exporter, cAdvisor, Nginx
- **Deployment**: Docker Compose

### New Architecture (Distributed PVE)
- **PVE Node A** (172.16.20.100):
  - `vice-monitoring` (172.16.20.10): Prometheus, Grafana, Alertmanager
  - `vice-node-exporter-a` (172.16.20.11): Node Exporter for PVE Node A
  - `vice-awx` (172.16.20.40): AWX/Ansible Automation Server
  - `vice-terraform-backend` (172.16.20.41): Terraform state storage

- **PVE Node B** (192.16.20.200):
  - `vice-bot-one` (172.16.20.20): Discord Bot Instance 1
  - `vice-bot-two` (172.16.20.21): Discord Bot Instance 2
  - `vice-as01` (172.16.20.30): Application Server
  - `vice-node-exporter-b` (172.16.20.31): Node Exporter for PVE Node B

## 🚀 Quick Start

### Prerequisites

1. **Proxmox VE Setup**:
   - Two PVE nodes with API access
   - API token with sufficient permissions
   - Network connectivity between nodes

2. **Local Environment**:
   - Terraform >= 1.0
   - Ansible >= 2.12
   - SSH key pair for VM access

3. **Discord Bot**:
   - Discord bot token
   - Discord webhook URL for alerts

### 1. Configuration Setup

```bash
# Copy and customize the Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your PVE API credentials

# Copy and customize the Ansible inventory
cp ansible/inventory/hosts.yml ansible/inventory/hosts.yml
# Edit hosts.yml with your specific configuration
```

### 2. Automated Migration

```bash
# Run the automated migration script
./scripts/migrate-to-pve.sh
```

### 3. Manual Steps (if needed)

```bash
# 1. Provision VMs with Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 2. Deploy services with Ansible
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/deploy-monitoring.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-discord-bots.yml
ansible-playbook -i inventory/hosts.yml playbooks/deploy-awx.yml
```

## 📁 Project Structure

```
vice-monitoring-infrastructure/
├── terraform/                    # Infrastructure as Code
│   ├── pve-provider.tf          # PVE provider configuration
│   ├── monitoring-stack.tf      # Monitoring VMs on PVE Node A
│   ├── application-vms.tf       # Application VMs on PVE Node B
│   ├── awx-automation.tf        # AWX and Terraform backend VMs
│   ├── outputs.tf               # Terraform outputs
│   └── terraform.tfvars.example # Example variables file
├── ansible/                     # Configuration Management
│   ├── inventory/
│   │   └── hosts.yml           # Ansible inventory
│   ├── playbooks/
│   │   ├── deploy-monitoring.yml    # Deploy monitoring stack
│   │   ├── deploy-discord-bots.yml  # Deploy Discord bots
│   │   └── deploy-awx.yml           # Deploy AWX
│   ├── templates/               # Jinja2 templates
│   │   ├── docker-compose-monitoring.yml.j2
│   │   ├── prometheus.yml.j2
│   │   ├── alertmanager.yml.j2
│   │   ├── grafana-datasource.yml.j2
│   │   ├── awx-docker-compose.yml.j2
│   │   ├── discord-bot-config.yml.j2
│   │   ├── discord-bot-docker-compose.yml.j2
│   │   ├── monitoring.env.j2
│   │   ├── awx.env.j2
│   │   ├── requirements.txt.j2
│   │   └── nginx.conf.j2
│   └── files/                   # Static files
│       ├── prometheus/
│       │   ├── rules/           # Alerting rules
│       │   └── targets/         # Scrape targets
│       ├── grafana/
│       │   └── dashboards/      # Grafana dashboards
│       └── discord-bot/         # Bot source code
├── scripts/
│   └── migrate-to-pve.sh       # Automated migration script
└── docs/
    └── pve-migration-guide.md  # Detailed migration guide
```

## 🔧 Configuration

### Terraform Variables

Key variables in `terraform.tfvars`:

```hcl
# PVE API Configuration
pve_api_url = "https://172.16.20.100:8006/api2/json"
pve_token_id = "your-token-id@realm!token-name"
pve_token_secret = "your-token-secret"

# Network Configuration
vice_network = "172.16.20.0/24"
monitoring_network = "172.20.0.0/16"
```

### Ansible Variables

Key variables in `ansible/inventory/hosts.yml`:

```yaml
all:
  vars:
    monitoring_network: "172.20.0.0/16"
    prometheus_port: 9090
    grafana_port: 3000
    bot_prefix: "!"
    prometheus_url: "http://172.16.20.10:9090"
    nginx_port: 80
    awx_port: 8052
    vice_network: "172.16.20.0/24"
```

## 📊 Monitoring & Alerting

### Prometheus Targets
- **Discord Bots**: `172.16.20.20:8080`, `172.16.20.21:8080`
- **Node Exporters**: All VMs on port 9100
- **AWX**: `172.16.20.40:8052`
- **Monitoring Stack**: Local services

### Alerting Rules
- **Discord Bot**: Bot down, high latency, error rate
- **Linux System**: High CPU/memory/disk usage, node exporter down
- **Network**: Interface down, high errors/drops, saturation

### Grafana Dashboards
- **Discord Bot Overview**: Bot status, response times
- **Linux System Overview**: CPU, memory, disk usage
- **Network Overview**: Traffic, errors, drops

## 🤖 Discord Bot Features

### Commands
- `!status`: Show bot and system status
- `!ping`: Show bot latency
- `!system`: Detailed system info (admin only)

### Metrics
- Command execution count and duration
- Message count
- Bot uptime
- System CPU and memory usage

## 🔄 Automation with AWX

### AWX Features
- Web-based Ansible automation
- Job templates for service deployment
- Inventory management
- Role-based access control

### Access
- **URL**: `http://172.16.20.40:8052`
- **Default Credentials**: admin/admin
- **Change password on first login**

## 🔒 Security

### Network Security
- Isolated VICE network (172.16.20.0/24)
- Separate monitoring network (172.20.0.0/16)
- SSH key-based authentication

### Service Security
- Grafana admin password change required
- AWX admin password change required
- Discord bot token protection
- Prometheus basic authentication (optional)

## 📈 Benefits of Migration

### Scalability
- **Horizontal scaling**: Add more bot instances easily
- **Resource isolation**: Each service on dedicated VM
- **Load distribution**: Services across multiple PVE nodes

### Reliability
- **High availability**: Services can run on different nodes
- **Fault isolation**: Single service failure doesn't affect others
- **Backup flexibility**: Individual VM backups

### Management
- **Infrastructure as Code**: Terraform for VM provisioning
- **Configuration Management**: Ansible for service deployment
- **Automation Platform**: AWX for workflow management
- **Monitoring**: Comprehensive observability

### Maintenance
- **Independent updates**: Update services without affecting others
- **Rolling deployments**: Zero-downtime updates
- **Easy rollback**: VM snapshots and backups

## 🛠️ Troubleshooting

### Common Issues

1. **Terraform PVE Connection**:
   ```bash
   # Check PVE API connectivity
   curl -k -H "Authorization: PVEAPIToken=your-token" \
        https://172.16.20.100:8006/api2/json/nodes
   ```

2. **Ansible SSH Connection**:
   ```bash
   # Test SSH connectivity
   ansible all -i inventory/hosts.yml -m ping
   ```

3. **Service Health Checks**:
   ```bash
   # Check monitoring stack
   curl http://172.16.20.10:9090/-/healthy  # Prometheus
   curl http://172.16.20.10:3000/api/health  # Grafana
   ```

### Logs
- **Prometheus**: `docker logs prometheus`
- **Grafana**: `docker logs grafana`
- **Discord Bot**: `docker logs vice-bot-one`
- **AWX**: `docker logs awx`

## 📚 Documentation

- [PVE Migration Guide](docs/pve-migration-guide.md): Detailed migration process
- [Architecture Documentation](docs/architecture.md): System architecture details
- [Deployment Guide](docs/deployment.md): Step-by-step deployment instructions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the documentation
3. Open an issue on GitHub
4. Contact the VICE team

---

**Note**: This migration represents a significant architectural change. Ensure you have proper backups and test thoroughly in a staging environment before migrating production systems. 