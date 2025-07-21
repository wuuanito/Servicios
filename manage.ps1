# Script de gestión para NaturePharma Services en Windows
# PowerShell script para facilitar el despliegue y gestión

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('setup', 'build', 'start', 'stop', 'restart', 'update', 'logs', 'status', 'cleanup', 'dev', 'dev-stop', 'dev-logs', 'help')]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string]$Service = ""
)

# Colores para output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($message) {
    Write-ColorOutput Blue "[INFO] $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARNING] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

# Verificar si Docker está instalado
function Test-Dependencies {
    Write-Info "Verificando dependencias..."
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker no está instalado. Por favor instala Docker Desktop primero."
        exit 1
    }
    
    if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        exit 1
    }
    
    Write-Success "Dependencias verificadas correctamente"
}

# Configuración inicial
function Initialize-Setup {
    Write-Info "Configurando entorno inicial..."
    
    # Crear archivo .env si no existe
    if (!(Test-Path ".env")) {
        Write-Info "Creando archivo .env desde .env.example..."
        Copy-Item ".env.example" ".env"
        Write-Warning "Por favor, edita el archivo .env con tus configuraciones específicas"
        Write-Warning "Especialmente las credenciales de email y JWT_SECRET"
    } else {
        Write-Info "Archivo .env ya existe"
    }
    
    # Crear directorios necesarios
    Write-Info "Creando directorios necesarios..."
    
    $directories = @(
        "laboratorio-service\uploads\defectos",
        "ServicioSolicitudesOt\uploads",
        "auth-service\logs",
        "nginx\ssl",
        "backups"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Directorio creado: $dir"
        }
    }
    
    Write-Success "Configuración inicial completada"
}

# Construir imágenes
function Build-Images {
    Write-Info "Construyendo imágenes Docker..."
    docker-compose build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Imágenes construidas correctamente"
    } else {
        Write-Error "Error al construir las imágenes"
        exit 1
    }
}

# Iniciar servicios en producción
function Start-Services {
    Write-Info "Iniciando servicios en modo producción..."
    docker-compose up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Servicios iniciados correctamente"
        Show-ServiceUrls
    } else {
        Write-Error "Error al iniciar los servicios"
        exit 1
    }
}

# Detener servicios
function Stop-Services {
    Write-Info "Deteniendo servicios..."
    docker-compose down
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Servicios detenidos correctamente"
    } else {
        Write-Error "Error al detener los servicios"
    }
}

# Reiniciar servicios
function Restart-Services {
    Write-Info "Reiniciando servicios..."
    docker-compose restart
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Servicios reiniciados correctamente"
    } else {
        Write-Error "Error al reiniciar los servicios"
    }
}

# Actualizar servicios
function Update-Services {
    Write-Info "Actualizando servicios..."
    
    # Detener servicios
    docker-compose down
    
    # Reconstruir imágenes
    docker-compose build --no-cache
    
    # Iniciar servicios
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Servicios actualizados correctamente"
        Show-ServiceUrls
    } else {
        Write-Error "Error al actualizar los servicios"
    }
}

# Ver logs
function Show-Logs {
    if ($Service -eq "") {
        Write-Info "Mostrando logs de todos los servicios..."
        docker-compose logs -f
    } else {
        Write-Info "Mostrando logs del servicio: $Service"
        docker-compose logs -f $Service
    }
}

# Ver estado
function Show-Status {
    Write-Info "Estado de los servicios:"
    docker-compose ps
    Write-Info ""
    Write-Info "Uso de recursos:"
    docker stats --no-stream
}

# Limpiar recursos
function Clear-Resources {
    Write-Info "Limpiando recursos Docker..."
    
    # Detener y eliminar contenedores
    docker-compose down -v
    
    # Eliminar imágenes no utilizadas
    docker image prune -f
    
    # Eliminar volúmenes no utilizados
    docker volume prune -f
    
    Write-Success "Limpieza completada"
}

# Iniciar en modo desarrollo
function Start-Development {
    Write-Info "Iniciando servicios en modo desarrollo..."
    
    # Crear archivo .env si no existe
    if (!(Test-Path ".env")) {
        Write-Info "Creando archivo .env desde .env.example..."
        Copy-Item ".env.example" ".env"
        Write-Warning "Recuerda configurar las variables de entorno en .env"
    }
    
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
}

# Detener modo desarrollo
function Stop-Development {
    Write-Info "Deteniendo servicios de desarrollo..."
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
    Write-Success "Servicios de desarrollo detenidos"
}

# Logs de desarrollo
function Show-DevLogs {
    if ($Service -eq "") {
        Write-Info "Mostrando logs de desarrollo de todos los servicios..."
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
    } else {
        Write-Info "Mostrando logs de desarrollo del servicio: $Service"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f $Service
    }
}

# Mostrar URLs de servicios
function Show-ServiceUrls {
    Write-Info ""
    Write-Success "=== URLs de Servicios ==="
    Write-Info "Auth Service: http://localhost:4001"
    Write-Info "Calendar Service: http://localhost:3003"
    Write-Info "Laboratorio Service: http://localhost:3004"
    Write-Info "Solicitudes Service: http://localhost:3001"
    Write-Info "Cremer Backend: http://localhost:3002"
    Write-Info "Tecnomaco Backend: http://localhost:3006"
    Write-Info "Servidor RPS: http://localhost:4000"
    Write-Info "phpMyAdmin: http://localhost:8081"
    Write-Info "Nginx Gateway: http://localhost"
    Write-Info ""
}

# Mostrar ayuda
function Show-Help {
    Write-Info "Script de gestión para NaturePharma Services"
    Write-Info ""
    Write-Info "Uso: .\manage.ps1 -Command <comando> [-Service <servicio>]"
    Write-Info ""
    Write-Info "Comandos disponibles:"
    Write-Info "  setup       - Configuración inicial (crear .env, directorios)"
    Write-Info "  build       - Construir imágenes Docker"
    Write-Info "  start       - Iniciar todos los servicios (producción)"
    Write-Info "  stop        - Detener todos los servicios"
    Write-Info "  restart     - Reiniciar todos los servicios"
    Write-Info "  update      - Actualizar servicios (rebuild + restart)"
    Write-Info "  logs        - Ver logs [opcionalmente de un servicio específico]"
    Write-Info "  status      - Ver estado de los servicios"
    Write-Info "  cleanup     - Limpiar recursos Docker"
    Write-Info "  dev         - Iniciar servicios en modo desarrollo"
    Write-Info "  dev-stop    - Detener servicios de desarrollo"
    Write-Info "  dev-logs    - Ver logs de desarrollo"
    Write-Info "  help        - Mostrar esta ayuda"
    Write-Info ""
    Write-Info "Ejemplos:"
    Write-Info "  .\manage.ps1 -Command setup"
    Write-Info "  .\manage.ps1 -Command start"
    Write-Info "  .\manage.ps1 -Command logs -Service auth-service"
    Write-Info "  .\manage.ps1 -Command dev"
}

# Función principal
Test-Dependencies

switch ($Command) {
    'setup' { Initialize-Setup }
    'build' { Build-Images }
    'start' { Start-Services }
    'stop' { Stop-Services }
    'restart' { Restart-Services }
    'update' { Update-Services }
    'logs' { Show-Logs }
    'status' { Show-Status }
    'cleanup' { Clear-Resources }
    'dev' { Start-Development }
    'dev-stop' { Stop-Development }
    'dev-logs' { Show-DevLogs }
    'help' { Show-Help }
    default { 
        Write-Error "Comando no reconocido: $Command"
        Show-Help
        exit 1
    }
}