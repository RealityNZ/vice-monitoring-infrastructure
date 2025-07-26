#!/bin/bash

# Grafana Datasource Configuration Script
# Configures Prometheus as the default datasource

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-viceadmin2024}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://prometheus:9090}"

echo "🔧 Configuring Grafana Prometheus Datasource"
echo "📍 Grafana URL: $GRAFANA_URL"
echo "📍 Prometheus URL: $PROMETHEUS_URL"
echo ""

# Wait for Grafana to be ready
print_warning "Waiting for Grafana to be ready..."
until curl -s "$GRAFANA_URL/api/health" > /dev/null; do
    sleep 2
done
print_success "Grafana is ready"

# Create datasource configuration
DATASOURCE_CONFIG=$(cat <<EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "$PROMETHEUS_URL",
  "isDefault": true,
  "editable": true,
  "jsonData": {
    "timeInterval": "15s",
    "queryTimeout": "60s",
    "httpMethod": "POST"
  }
}
EOF
)

# Add the datasource
print_warning "Adding Prometheus datasource..."
RESPONSE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d "$DATASOURCE_CONFIG" \
    "$GRAFANA_URL/api/datasources")

HTTP_CODE="${RESPONSE: -3}"
RESPONSE_BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "409" ]; then
    if [ "$HTTP_CODE" = "409" ]; then
        print_warning "Datasource already exists, updating..."
        # Get datasource ID
        DS_ID=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            "$GRAFANA_URL/api/datasources/name/Prometheus" | jq -r '.id')
        
        # Update the datasource
        curl -s -X PUT \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d "$DATASOURCE_CONFIG" \
            "$GRAFANA_URL/api/datasources/$DS_ID" > /dev/null
    fi
    print_success "Prometheus datasource configured successfully"
else
    print_error "Failed to configure datasource. HTTP Code: $HTTP_CODE"
    print_error "Response: $RESPONSE_BODY"
    exit 1
fi

# Test the datasource
print_warning "Testing datasource connection..."
TEST_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d '{"query": "up"}' \
    "$GRAFANA_URL/api/datasources/proxy/1/api/v1/query")

TEST_HTTP_CODE="${TEST_RESPONSE: -3}"

if [ "$TEST_HTTP_CODE" = "200" ]; then
    print_success "Datasource test successful"
else
    print_warning "Datasource test failed. HTTP Code: $TEST_HTTP_CODE"
    print_warning "This might be normal if Prometheus is still starting up"
fi

echo ""
print_success "🎉 Grafana datasource configuration completed!"
echo ""
echo "📊 You can now:"
echo "   1. Access Grafana at: $GRAFANA_URL"
echo "   2. Create dashboards using Prometheus metrics"
echo "   3. Import existing dashboards from the dashboards/ directory"
echo "" 