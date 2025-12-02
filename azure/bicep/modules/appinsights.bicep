// Azure Application Insights Module
// Application monitoring and diagnostics

param location string
param appInsightsName string
param logAnalyticsResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'IbizaWebAppExtensionCreate'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsResourceId
    IngestionMode: 'LogAnalytics'
  }

  tags: {
    project: 'ContosoUniversity'
    environment: 'shared'
  }
}

// Availability Test
resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: '${appInsightsName}-availability-test'
  location: location
  kind: 'ping'
  properties: {
    Name: 'Home Page Availability'
    Description: 'Check home page availability'
    Enabled: true
    Frequency: 300
    Timeout: 120
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      {
        Id: 'us-tx-sn1-azr'
      }
      {
        Id: 'us-ca-sjc-azr'
      }
      {
        Id: 'us-il-ch1-azr'
      }
      {
        Id: 'us-va-ash-azr'
      }
      {
        Id: 'us-fl-mia-edge'
      }
    ]
    SyntheticMonitorId: appInsightsName
    Configuration: {
      WebTest: '<WebTest   Name="PLACEHOLDER"   Enabled="True"   CssProjectStructure=""   CssIteration=""   Timeout="120"   WorkItemIds=""   xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"   Description=""   CredentialUserName=""   CredentialPassword=""   PreAuthenticate="True"   Proxy="default"   StopOnFailure="False"   RecordedResultFile=""   ResultsLocale=""><Items><Request   Method="GET"   Guid="a6fa7a0b-6e87-4324-85dd-0e1f7f5f9e8a"   Version="1.1"   Url="PLACEHOLDER"   ThinkTime="0"   Timeout="300"   ParseDependentRequests="True"   FollowRedirects="True"   RecordResult="True"   Cache="False"   ResponseTimeGoal="0"   Encoding="utf-8"   ExpectedHttpStatusCode="200"   ExpectedResponseUrl=""   ReportingName=""   IgnoreHttpStatusCode="False"   /></Items></WebTest>'
    }
  }

  tags: {
    project: 'ContosoUniversity'
    environment: 'shared'
  }
}

// Metric Alert for Failed Requests
resource failedRequestsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appInsightsName}-failed-requests'
  location: 'global'
  properties: {
    description: 'Alert when failed request rate is high'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailedRequests'
          metricName: 'failed/count'
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Total'
          dimensions: []
        }
      ]
    }
    actions: []
  }

  tags: {
    project: 'ContosoUniversity'
  }
}

// Metric Alert for High Response Time
resource highResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appInsightsName}-high-response-time'
  location: 'global'
  properties: {
    description: 'Alert when response time is high'
    severity: 3
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 3000
          timeAggregation: 'Average'
          dimensions: []
        }
      ]
    }
    actions: []
  }

  tags: {
    project: 'ContosoUniversity'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output appId string = appInsights.properties.AppId
output resourceId string = appInsights.id
