#!/bin/bash

# Update Vice Network Monitoring Targets
# This script pulls the latest configuration and applies it

set -e

echo "🔄 Updating Vice Network Monitoring Targets"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Check if we're in the right directory
if [ ! -f "docker-compose-monitoring.yml" ]; then
    print_error "Please run this script from the vice-monitoring-infrastructure directory"
    exit 1
fi

# Pull latest changes from Git
print_status "Pulling latest configuration from Git..."
git pull origin master

# Copy the updated Prometheus configuration
print_status "Updating Prometheus configuration..."
cp prometheus/prometheus-monitoring.yml prometheus/prometheus.yml

# Reload Prometheus configuration
print_status "Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload

# Check if the reload was successful
if [ $? -eq 0 ]; then
    print_success "Prometheus configuration reloaded successfully"
else
    print_warning "Prometheus reload failed. You may need to restart the container:"
    echo "   docker-compose -f docker-compose-monitoring.yml restart prometheus"
fi

# Show current targets
print_status "Current monitoring targets:"
echo ""
echo "📊 Vice-AS-01 (Monitoring Host):"
echo "   - Node Exporter: 172.236.225.9:9100"
echo "   - cAdvisor: 172.236.225.9:8080"
echo "   - Prometheus: 172.236.225.9:9090"
echo "   - Grafana: 172.236.225.9:3000"
echo "   - Alertmanager: 172.236.225.9:9093"
echo ""
echo "🤖 Bot Hosts:"
echo "   - Vice-Bot-One: 172.235.32.153:9100"
echo "   - Vice-Bot-Two: 172.233.137.104:9100"
echo ""

print_success "Target configuration updated!"
echo ""
echo "🔍 You can verify targets in Prometheus at: http://172.236.225.9:9090/targets"
echo "📈 Access Grafana at: http://172.236.225.9:3000 (admin/viceadmin2024)"
echo "" 