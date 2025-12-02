# Azure Deployment Scripts

This directory contains PowerShell scripts for deploying the Contoso University application to Azure.

## Prerequisites

1. Install Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
2. Install PowerShell 7+: https://github.com/PowerShell/PowerShell
3. Authenticate with Azure:
   ```powershell
   az login
   az account set --subscription "Your Subscription Name"
   ```

## Deployment Steps

### 1. Create Resource Groups

```powershell
# Development
az group create --name contosouniversity-dev-rg --location eastus

# Staging
az group create --name contosouniversity-staging-rg --location eastus

# Production
az group create --name contosouniversity-prod-rg --location eastus
```

### 2. Deploy Infrastructure

#### Development Environment
```powershell
az deployment group create `
  --name "contosouniversity-dev-deployment" `
  --resource-group "contosouniversity-dev-rg" `
  --template-file "bicep/main.bicep" `
  --parameters "bicep/main.dev.bicepparam"
```

#### Staging Environment
```powershell
az deployment group create `
  --name "contosouniversity-staging-deployment" `
  --resource-group "contosouniversity-staging-rg" `
  --template-file "bicep/main.bicep" `
  --parameters "bicep/main.staging.bicepparam"
```

#### Production Environment
```powershell
az deployment group create `
  --name "contosouniversity-prod-deployment" `
  --resource-group "contosouniversity-prod-rg" `
  --template-file "bicep/main.bicep" `
  --parameters "bicep/main.prod.bicepparam"
```

### 3. Configure Secrets in Key Vault

After deployment, update Key Vault secrets with actual values:

```powershell
# Get the Key Vault name from deployment output
$keyVaultName = "contosouniversity-kv-dev-<unique-suffix>"

# Update SQL Database Connection String
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "SqlDatabaseConnectionString" `
  --value "Server=tcp:contosouniversity-sql-dev-<suffix>.database.windows.net,1433;Initial Catalog=ContosoUniversity;Persist Security Info=False;User ID=sqladmin;Password=YourSecurePassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Update Storage Account Key
$storageAccountName = "contosouniversityst<suffix>"
$storageKey = az storage account keys list --resource-group contosouniversity-dev-rg --account-name $storageAccountName --query "[0].value" -o tsv
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "StorageAccountKey" `
  --value "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageKey;EndpointSuffix=core.windows.net"

# Update Service Bus Connection String
$serviceBusName = "contosouniversity-sb-dev-<suffix>"
$serviceBusCS = az servicebus namespace authorization-rule keys list --resource-group contosouniversity-dev-rg --namespace-name $serviceBusName --name listen --query "primaryConnectionString" -o tsv
az keyvault secret set `
  --vault-name $keyVaultName `
  --name "ServiceBusConnectionString" `
  --value $serviceBusCS
```

### 4. Migrate Database

1. Create database backup from on-premises SQL Server
2. Upload backup to Azure Storage
3. Restore database to Azure SQL:

```powershell
# Using Azure Data Studio or SSMS
# Or use Azure DMS for online migration
```

### 5. Migrate File Uploads

```powershell
# Using AzCopy to migrate existing files
$storageAccountName = "contosouniversityst<suffix>"
$storageKey = az storage account keys list --resource-group contosouniversity-dev-rg --account-name $storageAccountName --query "[0].value" -o tsv

# Download AzCopy if not already installed
# https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10

# Copy existing uploads to Azure Blob Storage
azcopy copy "C:\Path\To\Uploads\*" `
  "https://$storageAccountName.blob.core.windows.net/teaching-materials" `
  --recursive `
  --from-to LocalBlob
```

### 6. Deploy Application

See CI/CD pipeline documentation for automated deployment.

## Verification

```powershell
# Get deployment outputs
az deployment group show `
  --name "contosouniversity-dev-deployment" `
  --resource-group "contosouniversity-dev-rg" `
  --query "properties.outputs"

# Check App Service health
az webapp show --name "contosouniversity-app-dev-<suffix>" --resource-group "contosouniversity-dev-rg"

# Check SQL Database
az sql db show --name "ContosoUniversity" --server "contosouniversity-sql-dev-<suffix>" --resource-group "contosouniversity-dev-rg"

# Monitor application
az monitor metrics list `
  --resource "/subscriptions/{subscriptionId}/resourceGroups/contosouniversity-dev-rg/providers/Microsoft.Web/sites/contosouniversity-app-dev-<suffix>" `
  --metric "CpuTime" `
  --interval PT5M `
  --start-time 2024-01-01T00:00:00Z
```

## Cleanup

To delete all resources:

```powershell
# Development
az group delete --name contosouniversity-dev-rg --yes --no-wait

# Staging
az group delete --name contosouniversity-staging-rg --yes --no-wait

# Production
az group delete --name contosouniversity-prod-rg --yes --no-wait
```

## Troubleshooting

### Deployment Fails
```powershell
# View detailed error
az deployment group show --name "deployment-name" --resource-group "rg-name" --query "properties.error"
```

### Connection String Issues
```powershell
# Verify connection string format
az sql server show --name "server-name" --resource-group "rg-name" --query "fullyQualifiedDomainName"
```

### Key Vault Access Issues
```powershell
# Grant App Service access to Key Vault
$webAppPrincipalId = az webapp identity show --name "app-name" --resource-group "rg-name" --query "principalId" -o tsv
az keyvault set-policy --name "kv-name" --object-id $webAppPrincipalId --secret-permissions get list
```

## References

- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/sql-database-paas-overview)
