# Application Code Changes for Azure Migration

This document outlines the code changes needed to migrate the Contoso University application to Azure.

## 1. NuGet Package Updates

Add the following NuGet packages to your project:

```xml
<!-- Package.config or .csproj -->
<PackageReference Include="Azure.Identity" Version="1.10.0" />
<PackageReference Include="Azure.Security.KeyVault.Secrets" Version="4.5.0" />
<PackageReference Include="Azure.Extensions.AspNetCore.Configuration.Secrets" Version="1.3.0" />
<PackageReference Include="Azure.Storage.Blobs" Version="12.19.0" />
<PackageReference Include="Azure.Messaging.ServiceBus" Version="7.17.0" />
<PackageReference Include="Microsoft.ApplicationInsights" Version="2.22.0" />
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.22.0" />
```

Or using Package Manager Console:

```powershell
Install-Package Azure.Identity
Install-Package Azure.Security.KeyVault.Secrets
Install-Package Azure.Extensions.AspNetCore.Configuration.Secrets
Install-Package Azure.Storage.Blobs
Install-Package Azure.Messaging.ServiceBus
Install-Package Microsoft.ApplicationInsights.AspNetCore
```

## 2. Configuration Changes in Web.config

Replace local configuration with Azure Key Vault and App Service settings:

```xml
<!-- Before (Local) -->
<configuration>
  <connectionStrings>
    <add name="DefaultConnection" 
         connectionString="Data Source=(LocalDb)\MSSQLLocalDB;..." />
  </connectionStrings>
  <appSettings>
    <add key="NotificationQueuePath" value=".\Private$\ContosoUniversityNotifications"/>
  </appSettings>
</configuration>

<!-- After (Azure) -->
<configuration>
  <!-- Connection strings will be read from App Service Configuration -->
  <!-- Sensitive values will be fetched from Key Vault at runtime -->
</configuration>
```

## 3. Startup/Global.asax Changes

### Update Global.asax.cs

```csharp
protected void Application_Start()
{
    // ... existing code ...
    
    // Initialize Azure services
    var config = new HttpConfiguration();
    var serviceProvider = RegisterDependencies(config);
    
    // ... rest of startup code ...
}

private IServiceProvider RegisterDependencies(HttpConfiguration config)
{
    var services = new ServiceCollection();
    var configuration = new ConfigurationBuilder()
        .AddEnvironmentVariables()
        .AddAppConfiguration()  // Custom extension for Azure App Configuration
        .Build();

    // Register Azure services
    AzureStartupConfiguration.AddAzureServices(services, configuration, env);
    
    // Register application services
    services.AddScoped<IAzureStorageService, AzureStorageService>();
    services.AddScoped<IAzureNotificationService, AzureNotificationService>();
    
    return services.BuildServiceProvider();
}
```

## 4. File Upload Handler Changes

### Current: Local File System

```csharp
// Controllers/CoursesController.cs - Before
public ActionResult Upload(HttpPostedFileBase file)
{
    if (file != null && file.ContentLength > 0)
    {
        string fileName = Path.GetFileName(file.FileName);
        string path = Server.MapPath("~/Uploads/TeachingMaterials/");
        file.SaveAs(Path.Combine(path, fileName));
    }
    return RedirectToAction("Index");
}
```

### New: Azure Blob Storage

```csharp
// Controllers/CoursesController.cs - After
[Inject]
private IAzureStorageService _storageService;

public async Task<ActionResult> Upload(HttpPostedFileBase file)
{
    if (file != null && file.ContentLength > 0)
    {
        try
        {
            using (var stream = file.InputStream)
            {
                string fileName = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{Path.GetFileName(file.FileName)}";
                var uri = await _storageService.UploadFileAsync(
                    stream,
                    fileName,
                    "teaching-materials");
                
                // Store URI in database for later retrieval
                // ...
            }
        }
        catch (Exception ex)
        {
            // Handle error
        }
    }
    return RedirectToAction("Index");
}
```

## 5. Notification System Changes

### Current: MSMQ

```csharp
// Services/NotificationService.cs - Before
using System.Messaging;

public void SendNotification(Notification notification)
{
    var queue = new MessageQueue(@".\Private$\ContosoUniversityNotifications");
    queue.Send(notification);
}
```

### New: Azure Service Bus

```csharp
// Services/AzureNotificationService.cs - After
using Azure.Messaging.ServiceBus;

[Inject]
private IAzureNotificationService _notificationService;

public async Task SendNotification(Notification notification)
{
    await _notificationService.SendNotificationAsync(notification);
}
```

## 6. Logging Changes

### Add Application Insights

```csharp
// In Global.asax.cs or Startup
using Microsoft.ApplicationInsights.AspNetCore;

public void ConfigureServices(IServiceCollection services)
{
    // Add Application Insights
    services.AddApplicationInsightsTelemetry(Configuration);
    
    // ... other services ...
}
```

### Update Logging

```csharp
// Using ILogger instead of custom logging
using Microsoft.Extensions.Logging;

public class HomeController : BaseController
{
    private readonly ILogger<HomeController> _logger;
    
    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }
    
    public ActionResult Index()
    {
        _logger.LogInformation("Home page accessed");
        return View();
    }
}
```

## 7. Connection String Migration

### Update SchoolContext

```csharp
// Data/SchoolContext.cs
public class SchoolContext : DbContext
{
    public SchoolContext(DbContextOptions<SchoolContext> options) 
        : base(options)
    {
    }
    
    public DbSet<Course> Courses { get; set; }
    public DbSet<Enrollment> Enrollments { get; set; }
    // ... other DbSets ...
}
```

### In Startup (Dependency Injection)

```csharp
services.AddDbContext<SchoolContext>(options =>
    options.UseSqlServer(
        Configuration.GetConnectionString("DefaultConnection")));
```

## 8. Health Check Endpoint

Add a health check endpoint for Azure monitoring:

```csharp
// Controllers/HealthController.cs (new)
public class HealthController : Controller
{
    private readonly SchoolContext _context;
    
    public HealthController(SchoolContext context)
    {
        _context = context;
    }
    
    [HttpGet("/api/health")]
    public async Task<IActionResult> Health()
    {
        try
        {
            // Check database connection
            await _context.Database.ExecuteSqlAsync($"SELECT 1");
            
            return Ok(new { status = "healthy" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { status = "unhealthy", error = ex.Message });
        }
    }
}
```

## 9. Dependency Injection Registration

```csharp
// Startup configuration
public void ConfigureServices(IServiceCollection services)
{
    // Configuration
    var configuration = Configuration;
    
    // Database
    services.AddDbContext<SchoolContext>(options =>
        options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
    
    // Azure Storage
    services.AddScoped<IAzureStorageService>(provider =>
        new AzureStorageService(configuration, 
            provider.GetRequiredService<ILogger<AzureStorageService>>(),
            "teaching-materials"));
    
    // Azure Notifications
    services.AddScoped<IAzureNotificationService>(provider =>
        new AzureNotificationService(configuration,
            provider.GetRequiredService<ILogger<AzureNotificationService>>()));
    
    // Other services
    services.AddControllersWithViews();
    services.AddApplicationInsightsTelemetry();
}
```

## 10. Environment-Specific Configuration

Create appsettings files for different environments:

### appsettings.Development.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=(LocalDb)\\MSSQLLocalDB;Initial Catalog=ContosoUniversity;Integrated Security=True"
  },
  "ApplicationInsights": {
    "InstrumentationKey": "local-key"
  }
}
```

### appsettings.Production.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:your-server.database.windows.net;Database=ContosoUniversity;..."
  },
  "KeyVaultUri": "https://your-keyvault.vault.azure.net/",
  "ApplicationInsights": {
    "InstrumentationKey": "[Loaded from Key Vault]"
  }
}
```

## 11. Testing Changes

Update unit tests to use Azure service mocks:

```csharp
// Tests/CourseControllerTests.cs
public class CourseControllerTests
{
    private Mock<IAzureStorageService> _mockStorageService;
    
    public CourseControllerTests()
    {
        _mockStorageService = new Mock<IAzureStorageService>();
    }
    
    [Fact]
    public async Task Upload_WithValidFile_ShouldSaveToAzureStorage()
    {
        // Arrange
        var mockFile = new Mock<HttpPostedFileBase>();
        mockFile.Setup(f => f.FileName).Returns("test.pdf");
        
        _mockStorageService
            .Setup(s => s.UploadFileAsync(It.IsAny<Stream>(), It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(new Uri("https://storage.blob.core.windows.net/test.pdf"));
        
        // Act
        var controller = new CoursesController(_mockStorageService.Object);
        var result = await controller.Upload(mockFile.Object);
        
        // Assert
        Assert.NotNull(result);
        _mockStorageService.Verify(s => s.UploadFileAsync(It.IsAny<Stream>(), It.IsAny<string>(), It.IsAny<string>()), Times.Once);
    }
}
```

## Summary

Key changes:
1. Add Azure SDK NuGet packages
2. Remove local file system operations
3. Replace MSMQ with Azure Service Bus
4. Migrate configuration to Key Vault
5. Add Application Insights logging
6. Update database connection strings
7. Implement health check endpoint
8. Update dependency injection
9. Test with Azure services

