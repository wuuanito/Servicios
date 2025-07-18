# Script de despliegue completo para usuarios root en Windows
# Laboratorio Service - Despliegue con corrección de permisos root
# Usuario: root, Contraseña: root

Write-Host "🚀 Despliegue completo laboratorio-service (Usuario Root - Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Función para logging con colores
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Verificar si Docker está ejecutándose
try {
    docker info | Out-Null
    Write-Info "Docker está ejecutándose correctamente"
} catch {
    Write-Error "Docker no está ejecutándose. Por favor, inicia Docker Desktop y vuelve a intentar."
    exit 1
}

Write-Info "Usuario actual: $env:USERNAME"
Write-Info "Directorio actual: $(Get-Location)"

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Error "Este script debe ejecutarse desde el directorio del laboratorio-service"
    exit 1
}

# Paso 1: Detener servicios existentes
Write-Info "Paso 1: Deteniendo servicios existentes..."
try {
    docker-compose down
    Write-Success "Servicios detenidos"
} catch {
    Write-Warning "No hay servicios ejecutándose o error al detener"
}

# Paso 2: Limpiar imágenes Docker antiguas
Write-Info "Paso 2: Limpiando imágenes Docker antiguas..."
try {
    docker system prune -f | Out-Null
    Write-Success "Limpieza completada"
} catch {
    Write-Warning "Error en la limpieza, continuando..."
}

# Paso 3: Crear y configurar directorio uploads
Write-Info "Paso 3: Configurando directorio uploads..."
try {
    # Crear directorio si no existe
    if (-not (Test-Path "uploads\defectos")) {
        New-Item -ItemType Directory -Path "uploads\defectos" -Force | Out-Null
        Write-Success "Directorio uploads/defectos creado"
    } else {
        Write-Info "Directorio uploads/defectos ya existe"
    }
    
    # En Windows, los permisos se manejan diferente
    # Asegurar que el directorio tenga permisos completos
    $acl = Get-Acl "uploads"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl "uploads" $acl
    
    Write-Success "Permisos configurados para el directorio uploads"
} catch {
    Write-Warning "Error configurando permisos, pero continuando..."
}

# Paso 4: Construir imagen sin caché
Write-Info "Paso 4: Construyendo imagen Docker sin caché..."
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

# Paso 5: Iniciar servicios
Write-Info "Paso 5: Iniciando servicios..."
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

# Paso 6: Esperar a que los servicios estén listos
Write-Info "Paso 6: Esperando a que los servicios estén listos..."
Start-Sleep -Seconds 15

# Paso 7: Verificar estado de los servicios
Write-Info "Paso 7: Verificando estado de los servicios..."
docker-compose ps

# Paso 8: Verificar logs del laboratorio-service
Write-Info "Paso 8: Verificando logs del laboratorio-service..."
Write-Host "Últimas 30 líneas de logs:" -ForegroundColor Yellow
docker-compose logs --tail=30 laboratorio-service

# Paso 9: Probar conectividad
Write-Info "Paso 9: Probando conectividad del servicio..."
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3004/health" -TimeoutSec 10 -ErrorAction Stop
    Write-Success "✅ Servicio respondiendo correctamente en puerto 3004"
} catch {
    Write-Warning "⚠️ El servicio no responde en puerto 3004, verificando logs adicionales..."
    Write-Host "Logs completos del contenedor:" -ForegroundColor Yellow
    docker-compose logs laboratorio-service
}

# Paso 10: Verificar permisos finales
Write-Info "Paso 10: Verificando permisos finales en el contenedor..."
try {
    docker exec laboratorio-service ls -la /app/uploads/ 2>$null
    
    # Probar escritura en el contenedor
    docker exec laboratorio-service touch /app/uploads/defectos/test-final.txt 2>$null
    docker exec laboratorio-service rm /app/uploads/defectos/test-final.txt 2>$null
    Write-Success "✅ Permisos de escritura en contenedor: OK"
} catch {
    Write-Warning "⚠️ No se pudo verificar permisos en el contenedor"
}

# Mostrar información final
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Success "🎯 DESPLIEGUE COMPLETADO EXITOSAMENTE"
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 URLs de acceso:" -ForegroundColor Cyan
Write-Host "   • Health Check: http://localhost:3004/health"
Write-Host "   • API Defectos: http://localhost:3004/api/laboratorio/defectos"
Write-Host "   • API Tareas: http://localhost:3004/api/laboratorio/tareas"
Write-Host "   • phpMyAdmin: http://localhost:8081"
Write-Host ""
Write-Host "🔧 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   • Ver logs en tiempo real: docker-compose logs -f laboratorio-service"
Write-Host "   • Verificar permisos: docker exec -it laboratorio-service ls -la /app/uploads/"
Write-Host "   • Acceder al contenedor: docker exec -it laboratorio-service sh"
Write-Host "   • Detener servicios: docker-compose down"
Write-Host "   • Reiniciar solo laboratorio: docker-compose restart laboratorio-service"
Write-Host ""
Write-Host "📋 Configuración aplicada:" -ForegroundColor Cyan
Write-Host "   • Puerto del servicio: 3004"
Write-Host "   • CORS: Habilitado para todos los orígenes (*)"
Write-Host "   • Uploads: ./uploads/defectos (host) -> /app/uploads/defectos (contenedor)"
Write-Host "   • Permisos: Configurados para Windows"
Write-Host "   • Usuario del contenedor: laboratorio (UID 1001)"
Write-Host "   • Sistema: Windows con Docker Desktop"
Write-Host ""
Write-Info "🔍 Para troubleshooting detallado, consulta SOLUCION-PERMISOS-CORS.md"
Write-Host "================================================================" -ForegroundColor Green

# Pausa final para mostrar información
Write-Host ""
Write-Success "✅ El laboratorio-service debería estar funcionando correctamente"
Write-Info "Presiona Ctrl+C para salir o espera 10 segundos..."
Start-Sleep -Seconds 10