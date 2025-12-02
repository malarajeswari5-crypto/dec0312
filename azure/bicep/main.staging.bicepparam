// Parameter file for staging environment
// Usage: az deployment group create --resource-group contosouniversity-staging-rg --template-file main.bicep --parameters main.staging.bicepparam

using './main.bicep'

param location = 'eastus'
param environment = 'staging'
param projectName = 'contosouniversity'
param appServicePlanSku = 'S2'
param sqlDatabaseSku = 'S1'
