# Azure Migration Plan - Contoso University

## Executive Summary

This document outlines the comprehensive migration strategy for the Contoso University ASP.NET 4.8 MVC application to Azure. The application will be modernized while maintaining compatibility with existing functionality.

---

## 1. Current Application Assessment

### Technology Stack
- **Framework**: ASP.NET Framework 4.8 (MVC5)
- **ORM**: Entity Framework Core 3.1
- **Database**: SQL Server (LocalDB/SQL Server)
- **UI Framework**: Bootstrap 4
- **Validation**: jQuery Validate
- **Authentication**: Windows Authentication (IIS), integrated with Notification System
- **Additional Features**: Custom Notification System with MSMQ support

### Key Components
1. **Controllers**: Home, Students, Courses, Departments, Instructors, Notifications
2. **Data Models**: Students, Courses, Enrollments, Departments, Instructors, OfficeAssignments
3. **Services**: NotificationService, LoggingService
4. **Data Access**: SchoolContext with EF Core 3.1
5. **File Uploads**: Teaching Materials upload functionality

### Current Limitations & Considerations
- ASP.NET Framework 4.8 is Windows-only and cannot run on Linux
- MSMQ (Message Queue) for notifications requires Windows infrastructure
- File uploads currently stored locally
- Configuration stored in Web.config
- No containerization

---

## 2. Azure Migration Strategy

### Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Front Door / CDN                  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Azure App Service (Windows)               │
│         - Runs ASP.NET 4.8 MVC application                  │
│         - Autoscaling based on demand                       │
│         - Native support for .NET Framework                 │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐  ┌────────▼──────────┐  ┌──────▼───────────┐
│  Azure SQL DB  │  │  Azure Storage    │  │ Azure Key Vault  │
│                │  │                   │  │                  │
│ - Database     │  │ - File uploads    │  │ - Connection     │
│ - User data    │  │ - Static assets   │  │   strings        │
│ - Transactional│  │ - Media files     │  │ - API keys       │
└────────────────┘  └───────────────────┘  └──────────────────┘
        │
┌───────▼────────┐
│ Azure Service  │
│ Bus / Storage  │
│ Queue          │
│                │
│ - Notification │
│   messages     │
└────────────────┘
```

### Why Azure App Service?
- ✅ Native support for .NET Framework 4.8
- ✅ No infrastructure management (PaaS)
- ✅ Integrated deployment options (Git, Visual Studio, Azure DevOps)
- ✅ Automatic patching and updates
- ✅ Built-in autoscaling
- ✅ Application Insights integration
- ✅ Easy SSL/TLS setup
- ✅ Staging slots for zero-downtime deployments
- ✅ Microsoft Entra ID integration

---

## 3. Azure Services to Deploy

### 3.1 Azure App Service Plan & Web App
- **SKU**: Standard S1 (minimum) or Premium P1V2 (for production)
- **Instances**: Start with 1-2 instances, scale based on load
- **Runtime**: .NET Framework 4.8
- **Features**:
  - Application Settings (configuration)
  - Connection Strings
  - SSL/TLS certificates
  - Application Insights
  - Deployment slots (staging/production)

### 3.2 Azure SQL Database
- **Edition**: Standard or Premium (based on requirements)
- **Compute**: DTU-based or vCore-based
- **Features**:
  - Automatic backups (7-35 days retention)
  - Geo-replication for disaster recovery
  - Database firewall rules
  - Transparent Data Encryption (TDE)
  - Always Encrypted for sensitive data

### 3.3 Azure Storage Account
- **Tier**: Standard (Hot) or Premium based on access patterns
- **Redundancy**: LRS (Local Redundant Storage) or GRS (Geo-Redundant Storage)
- **Uses**:
  - File uploads (Blob Storage)
  - Static assets (CDN integration)
  - Media storage

### 3.4 Azure Key Vault
- **Purpose**: Secure storage for secrets and keys
- **Secrets to store**:
  - Database connection strings
  - API keys
  - Application settings (sensitive)
  - SSL certificates

### 3.5 Azure Service Bus / Storage Queue
- **Purpose**: Replace MSMQ for notification system
- **Options**:
  - Azure Service Bus (Premium messaging)
  - Azure Storage Queue (Simple, cost-effective)
- **Migration Path**: Refactor MSMQ code to use Azure Service Bus queues

### 3.6 Application Insights
- **Monitoring**: Application performance, exceptions, dependencies
- **Logging**: Application traces, events
- **Diagnostics**: Real-time troubleshooting

---

## 4. Migration Phases

### Phase 1: Preparation (Week 1)
- [ ] Create Azure Resource Group
- [ ] Set up development environment
- [ ] Plan and document configuration changes
- [ ] Identify secrets that need to move to Key Vault

### Phase 2: Infrastructure Setup (Week 1-2)
- [ ] Create Bicep templates for:
  - App Service Plan & Web App
  - Azure SQL Database
  - Storage Account
  - Key Vault
  - Service Bus
  - Application Insights
- [ ] Deploy infrastructure to dev/test environment
- [ ] Configure networking and security

### Phase 3: Application Modifications (Week 2-3)
- [ ] Migrate database to Azure SQL
- [ ] Update configuration management:
  - Remove Web.config secrets
  - Implement Key Vault integration
- [ ] Update storage paths for file uploads
- [ ] Refactor MSMQ to Azure Service Bus
- [ ] Update connection strings
- [ ] Test locally with Azure Emulator

### Phase 4: Testing & Deployment (Week 3-4)
- [ ] Set up GitHub Actions CI/CD pipeline
- [ ] Deploy to staging environment
- [ ] Load testing and performance validation
- [ ] Security testing and compliance review
- [ ] Deploy to production

### Phase 5: Post-Migration (Ongoing)
- [ ] Monitor application performance
- [ ] Optimize costs
- [ ] Implement auto-scaling policies
- [ ] Set up alerts and health checks

---

## 5. Configuration Migration Strategy

### From Web.config to Azure Key Vault

**Current Configuration:**
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Data Source=(LocalDb)\MSSQLLocalDB;Initial Catalog=ContosoUniversityNoAuthEFCore;..." />
</connectionStrings>
<appSettings>
  <add key="NotificationQueuePath" value=".\Private$\ContosoUniversityNotifications"/>
</appSettings>
```

**Migration Approach:**
1. Move all secrets to Azure Key Vault
2. Store non-sensitive settings in App Service configuration
3. Use Azure Key Vault provider in application code
4. Implement managed identity for authentication

---

## 6. Database Migration

### Strategy
1. **Create**: Azure SQL Database with same schema
2. **Backup**: Take backup of LocalDB
3. **Migrate**: Use Azure Data Studio or DMS
4. **Validate**: Verify data integrity
5. **Update**: Update connection string in App Service

### Data Validation
- Verify all tables are migrated
- Check row counts
- Validate indexes and constraints
- Test Entity Framework migrations

---

## 7. File Storage Migration

### Current: Local file system at `Uploads/TeachingMaterials/`

### New: Azure Blob Storage
- Create container in Storage Account
- Update application code to use `CloudBlockBlob` or Azure SDK
- Migrate existing files using AzCopy or Storage Explorer
- Update URLs to use Blob Storage

---

## 8. Notification System Refactoring

### Current: MSMQ (Not supported in App Service)

### Options:

#### Option A: Azure Service Bus (Recommended)
- Fully managed message queue
- Native .NET SDK support
- Enterprise features (transactions, dead-letter queue)
- Better monitoring and scaling

#### Option B: Azure Storage Queue
- Simpler alternative
- Lower cost
- Works well for simple async tasks

#### Implementation:
```csharp
// Replace MSMQ references with Azure Service Bus
var client = new ServiceBusClient(connectionString);
var sender = client.CreateSender("notifications-queue");
await sender.SendMessageAsync(new ServiceBusMessage("notification content"));
```

---

## 9. Security Considerations

### Network Security
- [ ] Azure Virtual Network (optional for complex setups)
- [ ] Network Security Groups (NSGs)
- [ ] Application Gateway for Web Application Firewall (WAF)
- [ ] Private Endpoints for database access

### Identity & Authentication
- [ ] Microsoft Entra ID (Azure AD) integration
- [ ] Managed Identity for App Service
- [ ] Role-Based Access Control (RBAC)
- [ ] Multi-factor authentication

### Data Security
- [ ] Transparent Data Encryption (TDE) for SQL Database
- [ ] Always Encrypted for sensitive columns
- [ ] Encryption at rest and in transit (TLS 1.2+)
- [ ] Regular backups and disaster recovery

### Compliance
- [ ] Enable Azure Policy for governance
- [ ] Azure Security Center recommendations
- [ ] Audit logging
- [ ] Compliance with industry standards (if applicable)

---

## 10. Scaling & Performance

### Auto-scaling Rules
```
Metric: CPU Usage
- Scale up: When average CPU > 70% for 5 minutes
- Scale down: When average CPU < 30% for 5 minutes
- Min instances: 2
- Max instances: 5
```

### Content Delivery
- [ ] Azure CDN for static assets
- [ ] Blob Storage with CDN
- [ ] Cache invalidation strategy

### Database Performance
- [ ] Query optimization
- [ ] Indexing strategy
- [ ] Connection pooling
- [ ] Query Store for monitoring

---

## 11. Monitoring & Diagnostics

### Application Insights
- [ ] Exception tracking
- [ ] Performance counters
- [ ] Custom events
- [ ] Dependency tracking (SQL, Storage, Service Bus)
- [ ] Availability tests

### Alerts
- [ ] High CPU usage
- [ ] Failed requests
- [ ] Database connection failures
- [ ] Queue processing delays

### Logging
- [ ] Application logs to Application Insights
- [ ] Blob Storage for long-term retention
- [ ] Log Analytics for analysis

---

## 12. Cost Estimation

### Monthly Recurring Costs (Estimated)

| Service | SKU | Estimated Cost |
|---------|-----|-----------------|
| App Service Plan | Standard S1 | $73.00 |
| Azure SQL Database | Standard (S1) | $15.00 - $300+ |
| Storage Account | Hot tier 100GB | $2.00 + data transfer |
| Key Vault | Standard | $0.34 |
| Service Bus | Standard 1M messages | $10.00 + $0.05/M |
| Application Insights | Pay-as-you-go | $0.30/GB |
| **Estimated Total** | | **$100 - $400/month** |

---

## 13. Testing Checklist

- [ ] Functional testing (all controllers and views)
- [ ] Database operations (CRUD, migrations)
- [ ] File uploads to Blob Storage
- [ ] Notification system with Service Bus
- [ ] Authentication and authorization
- [ ] Performance under load (load testing)
- [ ] Security scanning (OWASP)
- [ ] Disaster recovery procedures
- [ ] Backup and restore procedures

---

## 14. Deployment Checklist

- [ ] Infrastructure deployed via Bicep
- [ ] Secrets configured in Key Vault
- [ ] Application settings configured in App Service
- [ ] Connection strings updated
- [ ] Database migrated and validated
- [ ] File migrations completed
- [ ] CI/CD pipeline configured
- [ ] SSL certificates installed
- [ ] Custom domain configured (if applicable)
- [ ] Monitoring and alerts enabled

---

## 15. Post-Migration Tasks

- [ ] Update DNS records (if custom domain)
- [ ] Monitor application performance
- [ ] User acceptance testing (UAT)
- [ ] Decommission on-premises infrastructure
- [ ] Archive old backups
- [ ] Document new procedures
- [ ] Training for operations team

---

## 16. Rollback Strategy

If issues occur during migration:

1. **Pre-cutover**: Keep on-premises systems running
2. **Graceful failback**: 
   - Revert DNS to on-premises
   - Stop traffic to Azure
   - Investigate and fix issues
3. **Retry**: After fixes, deploy again
4. **Timeline**: Maintain on-premises for 30-60 days

---

## 17. Next Steps

1. ✅ Review and approve this migration plan
2. ⏳ Create Azure Bicep templates for infrastructure
3. ⏳ Update application code for Azure configuration
4. ⏳ Set up CI/CD pipeline with GitHub Actions
5. ⏳ Execute Phase 1-2 (Preparation & Infrastructure)
6. ⏳ Execute Phase 3 (Application modifications)
7. ⏳ Execute Phase 4 (Testing & Deployment)

---

## References

- [Microsoft: Migrate .NET web app to Azure App Service](https://learn.microsoft.com/en-us/dotnet/azure/migration/app-service)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service)
- [Entity Framework Core with Azure SQL](https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration)
- [Key Vault in .NET Applications](https://learn.microsoft.com/en-us/azure/key-vault/general/developers-guide)
- [Azure Service Bus for .NET](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)

