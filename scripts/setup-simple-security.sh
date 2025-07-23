#!/bin/bash

# Simple Security Setup for Vice Monitoring Infrastructure
# Uses firewall rules instead of Nginx reverse proxy

set -e

echo "🔒 Setting up Simple Security for Vice Monitoring Infrastructure"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

# Get your IP address for firewall rules
print_status "Detecting your IP address..."
YOUR_IP=$(curl -s ifconfig.me)
if [ -z "$YOUR_IP" ]; then
    print_warning "Could not detect your IP automatically"
    echo "Please enter your IP address:"
    read -r YOUR_IP
else
    print_success "Detected your IP: $YOUR_IP"
fi

# Stop and disable Nginx (we don't need it)
print_status "Stopping Nginx..."
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
print_success "Nginx stopped and disabled"

# Update docker-compose to use direct port binding
print_status "Updating Docker Compose configuration..."
cd /opt/vice-monitoring-infrastructure

# Backup original file
cp docker-compose-monitoring.yml docker-compose-monitoring.yml.backup

# Update port bindings to allow external access
sed -i 's/- "127.0.0.1:9090:9090"/- "9090:9090"/' docker-compose-monitoring.yml
sed -i 's/- "127.0.0.1:3000:3000"/- "3000:3000"/' docker-compose-monitoring.yml
sed -i 's/- "127.0.0.1:9093:9093"/- "9093:9093"/' docker-compose-monitoring.yml

# Remove external URL configurations (not needed for direct access)
sed -i '/--web.external-url/d' docker-compose-monitoring.yml
sed -i '/GF_SERVER_ROOT_URL/d' docker-compose-monitoring.yml
sed -i '/GF_SERVER_SERVE_FROM_SUB_PATH/d' docker-compose-monitoring.yml

print_success "Docker Compose configuration updated"

# Configure firewall
print_status "Configuring firewall..."

# Install ufw if not present
if ! command -v ufw &> /dev/null; then
    apt update
    apt install -y ufw
fi

# Reset firewall to default
ufw --force reset

# Allow SSH
ufw allow 22/tcp

# Allow monitoring ports only from your IP
ufw allow from $YOUR_IP to any port 9090  # Prometheus
ufw allow from $YOUR_IP to any port 3000  # Grafana
ufw allow from $YOUR_IP to any port 9093  # Alertmanager
ufw allow from $YOUR_IP to any port 9100  # Node Exporter
ufw allow from $YOUR_IP to any port 8080  # cAdvisor

# Allow internal network access (for monitoring other hosts)
ufw allow from 172.235.32.153 to any port 9100  # Vice-Bot-One
ufw allow from 172.233.137.104 to any port 9100  # Vice-Bot-Two

# Enable firewall
ufw --force enable

print_success "Firewall configured to allow access only from $YOUR_IP"

# Restart monitoring stack
print_status "Restarting monitoring stack..."
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 10

# Test connectivity
print_status "Testing service connectivity..."

# Test Prometheus
if curl -s http://localhost:9090/api/v1/status/config > /dev/null; then
    print_success "Prometheus is accessible at http://172.236.225.9:9090"
else
    print_warning "Prometheus may not be ready yet"
fi

# Test Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    print_success "Grafana is accessible at http://172.236.225.9:3000"
    print_status "Default credentials: admin / viceadmin2024"
else
    print_warning "Grafana may not be ready yet"
fi

# Test Alertmanager
if curl -s http://localhost:9093/api/v1/status > /dev/null; then
    print_success "Alertmanager is accessible at http://172.236.225.9:9093"
else
    print_warning "Alertmanager may not be ready yet"
fi

print_success "🔒 Simple security setup completed!"
echo ""
echo "📊 Direct Access URLs:"
echo "   Prometheus: http://172.236.225.9:9090"
echo "   Grafana:    http://172.236.225.9:3000 (admin/viceadmin2024)"
echo "   Alertmanager: http://172.236.225.9:9093"
echo "   Node Exporter: http://172.236.225.9:9100"
echo "   cAdvisor:   http://172.236.225.9:8080"
echo ""
echo "🔐 Security:"
echo "   - Firewall restricts access to your IP: $YOUR_IP"
echo "   - No complex reverse proxy configuration"
echo "   - Direct access to all services"
echo ""
echo "⚠️  Important:"
echo "   - Only your IP ($YOUR_IP) can access these services"
echo "   - If your IP changes, run this script again"
echo "   - For additional security, consider using a VPN"
echo "" 