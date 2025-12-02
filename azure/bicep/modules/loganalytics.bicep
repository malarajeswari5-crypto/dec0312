// Azure Log Analytics Module
// Centralized logging and analytics

param location string
param logAnalyticsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      searchVersion: 1
      legacy: 0
      immediatePurgeDataOn30Days: false
    }
    workspaceCapping: {
      dailyQuotaGb: 10
    }
  }

  tags: {
    project: 'ContosoUniversity'
    environment: 'shared'
  }
}

// Solution - Application Insights Analytics
resource analyticsAdSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ApplicationInsights(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'ApplicationInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ApplicationInsights'
    promotionCode: ''
  }
}

// Data Source - Event Log (Windows)
resource eventLogDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  name: 'EventLog-Application'
  parent: logAnalyticsWorkspace
  kind: 'WindowsEvent'
  properties: {
    eventLogName: 'Application'
    eventTypes: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
}

// Data Source - Performance Counters
resource performanceCounterDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  name: 'PerfCounter'
  parent: logAnalyticsWorkspace
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Processor'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Processor Time'
  }
}

// Data Source - Processor Time
resource processorCounterDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  name: 'PerfCounter-ProcessorTime'
  parent: logAnalyticsWorkspace
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Committed Bytes In Use'
  }
}

// Saved Search - Application Errors
resource savedSearchErrors 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  name: 'ContosoUniversity-ApplicationErrors'
  parent: logAnalyticsWorkspace
  properties: {
    category: 'ContosoUniversity'
    displayName: 'Application Errors'
    query: 'traces | where severityLevel >= 2 | summarize Count = count() by tostring(customDimensions.Category)'
    version: 1
  }
}

// Saved Search - Performance Issues
resource savedSearchPerformance 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  name: 'ContosoUniversity-PerformanceIssues'
  parent: logAnalyticsWorkspace
  properties: {
    category: 'ContosoUniversity'
    displayName: 'Performance Issues'
    query: 'requests | where duration > 3000 | summarize AvgDuration = avg(duration), Count = count() by name'
    version: 1
  }
}

// Alert Rule - High Error Rate
resource alertRuleHighErrorRate 'Microsoft.OperationalInsights/workspaces/providers/alertRules@2022-06-15' = {
  name: 'ContosoUniversity-HighErrorRate'
  parent: logAnalyticsWorkspace.provider('Microsoft.AlertsManagement')
  properties: {
    description: 'Alert when error rate is high'
    severity: 2
    enabled: true
    condition: {
      allOf: [
        {
          query: 'traces | where severityLevel >= 2 | summarize count() by bin(TimeGenerated, 5m)'
          operator: 'GreaterThan'
          threshold: 50
          timeAggregationOperator: 'Total'
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: []
  }
}

output workspaceId string = logAnalyticsWorkspace.properties.customerId
output workspaceKey string = listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
output resourceId string = logAnalyticsWorkspace.id
