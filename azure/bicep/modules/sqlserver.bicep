// Azure SQL Server and Database Module

param location string
param sqlServerName string
param sqlDatabaseName string
param sqlDatabaseSku string = 'S0'
param environment string

// Generate secure admin password (in production, use Key Vault)
var adminUsername = 'sqladmin'
var adminPassword = uniqueString(resourceGroup().id, 'sql') // Not secure for production

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Firewall Rule - Allow Azure Services
resource firewallRuleAllowAzureServices 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall Rule - Allow specific IP (configure as needed)
resource firewallRuleClientIp 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  name: 'AllowClientIp'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: sqlDatabaseName
  parent: sqlServer
  location: location
  sku: {
    name: sqlDatabaseSku
    tier: getSqlTier(sqlDatabaseSku)
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368 // 32 GB
    storageAccountType: 'GRS'
    zoneRedundant: false
    isLedgerOn: false
    readScale: 'Disabled'
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Transparent Data Encryption
resource transparentDataEncryption 'Microsoft.Sql/servers/databases/transparentDataEncryption@2022-05-01-preview' = {
  name: 'current'
  parent: sqlDatabase
  properties: {
    state: 'Enabled'
  }
}

// Database Backup Long Term Retention
resource longTermBackupRetention 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    weeklyRetention: 'PT4W' // 4 weeks
    monthlyRetention: 'PT12M' // 12 months
    yearlyRetention: 'PT7Y' // 7 years
    weekOfYear: 1
  }
}

// Diagnostic Settings for SQL Database
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDatabaseName}-diagnostics'
  scope: sqlDatabase
  properties: {
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
      }
      {
        category: 'WorkloadManagement'
        enabled: true
      }
    ]
  }
}

// Helper function to get SQL tier based on SKU
function getSqlTier(sku string) string => {
  if (startsWith(sku, 'S')) {
    return 'Standard'
  } else if (startsWith(sku, 'P')) {
    return 'Premium'
  } else if (startsWith(sku, 'BC')) {
    return 'BusinessCritical'
  } else if (startsWith(sku, 'GP')) {
    return 'GeneralPurpose'
  } else if (startsWith(sku, 'HS')) {
    return 'Hyperscale'
  } else {
    return 'Standard'
  }
}

output serverName string = sqlServer.name
output databaseName string = sqlDatabase.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Persist Security Info=False;User ID=${adminUsername};Password=${adminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
