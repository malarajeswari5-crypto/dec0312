// Azure Service Bus Notification Service
// Replaces MSMQ for notification messaging

using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ContosoUniversity.Models;
using Newtonsoft.Json;

namespace ContosoUniversity.Services
{
    public interface IAzureNotificationService
    {
        Task SendNotificationAsync(Notification notification);
        Task SendBatchNotificationsAsync(IEnumerable<Notification> notifications);
        Task ProcessNotificationsAsync();
    }

    public class AzureNotificationService : IAzureNotificationService
    {
        private readonly ServiceBusClient _serviceBusClient;
        private readonly ServiceBusSender _sender;
        private readonly ILogger<AzureNotificationService> _logger;
        private const string QueueName = "notifications";

        public AzureNotificationService(
            IConfiguration configuration,
            ILogger<AzureNotificationService> logger)
        {
            _logger = logger;

            var connectionString = configuration.GetConnectionString("ServiceBusConnectionString");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new ArgumentException("Service Bus connection string not configured.");
            }

            _serviceBusClient = new ServiceBusClient(connectionString);
            _sender = _serviceBusClient.CreateSender(QueueName);
        }

        public async Task SendNotificationAsync(Notification notification)
        {
            try
            {
                var messageBody = JsonConvert.SerializeObject(notification);
                var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(messageBody))
                {
                    ContentType = "application/json",
                    Subject = "ContosoUniversity.Notification",
                    TimeToLive = TimeSpan.FromDays(1)
                };

                await _sender.SendMessageAsync(message);
                _logger.LogInformation($"Notification '{notification.Id}' sent to Service Bus.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error sending notification: {ex.Message}");
                throw;
            }
        }

        public async Task SendBatchNotificationsAsync(IEnumerable<Notification> notifications)
        {
            try
            {
                using var messageBatch = await _sender.CreateMessageBatchAsync();

                foreach (var notification in notifications)
                {
                    var messageBody = JsonConvert.SerializeObject(notification);
                    var message = new ServiceBusMessage(Encoding.UTF8.GetBytes(messageBody))
                    {
                        ContentType = "application/json",
                        Subject = "ContosoUniversity.Notification",
                        TimeToLive = TimeSpan.FromDays(1)
                    };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        throw new Exception("Message batch is too large.");
                    }
                }

                await _sender.SendMessagesAsync(messageBatch);
                _logger.LogInformation("Batch notifications sent to Service Bus.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error sending batch notifications: {ex.Message}");
                throw;
            }
        }

        public async Task ProcessNotificationsAsync()
        {
            try
            {
                var processorOptions = new ServiceBusProcessorOptions
                {
                    MaxConcurrentCalls = 1,
                    AutoCompleteMessages = false
                };

                var processor = _serviceBusClient.CreateProcessor(QueueName, processorOptions);

                processor.ProcessMessageAsync += MessageHandler;
                processor.ProcessErrorAsync += ErrorHandler;

                await processor.StartProcessingAsync();
                _logger.LogInformation("Service Bus notification processor started.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error starting notification processor: {ex.Message}");
                throw;
            }
        }

        private async Task MessageHandler(ProcessMessageEventArgs args)
        {
            string body = args.Message.Body.ToString();
            
            try
            {
                var notification = JsonConvert.DeserializeObject<Notification>(body);
                
                // Process notification here
                _logger.LogInformation($"Processing notification: {notification?.Id}");
                
                // Complete the message so it's removed from the queue
                await args.CompleteMessageAsync(args.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error processing message: {ex.Message}");
                // Abandon the message so it can be retried
                await args.AbandonMessageAsync(args.Message);
            }
        }

        private Task ErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError($"Service Bus error: {args.Exception?.Message}");
            return Task.CompletedTask;
        }

        public async ValueTask DisposeAsync()
        {
            await _sender.DisposeAsync();
            await _serviceBusClient.DisposeAsync();
        }
    }
}
