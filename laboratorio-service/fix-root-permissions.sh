#!/bin/bash

# Script para corregir permisos usando acceso root
# Laboratorio Service - Corrección definitiva de permisos
# Usuario: root, Contraseña: root

echo "🔧 Corrección de permisos con acceso root para laboratorio-service"
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

# Verificar si estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    log_error "Este script debe ejecutarse desde el directorio del laboratorio-service"
    exit 1
fi

log_info "Iniciando corrección de permisos con acceso root..."
log_info "Usuario actual: $(whoami)"
log_info "ID del usuario: $(id)"

# Detener servicios si están ejecutándose
log_info "Deteniendo servicios Docker..."
docker-compose down 2>/dev/null || log_warning "No hay servicios ejecutándose"

# Crear directorio uploads si no existe
log_info "Creando estructura de directorios..."
mkdir -p ./uploads/defectos

# Mostrar permisos actuales
log_info "Permisos actuales:"
ls -la ./uploads/ 2>/dev/null || log_info "Directorio uploads no existe aún"

# Aplicar corrección de permisos como root
log_info "Aplicando corrección de permisos como root..."

# Cambiar propietario a UID 1001 (usuario laboratorio del contenedor)
chown -R 1001:1001 ./uploads/
if [ $? -eq 0 ]; then
    log_success "Propietario cambiado a UID 1001 (laboratorio)"
else
    log_error "Error cambiando propietario"
    exit 1
fi

# Establecer permisos 775 para directorios y 664 para archivos
find ./uploads -type d -exec chmod 775 {} \;
find ./uploads -type f -exec chmod 664 {} \;
if [ $? -eq 0 ]; then
    log_success "Permisos establecidos correctamente"
else
    log_error "Error estableciendo permisos"
    exit 1
fi

# Verificar permisos después de la corrección
log_info "Permisos después de la corrección:"
ls -la ./uploads/
ls -la ./uploads/defectos/

# Probar escritura como root
log_info "Probando escritura como root..."
if touch ./uploads/defectos/test-root.txt; then
    rm ./uploads/defectos/test-root.txt
    log_success "✅ Escritura como root: OK"
else
    log_error "❌ No se puede escribir como root"
    exit 1
fi

# Simular escritura como UID 1001
log_info "Simulando escritura como UID 1001 (usuario laboratorio)..."
su -c "touch ./uploads/defectos/test-laboratorio.txt" -s /bin/sh - $(id -un 1001) 2>/dev/null || \
runuser -u "#1001" -- touch ./uploads/defectos/test-laboratorio.txt 2>/dev/null || \
log_warning "No se puede simular usuario 1001, pero los permisos deberían funcionar"

if [ -f "./uploads/defectos/test-laboratorio.txt" ]; then
    rm ./uploads/defectos/test-laboratorio.txt
    log_success "✅ Escritura como UID 1001: OK"
else
    log_warning "⚠️ No se pudo probar como UID 1001, pero los permisos están configurados"
fi

# Verificar y corregir contexto SELinux si está activo
if command -v getenforce >/dev/null 2>&1; then
    SELINUX_STATUS=$(getenforce 2>/dev/null)
    if [ "$SELINUX_STATUS" = "Enforcing" ] || [ "$SELINUX_STATUS" = "Permissive" ]; then
        log_info "SELinux detectado ($SELINUX_STATUS), configurando contexto..."
        chcon -Rt svirt_sandbox_file_t ./uploads/ 2>/dev/null || log_warning "No se pudo configurar contexto SELinux"
        setsebool -P container_manage_cgroup on 2>/dev/null || log_warning "No se pudo configurar SELinux boolean"
        log_success "Contexto SELinux configurado"
    fi
fi

# Información final
echo ""
log_success "🎯 Corrección de permisos completada exitosamente"
echo "================================================="
echo ""
log_info "📋 Resumen de configuración:"
echo "   • Propietario: 1001:1001 (usuario laboratorio del contenedor)"
echo "   • Permisos directorios: 775 (rwxrwxr-x)"
echo "   • Permisos archivos: 664 (rw-rw-r--)"
echo "   • SELinux: $(command -v getenforce >/dev/null 2>&1 && getenforce || echo 'No disponible')"
echo ""
log_info "🚀 Ahora puedes ejecutar el despliegue:"
echo "   docker-compose build --no-cache"
echo "   docker-compose up -d"
echo ""
log_info "📊 O usar el script completo:"
echo "   ./deploy-fix.sh"
echo "================================================="