#!/bin/bash

# Script de despliegue con corrección de permisos y CORS
# Laboratorio Service - NaturePharma

echo "🚀 Iniciando despliegue con correcciones de permisos y CORS..."
echo "================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si Docker está ejecutándose
if ! docker info > /dev/null 2>&1; then
    log_error "Docker no está ejecutándose. Por favor, inicia Docker y vuelve a intentar."
    exit 1
fi

log_info "Docker está ejecutándose correctamente"

# Detener servicios existentes
log_info "Deteniendo servicios existentes..."
docker-compose down

# Crear directorio de uploads en el host si no existe
log_info "Creando directorio de uploads en el host..."
mkdir -p ./uploads/defectos

# Establecer permisos correctos en el host
log_info "Configurando permisos en el directorio host..."
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    # Linux o macOS
    sudo chown -R 1001:1001 ./uploads/ 2>/dev/null || chown -R 1001:1001 ./uploads/ 2>/dev/null || log_warning "No se pudieron cambiar los propietarios (puede ser normal)"
    chmod -R 775 ./uploads/
    log_success "Permisos configurados en sistema Unix"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    icacls ./uploads /grant Everyone:F /T > /dev/null 2>&1 || log_warning "No se pudieron configurar permisos en Windows (puede ser normal)"
    log_success "Permisos configurados en Windows"
else
    log_warning "Sistema operativo no reconocido, saltando configuración de permisos del host"
fi

# Limpiar imágenes Docker antiguas
log_info "Limpiando imágenes Docker antiguas..."
docker system prune -f > /dev/null 2>&1

# Construir imagen sin caché
log_info "Construyendo imagen Docker sin caché..."
if docker-compose build --no-cache; then
    log_success "Imagen construida exitosamente"
else
    log_error "Error construyendo la imagen Docker"
    exit 1
fi

# Iniciar servicios
log_info "Iniciando servicios..."
if docker-compose up -d; then
    log_success "Servicios iniciados exitosamente"
else
    log_error "Error iniciando los servicios"
    exit 1
fi

# Esperar a que los servicios estén listos
log_info "Esperando a que los servicios estén listos..."
sleep 10

# Verificar estado de los servicios
log_info "Verificando estado de los servicios..."
docker-compose ps

# Verificar logs del laboratorio-service
log_info "Verificando logs del laboratorio-service..."
echo "Últimas 20 líneas de logs:"
docker-compose logs --tail=20 laboratorio-service

# Probar conectividad
log_info "Probando conectividad del servicio..."
if curl -s http://localhost:3004/health > /dev/null; then
    log_success "Servicio respondiendo correctamente en puerto 3004"
else
    log_warning "El servicio no responde en puerto 3004, verificando logs..."
    docker-compose logs laboratorio-service
fi

# Mostrar información de acceso
echo ""
echo "================================================="
log_success "Despliegue completado"
echo "================================================="
echo ""
echo "📊 URLs de acceso:"
echo "   • Health Check: http://localhost:3004/health"
echo "   • API Defectos: http://localhost:3004/api/laboratorio/defectos"
echo "   • API Tareas: http://localhost:3004/api/laboratorio/tareas"
echo "   • phpMyAdmin: http://localhost:8081"
echo ""
echo "🔧 Comandos útiles:"
echo "   • Ver logs: docker-compose logs -f laboratorio-service"
echo "   • Verificar permisos: docker exec -it laboratorio-service ls -la /app/uploads/"
echo "   • Acceder al contenedor: docker exec -it laboratorio-service sh"
echo "   • Detener servicios: docker-compose down"
echo ""
echo "📋 Configuración:"
echo "   • Puerto del servicio: 3004"
echo "   • CORS: Habilitado para todos los orígenes"
echo "   • Uploads: ./uploads/defectos (host) -> /app/uploads/defectos (contenedor)"
echo "   • Usuario del contenedor: laboratorio (UID 1001)"
echo ""
log_info "Para más detalles, consulta SOLUCION-PERMISOS-CORS.md"
echo "================================================="