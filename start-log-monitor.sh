#!/bin/bash

# Script para iniciar el Monitor de Logs de NaturePharma
# Autor: NaturePharma Dev Team
# Fecha: $(date +%Y-%m-%d)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    echo -e "${2}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_success() {
    print_message "✅ $1" "$GREEN"
}

print_error() {
    print_message "❌ $1" "$RED"
}

print_warning() {
    print_message "⚠️  $1" "$YELLOW"
}

print_info() {
    print_message "ℹ️  $1" "$BLUE"
}

# Banner
echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════════"
echo "           🚀 NATUREPHARMA LOG MONITOR STARTER 🚀"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"

# Verificar si Docker está instalado y ejecutándose
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker no está ejecutándose. Por favor inicia Docker primero."
    exit 1
fi

print_success "Docker está disponible y ejecutándose"

# Verificar si Docker Compose está disponible
print_info "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
    exit 1
fi

print_success "Docker Compose está disponible"

# Verificar si el archivo docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_error "Archivo docker-compose.yml no encontrado en el directorio actual"
    exit 1
fi

print_success "Archivo docker-compose.yml encontrado"

# Construir e iniciar solo el servicio de monitoreo de logs
print_info "Construyendo e iniciando el Monitor de Logs..."

# Detener el servicio si ya está ejecutándose
print_info "Deteniendo servicio anterior si existe..."
docker-compose stop log-monitor 2>/dev/null || true
docker-compose rm -f log-monitor 2>/dev/null || true

# Construir la imagen
print_info "Construyendo imagen del Monitor de Logs..."
if docker-compose build log-monitor; then
    print_success "Imagen construida exitosamente"
else
    print_error "Error construyendo la imagen"
    exit 1
fi

# Iniciar el servicio
print_info "Iniciando Monitor de Logs..."
if docker-compose up -d log-monitor; then
    print_success "Monitor de Logs iniciado exitosamente"
else
    print_error "Error iniciando el Monitor de Logs"
    exit 1
fi

# Esperar un momento para que el servicio se inicie
print_info "Esperando que el servicio se inicie completamente..."
sleep 5

# Verificar el estado del servicio
print_info "Verificando estado del servicio..."
if docker-compose ps log-monitor | grep -q "Up"; then
    print_success "Monitor de Logs está ejecutándose correctamente"
else
    print_warning "El servicio puede no estar ejecutándose correctamente"
    print_info "Mostrando logs del servicio:"
    docker-compose logs --tail=20 log-monitor
fi

# Mostrar información de acceso
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════════"
echo "                    🎉 MONITOR INICIADO 🎉"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"

print_success "Monitor de Logs disponible en:"
echo "   🌐 Red Local: http://192.168.20.158:8080"
echo "   🏠 Localhost: http://localhost:8080"
echo ""
print_info "Comandos útiles:"
echo "   📊 Ver logs del monitor: docker-compose logs -f log-monitor"
echo "   🔄 Reiniciar monitor: docker-compose restart log-monitor"
echo "   ⏹️  Detener monitor: docker-compose stop log-monitor"
echo "   📈 Ver estado: docker-compose ps log-monitor"
echo ""
print_info "El monitor se actualiza automáticamente cada 10 segundos"
print_info "Puedes cambiar la frecuencia desde la interfaz web"

echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════════"
echo "                  ✨ ¡LISTO PARA USAR! ✨"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"