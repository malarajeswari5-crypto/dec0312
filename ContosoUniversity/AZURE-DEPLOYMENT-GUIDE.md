# Guía de Despliegue a Azure App Services - ContosoUniversity

## ?? Pre-requisitos

1. **Cuenta de Azure** con suscripción activa
   - [Crear cuenta gratuita](https://azure.microsoft.com/free/)
2. **Azure CLI** instalado
   - [Descargar Azure CLI](https://aka.ms/installazurecliwindows)
3. **Visual Studio 2022** o **VS Code** con extensión de Azure
4. **.NET 8 SDK** instalado

## ?? Método 1: Despliegue Automático con Script PowerShell (Recomendado)

### Paso 1: Preparar el Script

1. Abre PowerShell como **Administrador**
2. Navega a la carpeta del proyecto:
   ```powershell
   cd "C:\Users\NZ752XA\source\repos\dotnet-migration-copilot-samples\ContosoUniversity"
   ```

### Paso 2: Ejecutar el Script

```powershell
.\deploy-to-azure.ps1
```

El script automáticamente:
- ? Creará un Resource Group
- ? Creará un SQL Server con base de datos
- ? Creará un App Service Plan
- ? Creará la Web App
- ? Configurará las connection strings
- ? Publicará la aplicación

### Paso 3: Verificar el Despliegue

Al finalizar, el script mostrará:
- ?? **URL de la aplicación**: `https://contosouniversity-XXXX.azurewebsites.net`
- ??? **SQL Server**: `contosouniversity-sql-XXXX.database.windows.net`
- ?? **Credenciales de SQL** (¡guárdalas!)

## ?? Método 2: Despliegue desde Visual Studio

### Opción A: Publicación Directa

1. **Click derecho** en el proyecto `ContosoUniversity.csproj`
2. Seleccionar **"Publish..."**
3. Elegir **"Azure"** ? **"Azure App Service (Linux)"**
4. Click en **"Create New"**
5. Configurar:
   - **Name**: `contosouniversity-app`
   - **Subscription**: Tu suscripción
   - **Resource Group**: `ContosoUniversity-RG` (crear nuevo)
   - **Hosting Plan**: Crear nuevo (B1 o superior)
6. Click en **"Create"**
7. Esperar a que se creen los recursos
8. Click en **"Publish"**

### Opción B: Perfil de Publicación

1. Descargar el perfil de publicación desde Azure Portal:
   - Ve a tu App Service
   - Click en **"Get publish profile"**
   - Guarda el archivo `.publishsettings`

2. En Visual Studio:
 - Click derecho en proyecto ? **"Publish..."**
   - **"Import Profile..."**
   - Seleccionar el archivo `.publishsettings`
   - Click en **"Publish"**

## ?? Método 3: Despliegue con Azure CLI Manual

### 1. Login a Azure
```bash
az login
```

### 2. Crear Resource Group
```bash
az group create --name ContosoUniversity-RG --location eastus
```

### 3. Crear SQL Server
```bash
az sql server create \
  --name contosouniversity-sql-$(Get-Random) \
  --resource-group ContosoUniversity-RG \
  --location eastus \
  --admin-user sqladmin \
  --admin-password "TuPassword123!"
```

### 4. Crear Base de Datos
```bash
az sql db create \
  --resource-group ContosoUniversity-RG \
  --server contosouniversity-sql-XXXX \
  --name ContosoUniversityDB \
  --service-objective S0
```

### 5. Configurar Firewall
```bash
az sql server firewall-rule create \
  --resource-group ContosoUniversity-RG \
  --server contosouniversity-sql-XXXX \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 6. Crear App Service Plan
```bash
az appservice plan create \
  --name ContosoUniversity-Plan \
  --resource-group ContosoUniversity-RG \
  --sku B1 \
  --is-linux
```

### 7. Crear Web App
```bash
az webapp create \
--name contosouniversity-app \
  --resource-group ContosoUniversity-RG \
  --plan ContosoUniversity-Plan \
  --runtime "DOTNET|8.0"
```

### 8. Configurar Connection String
```bash
az webapp config connection-string set \
  --name contosouniversity-app \
  --resource-group ContosoUniversity-RG \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=tcp:contosouniversity-sql-XXXX.database.windows.net,1433;..."
```

### 9. Publicar Aplicación
```bash
dotnet publish -c Release -o ./publish
cd publish
zip -r ../app.zip .
az webapp deployment source config-zip \
  --resource-group ContosoUniversity-RG \
  --name contosouniversity-app \
  --src ../app.zip
```

## ?? Método 4: CI/CD con GitHub Actions

### Configuración Inicial

1. **Obtener el Publish Profile**:
   - Ve a Azure Portal ? Tu App Service
   - Click en **"Get publish profile"**
   - Copia todo el contenido del archivo XML

2. **Agregar Secret en GitHub**:
   - Ve a tu repositorio ? **Settings** ? **Secrets and variables** ? **Actions**
   - Click en **"New repository secret"**
   - Nombre: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Valor: Pega el contenido del publish profile
   - Click en **"Add secret"**

3. **Editar el workflow**:
- Abre `.github/workflows/azure-deploy.yml`
   - Cambia `AZURE_WEBAPP_NAME` por el nombre de tu app
   - Commit y push

4. **Despliegue Automático**:
   - Cada push a `main` o `master` desplegará automáticamente
   - O ejecuta manualmente desde **Actions** tab

## ?? Configuración Post-Despliegue

### 1. Configurar Variables de Entorno

En Azure Portal ? Tu App Service ? **Configuration**:

```
ASPNETCORE_ENVIRONMENT = Production
NotificationQueuePath = .\Private$\ContosoUniversityNotifications
```

### 2. Configurar Connection String

En **Configuration** ? **Connection strings**:

- **Name**: `DefaultConnection`
- **Value**: `Server=tcp:YOURSERVER.database.windows.net,1433;Initial Catalog=ContosoUniversityDB;...`
- **Type**: `SQLAzure`

### 3. Habilitar Logging

En **Monitoring** ? **App Service logs**:
- Application Logging: **On**
- Level: **Information**

### 4. Escalar Recursos (Opcional)

En **Scale up (App Service plan)**:
- Selecciona un plan más grande si necesitas más recursos
- Recomendado: **B2** o **S1** para producción

## ?? Validación del Despliegue

### 1. Verificar el Sitio
```bash
curl https://contosouniversity-app.azurewebsites.net
```

### 2. Revisar Logs
```bash
az webapp log tail --name contosouniversity-app --resource-group ContosoUniversity-RG
```

### 3. Diagnosticar Problemas
En Azure Portal ? Tu App Service ? **Diagnose and solve problems**

## ?? Monitoreo

### Application Insights (Recomendado)

1. Crear Application Insights:
```bash
az monitor app-insights component create \
  --app contosouniversity-insights \
  --location eastus \
  --resource-group ContosoUniversity-RG
```

2. Obtener Instrumentation Key:
```bash
az monitor app-insights component show \
  --app contosouniversity-insights \
  --resource-group ContosoUniversity-RG \
  --query instrumentationKey
```

3. Agregar a `appsettings.json`:
```json
{
  "ApplicationInsights": {
    "InstrumentationKey": "tu-key-aqui"
  }
}
```

## ?? Estimación de Costos

### Configuración Básica (Desarrollo/Testing):
- **App Service B1**: ~$13/mes
- **SQL Database S0**: ~$15/mes
- **Total**: ~$28/mes

### Configuración Producción:
- **App Service S1**: ~$70/mes
- **SQL Database S1**: ~$30/mes
- **Application Insights**: Primeros 5GB gratis
- **Total**: ~$100/mes

## ?? Seguridad

### 1. Habilitar HTTPS Only
```bash
az webapp update --name contosouniversity-app \
  --resource-group ContosoUniversity-RG \
  --https-only true
```

### 2. Configurar Certificado SSL Personalizado (Opcional)
- Comprar certificado o usar Let's Encrypt
- En App Service ? **TLS/SSL settings** ? **Private Key Certificates**

### 3. Restringir Acceso a Base de Datos
```bash
# Agregar tu IP
az sql server firewall-rule create \
  --resource-group ContosoUniversity-RG \
  --server contosouniversity-sql-XXXX \
  --name MyIP \
  --start-ip-address TU.IP.AQUI \
  --end-ip-address TU.IP.AQUI
```

## ?? Troubleshooting

### Error: "Application Error"
```bash
# Ver logs en tiempo real
az webapp log tail --name contosouniversity-app --resource-group ContosoUniversity-RG

# O descargar logs
az webapp log download --name contosouniversity-app --resource-group ContosoUniversity-RG
```

### Error de Base de Datos
- Verifica que el firewall permita conexiones de Azure
- Verifica la connection string en Configuration
- Prueba la conexión desde tu máquina local

### Error 500
- Revisa Application Insights
- Verifica que todas las variables de entorno están configuradas
- Asegúrate que la base de datos está creada e inicializada

## ?? Recursos Adicionales

- [Documentación de Azure App Service](https://docs.microsoft.com/azure/app-service/)
- [Migración a Azure SQL Database](https://docs.microsoft.com/azure/azure-sql/migration-guides/)
- [CI/CD con GitHub Actions](https://docs.github.com/actions/deployment/deploying-to-azure)
- [Mejores Prácticas de Azure App Service](https://docs.microsoft.com/azure/app-service/app-service-best-practices)

## ?? Checklist Final

- [ ] Aplicación desplegada y funcionando
- [ ] Base de datos creada y conectada
- [ ] Connection strings configuradas
- [ ] Variables de entorno configuradas
- [ ] HTTPS habilitado
- [ ] Logs habilitados
- [ ] Backups configurados (opcional)
- [ ] Application Insights configurado (recomendado)
- [ ] CI/CD configurado (opcional)
- [ ] Documentación actualizada

## ?? Soporte

Si encuentras problemas:
1. Revisa los logs en Azure Portal
2. Consulta la [documentación oficial](https://docs.microsoft.com/azure/)
3. Abre un issue en el repositorio

¡Felicitaciones por desplegar tu aplicación a Azure! ??
