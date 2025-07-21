#!/bin/bash

# Script de instalación de dependencias para Ubuntu/Linux
# NaturePharma System - Dependencies Installation Script

echo "=== NaturePharma System - Instalación de Dependencias para Ubuntu ==="
echo "Este script instalará Docker, Docker Compose y configurará el sistema"
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

# Verificar si se ejecuta como root o con sudo
if [ "$EUID" -ne 0 ]; then
    show_error "Este script debe ejecutarse con sudo. Usa: sudo ./install-dependencies-ubuntu.sh"
fi

# Actualizar sistema
echo "1. Actualizando sistema..."
show_info "Actualizando lista de paquetes..."
apt update

show_info "Actualizando paquetes instalados..."
apt upgrade -y

show_success "Sistema actualizado"

# Instalar dependencias básicas
echo "\n2. Instalando dependencias básicas..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

show_success "Dependencias básicas instaladas"

# Verificar e instalar Docker
echo "\n3. Verificando Docker..."
if command -v docker &> /dev/null; then
    show_info "Docker ya está instalado"
    docker --version
else
    show_info "Instalando Docker..."
    
    # Agregar clave GPG oficial de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Agregar repositorio de Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Actualizar e instalar Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    show_success "Docker instalado exitosamente"
fi

# Verificar e instalar Docker Compose
echo "\n4. Verificando Docker Compose..."
if command -v docker-compose &> /dev/null; then
    show_info "Docker Compose ya está instalado"
    docker-compose --version
else
    show_info "Instalando Docker Compose..."
    
    # Descargar Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Hacer ejecutable
    chmod +x /usr/local/bin/docker-compose
    
    # Crear enlace simbólico
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    show_success "Docker Compose instalado exitosamente"
fi

# Configurar Docker
echo "\n5. Configurando Docker..."

# Iniciar y habilitar Docker
systemctl start docker
systemctl enable docker

show_info "Agregando usuario actual al grupo docker..."
# Obtener el usuario que ejecutó sudo
REAL_USER=$(who am i | awk '{print $1}')
if [ ! -z "$REAL_USER" ]; then
    usermod -aG docker $REAL_USER
    show_success "Usuario $REAL_USER agregado al grupo docker"
    show_info "IMPORTANTE: Cierra sesión y vuelve a iniciar para que los cambios surtan efecto"
else
    show_info "No se pudo determinar el usuario. Agrega manualmente tu usuario al grupo docker con: sudo usermod -aG docker \$USER"
fi

# Verificar instalación
echo "\n6. Verificando instalación..."
show_info "Versión de Docker:"
docker --version

show_info "Versión de Docker Compose:"
docker-compose --version

show_info "Estado del servicio Docker:"
systemctl status docker --no-pager -l

# Hacer scripts ejecutables
echo "\n7. Configurando scripts del proyecto..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

chmod +x debug-build-ubuntu.sh 2>/dev/null || true
chmod +x fix-docker-context-ubuntu.sh 2>/dev/null || true
chmod +x start-system-ubuntu.sh 2>/dev/null || true
chmod +x monitor-logs.sh 2>/dev/null || true
chmod +x start-log-monitor.sh 2>/dev/null || true

show_success "Scripts configurados como ejecutables"

# Instalar Node.js (opcional para desarrollo)
echo "\n8. ¿Deseas instalar Node.js para desarrollo local? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    show_info "Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    show_success "Node.js instalado: $(node --version)"
    show_success "npm instalado: $(npm --version)"
else
    show_info "Saltando instalación de Node.js"
fi

echo "\n=== INSTALACIÓN COMPLETADA ==="
show_success "Todas las dependencias han sido instaladas exitosamente"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Cierra sesión y vuelve a iniciar (para aplicar permisos de Docker)"
echo "2. Ejecuta: ./start-system-ubuntu.sh"
echo "3. Si hay problemas, ejecuta: ./debug-build-ubuntu.sh"
echo ""
echo "🔧 SCRIPTS DISPONIBLES:"
echo "- ./start-system-ubuntu.sh - Iniciar sistema completo"
echo "- ./debug-build-ubuntu.sh - Diagnóstico y construcción detallada"
echo "- ./fix-docker-context-ubuntu.sh - Reparar problemas de contexto"
echo ""
echo "✅ ¡Sistema listo para usar!"