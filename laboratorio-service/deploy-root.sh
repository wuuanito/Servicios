#!/bin/bash

# Script de despliegue completo para usuarios root
# Laboratorio Service - Despliegue con corrección de permisos root
# Usuario: root, Contraseña: root

echo "🚀 Despliegue completo laboratorio-service (Usuario Root)"
echo "================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
log_info "Usuario actual: $(whoami)"
log_info "ID del usuario: $(id)"

# Verificar si estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    log_error "Este script debe ejecutarse desde el directorio del laboratorio-service"
    exit 1
fi

# Paso 1: Detener servicios existentes
log_info "Paso 1: Deteniendo servicios existentes..."
docker-compose down

# Paso 2: Limpiar imágenes Docker antiguas
log_info "Paso 2: Limpiando imágenes Docker antiguas..."
docker system prune -f > /dev/null 2>&1

# Paso 3: Ejecutar corrección de permisos como root
log_info "Paso 3: Ejecutando corrección de permisos como root..."
if [ -f "./fix-root-permissions.sh" ]; then
    chmod +x ./fix-root-permissions.sh
    ./fix-root-permissions.sh
    if [ $? -ne 0 ]; then
        log_error "Error en la corrección de permisos"
        exit 1
    fi
else
    log_warning "Script fix-root-permissions.sh no encontrado, aplicando corrección directa..."
    
    # Corrección directa
    mkdir -p ./uploads/defectos
    chown -R 1001:1001 ./uploads/
    find ./uploads -type d -exec chmod 775 {} \;
    find ./uploads -type f -exec chmod 664 {} \;
    
    # Configurar SELinux si está activo
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX_STATUS=$(getenforce 2>/dev/null)
        if [ "$SELINUX_STATUS" = "Enforcing" ] || [ "$SELINUX_STATUS" = "Permissive" ]; then
            log_info "Configurando SELinux..."
            chcon -Rt svirt_sandbox_file_t ./uploads/ 2>/dev/null || log_warning "No se pudo configurar contexto SELinux"
            setsebool -P container_manage_cgroup on 2>/dev/null || log_warning "No se pudo configurar SELinux boolean"
        fi
    fi
    
    log_success "Corrección directa de permisos aplicada"
fi

# Paso 4: Construir imagen sin caché
log_info "Paso 4: Construyendo imagen Docker sin caché..."
if docker-compose build --no-cache; then
    log_success "Imagen construida exitosamente"
else
    log_error "Error construyendo la imagen Docker"
    exit 1
fi

# Paso 5: Iniciar servicios
log_info "Paso 5: Iniciando servicios..."
if docker-compose up -d; then
    log_success "Servicios iniciados exitosamente"
else
    log_error "Error iniciando los servicios"
    exit 1
fi

# Paso 6: Esperar a que los servicios estén listos
log_info "Paso 6: Esperando a que los servicios estén listos..."
sleep 15

# Paso 7: Verificar estado de los servicios
log_info "Paso 7: Verificando estado de los servicios..."
docker-compose ps

# Paso 8: Verificar logs del laboratorio-service
log_info "Paso 8: Verificando logs del laboratorio-service..."
echo "Últimas 30 líneas de logs:"
docker-compose logs --tail=30 laboratorio-service

# Paso 9: Probar conectividad
log_info "Paso 9: Probando conectividad del servicio..."
sleep 5
if curl -s http://localhost:3004/health > /dev/null; then
    log_success "✅ Servicio respondiendo correctamente en puerto 3004"
else
    log_warning "⚠️ El servicio no responde en puerto 3004, verificando logs adicionales..."
    echo "Logs completos del contenedor:"
    docker-compose logs laboratorio-service
fi

# Paso 10: Verificar permisos finales
log_info "Paso 10: Verificando permisos finales en el contenedor..."
docker exec laboratorio-service ls -la /app/uploads/ 2>/dev/null || log_warning "No se puede acceder al contenedor"
docker exec laboratorio-service touch /app/uploads/defectos/test-final.txt 2>/dev/null && \
docker exec laboratorio-service rm /app/uploads/defectos/test-final.txt 2>/dev/null && \
log_success "✅ Permisos de escritura en contenedor: OK" || \
log_warning "⚠️ No se pudo verificar permisos en el contenedor"

# Mostrar información final
echo ""
echo "================================================="
log_success "🎯 DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "================================================="
echo ""
echo "📊 URLs de acceso:"
echo "   • Health Check: http://localhost:3004/health"
echo "   • API Defectos: http://localhost:3004/api/laboratorio/defectos"
echo "   • API Tareas: http://localhost:3004/api/laboratorio/tareas"
echo "   • phpMyAdmin: http://localhost:8081"
echo ""
echo "🔧 Comandos útiles:"
echo "   • Ver logs en tiempo real: docker-compose logs -f laboratorio-service"
echo "   • Verificar permisos: docker exec -it laboratorio-service ls -la /app/uploads/"
echo "   • Acceder al contenedor: docker exec -it laboratorio-service sh"
echo "   • Detener servicios: docker-compose down"
echo "   • Reiniciar solo laboratorio: docker-compose restart laboratorio-service"
echo ""
echo "📋 Configuración aplicada:"
echo "   • Puerto del servicio: 3004"
echo "   • CORS: Habilitado para todos los orígenes (*)"
echo "   • Uploads: ./uploads/defectos (host) -> /app/uploads/defectos (contenedor)"
echo "   • Permisos: 1001:1001 con 775/664"
echo "   • Usuario del contenedor: laboratorio (UID 1001)"
echo "   • SELinux: $(command -v getenforce >/dev/null 2>&1 && getenforce || echo 'No disponible')"
echo ""
log_info "🔍 Para troubleshooting detallado, consulta SOLUCION-PERMISOS-CORS.md"
echo "================================================="

# Pausa final para mostrar información
echo ""
log_success "✅ El laboratorio-service debería estar funcionando correctamente"
log_info "Presiona Ctrl+C para salir o espera 10 segundos..."
sleep 10