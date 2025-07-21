# Git Repository Setup Guide

## Current Status

✅ **Local Repository**: Initialized and committed
✅ **Files**: All monitoring infrastructure files are committed
✅ **Branch**: `master` branch created

## Next Steps: Push to Remote Repository

### Option 1: GitHub

1. **Create Repository on GitHub**:
   - Go to https://github.com/new
   - Repository name: `vice-monitoring-infrastructure`
   - Description: `Vice Infrastructure Monitoring & Data Presentation with Grafana, Prometheus, and Discord Bot`
   - Make it **Private** (recommended for infrastructure code)
   - Don't initialize with README (we already have one)

2. **Add Remote and Push**:
   ```bash
   # Add the remote repository (replace YOUR_USERNAME with your GitHub username)
   git remote add origin https://github.com/YOUR_USERNAME/vice-monitoring-infrastructure.git
   
   # Push to GitHub
   git push -u origin master
   ```

### Option 2: GitLab

1. **Create Repository on GitLab**:
   - Go to https://gitlab.com/projects/new
   - Project name: `vice-monitoring-infrastructure`
   - Description: `Vice Infrastructure Monitoring & Data Presentation`
   - Make it **Private**
   - Don't initialize with README

2. **Add Remote and Push**:
   ```bash
   # Add the remote repository (replace YOUR_USERNAME with your GitLab username)
   git remote add origin https://gitlab.com/YOUR_USERNAME/vice-monitoring-infrastructure.git
   
   # Push to GitLab
   git push -u origin master
   ```

### Option 3: Azure DevOps

1. **Create Repository on Azure DevOps**:
   - Go to your Azure DevOps organization
   - Create new repository: `vice-monitoring-infrastructure`
   - Make it **Private**

2. **Add Remote and Push**:
   ```bash
   # Add the remote repository (replace with your Azure DevOps URL)
   git remote add origin https://dev.azure.com/YOUR_ORG/YOUR_PROJECT/_git/vice-monitoring-infrastructure
   
   # Push to Azure DevOps
   git push -u origin master
   ```

## Repository Structure

Your repository now contains:

```
vice-monitoring-infrastructure/
├── README.md                           # Project overview
├── docker-compose.yml                  # Complete stack configuration
├── .env.example                        # Environment template
├── .gitignore                          # Git ignore rules
├── DEPLOYMENT_CHECKLIST.md             # Deployment checklist
├── GIT_SETUP.md                        # This file
├── docs/                               # Documentation
│   ├── architecture.md                 # System architecture
│   ├── deployment.md                   # General deployment guide
│   └── vice-network-setup.md           # Vice-specific setup
├── prometheus/                         # Prometheus configuration
│   ├── prometheus.yml                  # Main config
│   ├── rules/                          # Alerting rules
│   └── targets/                        # Target configurations
├── grafana/                            # Grafana configuration
│   └── provisioning/                   # Auto-provisioning
├── discord-bot/                        # Discord bot
│   ├── src/bot.py                      # Bot source code
│   ├── config.yml                      # Bot configuration
│   ├── requirements.txt                # Python dependencies
│   └── Dockerfile                      # Container configuration
├── scripts/                            # Utility scripts
│   └── install.sh                      # Installation script
└── monitoring/                         # Monitoring configurations
    └── alertmanager/                   # Alert manager configs
```

## Network Configuration

The repository is pre-configured for your Vice network:

- **Monitoring Host**: Vice-DB-One (172.236.225.9)
- **Target Hosts**: 
  - Vice-Bot-One (172.235.32.153)
  - Vice-Bot-Two (172.233.137.104)

## Security Notes

⚠️ **Important**: Before pushing to a public repository, ensure:

1. **No sensitive data** is committed (check `.env` file is in `.gitignore`)
2. **No hardcoded passwords** or tokens
3. **No internal IP addresses** if using public repository
4. **Consider making repository private** for infrastructure code

## Post-Push Actions

After successfully pushing to your remote repository:

1. **Clone on Vice-DB-One**:
   ```bash
   # SSH to Vice-DB-One
   ssh user@172.236.225.9
   
   # Clone the repository
   cd /opt
   sudo git clone https://github.com/YOUR_USERNAME/vice-monitoring-infrastructure.git
   sudo chown -R $USER:$USER vice-monitoring-infrastructure
   cd vice-monitoring-infrastructure
   ```

2. **Deploy the monitoring stack**:
   ```bash
   # Configure environment
   cp .env.example .env
   nano .env  # Add your Discord bot token and other settings
   
   # Run installation
   chmod +x scripts/install.sh
   ./scripts/install.sh
   ```

3. **Follow the deployment checklist** in `DEPLOYMENT_CHECKLIST.md`

## Repository Management

### Adding Collaborators

If you want to add team members:

1. **GitHub**: Go to repository Settings → Collaborators
2. **GitLab**: Go to repository Members
3. **Azure DevOps**: Go to repository Security

### Branch Strategy

Consider setting up branches for:
- `main` - Production-ready code
- `develop` - Development work
- `feature/*` - Feature branches
- `hotfix/*` - Emergency fixes

### CI/CD Integration

For automated deployment, consider:
- GitHub Actions
- GitLab CI/CD
- Azure DevOps Pipelines

## Support

If you encounter issues:

1. Check the documentation in `docs/` directory
2. Review the deployment checklist
3. Check Git logs: `git log --oneline`
4. Verify remote configuration: `git remote -v`

---

**Repository Created**: ✅
**Ready for Deployment**: ✅
**Next Step**: Push to your preferred Git hosting service 