#!/bin/bash

# Script de reparación de contexto Docker para Ubuntu/Linux
# NaturePharma System - Fix Docker Context Script

echo "=== NaturePharma System - Fix Docker Context para Ubuntu ==="
echo "Reparando problemas de contexto Docker..."
echo "Fecha: $(date)"
echo ""

# Función para mostrar errores
show_error() {
    echo "❌ ERROR: $1"
    exit 1
}

# Función para mostrar éxito
show_success() {
    echo "✅ $1"
}

# Función para mostrar información
show_info() {
    echo "ℹ️  $1"
}

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "Directorio de trabajo: $(pwd)"
echo ""

# Verificar Docker
echo "1. Verificando Docker..."
if ! command -v docker &> /dev/null; then
    show_error "Docker no está instalado. Instálalo con: sudo apt update && sudo apt install docker.io"
fi

if ! sudo docker info &> /dev/null; then
    show_error "Docker no está ejecutándose. Inicia el servicio con: sudo systemctl start docker"
fi

show_success "Docker está ejecutándose"

# Limpiar completamente el entorno Docker
echo "\n2. Limpiando entorno Docker completamente..."
show_info "Deteniendo todos los contenedores..."
sudo docker-compose down --remove-orphans --volumes 2>/dev/null || true
sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true

show_info "Eliminando contenedores..."
sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true

show_info "Eliminando imágenes del proyecto..."
sudo docker rmi $(sudo docker images | grep naturepharma | awk '{print $3}') 2>/dev/null || true

show_info "Limpiando sistema Docker..."
sudo docker system prune -af
sudo docker volume prune -f
sudo docker network prune -f

show_success "Entorno Docker limpiado completamente"

# Verificar estructura de directorios
echo "\n3. Verificando estructura de directorios..."
services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")

for service in "${services[@]}"; do
    if [ -d "$service" ]; then
        show_success "Directorio $service existe"
        if [ -f "$service/Dockerfile" ]; then
            show_success "$service/Dockerfile existe"
        else
            show_error "$service/Dockerfile NO existe"
        fi
    else
        show_error "Directorio $service NO existe"
    fi
done

# Verificar docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    show_success "docker-compose.yml existe"
else
    show_error "docker-compose.yml NO existe"
fi

# Verificar Dockerfile.log-monitor
if [ -f "Dockerfile.log-monitor" ]; then
    show_success "Dockerfile.log-monitor existe"
else
    show_error "Dockerfile.log-monitor NO existe"
fi

# Construir imágenes explícitamente con contexto correcto
echo "\n4. Construyendo imágenes con contexto explícito..."

for service in "${services[@]}"; do
    echo "\n--- Construyendo $service ---"
    show_info "Contexto: ./$service/"
    show_info "Dockerfile: ./$service/Dockerfile"
    
    if sudo docker build -t "naturepharma-$service:latest" "./$service/"; then
        show_success "$service construido exitosamente"
    else
        show_error "Error al construir $service"
    fi
done

# Construir log-monitor
echo "\n--- Construyendo log-monitor ---"
show_info "Contexto: ."
show_info "Dockerfile: ./Dockerfile.log-monitor"

if sudo docker build -f "Dockerfile.log-monitor" -t "naturepharma-log-monitor:latest" "."; then
    show_success "log-monitor construido exitosamente"
else
    show_error "Error al construir log-monitor"
fi

# Verificar imágenes construidas
echo "\n5. Verificando imágenes construidas..."
sudo docker images | grep naturepharma

# Iniciar servicios
echo "\n6. Iniciando servicios..."
if sudo docker-compose up -d; then
    show_success "Servicios iniciados exitosamente"
else
    show_error "Error al iniciar servicios"
fi

# Esperar y verificar estado
echo "\n7. Esperando y verificando estado..."
sleep 10
sudo docker-compose ps

# Mostrar logs de servicios problemáticos
echo "\n8. Verificando logs de servicios..."
failed_services=$(sudo docker-compose ps --services --filter "status=exited")
if [ ! -z "$failed_services" ]; then
    echo "\n⚠️  Servicios con problemas detectados:"
    for service in $failed_services; do
        echo "\n--- Logs de $service ---"
        sudo docker-compose logs --tail=10 "$service"
    done
else
    show_success "Todos los servicios están ejecutándose correctamente"
fi

echo "\n=== SERVICIOS DISPONIBLES ==="
echo "🔐 Auth Service: http://localhost:4001"
echo "📅 Calendar Service: http://localhost:4002"
echo "🧪 Laboratorio Service: http://localhost:4003"
echo "📋 Solicitudes Service: http://localhost:4004"
echo "🏭 Cremer Backend: http://localhost:3002"
echo "⚙️  Tecnomaco Backend: http://localhost:3006"
echo "📊 Servidor RPS: http://localhost:4000"
echo "🗄️  phpMyAdmin: http://localhost:8081"
echo "📋 Log Monitor: http://localhost:8080"
echo ""
echo "✅ Reparación de contexto Docker completada!"