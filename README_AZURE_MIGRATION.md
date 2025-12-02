# Contoso University - Azure Migration Package

## 📋 Overview

This package contains all necessary materials for migrating the Contoso University ASP.NET 4.8 MVC application from on-premises to Microsoft Azure. The migration includes infrastructure as code, application updates, CI/CD pipelines, and comprehensive documentation.

## 📦 What's Included

### Documentation
- **AZURE_MIGRATION_PLAN.md** - Comprehensive migration strategy and timeline
- **IMPLEMENTATION_SUMMARY.md** - Executive summary with roadmap and deliverables
- **OPERATIONAL_GUIDE.md** - Production operations, monitoring, and troubleshooting
- **AZURE_CODE_CHANGES.md** - Application code modifications required
- **azure/DEPLOYMENT_GUIDE.md** - Step-by-step deployment instructions

### Infrastructure as Code
```
azure/bicep/
├── main.bicep                 # Orchestration template
├── main.dev.bicepparam       # Development environment config
├── main.staging.bicepparam   # Staging environment config
├── main.prod.bicepparam      # Production environment config
└── modules/                   # Reusable resource templates
    ├── appservice.bicep
    ├── sqlserver.bicep
    ├── storage.bicep
    ├── keyvault.bicep
    ├── servicebus.bicep
    ├── appinsights.bicep
    └── loganalytics.bicep
```

### Application Code
```
ContosoUniversity/Azure/
├── AzureStartupConfiguration.cs    # Azure service initialization
├── AzureStorageService.cs          # Blob Storage integration
└── AzureNotificationService.cs     # Service Bus integration
```

### CI/CD Pipelines
```
.github/workflows/
├── deploy-azure.yml              # Main deployment pipeline
└── database-migration.yml        # Database migration workflow
```

## 🚀 Quick Start

### Prerequisites
- Azure subscription (with appropriate permissions)
- Azure CLI (`az` command-line tool)
- PowerShell 7+ or Bash
- Visual Studio 2022 or Visual Studio Code
- .NET Framework 4.8 installed

### Installation Steps

1. **Install Azure CLI**
   ```bash
   # Windows (using Windows Package Manager)
   winget install Microsoft.AzureCLI
   
   # Or download from: https://aka.ms/azurecli
   ```

2. **Install PowerShell 7+** (if not already installed)
   ```powershell
   winget install Microsoft.PowerShell
   ```

3. **Authenticate with Azure**
   ```powershell
   az login
   az account set --subscription "Your Subscription Name"
   ```

4. **Clone or download this repository**
   ```powershell
   git clone https://github.com/your-org/contosouniversity.git
   cd contosouniversity
   ```

## 🏗️ Architecture

The application will be deployed across these Azure services:

```
┌─────────────────────────────────────┐
│    Azure App Service                │
│    - Windows, .NET Framework 4.8    │
│    - Auto-scaling, SSL, monitoring  │
└──────────────────┬──────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼────┐  ┌──────▼──┐  ┌───────▼──┐
│ SQL DB │  │ Storage │  │Key Vault │
│        │  │         │  │          │
│ - Data │  │ - Files │  │ - Secrets│
└────────┘  └─────────┘  └──────────┘

Additional: Service Bus, Application Insights, Log Analytics
```

## 📋 Migration Phases

### Phase 1: Preparation (Week 1)
- Review and approve migration plan
- Set up Azure environments
- Brief development team

### Phase 2: Infrastructure (Week 2)
- Deploy Bicep templates
- Configure services
- Set up monitoring

### Phase 3: Application Modifications (Week 2-3)
- Install Azure SDKs
- Update application code
- Migrate configuration

### Phase 4: Database Migration (Week 3)
- Create Azure SQL Database
- Migrate data
- Validate integrity

### Phase 5: Deployment & Testing (Week 4)
- Deploy to staging
- Run full test suite
- Prepare for production

### Phase 6: Production Deployment (Week 5)
- Deploy to production
- Monitor closely
- Handle issues

## 🔧 Configuration

### Key Configuration Files

**Development Environment**
```powershell
$environment = 'dev'
$resourceGroup = 'contosouniversity-dev-rg'
$location = 'eastus'
```

**Production Environment**
```powershell
$environment = 'prod'
$resourceGroup = 'contosouniversity-prod-rg'
$location = 'eastus'  # or 'westus' for secondary
```

### Environment Variables

```powershell
# Set these before deployment
$env:AZURE_SUBSCRIPTION_ID = "your-subscription-id"
$env:AZURE_TENANT_ID = "your-tenant-id"
$env:DEPLOYMENT_SUFFIX = "abc123"  # Unique suffix for resources
```

## 📖 Documentation Guide

**Start here:**
1. [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Overview and roadmap
2. [AZURE_MIGRATION_PLAN.md](AZURE_MIGRATION_PLAN.md) - Detailed migration strategy
3. [azure/DEPLOYMENT_GUIDE.md](azure/DEPLOYMENT_GUIDE.md) - Deployment steps

**For developers:**
- [AZURE_CODE_CHANGES.md](AZURE_CODE_CHANGES.md) - Code modifications needed
- [ContosoUniversity/Azure/](ContosoUniversity/Azure/) - Azure service implementations

**For operations:**
- [OPERATIONAL_GUIDE.md](OPERATIONAL_GUIDE.md) - Operations and troubleshooting
- [azure/bicep/](azure/bicep/) - Infrastructure templates

**For DevOps:**
- [.github/workflows/](github/workflows/) - CI/CD pipelines
- [azure/DEPLOYMENT_GUIDE.md](azure/DEPLOYMENT_GUIDE.md) - Deployment procedures

## 🔐 Security Considerations

### Key Security Features

✅ **Key Vault Integration** - Centralized secret management  
✅ **Managed Identity** - No credential hardcoding  
✅ **TLS/SSL Encryption** - All connections encrypted  
✅ **Firewall Rules** - Database and storage access control  
✅ **Audit Logging** - All administrative actions logged  
✅ **Role-Based Access Control** - Granular permissions  

### Secrets Management

Sensitive configuration is stored in Azure Key Vault:
- Database connection strings
- Storage account keys
- Service Bus connection strings
- API keys and credentials

⚠️ **IMPORTANT**: Never commit secrets to source control!

## 💰 Cost Estimates

### Monthly Costs (Recurring)

| Environment | Estimated Cost |
|-------------|-----------------|
| Development | ~$100/month |
| Staging | ~$200/month |
| Production | ~$450/month |
| **Total** | **~$750/month** |

*See IMPLEMENTATION_SUMMARY.md for detailed breakdown*

## 🧪 Testing

### Pre-Deployment Testing
```powershell
# Validate Bicep templates
az bicep build --file azure/bicep/main.bicep

# Test infrastructure deployment (dev)
az deployment group what-if `
  --resource-group contosouniversity-dev-rg `
  --template-file azure/bicep/main.bicep `
  --parameters azure/bicep/main.dev.bicepparam
```

### Post-Deployment Testing
```powershell
# Health check
$url = "https://contosouniversity-app-dev-<suffix>.azurewebsites.net/api/health"
Invoke-WebRequest -Uri $url

# Database connectivity
# ... use SQL Server Management Studio
```

## 🚨 Monitoring & Alerts

### Key Metrics to Monitor
- CPU usage
- Memory usage
- Database DTU
- Request failures
- Response time
- Exception rate

### Setting Up Alerts

Alerts are configured in the Application Insights template. After deployment:

1. Go to Azure Portal
2. Navigate to Application Insights resource
3. Select "Alerts" in left menu
4. Create alert rules as needed

## 🔄 CI/CD Pipeline

### Automated Deployments

Push to branches triggers automatic deployment:
- `main` → Production deployment
- `develop` → Development deployment

### Manual Deployment

```powershell
# Deploy to specific environment
gh workflow run deploy-azure.yml -f environment=prod
```

## 🆘 Troubleshooting

### Common Issues

**Application won't start**
```powershell
# Check logs
az webapp log show --name "contosouniversity-app-prod-<suffix>" `
  --resource-group contosouniversity-prod-rg

# Check configuration
az webapp config show --name "contosouniversity-app-prod-<suffix>" `
  --resource-group contosouniversity-prod-rg
```

**Database connection fails**
```powershell
# Verify firewall rules
az sql server firewall-rule list --server "contosouniversity-sql-prod-<suffix>" `
  --resource-group contosouniversity-prod-rg

# Check connection string
az keyvault secret show --vault-name "contosouniversity-kv-prod-<suffix>" `
  --name "SqlDatabaseConnectionString"
```

See [OPERATIONAL_GUIDE.md](OPERATIONAL_GUIDE.md) for more troubleshooting steps.

## 📞 Support

### Getting Help

1. **Documentation** - Review relevant guide based on your role
2. **Bicep Validation** - `az bicep build --file <file>`
3. **Azure CLI Help** - `az <command> --help`
4. **Azure Docs** - https://learn.microsoft.com/azure/

### Escalation Path

1. Team member → Technical Lead (1 hour)
2. Technical Lead → Project Manager (2 hours)
3. Project Manager → Management (4 hours)

## 🎓 Learning Resources

- [Azure for .NET Developers](https://learn.microsoft.com/dotnet/azure/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [SQL Database Best Practices](https://learn.microsoft.com/azure/azure-sql/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)

## 📝 License

[Your License Here]

## 👥 Contributing

Guidelines for contributing to this migration package:

1. Follow Azure naming conventions
2. Include inline documentation
3. Test all changes in dev environment
4. Submit pull request for review
5. Update documentation as needed

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12-03 | Initial release |

## 📌 Checklist Before Starting

- [ ] Azure subscription ready
- [ ] Permissions configured (subscription owner or contributor)
- [ ] Azure CLI installed and authenticated
- [ ] PowerShell 7+ installed
- [ ] Team trained on migration plan
- [ ] Backup of on-premises systems created
- [ ] Maintenance window scheduled
- [ ] Stakeholders notified
- [ ] DNS provider access available (if custom domain)
- [ ] Support team on standby

## 🎯 Success Criteria

- ✅ All services deployed and healthy
- ✅ Application accessible and functional
- ✅ Data migrated successfully
- ✅ Monitoring and alerts active
- ✅ CI/CD pipeline working
- ✅ Performance meets or exceeds baseline
- ✅ Zero data loss
- ✅ Team trained
- ✅ Documentation current
- ✅ Cost within budget

---

**Ready to migrate? Start with [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)**

For questions, refer to the appropriate guide or contact your migration team.
