#!/bin/bash

# Vice Monitoring Infrastructure Deployment Script
# Deploys Prometheus, Grafana, and Alertmanager to Vice-AS-01
# Excludes Discord Bot and other optional components

set -e

echo "🚀 Starting Vice Monitoring Infrastructure Deployment"
echo "📍 Target: Vice-AS-01 (172.236.225.9)"
echo "📦 Components: Prometheus, Grafana, Alertmanager, Node Exporter, cAdvisor"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This is not recommended for security reasons."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if Docker is installed
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are installed"

# Check if Docker daemon is running
print_status "Checking Docker daemon..."
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi

print_success "Docker daemon is running"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p prometheus/rules
mkdir -p prometheus/targets
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards
mkdir -p monitoring/alertmanager

print_success "Directories created"

# Copy configuration files
print_status "Copying configuration files..."

# Copy Prometheus configuration
if [ -f "prometheus/prometheus-monitoring.yml" ]; then
    cp prometheus/prometheus-monitoring.yml prometheus/prometheus.yml
    print_success "Prometheus configuration copied"
else
    print_warning "prometheus-monitoring.yml not found, using default prometheus.yml"
fi

# Copy Alertmanager configuration
if [ -f "monitoring/alertmanager/alertmanager.yml" ]; then
    print_success "Alertmanager configuration found"
else
    print_warning "Alertmanager configuration not found, will use default"
fi

# Copy Grafana datasource configuration
if [ -f "grafana/provisioning/datasources/prometheus.yml" ]; then
    print_success "Grafana datasource configuration found"
else
    print_warning "Grafana datasource configuration not found, will configure manually"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_status "Creating .env file..."
    cat > .env << EOF
# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=viceadmin2024

# Monitoring Configuration
MONITORING_HOST=172.236.225.9
VICE_BOT_ONE=172.235.32.153
VICE_BOT_TWO=172.236.228.231

# Alerting Configuration
ALERTMANAGER_PORT=9093
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
EOF
    print_success ".env file created"
else
    print_success ".env file already exists"
fi

# Stop any existing containers
print_status "Stopping any existing containers..."
docker-compose -f docker-compose-monitoring.yml down --remove-orphans 2>/dev/null || true
print_success "Existing containers stopped"

# Pull latest images
print_status "Pulling latest Docker images..."
docker-compose -f docker-compose-monitoring.yml pull
print_success "Images pulled successfully"

# Start the monitoring stack
print_status "Starting monitoring stack..."
docker-compose -f docker-compose-monitoring.yml up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 10

# Check service status
print_status "Checking service status..."
docker-compose -f docker-compose-monitoring.yml ps

# Test connectivity
print_status "Testing service connectivity..."

# Test Prometheus
if curl -s http://localhost:9090/api/v1/status/config > /dev/null; then
    print_success "Prometheus is accessible at http://localhost:9090"
else
    print_warning "Prometheus may not be ready yet. Check logs with: docker-compose -f docker-compose-monitoring.yml logs prometheus"
fi

# Test Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    print_success "Grafana is accessible at http://localhost:3000"
    print_status "Default credentials: admin / viceadmin2024"
else
    print_warning "Grafana may not be ready yet. Check logs with: docker-compose -f docker-compose-monitoring.yml logs grafana"
fi

# Test Alertmanager
if curl -s http://localhost:9093/api/v1/status > /dev/null; then
    print_success "Alertmanager is accessible at http://localhost:9093"
else
    print_warning "Alertmanager may not be ready yet. Check logs with: docker-compose -f docker-compose-monitoring.yml logs alertmanager"
fi

# Test Node Exporter
if curl -s http://localhost:9100/metrics > /dev/null; then
    print_success "Node Exporter is accessible at http://localhost:9100"
else
    print_warning "Node Exporter may not be ready yet. Check logs with: docker-compose -f docker-compose-monitoring.yml logs node-exporter"
fi

# Test cAdvisor
if curl -s http://localhost:8080/metrics > /dev/null; then
    print_success "cAdvisor is accessible at http://localhost:8080"
else
    print_warning "cAdvisor may not be ready yet. Check logs with: docker-compose -f docker-compose-monitoring.yml logs cadvisor"
fi

echo ""
print_success "🎉 Monitoring infrastructure deployment completed!"
echo ""
echo "📊 Access URLs:"
echo "   Prometheus: http://172.236.225.9:9090"
echo "   Grafana:    http://172.236.225.9:3000 (admin/viceadmin2024)"
echo "   Alertmanager: http://172.236.225.9:9093"
echo "   Node Exporter: http://172.236.225.9:9100"
echo "   cAdvisor:   http://172.236.225.9:8080"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose -f docker-compose-monitoring.yml logs -f [service]"
echo "   Stop services: docker-compose -f docker-compose-monitoring.yml down"
echo "   Restart services: docker-compose -f docker-compose-monitoring.yml restart"
echo "   Update services: docker-compose -f docker-compose-monitoring.yml pull && docker-compose -f docker-compose-monitoring.yml up -d"
echo ""
echo "📋 Next steps:"
echo "   1. Access Grafana and add Prometheus as a data source"
echo "   2. Import dashboards for system monitoring"
echo "   3. Configure alerts in Alertmanager"
echo "   4. Set up monitoring for external hosts (Vice-Bot-One, Vice-Bot-Two)"
echo "" 