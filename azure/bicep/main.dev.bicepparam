// Parameter file for development environment
// Usage: az deployment group create --resource-group contosouniversity-dev-rg --template-file main.bicep --parameters main.dev.bicepparam

using './main.bicep'

param location = 'eastus'
param environment = 'dev'
param projectName = 'contosouniversity'
param appServicePlanSku = 'S1'
param sqlDatabaseSku = 'S0'
