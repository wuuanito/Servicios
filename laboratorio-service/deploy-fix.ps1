# Script de despliegue con corrección de permisos y CORS
# Laboratorio Service - NaturePharma
# PowerShell Version para Windows

Write-Host "🚀 Iniciando despliegue con correcciones de permisos y CORS..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Función para logging con colores
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar si Docker está ejecutándose
try {
    docker info | Out-Null
    Write-Info "Docker está ejecutándose correctamente"
} catch {
    Write-Error "Docker no está ejecutándose. Por favor, inicia Docker Desktop y vuelve a intentar."
    exit 1
}

# Detener servicios existentes
Write-Info "Deteniendo servicios existentes..."
docker-compose down

# Crear directorio de uploads en el host si no existe
Write-Info "Creando directorio de uploads en el host..."
if (!(Test-Path "./uploads/defectos")) {
    New-Item -ItemType Directory -Path "./uploads/defectos" -Force | Out-Null
    Write-Success "Directorio de uploads creado"
} else {
    Write-Info "Directorio de uploads ya existe"
}

# Configurar permisos en Windows
Write-Info "Configurando permisos en el directorio host (Windows)..."
try {
    # Dar permisos completos a Everyone en el directorio uploads
    icacls "./uploads" /grant "Everyone:F" /T | Out-Null
    Write-Success "Permisos configurados en Windows"
} catch {
    Write-Warning "No se pudieron configurar permisos automáticamente (puede ser normal)"
}

# Limpiar imágenes Docker antiguas
Write-Info "Limpiando imágenes Docker antiguas..."
docker system prune -f | Out-Null

# Construir imagen sin caché
Write-Info "Construyendo imagen Docker sin caché..."
try {
    docker-compose build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Imagen construida exitosamente"
    } else {
        throw "Error en la construcción"
    }
} catch {
    Write-Error "Error construyendo la imagen Docker"
    exit 1
}

# Iniciar servicios
Write-Info "Iniciando servicios..."
try {
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Servicios iniciados exitosamente"
    } else {
        throw "Error iniciando servicios"
    }
} catch {
    Write-Error "Error iniciando los servicios"
    exit 1
}

# Esperar a que los servicios estén listos
Write-Info "Esperando a que los servicios estén listos..."
Start-Sleep -Seconds 10

# Verificar estado de los servicios
Write-Info "Verificando estado de los servicios..."
docker-compose ps

# Verificar logs del laboratorio-service
Write-Info "Verificando logs del laboratorio-service..."
Write-Host "Últimas 20 líneas de logs:" -ForegroundColor Yellow
docker-compose logs --tail=20 laboratorio-service

# Probar conectividad
Write-Info "Probando conectividad del servicio..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3004/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Success "Servicio respondiendo correctamente en puerto 3004"
    }
} catch {
    Write-Warning "El servicio no responde en puerto 3004, verificando logs..."
    docker-compose logs laboratorio-service
}

# Mostrar información de acceso
Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Success "Despliegue completado"
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 URLs de acceso:" -ForegroundColor Cyan
Write-Host "   • Health Check: http://localhost:3004/health"
Write-Host "   • API Defectos: http://localhost:3004/api/laboratorio/defectos"
Write-Host "   • API Tareas: http://localhost:3004/api/laboratorio/tareas"
Write-Host "   • phpMyAdmin: http://localhost:8081"
Write-Host ""
Write-Host "🔧 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   • Ver logs: docker-compose logs -f laboratorio-service"
Write-Host "   • Verificar permisos: docker exec -it laboratorio-service ls -la /app/uploads/"
Write-Host "   • Acceder al contenedor: docker exec -it laboratorio-service sh"
Write-Host "   • Detener servicios: docker-compose down"
Write-Host ""
Write-Host "📋 Configuración:" -ForegroundColor Cyan
Write-Host "   • Puerto del servicio: 3004"
Write-Host "   • CORS: Habilitado para todos los orígenes"
Write-Host "   • Uploads: ./uploads/defectos (host) -> /app/uploads/defectos (contenedor)"
Write-Host "   • Usuario del contenedor: laboratorio (UID 1001)"
Write-Host ""
Write-Info "Para más detalles, consulta SOLUCION-PERMISOS-CORS.md"
Write-Host "=================================================" -ForegroundColor Cyan

# Pausa para que el usuario pueda leer la información
Write-Host "Presiona cualquier tecla para continuar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")