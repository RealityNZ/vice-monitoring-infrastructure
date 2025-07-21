# Vice Infrastructure Monitoring & Data Presentation

## Overview

This repository contains the complete monitoring infrastructure for Vice Infrastructure, including Grafana dashboards, Prometheus configurations, and Discord bot integration for log collection and visualization.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Discord Bot   │    │   Prometheus    │    │     Grafana     │
│   (Logs)        │───▶│   (Metrics)     │───▶│   (Dashboards)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Node Exporter │
                       │   (Linux Hosts) │
                       └─────────────────┘
```

## Host Configuration: Vice-DB-One

The monitoring stack is hosted on `Vice-DB-One` with the following components:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Data visualization and dashboards
- **Discord Bot**: Log collection and metrics ingestion

## Project Structure

```
vice-monitoring-infrastructure/
├── README.md                           # This file
├── docker-compose.yml                  # Main deployment configuration
├── .env.example                        # Environment variables template
├── .gitignore                          # Git ignore rules
├── docs/                               # Documentation
│   ├── architecture.md                 # Detailed architecture
│   ├── deployment.md                   # Deployment guide
│   ├── troubleshooting.md              # Troubleshooting guide
│   └── discord-bot-setup.md            # Discord bot setup
├── prometheus/                         # Prometheus configuration
│   ├── prometheus.yml                  # Main Prometheus config
│   ├── rules/                          # Alerting rules
│   │   ├── linux-system.yml           # Linux system alerts
│   │   ├── network.yml                # Network monitoring alerts
│   │   └── discord-bot.yml            # Discord bot alerts
│   └── targets/                        # Target configurations
│       ├── linux-hosts.yml            # Linux host targets
│       └── discord-bot.yml            # Discord bot targets
├── grafana/                            # Grafana configuration
│   ├── provisioning/                   # Auto-provisioning
│   │   ├── dashboards/                 # Dashboard definitions
│   │   │   ├── linux-system.json      # Linux system dashboard
│   │   │   ├── network-monitoring.json # Network dashboard
│   │   │   └── discord-bot.json       # Discord bot dashboard
│   │   └── datasources/                # Data source configs
│   │       └── prometheus.yml          # Prometheus data source
│   └── dashboards/                     # Custom dashboards
│       ├── linux-system/              # Linux system dashboards
│       ├── network/                   # Network monitoring
│       └── discord-bot/               # Discord bot metrics
├── discord-bot/                        # Discord bot for log collection
│   ├── src/                           # Bot source code
│   ├── requirements.txt               # Python dependencies
│   ├── config.yml                     # Bot configuration
│   └── dockerfile                     # Bot containerization
├── scripts/                           # Utility scripts
│   ├── install.sh                     # Installation script
│   ├── backup.sh                      # Backup script
│   └── health-check.sh                # Health monitoring
└── monitoring/                        # Monitoring configurations
    ├── node-exporter/                 # Node exporter configs
    └── alertmanager/                  # Alert manager configs
```

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- Linux host (Vice-DB-One)
- Discord Bot Token (for log collection)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd vice-monitoring-infrastructure
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your specific values
   ```

3. **Deploy the stack:**
   ```bash
   docker-compose up -d
   ```

4. **Access the services:**
   - Grafana: http://vice-db-one:3000
   - Prometheus: http://vice-db-one:9090

## Monitoring Components

### 1. Linux System Monitoring
- **CPU Usage**: Real-time CPU utilization
- **Memory Usage**: RAM and swap monitoring
- **Disk Usage**: Storage capacity and I/O
- **Network Traffic**: Bandwidth utilization
- **System Load**: Load average monitoring
- **Process Monitoring**: Key process health

### 2. Network Monitoring
- **Bandwidth**: In/out traffic monitoring
- **Latency**: Network response times
- **Packet Loss**: Network reliability
- **Connection States**: TCP/UDP connections
- **Interface Status**: Network interface health

### 3. Discord Bot Integration
- **Log Collection**: Real-time Discord log ingestion
- **Message Metrics**: Message volume and patterns
- **User Activity**: User engagement metrics
- **Bot Performance**: Bot response times and errors
- **Channel Analytics**: Channel-specific metrics

## Alerting

The system includes comprehensive alerting for:
- High CPU/Memory usage (>80%)
- Disk space warnings (>85%)
- Network connectivity issues
- Discord bot failures
- Service availability

## Security

- All services run in isolated containers
- Environment-based configuration
- Secure credential management
- Network isolation between components

## Backup & Recovery

- Automated Prometheus data backups
- Grafana dashboard exports
- Configuration version control
- Disaster recovery procedures

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting guide
- Review the documentation
- Create an issue in the repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated**: December 2024
**Version**: 1.0.0
**Maintainer**: Vice Infrastructure Team 