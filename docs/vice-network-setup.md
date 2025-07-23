# Vice Network Infrastructure - Deployment Guide

## Network Overview

This guide provides specific deployment instructions for the Vice Infrastructure monitoring system based on your network configuration.

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Vice Infrastructure Network              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Vice-DB-One   │    │   Vice-Bot-One  │                │
│  │ 172.236.225.9   │    │ 172.235.32.153  │                │
│  │                 │    │                 │                │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                │
│  │ │ Prometheus  │ │    │ │ Node Exporter│ │                │
│  │ │ Grafana     │ │    │ │ (Port 9100) │ │                │
│  │ │ Alertmanager│ │    │ └─────────────┘ │                │
│  │ │ Discord Bot │ │    └─────────────────┘                │
│  │ │ cAdvisor    │ │                                       │
│  │ └─────────────┘ │    ┌─────────────────┐                │
│  └─────────────────┘    │   Vice-Bot-Two  │                │
│                         │ 172.236.228.231 │                │
│                         │                 │                │
│                         │ ┌─────────────┐ │                │
│                         │ │ Node Exporter│ │                │
│                         │ │ (Port 9100) │ │                │
│                         │ └─────────────┘ │                │
│                         └─────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Host Configuration

### Vice-DB-One (172.236.225.9) - Monitoring Host

**Role**: Primary monitoring server
**Services**: Prometheus, Grafana, Alertmanager, Discord Bot, cAdvisor

#### Port Configuration:
- **3000**: Grafana Web Interface
- **9090**: Prometheus Web Interface
- **9093**: Alertmanager Web Interface
- **9100**: Node Exporter (Local)
- **8080**: cAdvisor (Container metrics)
- **8000**: Discord Bot Metrics

### Vice-Bot-One (172.235.32.153) - Target Host

**Role**: Monitored target
**Services**: Node Exporter

#### Port Configuration:
- **9100**: Node Exporter (System metrics)

### Vice-Bot-Two (172.236.228.231) - Target Host

**Role**: Monitored target
**Services**: Node Exporter

#### Port Configuration:
- **9100**: Node Exporter (System metrics)

## Deployment Steps

### Step 1: Deploy Monitoring Stack on Vice-DB-One

```bash
# SSH to Vice-DB-One
ssh user@172.236.225.9

# Clone the repository
cd /opt
sudo git clone https://github.com/your-org/vice-monitoring-infrastructure.git
sudo chown -R $USER:$USER vice-monitoring-infrastructure
cd vice-monitoring-infrastructure

# Configure environment
cp .env.example .env
nano .env
```

**Required .env Configuration:**
```bash
# Host Configuration
VICE_DB_ONE_HOSTNAME=vice-db-one
VICE_DB_ONE_IP=172.236.225.9

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

### Step 2: Install and Start Monitoring Services

```bash
# Make installation script executable
chmod +x scripts/install.sh

# Run automated installation
./scripts/install.sh
```

### Step 3: Deploy Node Exporter on Target Hosts

#### On Vice-Bot-One (172.235.32.153):

```bash
# SSH to Vice-Bot-One
ssh user@172.235.32.153

# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xzf node_exporter-1.6.1.linux-amd64.tar.gz

# Install Node Exporter
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

# Verify installation
curl http://localhost:9100/metrics
```

#### On Vice-Bot-Two (172.236.228.231):

```bash
# SSH to Vice-Bot-Two
ssh user@172.236.228.231

# Repeat the same installation steps as above
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xzf node_exporter-1.6.1.linux-amd64.tar.gz

# Install Node Exporter
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

# Verify installation
curl http://localhost:9100/metrics
```

### Step 4: Configure Firewall Rules

#### On Vice-DB-One (172.236.225.9):

```bash
# Allow monitoring ports
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 9093/tcp  # Alertmanager
sudo ufw allow 9100/tcp  # Node Exporter
sudo ufw allow 8080/tcp  # cAdvisor
sudo ufw allow 8000/tcp  # Discord Bot

# Allow outbound connections to target hosts
sudo ufw allow out 9100/tcp to 172.235.32.153
sudo ufw allow out 9100/tcp to 172.236.228.231
```

#### On Vice-Bot-One (172.235.32.153):

```bash
# Allow Node Exporter port
sudo ufw allow 9100/tcp

# Allow inbound from monitoring host
sudo ufw allow from 172.236.225.9 to any port 9100
```

#### On Vice-Bot-Two (172.236.228.231):

```bash
# Allow Node Exporter port
sudo ufw allow 9100/tcp

# Allow inbound from monitoring host
sudo ufw allow from 172.236.225.9 to any port 9100
```

### Step 5: Verify Deployment

#### Check Prometheus Targets:

```bash
# On Vice-DB-One, check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'
```

Expected output should show:
- `172.236.225.9:9100` (UP)
- `172.235.32.153:9100` (UP)
- `172.236.228.231:9100` (UP)

#### Check Grafana:

```bash
# Access Grafana
curl http://172.236.225.9:3000/api/health
```

#### Check Alertmanager:

```bash
# Access Alertmanager
curl http://172.236.225.9:9093/api/v1/status
```

## Access URLs

### Web Interfaces:

- **Grafana**: http://172.236.225.9:3000
  - Username: `admin`
  - Password: `secure_password_here` (as configured in .env)

- **Prometheus**: http://172.236.225.9:9090
  - No authentication required (internal network)

- **Alertmanager**: http://172.236.225.9:9093
  - No authentication required (internal network)

### Metrics Endpoints:

- **Vice-DB-One Node Exporter**: http://172.236.225.9:9100/metrics
- **Vice-Bot-One Node Exporter**: http://172.235.32.153:9100/metrics
- **Vice-Bot-Two Node Exporter**: http://172.236.228.231:9100/metrics
- **Discord Bot Metrics**: http://172.236.225.9:8000/metrics

## Monitoring Configuration

### Prometheus Scrape Targets:

The system is configured to monitor:

1. **Vice-DB-One (172.236.225.9)**:
   - System metrics (Node Exporter)
   - Container metrics (cAdvisor)
   - Discord bot metrics
   - Prometheus self-monitoring

2. **Vice-Bot-One (172.235.32.153)**:
   - System metrics (Node Exporter)

3. **Vice-Bot-Two (172.236.228.231)**:
   - System metrics (Node Exporter)

### Alert Rules:

The system includes comprehensive alerting for:

- **High CPU/Memory usage** (>80% threshold)
- **High disk usage** (>85% threshold)
- **Network connectivity issues**
- **Service availability**
- **Discord bot performance**

## Discord Bot Setup

### 1. Create Discord Application:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create New Application
3. Go to Bot section
4. Create Bot and copy token

### 2. Configure Bot Permissions:

Required permissions:
- Send Messages
- Read Message History
- Embed Links
- Attach Files
- Use External Emojis
- Add Reactions

### 3. Invite Bot to Server:

Use this URL (replace CLIENT_ID):
```
https://discord.com/api/oauth2/authorize?client_id=CLIENT_ID&permissions=2048&scope=bot
```

### 4. Update Configuration:

Add bot token to `.env` on Vice-DB-One:
```bash
DISCORD_TOKEN=your_bot_token_here
```

### 5. Bot Commands:

Once deployed, the bot will respond to:
- `!status` - System overview
- `!metrics` - Current metrics
- `!alerts` - Active alerts
- `!logs` - Recent logs

## Troubleshooting

### Common Issues:

#### 1. Targets Not Scraping:

```bash
# Check network connectivity
telnet 172.235.32.153 9100
telnet 172.236.228.231 9100

# Check firewall rules
sudo ufw status
```

#### 2. Services Not Starting:

```bash
# Check Docker logs
docker-compose logs -f

# Check service status
docker-compose ps
```

#### 3. Node Exporter Issues:

```bash
# Check service status
sudo systemctl status node_exporter

# Check logs
sudo journalctl -u node_exporter -f
```

## Maintenance

### Regular Tasks:

1. **Daily**: Check alert status
2. **Weekly**: Review metrics and dashboards
3. **Monthly**: Update container images
4. **Quarterly**: Review and update alert thresholds

### Backup:

```bash
# Manual backup
./scripts/backup.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /opt/vice-monitoring-infrastructure/scripts/backup.sh
```

## Security Notes

1. **Change default passwords** in Grafana
2. **Use strong authentication** for external access
3. **Regular security updates** for all hosts
4. **Monitor access logs** for suspicious activity
5. **Backup configurations** regularly

## Support

For issues specific to your Vice network:

1. Check the troubleshooting section
2. Review logs on all hosts
3. Verify network connectivity between hosts
4. Check firewall configurations
5. Ensure all services are running

---

**Network Configuration Summary:**
- **Monitoring Host**: Vice-DB-One (172.236.225.9)
- **Target Hosts**: Vice-Bot-One (172.235.32.153), Vice-Bot-Two (172.236.228.231)
- **Monitoring Stack**: Prometheus, Grafana, Alertmanager, Discord Bot
- **Target Services**: Node Exporter on all hosts 