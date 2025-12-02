# Operational Guide for Contoso University on Azure

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Deployment Procedures](#deployment-procedures)
4. [Monitoring and Alerts](#monitoring-and-alerts)
5. [Troubleshooting](#troubleshooting)
6. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
7. [Security Operations](#security-operations)
8. [Performance Tuning](#performance-tuning)
9. [Cost Management](#cost-management)
10. [Runbooks](#runbooks)

---

## Overview

Contoso University is deployed on Azure as a distributed application using:
- **Azure App Service** for web hosting
- **Azure SQL Database** for data storage
- **Azure Storage** for file uploads
- **Azure Service Bus** for notifications
- **Application Insights** for monitoring
- **Azure Key Vault** for secrets management

---

## Architecture

### Resource Groups

```
contosouniversity-dev-rg      (Development environment)
contosouniversity-staging-rg  (Staging environment)
contosouniversity-prod-rg     (Production environment)
```

### Network Architecture

```
                    ┌─────────────────────┐
                    │  Azure Front Door   │
                    │  / CDN              │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ App Service Plan    │
                    │ (Windows, .NET 4.8) │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   ┌────▼──────┐    ┌─────────▼────────┐    ┌──────▼─────┐
   │  SQL DB   │    │ Storage Account  │    │ Key Vault  │
   │           │    │                  │    │            │
   │ - Data    │    │ - File Uploads   │    │ - Secrets  │
   │ - Schema  │    │ - Backups        │    │ - Certs    │
   └────┬──────┘    └─────────┬────────┘    └──────┬─────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Service Bus        │
                    │ (Notifications)    │
                    └────────────────────┘
```

---

## Deployment Procedures

### Pre-Deployment Checklist

- [ ] Review changes in pull request
- [ ] Verify all tests pass
- [ ] Check for breaking changes
- [ ] Review database migrations
- [ ] Update documentation
- [ ] Verify Key Vault secrets are configured
- [ ] Check connectivity to Azure services

### Deployment Steps

#### Manual Deployment

```powershell
# 1. Authenticate to Azure
az login
az account set --subscription "Your Subscription"

# 2. Deploy infrastructure (if needed)
az deployment group create `
  --name "contosouniversity-deployment" `
  --resource-group "contosouniversity-prod-rg" `
  --template-file "azure/bicep/main.bicep" `
  --parameters "azure/bicep/main.prod.bicepparam"

# 3. Deploy application
az webapp deployment source config-zip `
  --resource-group "contosouniversity-prod-rg" `
  --name "contosouniversity-app-prod-<suffix>" `
  --src "path/to/application.zip"

# 4. Verify deployment
$appUrl = "https://contosouniversity-app-prod-<suffix>.azurewebsites.net/api/health"
Invoke-WebRequest -Uri $appUrl
```

#### Automated Deployment (GitHub Actions)

```powershell
# Push to main branch triggers automated deployment
git push origin main

# Or manually trigger workflow
gh workflow run deploy-azure.yml -f environment=prod
```

### Rollback Procedures

```powershell
# If deployment fails, swap slots back to previous version
az webapp deployment slot swap `
  --resource-group "contosouniversity-prod-rg" `
  --name "contosouniversity-app-prod-<suffix>" `
  --slot "staging"
```

---

## Monitoring and Alerts

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Usage | > 70% for 5 min | Scale up |
| Memory Usage | > 80% for 5 min | Investigate |
| Failed Requests | > 1% | Check logs |
| Response Time | > 3 seconds avg | Investigate |
| Database DTU | > 80% | Scale up |

### Viewing Logs

#### Application Insights

```powershell
# Query failed requests
az monitor app-insights metrics show `
  --app "contosouniversity-ai-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg" `
  --metric "requests/failed"

# Query exceptions
az monitor app-insights events show `
  --app "contosouniversity-ai-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"
```

#### Azure Portal

1. Go to **Application Insights** resource
2. Select **Performance**, **Failures**, or **Logs** tab
3. Use KQL queries to analyze data

#### Log Analytics

```kusto
// Query failed requests
requests
| where success == false
| summarize count() by resultCode, name
| order by count_ desc

// Query slow requests
requests
| where duration > 3000
| summarize AvgDuration=avg(duration), Count=count() by name
| order by AvgDuration desc

// Query exceptions
exceptions
| summarize count() by outerMessage
| order by count_ desc
```

### Setting Up Alerts

```powershell
# High CPU alert
az monitor metrics alert create `
  --resource-group "contosouniversity-prod-rg" `
  --name "HighCpuAlert" `
  --scopes "/subscriptions/{subId}/resourceGroups/contosouniversity-prod-rg/providers/Microsoft.Web/serverfarms/contosouniversity-asp-prod-<suffix>" `
  --condition "avg Percentage CPU > 70" `
  --window-size 5m `
  --evaluation-frequency 1m

# Database DTU alert
az monitor metrics alert create `
  --resource-group "contosouniversity-prod-rg" `
  --name "HighDtuAlert" `
  --scopes "/subscriptions/{subId}/resourceGroups/contosouniversity-prod-rg/providers/Microsoft.Sql/servers/contosouniversity-sql-prod-<suffix>/databases/ContosoUniversity" `
  --condition "avg dtu_consumption_percent > 80" `
  --window-size 5m `
  --evaluation-frequency 1m
```

---

## Troubleshooting

### Application Not Starting

```powershell
# Check App Service status
az webapp show --name "contosouniversity-app-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg" `
  --query "state"

# View deployment logs
az webapp deployment logs show --name "contosouniversity-app-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"

# Check web server logs
az storage blob download `
  --container-name "application-logs" `
  --name "RD*.log" `
  --account-name "contosouniversityststorage" `
  --output file
```

### Database Connection Issues

```powershell
# Verify firewall rules
az sql server firewall-rule list --server "contosouniversity-sql-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"

# Verify database exists
az sql db show --server "contosouniversity-sql-prod-<suffix>" `
  --name "ContosoUniversity" `
  --resource-group "contosouniversity-prod-rg"

# Check connection string
az keyvault secret show --vault-name "contosouniversity-kv-prod-<suffix>" `
  --name "SqlDatabaseConnectionString"
```

### Storage Access Issues

```powershell
# Verify storage account exists
az storage account show --name "contosouniversityst<suffix>" `
  --resource-group "contosouniversity-prod-rg"

# Check container permissions
az storage container show-permission --name "teaching-materials" `
  --account-name "contosouniversityst<suffix>"

# Verify storage key in Key Vault
az keyvault secret show --vault-name "contosouniversity-kv-prod-<suffix>" `
  --name "StorageAccountKey"
```

### Service Bus Issues

```powershell
# Check namespace health
az servicebus namespace show --name "contosouniversity-sb-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"

# List queues
az servicebus queue list --namespace-name "contosouniversity-sb-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"

# Check queue status
az servicebus queue show --name "notifications" `
  --namespace-name "contosouniversity-sb-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"
```

---

## Backup and Disaster Recovery

### Database Backup Strategy

**Automatic Backups:**
- Daily backups: 7 days retention
- Weekly backups: 4 weeks retention
- Monthly backups: 12 months retention
- Yearly backups: 7 years retention

**Manual Backups:**

```powershell
# Create manual backup
az sql db export --resource-group "contosouniversity-prod-rg" `
  --server "contosouniversity-sql-prod-<suffix>" `
  --name "ContosoUniversity" `
  --admin-user "sqladmin" `
  --admin-password "your-password" `
  --storage-key "your-storage-key" `
  --storage-key-type "StorageAccessKey" `
  --storage-uri "https://storage.blob.core.windows.net/backups/backup.bacpac"
```

### Database Restoration

```powershell
# Restore from backup
az sql db import --resource-group "contosouniversity-prod-rg" `
  --server "contosouniversity-sql-prod-<suffix>" `
  --name "ContosoUniversity-Restored" `
  --admin-user "sqladmin" `
  --admin-password "your-password" `
  --storage-key "your-storage-key" `
  --storage-key-type "StorageAccessKey" `
  --storage-uri "https://storage.blob.core.windows.net/backups/backup.bacpac"
```

### Point-in-Time Restore

```powershell
# Restore to point in time
$restorePoint = (Get-Date).AddHours(-2)  # 2 hours ago

az sql db restore --resource-group "contosouniversity-prod-rg" `
  --server "contosouniversity-sql-prod-<suffix>" `
  --name "ContosoUniversity-Restored" `
  --restore-point-in-time $restorePoint `
  --source-database "ContosoUniversity"
```

### Disaster Recovery Plan

**RTO (Recovery Time Objective): 1 hour**
**RPO (Recovery Point Objective): 15 minutes**

1. **Detection**: Monitor Application Insights alerts
2. **Assessment**: Check Azure Service Health
3. **Communication**: Notify stakeholders
4. **Recovery**:
   - Switch to secondary region (if configured)
   - Restore database from backup
   - Deploy application to new App Service
   - Update DNS records
5. **Verification**: Run health checks
6. **Post-Incident**: Document and review

---

## Security Operations

### Access Control

```powershell
# Grant user access to Key Vault
az keyvault set-policy --name "contosouniversity-kv-prod-<suffix>" `
  --object-id "{user-object-id}" `
  --secret-permissions get list set delete

# Grant App Service access to Key Vault
$webAppPrincipalId = az webapp identity show `
  --name "contosouniversity-app-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg" `
  --query "principalId" -o tsv

az keyvault set-policy --name "contosouniversity-kv-prod-<suffix>" `
  --object-id $webAppPrincipalId `
  --secret-permissions get list
```

### Secret Rotation

```powershell
# Rotate database password
# 1. Generate new password
$newPassword = "NewSecurePassword$(Get-Random)"

# 2. Update SQL Server
az sql server update --name "contosouniversity-sql-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg" `
  --admin-password $newPassword

# 3. Update Key Vault
$newConnectionString = "Server=tcp:contosouniversity-sql-prod-<suffix>.database.windows.net,1433;Initial Catalog=ContosoUniversity;Persist Security Info=False;User ID=sqladmin;Password=$newPassword;..."

az keyvault secret set --vault-name "contosouniversity-kv-prod-<suffix>" `
  --name "SqlDatabaseConnectionString" `
  --value $newConnectionString

# 4. Restart App Service to pick up new connection string
az webapp restart --name "contosouniversity-app-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg"
```

### Audit Logging

```kusto
// Query administrative operations
AzureActivity
| where OperationName contains "Create" or OperationName contains "Update" or OperationName contains "Delete"
| where ResourceGroup contains "contosouniversity"
| summarize count() by Caller, OperationName, TimeGenerated
| order by TimeGenerated desc

// Query Key Vault access
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName contains "Secret"
| summarize count() by CallerIPAddress, Operation
```

---

## Performance Tuning

### Database Performance

```sql
-- Enable Query Store
ALTER DATABASE ContosoUniversity SET QUERY_STORE = ON;

-- Check slow queries
SELECT query_id, execution_count, total_elapsed_time
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
ORDER BY total_elapsed_time DESC;

-- Check table statistics
DBCC SHOW_STATISTICS (Student, 'IX_Student_LastName');

-- Update statistics
UPDATE STATISTICS Student;
```

### Application Performance

```csharp
// Enable caching in controllers
[OutputCache(Duration = 300)]  // Cache for 5 minutes
public ActionResult Index()
{
    return View();
}

// Use async/await
public async Task<ActionResult> Details(int id)
{
    var student = await db.Students.FindAsync(id);
    return View(student);
}

// Implement pagination
var students = await db.Students
    .OrderBy(s => s.LastName)
    .Skip((pageNumber - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();
```

### App Service Scaling

```powershell
# Increase instance count
az appservice plan update --name "contosouniversity-asp-prod-<suffix>" `
  --resource-group "contosouniversity-prod-rg" `
  --number-of-workers 3

# Configure auto-scale
az monitor autoscale create --name "cpu-auto-scale" `
  --resource-group "contosouniversity-prod-rg" `
  --resource "/subscriptions/{subId}/resourceGroups/contosouniversity-prod-rg/providers/Microsoft.Web/serverfarms/contosouniversity-asp-prod-<suffix>" `
  --min-count 2 `
  --max-count 5 `
  --count 2
```

---

## Cost Management

### Cost Optimization

1. **Right-size resources**:
   - Monitor actual usage
   - Downsize during off-peak hours
   - Use reserved instances for production

2. **Database optimization**:
   - Use DTU-based pricing for predictable workloads
   - Consider vCore-based for variable workloads
   - Archive old data to Blob Storage

3. **Storage optimization**:
   - Use lifecycle policies to move old files to cool/archive tier
   - Clean up old backups

### Cost Analysis

```powershell
# Get cost estimate
az billing invoice list --resource-group "contosouniversity-prod-rg"

# Export costs for analysis
az cost-management query create `
  --definition "timePeriod={start='2024-01-01',end='2024-01-31'},granularity='Daily',filter={type='Dimension',name='ResourceGroup',operator='In',values=['/subscriptions/{subId}/resourceGroups/contosouniversity-prod-rg']}" `
  --timeframe "Custom"
```

---

## Runbooks

### Daily Operational Checklist

```
☐ Check Application Insights for errors
☐ Monitor database performance
☐ Review backup completion status
☐ Check storage usage
☐ Verify no failed deployments
☐ Monitor for security alerts
☐ Review cost trends
```

### Weekly Operational Review

```
☐ Review performance metrics
☐ Check for capacity issues
☐ Update documentation
☐ Review security posture
☐ Test backup restoration
☐ Review incident logs
☐ Plan for scaling needs
```

### Monthly Operational Review

```
☐ Capacity planning
☐ Cost analysis and optimization
☐ Security audit
☐ Performance tuning opportunities
☐ Disaster recovery drill
☐ Update runbooks
☐ Plan upgrades/patches
```

### Incident Response

**Priority 1 (Critical)**
- Response time: 15 minutes
- Escalation: Immediately to team lead
- Communication: Every 15 minutes

**Priority 2 (High)**
- Response time: 1 hour
- Escalation: To team lead if not resolved in 2 hours
- Communication: Every hour

**Priority 3 (Medium)**
- Response time: 4 hours
- Escalation: To team lead if not resolved in 8 hours
- Communication: Daily

**Priority 4 (Low)**
- Response time: Next business day
- Escalation: As needed
- Communication: Upon resolution

---

## References

- [Azure Monitor Documentation](https://learn.microsoft.com/azure/azure-monitor/)
- [Azure SQL Database Best Practices](https://learn.microsoft.com/azure/azure-sql/database/best-practices-performance)
- [Azure App Service Diagnostics](https://learn.microsoft.com/azure/app-service/overview-diagnostics)
- [Azure Backup Overview](https://learn.microsoft.com/azure/backup/backup-overview)

