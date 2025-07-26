# VICE Infrastructure PVE Migration Guide

## Overview

This guide outlines the migration from the current single-host monitoring infrastructure to a distributed PVE-based infrastructure with automation tools (AWX/Ansible/Terraform).

## Architecture Comparison

### Current Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Vice-DB-One                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │ Prometheus  │ │   Grafana   │ │Discord Bot  │       │
│  │   :9090     │ │   :3000     │ │             │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### New PVE Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PVE Infrastructure                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  PVE Node A (172.16.20.100)                    PVE Node B (172.16.20.200)   │
│  ┌─────────────────┐ ┌─────────────────┐      ┌─────────────────┐          │
│  │ vice-monitoring │ │   vice-awx      │      │  vice-bot-one   │          │
│  │ 172.16.20.10    │ │ 172.16.20.40    │      │ 172.16.20.20    │          │
│  │ • Prometheus    │ │ • AWX/Ansible   │      │ • Discord Bot 1 │          │
│  │ • Grafana       │ │ • Automation    │      └─────────────────┘          │
│  │ • Alertmanager  │ └─────────────────┘      ┌─────────────────┐          │
│  └─────────────────┘ ┌─────────────────┐      │  vice-bot-two   │          │
│  ┌─────────────────┐ │terraform-backend│      │ 172.16.20.21    │          │
│  │node-exporter-a  │ │ 172.16.20.41    │      │ • Discord Bot 2 │          │
│  │ 172.16.20.11    │ │ • State Storage │      └─────────────────┘          │
│  └─────────────────┘ └─────────────────┘      ┌─────────────────┐          │
└─────────────────────────────────────────────────│  vice-as01     │          │
                                                  │ 172.16.20.30   │          │
                                                  │ • App Server   │          │
                                                  └─────────────────┘          │
                                                  ┌─────────────────┐          │
                                                  │node-exporter-b  │          │
                                                  │ 172.16.20.31    │          │
                                                  └─────────────────┘          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### PVE Nodes Setup
1. **PVE Node A (172.16.20.100)**
   - Proxmox VE 8.x installed
   - Ubuntu 22.04 template available
   - API access configured
   - Storage: local-lvm

2. **PVE Node B (172.16.20.200)**
   - Proxmox VE 8.x installed
   - Ubuntu 22.04 template available
   - API access configured
   - Storage: local-lvm

### Network Configuration
- **VICE Network**: 172.16.20.0/24
- **Monitoring Network**: 172.20.0.0/16
- **Gateway**: 172.16.20.1

### Required Tools
- Terraform >= 1.0
- Ansible >= 2.12
- Docker & Docker Compose
- SSH key pairs for authentication

## Migration Steps

### Phase 1: Infrastructure Provisioning

1. **Setup Terraform Environment**
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your PVE credentials
   ```

2. **Generate SSH Keys**
   ```bash
   mkdir -p terraform/ssh
   ssh-keygen -t rsa -b 4096 -f terraform/ssh/vice-monitoring -N ""
   ssh-keygen -t rsa -b 4096 -f terraform/ssh/pve-root -N ""
   ```

3. **Provision VMs**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Phase 2: Data Migration

1. **Backup Current Data**
   ```bash
   # From current Vice-DB-One
   docker exec vice-prometheus promtool tsdb backup /prometheus /backup/prometheus-backup
   docker exec vice-grafana grafana-cli admin backup /var/lib/grafana/backup
   ```

2. **Transfer Data to New Infrastructure**
   ```bash
   scp -r /backup/prometheus-backup vice@172.16.20.10:/home/vice/monitoring/
   scp -r /var/lib/grafana/backup vice@172.16.20.10:/home/vice/monitoring/
   ```

### Phase 3: Service Deployment

1. **Deploy Monitoring Stack**
   ```bash
   cd ansible/
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-monitoring.yml
   ```

2. **Deploy Discord Bots**
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-discord-bots.yml
   ```

3. **Deploy AWX/Ansible**
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-awx.yml
   ```

### Phase 4: Configuration Updates

1. **Update Prometheus Targets**
   - Add new VM IPs to monitoring targets
   - Update Discord bot endpoints

2. **Update Grafana Dashboards**
   - Import existing dashboards
   - Update datasource configurations

3. **Configure AWX Projects**
   - Import VICE infrastructure playbooks
   - Configure inventory and credentials

## VM Specifications

### Monitoring Stack (vice-monitoring)
- **IP**: 172.16.20.10
- **Resources**: 4 vCPU, 8GB RAM, 32GB Storage
- **Services**: Prometheus, Grafana, Alertmanager
- **Ports**: 9090, 3000, 9093

### Discord Bots
- **vice-bot-one**: 172.16.20.20 (2 vCPU, 4GB RAM, 20GB Storage)
- **vice-bot-two**: 172.16.20.21 (2 vCPU, 4GB RAM, 20GB Storage)

### Application Server (vice-as01)
- **IP**: 172.16.20.30
- **Resources**: 4 vCPU, 8GB RAM, 40GB Storage
- **Services**: Nginx, Application Services

### Automation Stack
- **vice-awx**: 172.16.20.40 (4 vCPU, 8GB RAM, 50GB Storage)
- **terraform-backend**: 172.16.20.41 (2 vCPU, 4GB RAM, 30GB Storage)

## Automation Benefits

### Terraform Benefits
- **Infrastructure as Code**: Version-controlled infrastructure
- **Consistent Deployments**: Repeatable VM provisioning
- **State Management**: Track infrastructure changes
- **Multi-Environment**: Easy staging/production separation

### Ansible Benefits
- **Configuration Management**: Automated service deployment
- **Idempotent Operations**: Safe repeated executions
- **Multi-Node Management**: Centralized configuration
- **Integration**: Works with existing monitoring

### AWX Benefits
- **Web Interface**: Visual automation management
- **Role-Based Access**: Team collaboration
- **Scheduling**: Automated maintenance tasks
- **Monitoring Integration**: Alert-driven automation

## Post-Migration Tasks

1. **Update DNS/Network Configuration**
   - Point monitoring URLs to new IPs
   - Update firewall rules

2. **Verify Services**
   - Test all monitoring endpoints
   - Validate Discord bot functionality
   - Check AWX automation workflows

3. **Documentation Updates**
   - Update runbooks and procedures
   - Document new automation workflows
   - Create maintenance schedules

4. **Backup Strategy**
   - Configure automated backups
   - Test disaster recovery procedures
   - Document rollback procedures

## Troubleshooting

### Common Issues
1. **VM Provisioning Failures**
   - Check PVE API connectivity
   - Verify template availability
   - Review storage capacity

2. **Service Deployment Issues**
   - Check SSH connectivity
   - Verify Docker installation
   - Review service logs

3. **Network Connectivity**
   - Verify network configuration
   - Check firewall rules
   - Test DNS resolution

### Support Resources
- PVE Documentation: https://pve.proxmox.com/wiki/
- Terraform PVE Provider: https://registry.terraform.io/providers/telmate/proxmox
- Ansible Documentation: https://docs.ansible.com/
- AWX Documentation: https://docs.ansible.com/ansible-tower/

## Rollback Plan

If migration issues occur:

1. **Keep Current Infrastructure Running**
   - Don't decommission until new system is verified
   - Maintain parallel operation during testing

2. **Gradual Migration**
   - Migrate services one at a time
   - Test each service before proceeding

3. **Rollback Procedures**
   - Document current configuration
   - Maintain backup of all data
   - Test rollback procedures

## Conclusion

This migration provides:
- **Scalability**: Distributed infrastructure
- **Reliability**: High availability setup
- **Automation**: Reduced manual operations
- **Maintainability**: Infrastructure as code
- **Monitoring**: Enhanced observability

The new infrastructure supports future growth while maintaining the existing monitoring capabilities. 