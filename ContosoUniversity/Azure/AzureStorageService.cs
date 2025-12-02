// Azure Blob Storage Service for file uploads
// Replaces local file system storage

using System;
using System.IO;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Services
{
    public interface IAzureStorageService
    {
        Task<Uri> UploadFileAsync(Stream fileStream, string fileName, string containerName = "uploads");
        Task<Stream> DownloadFileAsync(string fileName, string containerName = "uploads");
        Task DeleteFileAsync(string fileName, string containerName = "uploads");
        Task<bool> FileExistsAsync(string fileName, string containerName = "uploads");
        Uri GetFileUri(string fileName, string containerName = "uploads");
    }

    public class AzureStorageService : IAzureStorageService
    {
        private readonly BlobContainerClient _containerClient;
        private readonly ILogger<AzureStorageService> _logger;
        private readonly string _containerName;

        public AzureStorageService(
            IConfiguration configuration,
            ILogger<AzureStorageService> logger,
            string containerName = "uploads")
        {
            _logger = logger;
            _containerName = containerName;

            var connectionString = configuration.GetConnectionString("AzureStorage");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new ArgumentException("Azure Storage connection string not configured.");
            }

            var blobServiceClient = new BlobServiceClient(connectionString);
            _containerClient = blobServiceClient.GetBlobContainerClient(containerName);
        }

        public async Task<Uri> UploadFileAsync(Stream fileStream, string fileName, string containerName = "uploads")
        {
            try
            {
                var blobClient = _containerClient.GetBlobClient(fileName);
                
                fileStream.Position = 0;
                await blobClient.UploadAsync(fileStream, overwrite: true);
                
                _logger.LogInformation($"File '{fileName}' uploaded successfully to Azure Blob Storage.");
                return blobClient.Uri;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error uploading file '{fileName}': {ex.Message}");
                throw;
            }
        }

        public async Task<Stream> DownloadFileAsync(string fileName, string containerName = "uploads")
        {
            try
            {
                var blobClient = _containerClient.GetBlobClient(fileName);
                var download = await blobClient.DownloadAsync();
                return download.Value.Content;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error downloading file '{fileName}': {ex.Message}");
                throw;
            }
        }

        public async Task DeleteFileAsync(string fileName, string containerName = "uploads")
        {
            try
            {
                var blobClient = _containerClient.GetBlobClient(fileName);
                await blobClient.DeleteAsync();
                _logger.LogInformation($"File '{fileName}' deleted from Azure Blob Storage.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error deleting file '{fileName}': {ex.Message}");
                throw;
            }
        }

        public async Task<bool> FileExistsAsync(string fileName, string containerName = "uploads")
        {
            try
            {
                var blobClient = _containerClient.GetBlobClient(fileName);
                return await blobClient.ExistsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error checking file '{fileName}': {ex.Message}");
                return false;
            }
        }

        public Uri GetFileUri(string fileName, string containerName = "uploads")
        {
            return _containerClient.GetBlobClient(fileName).Uri;
        }
    }
}
