// Azure Key Vault Module
// Stores secrets, connection strings, and API keys

param location string
param keyVaultName string
param environment string

@allowed([
  'dev'
  'staging'
  'prod'
])
param accessPolicy string = 'default'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
    purpose: 'SecretManagement'
  }
}

// Storage for Application Insights Connection String (placeholder)
resource appInsightsSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AppInsightsConnectionString'
  parent: keyVault
  properties: {
    value: 'InstrumentationKey=PLACEHOLDER;'
  }
}

// Storage for SQL Connection String (placeholder)
resource sqlConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'SqlDatabaseConnectionString'
  parent: keyVault
  properties: {
    value: 'Server=PLACEHOLDER;Database=ContosoUniversity;'
  }
}

// Storage for Service Bus Connection String (placeholder)
resource serviceBusSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'ServiceBusConnectionString'
  parent: keyVault
  properties: {
    value: 'Endpoint=sb://PLACEHOLDER/;'
  }
}

// Storage for Storage Account Key (placeholder)
resource storageAccountKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'StorageAccountKey'
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;PLACEHOLDER;'
  }
}

output vaultUri string = keyVault.properties.vaultUri
output vaultName string = keyVault.name
output resourceId string = keyVault.id
