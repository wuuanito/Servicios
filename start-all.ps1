# Script de inicio rápido para NaturePharma Services
# Levanta todo el sistema con un solo comando

Write-Host "=== NaturePharma Services - Inicio Rápido ===" -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker está corriendo
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✓ Docker está corriendo" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker no está corriendo. Por favor inicia Docker Desktop." -ForegroundColor Red
    Write-Host "Presiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Verificar si existe .env
if (!(Test-Path ".env")) {
    Write-Host "Configurando entorno por primera vez..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✓ Archivo .env creado" -ForegroundColor Green
    
    # Crear directorios necesarios
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
        }
    }
    Write-Host "✓ Directorios creados" -ForegroundColor Green
}

# Mostrar opciones
Write-Host ""
Write-Host "Selecciona el modo de inicio:" -ForegroundColor Cyan
Write-Host "1. Producción (recomendado para uso normal)" -ForegroundColor White
Write-Host "2. Desarrollo (con hot-reload)" -ForegroundColor White
Write-Host "3. Solo Base de Datos (phpMyAdmin)" -ForegroundColor White
Write-Host "4. Salir" -ForegroundColor White
Write-Host ""

do {
    $choice = Read-Host "Ingresa tu opción (1-4)"
} while ($choice -notmatch '^[1-4]$')

switch ($choice) {
    '1' {
        Write-Host ""
        Write-Host "Iniciando servicios en modo PRODUCCIÓN..." -ForegroundColor Green
        Write-Host "Esto puede tomar unos minutos la primera vez..." -ForegroundColor Yellow
        Write-Host ""
        
        docker-compose up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "=== ✓ SERVICIOS INICIADOS CORRECTAMENTE ===" -ForegroundColor Green
            Write-Host ""
            Write-Host "URLs disponibles:" -ForegroundColor Cyan
            Write-Host "• API Gateway (Nginx): http://localhost" -ForegroundColor White
            Write-Host "• Auth Service: http://localhost:4001" -ForegroundColor White
            Write-Host "• Calendar Service: http://localhost:3003" -ForegroundColor White
            Write-Host "• Laboratorio Service: http://localhost:3004" -ForegroundColor White
            Write-Host "• Solicitudes Service: http://localhost:3001" -ForegroundColor White
            Write-Host "• Cremer Backend: http://localhost:3002" -ForegroundColor White
            Write-Host "• Tecnomaco Backend: http://localhost:3006" -ForegroundColor White
            Write-Host "• Servidor RPS: http://localhost:4000" -ForegroundColor White
            Write-Host "• phpMyAdmin: http://localhost:8081" -ForegroundColor White
            Write-Host ""
            Write-Host "Para ver logs: docker-compose logs -f" -ForegroundColor Yellow
            Write-Host "Para detener: docker-compose down" -ForegroundColor Yellow
        } else {
            Write-Host "Error al iniciar los servicios" -ForegroundColor Red
        }
    }
    
    '2' {
        Write-Host ""
        Write-Host "Iniciando servicios en modo DESARROLLO..." -ForegroundColor Green
        Write-Host "Los servicios se reiniciarán automáticamente al cambiar código" -ForegroundColor Yellow
        Write-Host ""
        
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
    }
    
    '3' {
        Write-Host ""
        Write-Host "Iniciando solo phpMyAdmin..." -ForegroundColor Green
        Write-Host "Asegúrate de que MySQL esté corriendo localmente" -ForegroundColor Yellow
        Write-Host ""
        
        docker-compose up -d phpmyadmin
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ phpMyAdmin iniciado: http://localhost:8081" -ForegroundColor Green
        } else {
            Write-Host "Error al iniciar phpMyAdmin" -ForegroundColor Red
        }
    }
    
    '4' {
        Write-Host "Saliendo..." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")