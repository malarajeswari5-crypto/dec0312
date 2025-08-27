using ContosoUniversity.Models;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace ContosoUniversity.Services
{
    public class NotificationService
    {
        private readonly ILogger<NotificationService> _logger;
        private readonly List<Notification> _notifications; // In-memory store for demo

        public NotificationService(ILogger<NotificationService> logger)
        {
            _logger = logger;
            _notifications = new List<Notification>();
        }

        public void SendNotification(string entityType, string entityId, EntityOperation operation, string userName = null)
        {
            SendNotification(entityType, entityId, null, operation, userName);
        }

        public void SendNotification(string entityType, string entityId, string entityDisplayName, EntityOperation operation, string userName = null)
        {
            try
            {
                var notification = new Notification
                {
                    EntityType = entityType,
                    EntityId = entityId,
                    Operation = operation.ToString(),
                    Message = GenerateMessage(entityType, entityId, entityDisplayName, operation),
                    CreatedAt = DateTime.Now,
                    CreatedBy = userName ?? "System",
                    IsRead = false
                };

                _notifications.Add(notification);
                _logger.LogInformation("Notification sent: {Message}", notification.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send notification");
            }
        }

        public Notification? ReceiveNotification()
        {
            try
            {
                var unreadNotification = _notifications.FirstOrDefault(n => !n.IsRead);
                return unreadNotification;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to receive notification");
                return null;
            }
        }

        public void MarkAsRead(int notificationId)
        {
            var notification = _notifications.FirstOrDefault(n => n.Id == notificationId);
            if (notification != null)
            {
                notification.IsRead = true;
                _logger.LogInformation("Notification {Id} marked as read", notificationId);
            }
        }

        public IEnumerable<Notification> GetAllNotifications()
        {
            return _notifications.OrderByDescending(n => n.CreatedAt);
        }

        private string GenerateMessage(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            var displayText = !string.IsNullOrWhiteSpace(entityDisplayName) 
                ? $"{entityType} '{entityDisplayName}'" 
                : $"{entityType} (ID: {entityId})";

            return operation switch
            {
                EntityOperation.CREATE => $"New {displayText} has been created",
                EntityOperation.UPDATE => $"{displayText} has been updated",
                EntityOperation.DELETE => $"{displayText} has been deleted",
                _ => $"{displayText} operation: {operation}"
            };
        }
    }
}
