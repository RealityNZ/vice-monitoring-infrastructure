# Grafana Datasource Setup Guide

## Overview

This guide explains how to connect Prometheus as a datasource in Grafana for the Vice Infrastructure monitoring system.

## Prerequisites

- Grafana is running and accessible
- Prometheus is running and accessible
- Docker Compose stack is deployed

## Method 1: Automatic Provisioning (Recommended)

The monitoring stack is configured to automatically provision the Prometheus datasource when Grafana starts.

### Steps:

1. **Start the monitoring stack:**
   ```bash
   docker-compose up -d
   ```

2. **Wait for services to start:**
   ```bash
   docker-compose ps
   ```

3. **Access Grafana:**
   - URL: `http://localhost:3000` (or your server IP)
   - Username: `admin`
   - Password: `viceadmin2024`

4. **Verify datasource:**
   - Go to **Configuration** → **Data Sources**
   - You should see "Prometheus" listed as the default datasource

## Method 2: Manual Configuration

If automatic provisioning doesn't work, follow these steps:

### Step 1: Access Grafana Configuration

1. Open Grafana in your browser
2. Click the **Configuration** icon (gear/cog) in the left sidebar
3. Select **Data Sources**

### Step 2: Add Prometheus Datasource

1. Click **Add data source**
2. Select **Prometheus** from the list
3. Configure the following settings:

```
Name: Prometheus
URL: http://prometheus:9090
Access: Proxy
```

### Step 3: Advanced Settings (Optional)

```
Query timeout: 60s
HTTP Method: POST
Scrape interval: 15s
```

### Step 4: Test Connection

1. Click **Save & Test**
2. You should see: "Data source is working"

## Method 3: API Configuration (Advanced)

Use the provided script to configure the datasource programmatically:

### For Linux/Mac:
```bash
./scripts/setup-grafana-datasource.sh
```

### For Windows (PowerShell):
```powershell
# Set environment variables
$env:GRAFANA_URL = "http://localhost:3000"
$env:GRAFANA_USER = "admin"
$env:GRAFANA_PASSWORD = "viceadmin2024"
$env:PROMETHEUS_URL = "http://prometheus:9090"

# Run the script (requires bash/WSL)
bash scripts/setup-grafana-datasource.sh
```

## Troubleshooting

### Issue: "Data source is working" but no data appears

**Possible causes:**
1. Prometheus is not scraping targets
2. Targets are not accessible
3. Network connectivity issues

**Solutions:**
1. Check Prometheus targets: `http://localhost:9090/targets`
2. Verify target endpoints are reachable
3. Check Prometheus logs: `docker-compose logs prometheus`

### Issue: "Failed to connect to data source"

**Possible causes:**
1. Prometheus is not running
2. Wrong URL
3. Network isolation

**Solutions:**
1. Check if Prometheus is running: `docker-compose ps`
2. Verify URL: should be `http://prometheus:9090` (internal Docker network)
3. Check Prometheus logs: `docker-compose logs prometheus`

### Issue: Datasource not appearing automatically

**Possible causes:**
1. Provisioning files not mounted correctly
2. File permissions issues
3. Configuration errors

**Solutions:**
1. Check Docker Compose volumes:
   ```yaml
   volumes:
     - ./grafana/provisioning:/etc/grafana/provisioning
   ```
2. Verify file exists: `grafana/provisioning/datasources/prometheus.yml`
3. Check Grafana logs: `docker-compose logs grafana`

## Verification

### Test Basic Query

1. Go to **Explore** in Grafana
2. Select **Prometheus** datasource
3. Run this query: `up`
4. You should see results showing target status

### Test System Metrics

1. Run this query: `node_cpu_seconds_total`
2. You should see CPU metrics from Node Exporter

### Test Container Metrics

1. Run this query: `container_cpu_usage_seconds_total`
2. You should see container metrics from cAdvisor

## Next Steps

After successfully connecting the datasource:

1. **Import Dashboards:**
   - Go to **Dashboards** → **Import**
   - Import dashboards from the `grafana/dashboards/` directory

2. **Create Custom Dashboards:**
   - Use the **Dashboard** → **New** feature
   - Add panels using Prometheus queries

3. **Set Up Alerts:**
   - Configure alert rules in Prometheus
   - Set up Alertmanager for notifications

## Configuration Files

### Datasource Configuration
Location: `grafana/provisioning/datasources/prometheus.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "15s"
      queryTimeout: "60s"
      httpMethod: "POST"
    secureJsonData: {}
```

### Environment Variables
You can customize the setup using these environment variables:

```bash
GRAFANA_URL=http://localhost:3000
GRAFANA_USER=admin
GRAFANA_PASSWORD=viceadmin2024
PROMETHEUS_URL=http://prometheus:9090
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Grafana logs: `docker-compose logs grafana`
3. Review Prometheus logs: `docker-compose logs prometheus`
4. Check the main README.md for additional information 