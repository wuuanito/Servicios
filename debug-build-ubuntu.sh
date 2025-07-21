#!/bin/bash

# Script de diagnóstico y construcción para Ubuntu/Linux
# NaturePharma System - Debug Build Script

echo "=== NaturePharma System - Debug Build Script para Ubuntu ==="
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

# Verificar si Docker está instalado y ejecutándose
echo "1. Verificando Docker..."
if ! command -v docker &> /dev/null; then
    show_error "Docker no está instalado. Instálalo con: sudo apt update && sudo apt install docker.io"
fi

if ! sudo docker info &> /dev/null; then
    show_error "Docker no está ejecutándose. Inicia el servicio con: sudo systemctl start docker"
fi

show_success "Docker está instalado y ejecutándose"

# Verificar si Docker Compose está instalado
echo "\n2. Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    show_error "Docker Compose no está instalado. Instálalo con: sudo apt install docker-compose"
fi

show_success "Docker Compose está instalado"

# Verificar que estamos en el directorio correcto
echo "\n3. Verificando directorio de trabajo..."
if [ ! -f "docker-compose.yml" ]; then
    show_error "No se encontró docker-compose.yml. Asegúrate de estar en el directorio correcto."
fi

show_success "Archivo docker-compose.yml encontrado"
echo "Directorio actual: $(pwd)"

# Verificar Dockerfiles de servicios
echo "\n4. Verificando Dockerfiles..."
services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")

for service in "${services[@]}"; do
    if [ -f "$service/Dockerfile" ]; then
        show_success "$service/Dockerfile encontrado"
    else
        show_error "$service/Dockerfile NO encontrado"
    fi
done

# Verificar Dockerfile especial para log-monitor
if [ -f "Dockerfile.log-monitor" ]; then
    show_success "Dockerfile.log-monitor encontrado"
else
    show_error "Dockerfile.log-monitor NO encontrado"
fi

# Limpiar entorno Docker
echo "\n5. Limpiando entorno Docker..."
show_info "Deteniendo contenedores existentes..."
sudo docker-compose down --remove-orphans 2>/dev/null || true

show_info "Eliminando imágenes antiguas..."
sudo docker system prune -f

show_info "Eliminando volúmenes no utilizados..."
sudo docker volume prune -f

show_success "Entorno Docker limpiado"

# Construir servicios individualmente
echo "\n6. Construyendo servicios individualmente..."

for service in "${services[@]}"; do
    echo "\n--- Construyendo $service ---"
    if sudo docker build -t "naturepharma-$service" "./$service/"; then
        show_success "$service construido exitosamente"
    else
        show_error "Error al construir $service"
    fi
done

# Construir log-monitor
echo "\n--- Construyendo log-monitor ---"
if sudo docker build -f Dockerfile.log-monitor -t "naturepharma-log-monitor" "."; then
    show_success "log-monitor construido exitosamente"
else
    show_error "Error al construir log-monitor"
fi

# Iniciar todos los servicios
echo "\n7. Iniciando todos los servicios..."
if sudo docker-compose up -d; then
    show_success "Servicios iniciados exitosamente"
else
    show_error "Error al iniciar servicios"
fi

# Esperar a que los servicios se inicien
echo "\n8. Esperando a que los servicios se inicien..."
sleep 10

# Mostrar estado de los servicios
echo "\n9. Estado de los servicios:"
sudo docker-compose ps

# Mostrar logs de servicios que puedan tener problemas
echo "\n10. Verificando logs de servicios..."
for service in "${services[@]}"; do
    echo "\n--- Logs de $service (últimas 5 líneas) ---"
    sudo docker-compose logs --tail=5 "$service" 2>/dev/null || echo "No hay logs disponibles para $service"
done

# Mostrar URLs de acceso
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
echo "=== COMANDOS ÚTILES ==="
echo "Ver logs: sudo docker-compose logs [servicio]"
echo "Reiniciar servicio: sudo docker-compose restart [servicio]"
echo "Detener todo: sudo docker-compose down"
echo "Ver estado: sudo docker-compose ps"
echo ""
echo "✅ Script completado exitosamente!"