# Vice Infrastructure Monitoring - Deployment Guide

## Overview

This guide provides detailed instructions for deploying the Vice Infrastructure monitoring stack on your Linux host (Vice-DB-One).

## Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04+ or CentOS 8+
- **CPU**: 2+ cores
- **RAM**: 4GB+ (8GB recommended)
- **Storage**: 50GB+ available space
- **Network**: Stable internet connection

### Software Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git
- curl/wget
- sudo access

## Installation Steps

### 1. System Preparation

#### Update System Packages
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### Install Docker
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

#### Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/your-org/vice-monitoring-infrastructure.git
sudo chown -R $USER:$USER vice-monitoring-infrastructure
cd vice-monitoring-infrastructure
```

### 3. Configuration

#### Environment Setup
```bash
cp .env.example .env
nano .env
```

**Required Environment Variables:**
```bash
# Discord Bot Configuration
DISCORD_TOKEN=your_discord_bot_token_here
DISCORD_GUILD_ID=your_guild_id_here
DISCORD_CHANNEL_ID=your_channel_id_here

# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_password_here

# Alertmanager Configuration
ALERTMANAGER_SMTP_USERNAME=your_email@gmail.com
ALERTMANAGER_SMTP_PASSWORD=your_app_password
ALERTMANAGER_SMTP_TO=admin@vice.com
```

#### Network Configuration
Update the target files in `prometheus/targets/` with your actual host IPs:

```yaml
# prometheus/targets/linux-hosts.yml
- targets:
  - '192.168.1.100:9100'  # Vice-DB-One
  - '192.168.1.101:9100'  # Vice-Web-One
  - '192.168.1.102:9100'  # Vice-App-One
```

### 4. Automated Installation

Run the installation script:
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

### 5. Manual Installation (Alternative)

If you prefer manual installation:

```bash
# Create directories
mkdir -p logs backups ssl data/{prometheus,grafana,alertmanager}

# Build and start services
docker-compose build
docker-compose up -d

# Verify services
docker-compose ps
```

## Service Configuration

### Prometheus Configuration

The main Prometheus configuration is in `prometheus/prometheus.yml`. Key settings:

- **Scrape Interval**: 15s (default)
- **Retention**: 200 hours
- **Storage**: Local TSDB

### Grafana Configuration

- **Default Credentials**: admin/viceadmin2024
- **Data Source**: Auto-configured Prometheus
- **Dashboards**: Auto-provisioned

### Alertmanager Configuration

Configure alert routing in `monitoring/alertmanager/alertmanager.yml`:

```yaml
receivers:
  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@vice.com'
    slack_configs:
      - channel: '#alerts'
```

## Verification

### Check Service Status
```bash
# Check all services
docker-compose ps

# Check individual services
curl http://localhost:9090/api/v1/status/config  # Prometheus
curl http://localhost:3000/api/health           # Grafana
curl http://localhost:9093/api/v1/status        # Alertmanager
curl http://localhost:9100/metrics              # Node Exporter
```

### Access Web Interfaces

- **Grafana**: http://your-host-ip:3000
- **Prometheus**: http://your-host-ip:9090
- **Alertmanager**: http://your-host-ip:9093

## Discord Bot Setup

### 1. Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create New Application
3. Go to Bot section
4. Create Bot and copy token

### 2. Configure Bot Permissions

Required permissions:
- Send Messages
- Read Message History
- Embed Links
- Attach Files
- Use External Emojis
- Add Reactions

### 3. Invite Bot to Server

Use this URL (replace CLIENT_ID):
```
https://discord.com/api/oauth2/authorize?client_id=CLIENT_ID&permissions=2048&scope=bot
```

### 4. Update Configuration

Add bot token to `.env`:
```bash
DISCORD_TOKEN=your_bot_token_here
```

## Monitoring Targets

### Linux Hosts

Install Node Exporter on each Linux host:

```bash
# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xzf node_exporter-1.6.1.linux-amd64.tar.gz

# Install as service
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

### Network Monitoring

For network monitoring, consider additional exporters:

- **Blackbox Exporter**: HTTP/HTTPS monitoring
- **SNMP Exporter**: Network device monitoring
- **Ping Exporter**: Network connectivity

## Security Considerations

### Firewall Configuration

```bash
# Allow monitoring ports
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9093/tcp  # Alertmanager
sudo ufw allow 9100/tcp  # Node Exporter
sudo ufw allow 8000/tcp  # Discord Bot
```

### SSL/TLS Configuration

For production, enable SSL:

```bash
# Generate certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/nginx.key -out ssl/nginx.crt

# Update .env
ENABLE_SSL=true
```

### Access Control

- Change default passwords
- Use strong authentication
- Implement network segmentation
- Regular security updates

## Backup and Recovery

### Automated Backups

The system includes automated backup scripts:

```bash
# Manual backup
./scripts/backup.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /opt/vice-monitoring-infrastructure/scripts/backup.sh
```

### Backup Contents

- Prometheus data
- Grafana dashboards
- Configuration files
- Alertmanager data

### Recovery Process

```bash
# Stop services
docker-compose down

# Restore from backup
tar -xzf backup-YYYY-MM-DD.tar.gz
docker-compose up -d
```

## Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check logs
docker-compose logs -f

# Check resource usage
docker stats

# Restart services
docker-compose restart
```

#### Prometheus Targets Down
```bash
# Check target configuration
curl http://localhost:9090/api/v1/targets

# Verify network connectivity
telnet target-host 9100
```

#### Grafana Login Issues
```bash
# Reset admin password
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword
```

### Log Locations

- **Application Logs**: `logs/` directory
- **Docker Logs**: `docker-compose logs -f`
- **System Logs**: `/var/log/syslog` or `/var/log/messages`

## Maintenance

### Regular Tasks

1. **Weekly**: Review alert rules and thresholds
2. **Monthly**: Update container images
3. **Quarterly**: Review and update dashboards
4. **Annually**: Security audit and penetration testing

### Updates

```bash
# Update repository
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Support

For issues and questions:

1. Check the troubleshooting guide
2. Review logs and error messages
3. Consult the documentation
4. Create an issue in the repository

## Next Steps

After successful deployment:

1. Import custom dashboards
2. Configure alert notifications
3. Set up additional monitoring targets
4. Implement log aggregation
5. Configure backup automation
6. Set up monitoring for the monitoring stack itself 