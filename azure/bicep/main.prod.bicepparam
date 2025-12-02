// Parameter file for production environment
// Usage: az deployment group create --resource-group contosouniversity-prod-rg --template-file main.bicep --parameters main.prod.bicepparam

using './main.bicep'

param location = 'eastus'
param environment = 'prod'
param projectName = 'contosouniversity'
param appServicePlanSku = 'P1V2'
param sqlDatabaseSku = 'S2'
