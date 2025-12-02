// Azure App Service Module
// Hosts the ASP.NET 4.8 MVC application

param location string
param appServicePlanName string
param webAppName string
param appServicePlanSku string = 'S1'
param environment string
param appInsightsInstrumentationKey string
param sqlDatabaseConnectionString string
param storageAccountName string
param storageAccountKey string
param serviceBusConnectionString string
param keyVaultUri string

// App Service Plan (Windows)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'windows'
  sku: {
    name: appServicePlanSku
    capacity: (environment == 'prod') ? 2 : 1
  }
  properties: {
    reserved: false
    isLinux: false
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    httpsOnly: true
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Application Settings
resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  parent: webApp
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: true
    detailedErrorLoggingEnabled: true
    publishingUsername: 'webAppUser'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: true
    autoHealRules: {
      triggers: {
        statusCodes: [
          {
            status: 500
            subStatus: 0
            count: 10
            timeInterval: '00:01:00'
          }
        ]
      }
      actions: {
        actionType: 'Recycle'
        minProcessExecutionTime: '00:01:00'
      }
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.0'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    fileChangeAuditEnabled: false
    functionAppScaleLimit: 0
    healthCheckPath: '/api/health'
    fileChangeAuditEnabled: false
    websiteTimeZone: 'UTC'
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

// Application Configuration Settings
resource siteAppSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsInstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${appInsightsInstrumentationKey}'
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'recommended'
    ASPNETCORE_ENVIRONMENT: environment
  }
}

// Connection Strings
resource connectionStrings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'connectionstrings'
  parent: webApp
  properties: {
    DefaultConnection: {
      value: sqlDatabaseConnectionString
      type: 'SQLServer'
    }
    AzureWebJobsStorage: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=core.windows.net'
      type: 'Custom'
    }
    ServiceBusConnectionString: {
      value: serviceBusConnectionString
      type: 'Custom'
    }
    KeyVaultUri: {
      value: keyVaultUri
      type: 'Custom'
    }
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostics'
  scope: webApp
  properties: {
    workspaceId: ''
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Auto-scale Settings (for production)
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2015-04-01' = if (environment == 'prod') {
  name: '${webAppName}-autoscale'
  location: location
  properties: {
    profiles: [
      {
        name: 'Auto scale based on CPU'
        capacity: {
          minimum: '2'
          maximum: '5'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: appServicePlan.id
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output principalId string = webApp.identity.principalId
