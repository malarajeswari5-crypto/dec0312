# Script para desplegar ContosoUniversity a Azure App Services
# Asegúrate de tener Azure CLI instalado: https://aka.ms/installazurecliwindows

# Variables - MODIFICA ESTOS VALORES
$resourceGroup = "ContosoUniversity-RG"
$location = "eastus"
$appServicePlan = "ContosoUniversity-Plan"
$webAppName = "contosouniversity-$(Get-Random -Minimum 1000 -Maximum 9999)"
$sqlServerName = "contosouniversity-sql-$(Get-Random -Minimum 1000 -Maximum 9999)"
$sqlDatabaseName = "ContosoUniversityDB"
$sqlAdminUser = "sqladmin"
$sqlAdminPassword = "P@ssw0rd$(Get-Random -Minimum 100 -Maximum 999)!"

Write-Host "Iniciando despliegue a Azure..." -ForegroundColor Green

# 1. Login a Azure (si no estás autenticado)
Write-Host "`n1. Autenticando en Azure..." -ForegroundColor Yellow
az login

# 2. Crear Resource Group
Write-Host "`n2. Creando Resource Group: $resourceGroup..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location

# 3. Crear SQL Server
Write-Host "`n3. Creando SQL Server: $sqlServerName..." -ForegroundColor Yellow
az sql server create `
    --name $sqlServerName `
    --resource-group $resourceGroup `
    --location $location `
    --admin-user $sqlAdminUser `
    --admin-password $sqlAdminPassword

# 4. Configurar Firewall de SQL Server (permitir servicios de Azure)
Write-Host "`n4. Configurando Firewall de SQL Server..." -ForegroundColor Yellow
az sql server firewall-rule create `
    --resource-group $resourceGroup `
    --server $sqlServerName `
    --name "AllowAzureServices" `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0

# 5. Crear SQL Database
Write-Host "`n5. Creando SQL Database: $sqlDatabaseName..." -ForegroundColor Yellow
az sql db create `
    --resource-group $resourceGroup `
    --server $sqlServerName `
    --name $sqlDatabaseName `
  --service-objective S0

# 6. Crear App Service Plan
Write-Host "`n6. Creando App Service Plan: $appServicePlan..." -ForegroundColor Yellow
az appservice plan create `
    --name $appServicePlan `
    --resource-group $resourceGroup `
    --location $location `
    --sku B1 `
    --is-linux

# 7. Crear Web App
Write-Host "`n7. Creando Web App: $webAppName..." -ForegroundColor Yellow
az webapp create `
    --name $webAppName `
    --resource-group $resourceGroup `
    --plan $appServicePlan `
    --runtime "DOTNET|8.0"

# 8. Obtener connection string de SQL
$sqlConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlAdminUser;Password=$sqlAdminPassword;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# 9. Configurar Connection String en Web App
Write-Host "`n8. Configurando Connection String en Web App..." -ForegroundColor Yellow
az webapp config connection-string set `
    --name $webAppName `
    --resource-group $resourceGroup `
    --connection-string-type SQLAzure `
    --settings DefaultConnection="$sqlConnectionString"

# 10. Configurar App Settings
Write-Host "`n9. Configurando App Settings..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $webAppName `
    --resource-group $resourceGroup `
    --settings ASPNETCORE_ENVIRONMENT="Production" `
    NotificationQueuePath=".\Private$\ContosoUniversityNotifications"

# 11. Publicar aplicación
Write-Host "`n10. Publicando aplicación..." -ForegroundColor Yellow
Write-Host "Ejecutando: dotnet publish -c Release -o ./publish" -ForegroundColor Cyan
dotnet publish -c Release -o ./publish

Write-Host "Comprimiendo archivos..." -ForegroundColor Cyan
Compress-Archive -Path ./publish/* -DestinationPath ./app.zip -Force

Write-Host "Desplegando a Azure..." -ForegroundColor Cyan
az webapp deployment source config-zip `
    --resource-group $resourceGroup `
    --name $webAppName `
    --src ./app.zip

# Limpiar archivos temporales
Remove-Item ./app.zip
Remove-Item -Recurse ./publish

# Mostrar información
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Green
Write-Host "DESPLIEGUE COMPLETADO EXITOSAMENTE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nInformación de tu aplicación:" -ForegroundColor Cyan
Write-Host "  • Web App URL: https://$webAppName.azurewebsites.net" -ForegroundColor White
Write-Host "  • Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "  • SQL Server: $sqlServerName.database.windows.net" -ForegroundColor White
Write-Host "  • Database: $sqlDatabaseName" -ForegroundColor White
Write-Host "  • SQL Admin User: $sqlAdminUser" -ForegroundColor White
Write-Host "  • SQL Admin Password: $sqlAdminPassword" -ForegroundColor Yellow
Write-Host "`n??  IMPORTANTE: Guarda la contraseña de SQL en un lugar seguro!" -ForegroundColor Red
Write-Host "`nAbre la aplicación en: https://$webAppName.azurewebsites.net" -ForegroundColor Green
