#!/bin/bash

# Script para corregir permisos en el host antes del despliegue
# Laboratorio Service - Corrección de permisos del directorio uploads

echo "🔧 Corrigiendo permisos del directorio uploads en el host..."

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

# Crear directorio uploads si no existe
log_info "Creando directorio uploads si no existe..."
mkdir -p ./uploads/defectos

# Mostrar permisos actuales
log_info "Permisos actuales del directorio uploads:"
ls -la ./uploads/

# Detectar el sistema operativo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    log_info "Sistema Linux detectado"
    
    # Verificar si tenemos permisos de sudo
    if sudo -n true 2>/dev/null; then
        log_info "Permisos de sudo disponibles, corrigiendo permisos..."
        sudo chown -R 1001:1001 ./uploads/
        sudo chmod -R 775 ./uploads/
        log_success "Permisos corregidos con sudo"
    else
        log_warning "Sin permisos de sudo, intentando corrección básica..."
        chown -R 1001:1001 ./uploads/ 2>/dev/null || log_warning "No se pudo cambiar el propietario"
        chmod -R 775 ./uploads/
        log_info "Corrección básica aplicada"
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    log_info "Sistema macOS detectado"
    
    # En macOS, intentar cambiar permisos
    if sudo -n true 2>/dev/null; then
        log_info "Permisos de sudo disponibles, corrigiendo permisos..."
        sudo chown -R 1001:1001 ./uploads/
        sudo chmod -R 775 ./uploads/
        log_success "Permisos corregidos con sudo"
    else
        log_warning "Sin permisos de sudo, intentando corrección básica..."
        chown -R 1001:1001 ./uploads/ 2>/dev/null || log_warning "No se pudo cambiar el propietario"
        chmod -R 775 ./uploads/
        log_info "Corrección básica aplicada"
    fi
    
else
    log_warning "Sistema operativo no reconocido: $OSTYPE"
    log_info "Intentando corrección genérica..."
    chmod -R 775 ./uploads/
    log_info "Permisos básicos aplicados"
fi

# Mostrar permisos después de la corrección
log_info "Permisos después de la corrección:"
ls -la ./uploads/
ls -la ./uploads/defectos/ 2>/dev/null || log_info "Directorio defectos será creado por el contenedor"

# Verificar si podemos escribir en el directorio
log_info "Probando permisos de escritura..."
if touch ./uploads/defectos/test-host-permissions.txt 2>/dev/null; then
    rm ./uploads/defectos/test-host-permissions.txt
    log_success "✅ Permisos de escritura OK desde el host"
else
    log_warning "⚠️ No se puede escribir desde el host, pero el contenedor debería poder hacerlo"
fi

echo ""
log_success "Corrección de permisos del host completada"
echo "================================================="
echo ""
log_info "Ahora puedes ejecutar el despliegue:"
echo "   • Linux/macOS: ./deploy-fix.sh"
echo "   • Windows: .\\deploy-fix.ps1"
echo "   • Manual: docker-compose down && docker-compose build --no-cache && docker-compose up -d"
echo ""
log_info "Si persisten problemas, el contenedor intentará corregir permisos automáticamente"
echo "================================================="