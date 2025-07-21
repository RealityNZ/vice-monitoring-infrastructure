#!/bin/bash

# Vice Infrastructure Monitoring Installation Script
# This script installs and configures the complete monitoring stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    log "System requirements check passed"
}

# Create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p backups
    mkdir -p ssl
    mkdir -p data/prometheus
    mkdir -p data/grafana
    mkdir -p data/alertmanager
    
    log "Directories created successfully"
}

# Setup environment file
setup_environment() {
    log "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            warn "Please edit .env file with your configuration values"
        else
            error ".env.example file not found"
            exit 1
        fi
    else
        warn ".env file already exists. Skipping..."
    fi
}

# Install Node Exporter on Linux hosts
install_node_exporter() {
    log "Installing Node Exporter..."
    
    # Download and install Node Exporter
    NODE_EXPORTER_VERSION="1.6.1"
    NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    
    if [ ! -f "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" ]; then
        log "Downloading Node Exporter..."
        wget $NODE_EXPORTER_URL
    fi
    
    if [ ! -d "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" ]; then
        log "Extracting Node Exporter..."
        tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    fi
    
    # Create systemd service
    sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # Copy binary
    sudo cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
    sudo chown prometheus:prometheus /usr/local/bin/node_exporter
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
    
    log "Node Exporter installed and started"
}

# Setup firewall rules
setup_firewall() {
    log "Setting up firewall rules..."
    
    # Check if ufw is available
    if command -v ufw &> /dev/null; then
        sudo ufw allow 9090/tcp  # Prometheus
        sudo ufw allow 3000/tcp  # Grafana
        sudo ufw allow 9093/tcp  # Alertmanager
        sudo ufw allow 9100/tcp  # Node Exporter
        sudo ufw allow 8000/tcp  # Discord Bot
        log "Firewall rules configured with ufw"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=9090/tcp
        sudo firewall-cmd --permanent --add-port=3000/tcp
        sudo firewall-cmd --permanent --add-port=9093/tcp
        sudo firewall-cmd --permanent --add-port=9100/tcp
        sudo firewall-cmd --permanent --add-port=8000/tcp
        sudo firewall-cmd --reload
        log "Firewall rules configured with firewalld"
    else
        warn "No supported firewall found. Please configure firewall manually."
    fi
}

# Build and start services
start_services() {
    log "Building and starting monitoring services..."
    
    # Build images
    docker-compose build
    
    # Start services
    docker-compose up -d
    
    log "Services started successfully"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Wait for services to start
    sleep 30
    
    # Check Prometheus
    if curl -s http://localhost:9090/api/v1/status/config > /dev/null; then
        log "✓ Prometheus is running"
    else
        error "✗ Prometheus is not responding"
    fi
    
    # Check Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        log "✓ Grafana is running"
    else
        error "✗ Grafana is not responding"
    fi
    
    # Check Alertmanager
    if curl -s http://localhost:9093/api/v1/status > /dev/null; then
        log "✓ Alertmanager is running"
    else
        error "✗ Alertmanager is not responding"
    fi
    
    # Check Node Exporter
    if curl -s http://localhost:9100/metrics > /dev/null; then
        log "✓ Node Exporter is running"
    else
        error "✗ Node Exporter is not responding"
    fi
    
    log "Installation verification completed"
}

# Display access information
display_info() {
    log "Installation completed successfully!"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "  Grafana:     http://localhost:3000 (admin/viceadmin2024)"
    echo -e "  Prometheus:  http://localhost:9090"
    echo -e "  Alertmanager: http://localhost:9093"
    echo -e "  Node Exporter: http://localhost:9100"
    echo -e "  Discord Bot: http://localhost:8000/metrics"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Configure your Discord bot token in .env file"
    echo -e "  2. Set up alert notifications in Alertmanager"
    echo -e "  3. Import dashboards in Grafana"
    echo -e "  4. Configure additional monitoring targets"
    echo
    echo -e "${GREEN}Useful Commands:${NC}"
    echo -e "  View logs:     docker-compose logs -f"
    echo -e "  Stop services: docker-compose down"
    echo -e "  Restart:       docker-compose restart"
    echo -e "  Update:        git pull && docker-compose up -d --build"
}

# Main installation function
main() {
    log "Starting Vice Infrastructure Monitoring installation..."
    
    check_root
    check_requirements
    create_directories
    setup_environment
    install_node_exporter
    setup_firewall
    start_services
    verify_installation
    display_info
    
    log "Installation completed!"
}

# Run main function
main "$@" 