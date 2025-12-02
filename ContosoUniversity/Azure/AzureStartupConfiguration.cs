// Startup Configuration for Azure Integration
// This file configures the application to work with Azure services

using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.ApplicationInsights.Extensibility;

namespace ContosoUniversity.Azure
{
    public class AzureStartupConfiguration
    {
        public static IServiceCollection AddAzureServices(
            IServiceCollection services,
            IConfiguration configuration,
            IWebHostEnvironment environment)
        {
            var environment_name = environment.EnvironmentName;

            // Azure Key Vault Integration
            if (environment_name != "Development")
            {
                var keyVaultUri = configuration["KeyVaultUri"];
                if (!string.IsNullOrEmpty(keyVaultUri))
                {
                    var client = new SecretClient(
                        new Uri(keyVaultUri),
                        new DefaultAzureCredential());
                    
                    // This allows accessing Key Vault secrets via configuration
                    configuration.AddAzureKeyVault(
                        client,
                        new KeyVaultSecretManager());
                }
            }

            // Application Insights
            services.AddApplicationInsightsTelemetry(configuration);

            // Azure Storage
            var storageConnectionString = configuration["AzureWebJobsStorage"] 
                ?? configuration.GetConnectionString("AzureStorage");
            if (!string.IsNullOrEmpty(storageConnectionString))
            {
                // Add Azure Storage services
                // services.AddAzureStorage(storageConnectionString);
            }

            // Azure Service Bus
            var serviceBusConnectionString = configuration.GetConnectionString("ServiceBusConnectionString");
            if (!string.IsNullOrEmpty(serviceBusConnectionString))
            {
                // Add Azure Service Bus services
                // services.AddAzureServiceBus(serviceBusConnectionString);
            }

            return services;
        }
    }

    // Helper class for Key Vault secret management
    public class KeyVaultSecretManager : Azure.Extensions.AspNetCore.Configuration.Secrets.IKeyVaultSecretManager
    {
        public bool Load(Azure.Security.KeyVault.Secrets.SecretProperties properties)
        {
            return !properties.Name.StartsWith("unused");
        }

        public string GetKey(Azure.Security.KeyVault.Secrets.KeyVaultSecret secret)
        {
            return secret.Name
                .Replace("--", ConfigurationPath.KeyDelimiter)
                .ToUpper();
        }
    }
}
