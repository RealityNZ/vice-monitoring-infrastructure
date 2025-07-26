#!/bin/bash

# VICE Infrastructure PVE Migration Script
# This script automates the migration from current single-host to PVE infrastructure

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
CURRENT_HOST="${CURRENT_HOST:-vice-db-one}"
PVE_NODE_A="${PVE_NODE_A:-172.16.20.100}"
PVE_NODE_B="${PVE_NODE_B:-172.16.20.200}"
MONITORING_VM_IP="${MONITORING_VM_IP:-172.16.20.10}"
BACKUP_DIR="${BACKUP_DIR:-/tmp/vice-migration-backup}"

echo "🚀 VICE Infrastructure PVE Migration Script"
echo "=============================================="
echo ""
echo "📋 Migration Overview:"
echo "  Current Host: $CURRENT_HOST"
echo "  PVE Node A: $PVE_NODE_A"
echo "  PVE Node B: $PVE_NODE_B"
echo "  Monitoring VM: $MONITORING_VM_IP"
echo "  Backup Directory: $BACKUP_DIR"
echo ""

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if running on current host
    if [ "$(hostname)" != "$CURRENT_HOST" ]; then
        print_warning "Not running on $CURRENT_HOST. Some operations may fail."
    fi
    
    # Check required tools
    local tools=("docker" "docker-compose" "terraform" "ansible" "ssh-keygen")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "Required tool '$tool' not found. Please install it first."
            exit 1
        fi
    done
    
    print_success "Prerequisites check completed"
}

# Generate SSH keys
generate_ssh_keys() {
    print_info "Generating SSH keys for migration..."
    
    mkdir -p terraform/ssh
    
    if [ ! -f "terraform/ssh/vice-monitoring" ]; then
        ssh-keygen -t rsa -b 4096 -f terraform/ssh/vice-monitoring -N "" -C "vice-monitoring@$(hostname)"
        print_success "Generated vice-monitoring SSH key"
    else
        print_warning "vice-monitoring SSH key already exists"
    fi
    
    if [ ! -f "terraform/ssh/pve-root" ]; then
        ssh-keygen -t rsa -b 4096 -f terraform/ssh/pve-root -N "" -C "pve-root@$(hostname)"
        print_success "Generated pve-root SSH key"
    else
        print_warning "pve-root SSH key already exists"
    fi
}

# Backup current data
backup_current_data() {
    print_info "Creating backup of current infrastructure..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup Prometheus data
    print_info "Backing up Prometheus data..."
    docker exec vice-prometheus promtool tsdb backup /prometheus "$BACKUP_DIR/prometheus-backup" || {
        print_warning "Prometheus backup failed, continuing..."
    }
    
    # Backup Grafana data
    print_info "Backing up Grafana data..."
    docker exec vice-grafana grafana-cli admin backup "$BACKUP_DIR/grafana-backup" || {
        print_warning "Grafana backup failed, continuing..."
    }
    
    # Backup configuration files
    print_info "Backing up configuration files..."
    cp -r prometheus/ "$BACKUP_DIR/"
    cp -r grafana/ "$BACKUP_DIR/"
    cp -r discord-bot/ "$BACKUP_DIR/"
    cp docker-compose.yml "$BACKUP_DIR/"
    
    print_success "Backup completed: $BACKUP_DIR"
}

# Setup Terraform
setup_terraform() {
    print_info "Setting up Terraform infrastructure..."
    
    cd terraform/
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please edit terraform.tfvars with your PVE credentials"
            read -p "Press Enter when ready to continue..."
        else
            print_error "terraform.tfvars.example not found. Please create terraform.tfvars manually."
            exit 1
        fi
    fi
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    
    # Plan the infrastructure
    print_info "Planning infrastructure deployment..."
    terraform plan -out=tfplan
    
    # Confirm deployment
    echo ""
    print_warning "Review the Terraform plan above. This will create VMs on your PVE nodes."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Applying Terraform configuration..."
        terraform apply tfplan
        
        # Get VM IPs
        MONITORING_IP=$(terraform output -raw monitoring_stack_ip)
        BOT_ONE_IP=$(terraform output -raw vice_bot_one_ip)
        BOT_TWO_IP=$(terraform output -raw vice_bot_two_ip)
        AS01_IP=$(terraform output -raw vice_as01_ip)
        AWX_IP=$(terraform output -raw awx_server_ip)
        
        print_success "Infrastructure deployed successfully!"
        echo "  Monitoring Stack: $MONITORING_IP"
        echo "  Vice Bot One: $BOT_ONE_IP"
        echo "  Vice Bot Two: $BOT_TWO_IP"
        echo "  Vice AS01: $AS01_IP"
        echo "  AWX Server: $AWX_IP"
    else
        print_warning "Terraform deployment cancelled"
        exit 1
    fi
    
    cd ..
}

# Wait for VMs to be ready
wait_for_vms() {
    print_info "Waiting for VMs to be ready..."
    
    local vms=("$MONITORING_IP" "$BOT_ONE_IP" "$BOT_TWO_IP" "$AS01_IP" "$AWX_IP")
    
    for vm_ip in "${vms[@]}"; do
        print_info "Waiting for $vm_ip to be ready..."
        until ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i terraform/ssh/vice-monitoring vice@"$vm_ip" "echo 'VM ready'" 2>/dev/null; do
            sleep 10
        done
        print_success "$vm_ip is ready"
    done
}

# Deploy services with Ansible
deploy_services() {
    print_info "Deploying services with Ansible..."
    
    cd ansible/
    
    # Update inventory with actual IPs
    sed -i "s/172.16.20.10/$MONITORING_IP/g" inventory/hosts.yml
    sed -i "s/172.16.20.20/$BOT_ONE_IP/g" inventory/hosts.yml
    sed -i "s/172.16.20.21/$BOT_TWO_IP/g" inventory/hosts.yml
    sed -i "s/172.16.20.30/$AS01_IP/g" inventory/hosts.yml
    sed -i "s/172.16.20.40/$AWX_IP/g" inventory/hosts.yml
    
    # Deploy monitoring stack
    print_info "Deploying monitoring stack..."
    ansible-playbook -i inventory/hosts.yml playbooks/deploy-monitoring.yml
    
    # Deploy Discord bots
    print_info "Deploying Discord bots..."
    ansible-playbook -i inventory/hosts.yml playbooks/deploy-discord-bots.yml
    
    # Deploy AWX
    print_info "Deploying AWX automation server..."
    ansible-playbook -i inventory/hosts.yml playbooks/deploy-awx.yml
    
    cd ..
}

# Transfer backup data
transfer_backup_data() {
    print_info "Transferring backup data to new infrastructure..."
    
    # Transfer Prometheus backup
    if [ -d "$BACKUP_DIR/prometheus-backup" ]; then
        scp -i terraform/ssh/vice-monitoring -r "$BACKUP_DIR/prometheus-backup" vice@"$MONITORING_IP":/home/vice/monitoring/
        print_success "Prometheus backup transferred"
    fi
    
    # Transfer Grafana backup
    if [ -d "$BACKUP_DIR/grafana-backup" ]; then
        scp -i terraform/ssh/vice-monitoring -r "$BACKUP_DIR/grafana-backup" vice@"$MONITORING_IP":/home/vice/monitoring/
        print_success "Grafana backup transferred"
    fi
}

# Verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # Test monitoring services
    print_info "Testing monitoring services..."
    
    # Test Prometheus
    if curl -s "http://$MONITORING_IP:9090/api/v1/status/config" > /dev/null; then
        print_success "Prometheus is running"
    else
        print_error "Prometheus is not responding"
    fi
    
    # Test Grafana
    if curl -s "http://$MONITORING_IP:3000/api/health" > /dev/null; then
        print_success "Grafana is running"
    else
        print_error "Grafana is not responding"
    fi
    
    # Test AWX
    if curl -s "http://$AWX_IP:8052/api/v2/ping/" > /dev/null; then
        print_success "AWX is running"
    else
        print_error "AWX is not responding"
    fi
}

# Display final information
display_final_info() {
    echo ""
    echo "🎉 Migration completed successfully!"
    echo "=================================="
    echo ""
    echo "📊 New Infrastructure Details:"
    echo "  Monitoring Stack: http://$MONITORING_IP:3000 (Grafana)"
    echo "  Prometheus: http://$MONITORING_IP:9090"
    echo "  Alertmanager: http://$MONITORING_IP:9093"
    echo "  AWX Automation: http://$AWX_IP:8052"
    echo ""
    echo "🤖 Discord Bots:"
    echo "  Bot One: $BOT_ONE_IP"
    echo "  Bot Two: $BOT_TWO_IP"
    echo ""
    echo "🖥️  Application Server:"
    echo "  AS01: $AS01_IP"
    echo ""
    echo "📁 Backup Location: $BACKUP_DIR"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Update DNS records to point to new IPs"
    echo "  2. Update firewall rules"
    echo "  3. Test all services thoroughly"
    echo "  4. Configure AWX projects and workflows"
    echo "  5. Set up automated backups"
    echo "  6. Document new procedures"
    echo ""
    echo "⚠️  Important: Keep the current infrastructure running until you're confident"
    echo "   the new system is working correctly!"
}

# Main migration function
main() {
    echo "Starting VICE Infrastructure migration to PVE..."
    echo ""
    
    check_prerequisites
    generate_ssh_keys
    backup_current_data
    setup_terraform
    wait_for_vms
    deploy_services
    transfer_backup_data
    verify_deployment
    display_final_info
}

# Run migration
main "$@" 