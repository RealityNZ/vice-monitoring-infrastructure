#!/bin/bash

# Node Exporter Installation Script for Vice Bot Hosts
# Run this on Vice-Bot-One and Vice-Bot-Two

set -e

echo "📊 Installing Node Exporter for Vice Bot Host"
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

# Get hostname for identification
HOSTNAME=$(hostname)
print_status "Installing Node Exporter on: $HOSTNAME"

# Download and install Node Exporter
print_status "Downloading Node Exporter..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

print_status "Extracting Node Exporter..."
tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz

print_status "Installing Node Exporter..."
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create user
print_status "Creating node_exporter user..."
sudo useradd -rs /bin/false node_exporter

# Reload systemd and start service
print_status "Starting Node Exporter service..."
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify installation
print_status "Verifying installation..."
sleep 3

if curl -s http://localhost:9100/metrics > /dev/null; then
    print_success "Node Exporter is running successfully!"
    print_success "Metrics available at: http://localhost:9100/metrics"
else
    print_error "Node Exporter failed to start. Check logs with: journalctl -u node_exporter"
    exit 1
fi

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall for Node Exporter..."
    ufw allow from 172.236.225.9 to any port 9100
    print_success "Firewall configured to allow monitoring host access"
else
    print_warning "ufw not found. Please configure firewall manually to allow port 9100 from 172.236.225.9"
fi

# Clean up
print_status "Cleaning up installation files..."
rm -rf /tmp/node_exporter-1.6.1.linux-amd64*

print_success "🎉 Node Exporter installation completed!"
echo ""
echo "📊 Service Status:"
echo "   Service: node_exporter"
echo "   Status: $(systemctl is-active node_exporter)"
echo "   Port: 9100"
echo "   Metrics: http://localhost:9100/metrics"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: systemctl status node_exporter"
echo "   View logs: journalctl -u node_exporter -f"
echo "   Restart: systemctl restart node_exporter"
echo "   Stop: systemctl stop node_exporter"
echo ""
echo "📈 This host will now be monitored by Vice-AS-01 (172.236.225.9)"
echo "" 