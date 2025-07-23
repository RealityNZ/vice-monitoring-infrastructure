#!/bin/bash

# Vice Monitoring Infrastructure Security Setup
# This script sets up Nginx reverse proxy with authentication and SSL

set -e

echo "🔒 Setting up Security for Vice Monitoring Infrastructure"
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

# Install Nginx and required packages
print_status "Installing Nginx and required packages..."
apt update
apt install -y nginx apache2-utils

# Create SSL directory
print_status "Creating SSL directory..."
mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
print_status "Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/monitoring.key \
    -out /etc/nginx/ssl/monitoring.crt \
    -subj "/C=US/ST=State/L=City/O=Vice/OU=IT/CN=172.236.225.9"

# Create authentication file
print_status "Setting up authentication..."
echo "Enter username for monitoring access:"
read -r username
htpasswd -c /etc/nginx/.htpasswd "$username"

# Copy Nginx configuration
print_status "Configuring Nginx..."
cp nginx/nginx.conf /etc/nginx/nginx.conf

# Test Nginx configuration
print_status "Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration test failed"
    exit 1
fi

# Start and enable Nginx
print_status "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall..."
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 22/tcp
    print_success "Firewall configured"
else
    print_warning "ufw not found. Please configure firewall manually."
fi

# Update docker-compose to use internal ports only
print_status "Updating Docker Compose configuration for security..."
sed -i 's/- "9090:9090"/- "127.0.0.1:9090:9090"/' docker-compose-monitoring.yml
sed -i 's/- "3000:3000"/- "127.0.0.1:3000:3000"/' docker-compose-monitoring.yml
sed -i 's/- "9093:9093"/- "127.0.0.1:9093:9093"/' docker-compose-monitoring.yml

# Restart monitoring stack
print_status "Restarting monitoring stack with new security configuration..."
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d

print_success "🔒 Security setup completed!"
echo ""
echo "📊 Secure Access URLs:"
echo "   Prometheus: https://172.236.225.9/prometheus/"
echo "   Grafana:    https://172.236.225.9/grafana/ (admin/viceadmin2024)"
echo "   Alertmanager: https://172.236.225.9/alertmanager/"
echo "   Health Check: https://172.236.225.9/health"
echo ""
echo "🔐 Authentication:"
echo "   Username: $username"
echo "   Password: (the one you entered)"
echo ""
echo "⚠️  Security Notes:"
echo "   - All services are now behind HTTPS with authentication"
echo "   - Internal services are only accessible via localhost"
echo "   - Self-signed certificate is used (browser will show warning)"
echo "   - For production, replace with proper SSL certificate"
echo ""
echo "🔧 Useful commands:"
echo "   View Nginx logs: tail -f /var/log/nginx/access.log"
echo "   Test SSL: openssl s_client -connect 172.236.225.9:443"
echo "   Add user: htpasswd /etc/nginx/.htpasswd newuser"
echo "" 