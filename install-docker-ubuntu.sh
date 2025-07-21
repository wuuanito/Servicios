#!/bin/bash

# Script de instalación de Docker y Docker Compose para Ubuntu Server
# Ejecutar con: sudo ./install-docker-ubuntu.sh

echo "=== Instalador Docker para NaturePharma en Ubuntu Server ==="
echo "Este script instalará Docker, Docker Compose y configurará el entorno"
echo "Fecha: $(date)"
echo ""

# Verificar que se ejecute con sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Este script debe ejecutarse con sudo"
    echo "Uso: sudo ./install-docker-ubuntu.sh"
    exit 1
fi

# Obtener información del sistema
echo "📋 Información del sistema:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   Kernel: $(uname -r)"
echo "   Arquitectura: $(uname -m)"
echo "   Usuario actual: $(whoami)"
echo ""

# Función para mostrar progreso
show_progress() {
    echo "🔄 $1..."
}

# Función para mostrar éxito
show_success() {
    echo "✅ $1"
}

# Función para mostrar error
show_error() {
    echo "❌ ERROR: $1"
}

# Verificar si Docker ya está instalado
if command -v docker >/dev/null 2>&1; then
    echo "ℹ️  Docker ya está instalado:"
    docker --version
    echo ""
else
    echo "📦 Instalando Docker..."
    
    # Actualizar paquetes
    show_progress "Actualizando lista de paquetes"
    apt update -y
    
    # Instalar dependencias
    show_progress "Instalando dependencias"
    apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common
    
    # Agregar clave GPG oficial de Docker
    show_progress "Agregando clave GPG de Docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Agregar repositorio de Docker
    show_progress "Agregando repositorio de Docker"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Actualizar paquetes nuevamente
    show_progress "Actualizando lista de paquetes con repositorio Docker"
    apt update -y
    
    # Instalar Docker
    show_progress "Instalando Docker Engine"
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    if command -v docker >/dev/null 2>&1; then
        show_success "Docker instalado correctamente"
        docker --version
    else
        show_error "Falló la instalación de Docker"
        exit 1
    fi
fi

# Verificar si Docker Compose ya está instalado
if command -v docker-compose >/dev/null 2>&1; then
    echo "ℹ️  Docker Compose ya está instalado:"
    docker-compose --version
    echo ""
elif docker compose version >/dev/null 2>&1; then
    echo "ℹ️  Docker Compose (plugin) ya está instalado:"
    docker compose version
    echo ""
else
    echo "📦 Instalando Docker Compose..."
    
    # Obtener la última versión de Docker Compose
    show_progress "Obteniendo última versión de Docker Compose"
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    if [ -z "$COMPOSE_VERSION" ]; then
        echo "⚠️  No se pudo obtener la versión automáticamente, usando v2.21.0"
        COMPOSE_VERSION="v2.21.0"
    fi
    
    echo "   Versión a instalar: $COMPOSE_VERSION"
    
    # Descargar Docker Compose
    show_progress "Descargando Docker Compose $COMPOSE_VERSION"
    curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Dar permisos de ejecución
    chmod +x /usr/local/bin/docker-compose
    
    # Crear enlace simbólico
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    if command -v docker-compose >/dev/null 2>&1; then
        show_success "Docker Compose instalado correctamente"
        docker-compose --version
    else
        show_error "Falló la instalación de Docker Compose"
        exit 1
    fi
fi

echo ""
echo "🔧 Configurando Docker..."

# Iniciar y habilitar Docker
show_progress "Iniciando servicio Docker"
systemctl start docker
systemctl enable docker

# Verificar que Docker esté ejecutándose
if systemctl is-active --quiet docker; then
    show_success "Servicio Docker está ejecutándose"
else
    show_error "El servicio Docker no está ejecutándose"
    echo "   Intenta: sudo systemctl start docker"
    exit 1
fi

# Agregar usuario actual al grupo docker (si no es root)
if [ "$SUDO_USER" != "" ] && [ "$SUDO_USER" != "root" ]; then
    show_progress "Agregando usuario $SUDO_USER al grupo docker"
    usermod -aG docker "$SUDO_USER"
    show_success "Usuario $SUDO_USER agregado al grupo docker"
    echo "   ⚠️  El usuario debe cerrar sesión y volver a iniciar para aplicar cambios"
fi

echo ""
echo "🧪 Probando instalación..."

# Probar Docker
show_progress "Probando Docker"
if docker run --rm hello-world >/dev/null 2>&1; then
    show_success "Docker funciona correctamente"
else
    show_error "Docker no funciona correctamente"
    echo "   Verifica: sudo docker run hello-world"
fi

# Probar Docker Compose
show_progress "Probando Docker Compose"
if docker-compose --version >/dev/null 2>&1; then
    show_success "Docker Compose funciona correctamente"
else
    show_error "Docker Compose no funciona correctamente"
fi

echo ""
echo "📁 Configurando entorno NaturePharma..."

# Crear directorios necesarios
show_progress "Creando directorios del proyecto"
mkdir -p uploads logs ssl backups
chmod 777 uploads logs ssl backups

# Configurar permisos para scripts
show_progress "Configurando permisos de scripts"
for script in *.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        chmod 777 "$script"
    fi
done

# Configurar archivo .env si no existe
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    show_progress "Creando archivo .env"
    cp .env.example .env
    chmod 777 .env
    show_success "Archivo .env creado desde .env.example"
fi

echo ""
echo "🔍 Información del sistema después de la instalación:"
echo "   Docker version: $(docker --version)"
echo "   Docker Compose version: $(docker-compose --version)"
echo "   Docker status: $(systemctl is-active docker)"
echo "   Espacio en disco disponible: $(df -h / | awk 'NR==2{print $4}')"
echo "   Memoria disponible: $(free -h | awk 'NR==2{print $7}')"
echo ""

echo "📋 Comandos útiles:"
echo "   Verificar Docker:        sudo docker info"
echo "   Ver contenedores:        sudo docker ps"
echo "   Ver imágenes:           sudo docker images"
echo "   Limpiar sistema:        sudo docker system prune"
echo "   Logs de Docker:         sudo journalctl -u docker"
echo ""

echo "🚀 Próximos pasos:"
echo "   1. Ejecuta: sudo ./start-system-ubuntu.sh"
echo "   2. O para diagnóstico: sudo ./debug-build-ubuntu.sh"
echo "   3. Monitor en tiempo real: http://localhost:8081"
echo ""

echo "⚠️  IMPORTANTE:"
echo "   - Si agregaste un usuario al grupo docker, debe cerrar sesión y volver a iniciar"
echo "   - Todos los comandos Docker deben ejecutarse con sudo en este servidor"
echo "   - Los archivos tienen permisos 777 para evitar problemas de permisos"
echo ""

show_success "Instalación completada exitosamente"
echo "=== Docker y Docker Compose listos para NaturePharma ==="
echo "Fecha de instalación: $(date)"
echo "======================================================="