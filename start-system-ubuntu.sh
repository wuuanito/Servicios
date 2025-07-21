#!/bin/bash

# Script de inicio del sistema NaturePharma para Ubuntu/Linux
# Versión: 2.0
# Fecha: $(date +%Y-%m-%d)

echo "=== NaturePharma System Startup Script para Ubuntu ==="
echo "Iniciando sistema de microservicios..."
echo "Fecha: $(date)"
echo ""

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "Directorio de trabajo: $(pwd)"
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

# Verificar Docker
echo "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    show_error "Docker no está instalado. Instálalo con: sudo apt update && sudo apt install docker.io"
fi

if ! sudo docker info &> /dev/null; then
    show_error "Docker no está ejecutándose. Inicia el servicio con: sudo systemctl start docker"
fi

show_success "Docker está ejecutándose"

# Verificar Docker Compose
echo "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    show_error "Docker Compose no está instalado. Instálalo con: sudo apt install docker-compose"
fi

show_success "Docker Compose está disponible"

# Detener servicios existentes
echo "\nDeteniendo servicios existentes..."
sudo docker-compose down --remove-orphans 2>/dev/null || true
show_info "Servicios existentes detenidos"

# Construir e iniciar servicios
echo "\nConstruyendo e iniciando servicios..."
if sudo docker-compose up -d --build; then
    show_success "Servicios construidos e iniciados exitosamente"
else
    show_error "Error al construir o iniciar servicios. Ejecuta debug-build-ubuntu.sh para diagnóstico detallado."
fi

# Esperar a que los servicios se inicien
echo "\nEsperando a que los servicios se inicien..."
sleep 15

# Mostrar estado de los servicios
echo "\nEstado de los servicios:"
sudo docker-compose ps

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
echo "=== COMANDOS ÚTILES DE DOCKER COMPOSE ==="
echo "Ver logs en tiempo real: sudo docker-compose logs -f"
echo "Ver logs de un servicio: sudo docker-compose logs [nombre-servicio]"
echo "Reiniciar un servicio: sudo docker-compose restart [nombre-servicio]"
echo "Detener todos los servicios: sudo docker-compose down"
echo "Ver estado de servicios: sudo docker-compose ps"
echo "Reconstruir servicios: sudo docker-compose up -d --build"
echo ""
echo "=== SCRIPTS DE DIAGNÓSTICO ==="
echo "Para diagnóstico detallado: ./debug-build-ubuntu.sh"
echo "Para reparar contexto Docker: ./fix-docker-context-ubuntu.sh"
echo ""
echo "✅ Sistema NaturePharma iniciado exitosamente!"
echo "Todos los servicios están disponibles en las URLs mostradas arriba."