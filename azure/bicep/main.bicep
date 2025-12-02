// Main Bicep template for Contoso University Azure Migration
// This template deploys all required resources for the application

param location string = resourceGroup().location
param environment string = 'dev' // dev, staging, prod
param projectName string = 'contosouniversity'
param appServicePlanSku string = 'S1' // Standard S1 for dev/test
param sqlDatabaseSku string = 'S0' // Standard S0 for dev/test

// Naming convention
var uniqueSuffix = uniqueString(resourceGroup().id)
var appServicePlanName = '${projectName}-asp-${environment}-${uniqueSuffix}'
var webAppName = '${projectName}-app-${environment}-${uniqueSuffix}'
var sqlServerName = '${projectName}-sql-${environment}-${uniqueSuffix}'
var sqlDatabaseName = 'ContosoUniversity'
var storageAccountName = '${replace(projectName, '-', '')}st${environment}${uniqueSuffix}'
var keyVaultName = '${projectName}-kv-${environment}-${uniqueSuffix}'
var serviceBusNamespaceName = '${projectName}-sb-${environment}-${uniqueSuffix}'
var appInsightsName = '${projectName}-ai-${environment}-${uniqueSuffix}'
var logAnalyticsName = '${projectName}-la-${environment}-${uniqueSuffix}'

// Modules
module keyVault './modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    location: location
    keyVaultName: keyVaultName
    environment: environment
  }
}

module logAnalytics './modules/loganalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
  }
}

module appInsights './modules/appinsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsResourceId: logAnalytics.outputs.resourceId
  }
}

module storage './modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    environment: environment
  }
}

module sqlServer './modules/sqlserver.bicep' = {
  name: 'sqlServerDeployment'
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlDatabaseSku: sqlDatabaseSku
    environment: environment
  }
}

module serviceBus './modules/servicebus.bicep' = {
  name: 'serviceBusDeployment'
  params: {
    location: location
    serviceBusNamespaceName: serviceBusNamespaceName
    environment: environment
  }
}

module appService './modules/appservice.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    appServicePlanSku: appServicePlanSku
    environment: environment
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    sqlDatabaseConnectionString: sqlServer.outputs.connectionString
    storageAccountName: storageAccountName
    storageAccountKey: storage.outputs.accountKey
    serviceBusConnectionString: serviceBus.outputs.connectionString
    keyVaultUri: keyVault.outputs.vaultUri
  }
}

// Outputs
output webAppUrl string = appService.outputs.webAppUrl
output storageAccountName string = storage.outputs.accountName
output sqlServerName string = sqlServer.outputs.serverName
output keyVaultName string = keyVault.outputs.vaultName
output appInsightsName string = appInsightsName
output appServicePlanName string = appServicePlanName
