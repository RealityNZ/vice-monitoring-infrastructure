# Vice Infrastructure Monitoring - Architecture Documentation

## System Overview

The Vice Infrastructure monitoring system is a comprehensive solution designed to monitor Linux systems, network infrastructure, and Discord bot operations. The architecture follows a microservices pattern with containerized components for scalability and maintainability.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Vice Infrastructure Monitoring               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │   Discord   │    │  Prometheus │    │   Grafana   │        │
│  │     Bot     │◄──►│  (Metrics)  │◄──►│(Dashboards) │        │
│  │  (Logs)     │    │             │    │             │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│         │                   │                   │              │
│         │                   │                   │              │
│         ▼                   ▼                   ▼              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ Alertmanager│    │ Node Exporter│   │   cAdvisor  │        │
│  │ (Alerts)    │    │(System Metrics)│  │(Container)  │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Linux Hosts   │
                    │  (Targets)      │
                    └─────────────────┘
```

## Component Architecture

### 1. Prometheus (Metrics Collection)

**Purpose**: Central metrics collection and storage
**Port**: 9090
**Storage**: Time Series Database (TSDB)

#### Key Features:
- **Scraping**: Pull-based metrics collection from targets
- **Storage**: Local time-series database with configurable retention
- **Querying**: PromQL query language for data analysis
- **Alerting**: Rule-based alert generation

#### Configuration:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

#### Data Flow:
1. Prometheus scrapes metrics from configured targets
2. Metrics are stored in TSDB with timestamps
3. Alert rules are evaluated against collected data
4. Alerts are sent to Alertmanager when conditions are met

### 2. Grafana (Visualization)

**Purpose**: Data visualization and dashboard management
**Port**: 3000
**Authentication**: Built-in user management

#### Key Features:
- **Dashboards**: Customizable visualization panels
- **Data Sources**: Support for multiple data sources (Prometheus primary)
- **Alerting**: Built-in alerting capabilities
- **Templating**: Dynamic dashboard variables

#### Dashboard Categories:
1. **Linux System Monitoring**
   - CPU, Memory, Disk usage
   - System load and processes
   - Network interface statistics

2. **Network Monitoring**
   - Bandwidth utilization
   - Connection states
   - Network errors and drops

3. **Discord Bot Monitoring**
   - Message processing metrics
   - Bot performance indicators
   - Error rates and response times

### 3. Discord Bot (Log Collection & Metrics)

**Purpose**: Discord log collection and metrics exposure
**Port**: 8000 (metrics endpoint)
**Language**: Python 3.11

#### Key Features:
- **Log Collection**: Real-time Discord message collection
- **Metrics Exposure**: Prometheus-compatible metrics endpoint
- **Command Interface**: Discord commands for monitoring queries
- **Alert Integration**: Direct alert notifications to Discord

#### Metrics Exposed:
```python
# Core metrics
discord_messages_processed_total
discord_commands_executed_total
discord_errors_total
discord_response_time_seconds

# Status metrics
discord_guild_count
discord_user_count
discord_channel_count
discord_bot_uptime_seconds
```

#### Commands Available:
- `!status` - System status overview
- `!metrics` - Current metrics display
- `!alerts` - Active alerts list
- `!logs` - Recent log entries

### 4. Alertmanager (Alert Management)

**Purpose**: Alert routing and notification management
**Port**: 9093
**Configuration**: YAML-based routing rules

#### Key Features:
- **Alert Routing**: Route alerts to appropriate receivers
- **Grouping**: Group related alerts together
- **Inhibition**: Suppress alerts based on conditions
- **Silencing**: Temporarily silence specific alerts

#### Alert Categories:
1. **Critical Alerts**
   - Service down conditions
   - High resource usage
   - Security incidents

2. **Warning Alerts**
   - Approaching thresholds
   - Performance degradation
   - Capacity warnings

3. **Info Alerts**
   - Status changes
   - Maintenance notifications
   - System updates

### 5. Node Exporter (System Metrics)

**Purpose**: Linux system metrics collection
**Port**: 9100
**Scope**: Host-level system monitoring

#### Metrics Collected:
- **CPU**: Usage, load, temperature
- **Memory**: RAM, swap, buffers
- **Disk**: Usage, I/O, filesystem
- **Network**: Traffic, errors, connections
- **System**: Uptime, processes, file descriptors

### 6. cAdvisor (Container Metrics)

**Purpose**: Container and Docker metrics collection
**Port**: 8080
**Scope**: Container-level monitoring

#### Metrics Collected:
- **Container Stats**: CPU, memory, network per container
- **Docker Events**: Container lifecycle events
- **Resource Usage**: Per-container resource consumption

## Data Flow Architecture

### 1. Metrics Collection Flow

```
Linux Hosts → Node Exporter → Prometheus → Grafana
     ↓              ↓            ↓          ↓
  System        Container    Storage    Visualization
  Metrics       Metrics      (TSDB)     (Dashboards)
```

### 2. Alert Flow

```
Prometheus → Alert Rules → Alertmanager → Receivers
     ↓           ↓            ↓            ↓
  Metrics    Evaluation    Routing     Notifications
  (TSDB)     (PromQL)     (YAML)      (Email/Slack/Discord)
```

### 3. Log Collection Flow

```
Discord → Discord Bot → Message Queue → Metrics → Prometheus
   ↓          ↓            ↓           ↓          ↓
Messages   Processing    Storage    Exposure    Collection
(Real-time) (Python)    (Memory)   (HTTP)      (Scraping)
```

## Network Architecture

### Port Configuration

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Grafana | 3000 | HTTP | Web interface |
| Prometheus | 9090 | HTTP | Metrics & API |
| Alertmanager | 9093 | HTTP | Alert management |
| Node Exporter | 9100 | HTTP | System metrics |
| cAdvisor | 8080 | HTTP | Container metrics |
| Discord Bot | 8000 | HTTP | Bot metrics |

### Network Security

#### Internal Communication
- All services communicate within Docker network
- Network isolation prevents external access
- Service discovery via Docker DNS

#### External Access
- Reverse proxy (Nginx) for external access
- SSL/TLS termination at proxy level
- Authentication required for all external access

## Storage Architecture

### Data Persistence

#### Prometheus Data
- **Location**: `/prometheus` (Docker volume)
- **Format**: Time Series Database (TSDB)
- **Retention**: Configurable (default: 200 hours)
- **Backup**: Automated daily backups

#### Grafana Data
- **Location**: `/var/lib/grafana` (Docker volume)
- **Content**: Dashboards, users, preferences
- **Backup**: Configuration export/import

#### Alertmanager Data
- **Location**: `/alertmanager` (Docker volume)
- **Content**: Alert state, silences, notifications
- **Persistence**: Maintains state across restarts

### Backup Strategy

#### Automated Backups
```bash
# Daily backup script
0 2 * * * /opt/vice-monitoring-infrastructure/scripts/backup.sh
```

#### Backup Contents
- Prometheus TSDB data
- Grafana dashboards (JSON export)
- Configuration files
- Alertmanager state

## Security Architecture

### Authentication & Authorization

#### Grafana
- Built-in user management
- LDAP integration support
- Role-based access control
- API key authentication

#### Prometheus
- No built-in authentication
- Network-level security
- Reverse proxy authentication

#### Discord Bot
- Discord OAuth2 authentication
- Role-based command access
- Rate limiting protection

### Data Security

#### Encryption
- TLS/SSL for all external communications
- Encrypted storage for sensitive data
- Secure credential management

#### Access Control
- Network segmentation
- Firewall rules
- Service isolation

## Scalability Architecture

### Horizontal Scaling

#### Prometheus
- Federation for multi-site monitoring
- Remote storage integration
- Sharding for large deployments

#### Grafana
- Multiple instances behind load balancer
- Shared database for user management
- External authentication providers

### Vertical Scaling

#### Resource Allocation
- Configurable memory limits
- CPU allocation per service
- Storage capacity planning

#### Performance Optimization
- Prometheus retention tuning
- Grafana caching configuration
- Database optimization

## Monitoring the Monitor

### Self-Monitoring

#### Service Health
- Container health checks
- Service availability monitoring
- Resource usage tracking

#### Data Quality
- Metrics collection success rates
- Alert rule evaluation
- Data retention compliance

### External Monitoring
- Uptime monitoring
- Performance monitoring
- Security monitoring

## Disaster Recovery

### Backup & Restore

#### Automated Recovery
- Configuration-driven deployment
- Infrastructure as Code
- Automated testing

#### Manual Recovery
- Step-by-step recovery procedures
- Data restoration processes
- Service validation

### High Availability

#### Service Redundancy
- Multiple Prometheus instances
- Grafana clustering
- Load balancer configuration

#### Data Replication
- Prometheus remote storage
- Grafana database replication
- Configuration synchronization

## Future Enhancements

### Planned Features

1. **Log Aggregation**
   - ELK Stack integration
   - Centralized log management
   - Log correlation with metrics

2. **Advanced Analytics**
   - Machine learning integration
   - Predictive analytics
   - Anomaly detection

3. **Mobile Support**
   - Mobile dashboard access
   - Push notifications
   - Offline capability

4. **API Integration**
   - RESTful API for external access
   - Webhook support
   - Third-party integrations

### Technology Evolution

1. **Container Orchestration**
   - Kubernetes deployment
   - Service mesh integration
   - Auto-scaling capabilities

2. **Cloud Integration**
   - Multi-cloud monitoring
   - Cloud-native metrics
   - Hybrid deployment support

3. **Observability**
   - Distributed tracing
   - OpenTelemetry integration
   - Full-stack observability

## Conclusion

The Vice Infrastructure monitoring architecture provides a robust, scalable, and maintainable solution for comprehensive infrastructure monitoring. The modular design allows for easy extension and customization while maintaining high availability and security standards.

The system successfully integrates traditional system monitoring with modern Discord-based log collection, providing a unified view of infrastructure health and performance. 