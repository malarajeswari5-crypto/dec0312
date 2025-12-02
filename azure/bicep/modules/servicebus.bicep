// Azure Service Bus Module
// For notification messaging system (replaces MSMQ)

param location string
param serviceBusNamespaceName string
param environment string

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: (environment == 'prod') ? 'Premium' : 'Standard'
    tier: (environment == 'prod') ? 'Premium' : 'Standard'
    capacity: (environment == 'prod') ? 4 : 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: (environment == 'prod') ? true : false
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Notification Queue
resource notificationQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: 'notifications'
  parent: serviceBusNamespace
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT23H59M59.9999999S'
    enablePartitioning: true
    enableExpress: false
    enableBatchedOperations: true
    status: 'Active'
    forwardTo: ''
    forwardDeadLetteredMessagesTo: ''
  }
}

// Email Notification Queue
resource emailNotificationQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: 'email-notifications'
  parent: serviceBusNamespace
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P7D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 3
    autoDeleteOnIdle: 'P10675199DT23H59M59.9999999S'
    enablePartitioning: true
    enableExpress: false
    enableBatchedOperations: true
    status: 'Active'
  }
}

// Authorization Rule for Listening
resource listenAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  name: 'listen'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

// Authorization Rule for Queue
resource queueAuthRule 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2022-01-01-preview' = {
  name: 'RootManageSharedAccessKey'
  parent: notificationQueue
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serviceBusNamespaceName}-diagnostics'
  scope: serviceBusNamespace
  properties: {
    logs: [
      {
        category: 'OperationalLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
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
  }
}

output namespaceName string = serviceBusNamespace.name
output connectionString string = listkeys(listenAuthRule.id, serviceBusNamespace.apiVersion).primaryConnectionString
output notificationQueueName string = notificationQueue.name
