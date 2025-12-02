// Azure Storage Account Module
// For file uploads and static assets

param location string
param storageAccountName string
param environment string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: (environment == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  tags: {
    environment: environment
    project: 'ContosoUniversity'
  }
}

// Blob Container for File Uploads
resource uploadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/uploads'
  properties: {
    publicAccess: 'None'
  }
}

// Blob Container for Teaching Materials
resource teachingMaterialsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/teaching-materials'
  properties: {
    publicAccess: 'Container' // Allow public read access to blobs
  }
}

// Blob Container for Static Assets (CSS, JS, etc.)
resource staticAssetsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/static-assets'
  properties: {
    publicAccess: 'Container'
  }
}

// Blob Container for Backups
resource backupContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/backups'
  properties: {
    publicAccess: 'None'
  }
}

// File Share for potential future use
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storageAccount.name}/default/application-files'
  properties: {
    shareQuota: 100
    accessTier: 'Hot'
    enabledProtocols: 'SMB'
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diagnostics'
  scope: storageAccount
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output accountName string = storageAccount.name
output accountKey string = storageAccount.listKeys().keys[0].value
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output fileEndpoint string = storageAccount.properties.primaryEndpoints.file
