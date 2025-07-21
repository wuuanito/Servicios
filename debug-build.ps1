# Script de diagnóstico para Windows PowerShell
# NaturePharma - Diagnóstico del Sistema

Write-Host "🔍 Diagnóstico del Sistema NaturePharma" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "📁 Directorio de trabajo: $(Get-Location)" -ForegroundColor Yellow
Write-Host ""

# Verificar Docker
try {
    docker --version | Out-Null
    Write-Host "✅ Docker está corriendo" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Verificar Docker Compose
try {
    docker-compose --version | Out-Null
    Write-Host "✅ Docker Compose está disponible" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose no está disponible" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verificar docker-compose.yml
if (Test-Path "docker-compose.yml") {
    Write-Host "✅ docker-compose.yml encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ docker-compose.yml NO encontrado" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Lista de servicios a verificar
$services = @(
    "auth-service",
    "calendar-service", 
    "laboratorio-service",
    "ServicioSolicitudesOt",
    "Cremer-Backend",
    "Tecnomaco-Backend",
    "SERVIDOR_RPS"
)

Write-Host "🔍 Verificando Dockerfiles..." -ForegroundColor Cyan
$missing_dockerfiles = @()

foreach ($service in $services) {
    $dockerfile_path = "$service\Dockerfile"
    if (Test-Path $dockerfile_path) {
        Write-Host "✅ $service/Dockerfile encontrado" -ForegroundColor Green
    } else {
        Write-Host "❌ $service/Dockerfile NO encontrado" -ForegroundColor Red
        $missing_dockerfiles += $service
    }
}

Write-Host ""

if ($missing_dockerfiles.Count -gt 0) {
    Write-Host "❌ Error: Faltan los siguientes Dockerfiles:" -ForegroundColor Red
    foreach ($missing in $missing_dockerfiles) {
        Write-Host "   • $missing/Dockerfile" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Por favor, crea los Dockerfiles faltantes antes de continuar." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ Todos los Dockerfiles están presentes" -ForegroundColor Green
}

Write-Host ""
Write-Host "🏗️ Construyendo servicios individualmente..." -ForegroundColor Cyan

# Limpiar entorno Docker
Write-Host "🧹 Limpiando entorno Docker..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null
docker system prune -f 2>$null

Write-Host ""

# Construir cada servicio individualmente
foreach ($service in $services) {
    Write-Host "🔨 Construyendo $service..." -ForegroundColor Cyan
    $result = docker-compose build $service 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $service construido exitosamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error construyendo $service:" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host ""
Write-Host "🚀 Iniciando todos los servicios..." -ForegroundColor Cyan
$start_result = docker-compose up -d 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Servicios iniciados exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Estado de los servicios:" -ForegroundColor Cyan
    docker-compose ps
    Write-Host ""
    Write-Host "🌐 Servicios disponibles:" -ForegroundColor Cyan
    Write-Host "   • Auth Service: http://localhost:4001" -ForegroundColor Yellow
    Write-Host "   • Calendar Service: http://localhost:3003" -ForegroundColor Yellow
    Write-Host "   • Laboratorio Service: http://localhost:3004" -ForegroundColor Yellow
    Write-Host "   • Solicitudes Service: http://localhost:3001" -ForegroundColor Yellow
    Write-Host "   • Cremer Backend: http://localhost:3002" -ForegroundColor Yellow
    Write-Host "   • Tecnomaco Backend: http://localhost:3006" -ForegroundColor Yellow
    Write-Host "   • Servidor RPS: http://localhost:4000" -ForegroundColor Yellow
    Write-Host "   • phpMyAdmin: http://localhost:8081" -ForegroundColor Yellow
    Write-Host "   • Log Monitor: http://localhost:8080" -ForegroundColor Yellow
} else {
    Write-Host "❌ Error iniciando servicios:" -ForegroundColor Red
    Write-Host $start_result -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Diagnóstico completado" -ForegroundColor Green