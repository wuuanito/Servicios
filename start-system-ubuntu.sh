#!/bin/bash

# Script de inicio del sistema NaturePharma para Ubuntu Server
# Ejecutar con: sudo ./start-system-ubuntu.sh

echo "=== NaturePharma System Startup Script para Ubuntu ==="
echo "Iniciando sistema de microservicios..."
echo "Fecha: $(date)"
echo ""
echo "Directorio de trabajo: $(pwd)"
echo ""

# Verificar que se ejecute con sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Este script debe ejecutarse con sudo"
    echo "Uso: sudo ./start-system-ubuntu.sh"
    exit 1
fi

# Función para mostrar spinner de carga
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo "Verificando Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker está ejecutándose"
    else
        echo "🔄 Iniciando Docker..."
        systemctl start docker
        sleep 3
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker iniciado correctamente"
        else
            echo "❌ ERROR: No se pudo iniciar Docker"
            echo "   Ejecuta: sudo systemctl status docker"
            exit 1
        fi
    fi
else
    echo "❌ ERROR: Docker no está instalado"
    echo "   Instala Docker primero con el script de instalación"
    exit 1
fi

echo "Verificando Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    echo "✅ Docker Compose está disponible"
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose está disponible"
    COMPOSE_CMD="docker compose"
else
    echo "❌ ERROR: Docker Compose no está disponible"
    echo "   Instala Docker Compose primero"
    exit 1
fi

echo ""
echo "Deteniendo servicios existentes..."
$COMPOSE_CMD down >/dev/null 2>&1
echo "ℹ️  Servicios existentes detenidos"

echo ""
echo "Verificando archivos necesarios..."

# Verificar docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ ERROR: docker-compose.yml no encontrado"
    exit 1
fi

# Verificar y crear .env si no existe
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "📝 Creando archivo .env desde .env.example..."
        cp .env.example .env
        chmod 777 .env
        echo "✅ Archivo .env creado"
    else
        echo "⚠️  Creando archivo .env básico..."
        cat > .env << 'EOF'
# Configuración básica NaturePharma
NODE_ENV=production
DB_HOST=192.168.20.158
DB_PORT=3306
DB_USER=naturepharma
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!
AUTH_DB_NAME=naturepharma_auth
CALENDAR_DB_NAME=naturepharma_calendar
LABORATORIO_DB_NAME=naturepharma_laboratorio
SOLICITUDES_DB_NAME=naturepharma_solicitudes
JWT_SECRET=naturepharma_jwt_secret_key_2024
JWT_EXPIRES_IN=24h
GMAIL_USER=
GMAIL_APP_PASSWORD=
AUTH_SERVICE_URL=http://localhost:3001
CALENDAR_SERVICE_URL=http://localhost:3002
LABORATORIO_SERVICE_URL=http://localhost:3003
SOLICITUDES_SERVICE_URL=http://localhost:3004
AUTH_PORT=3001
CALENDAR_PORT=3002
LABORATORIO_PORT=3003
SOLICITUDES_PORT=3004
CREMER_PORT=3005
TECNOMACO_PORT=3006
SERVIDOR_RPS_PORT=3007
EOF
        chmod 777 .env
        echo "✅ Archivo .env básico creado"
    fi
else
    echo "✅ Archivo .env encontrado"
fi

# Verificar Dockerfiles críticos
echo "🔍 Verificando Dockerfiles..."
missing_dockerfiles=0

for service_dir in auth-service calendar-service laboratorio-service ServicioSolicitudesOt Cremer-Backend Tecnomaco-Backend SERVIDOR_RPS; do
    if [ -d "$service_dir" ] && [ ! -f "$service_dir/Dockerfile" ]; then
        echo "❌ Dockerfile faltante en $service_dir"
        ((missing_dockerfiles++))
    fi
done

if [ $missing_dockerfiles -gt 0 ]; then
    echo "⚠️  Se encontraron $missing_dockerfiles Dockerfiles faltantes"
    echo "🔧 Ejecutando reparación automática..."
    
    if [ -f "fix-missing-dockerfiles-ubuntu.sh" ]; then
        chmod +x fix-missing-dockerfiles-ubuntu.sh
        ./fix-missing-dockerfiles-ubuntu.sh
    else
        echo "❌ ERROR: Script de reparación no encontrado"
        echo "   Ejecuta primero: sudo ./debug-build-ubuntu.sh"
        exit 1
    fi
fi

echo ""
echo "📁 Creando directorios necesarios..."
mkdir -p uploads logs ssl backups
chmod 777 uploads logs ssl backups

# Crear directorios específicos para servicios
for service in auth-service calendar-service laboratorio-service ServicioSolicitudesOt Cremer-Backend Tecnomaco-Backend SERVIDOR_RPS; do
    if [ -d "$service" ]; then
        mkdir -p "$service/uploads" "$service/logs" "$service/temp"
        chmod 777 "$service/uploads" "$service/logs" "$service/temp" 2>/dev/null
    fi
done

echo "✅ Directorios creados"

echo ""
echo "🧹 Limpiando recursos Docker anteriores..."
# Limpiar imágenes huérfanas y contenedores detenidos
docker system prune -f >/dev/null 2>&1
echo "✅ Limpieza completada"

echo ""
echo "Construyendo e iniciando servicios..."
echo "⏳ Este proceso puede tomar varios minutos..."
echo ""

# Intentar construir e iniciar servicios
if $COMPOSE_CMD up -d --build; then
    echo ""
    echo "✅ Servicios iniciados exitosamente"
    
    echo ""
    echo "⏳ Esperando que los servicios estén listos..."
    sleep 10
    
    echo ""
    echo "📊 Estado de los servicios:"
    $COMPOSE_CMD ps
    
    echo ""
    echo "🌐 URLs de acceso:"
    echo "   🔐 Auth Service:        http://localhost:3001"
    echo "   📅 Calendar Service:    http://localhost:3002"
    echo "   🧪 Laboratorio Service: http://localhost:3003"
    echo "   📋 Solicitudes Service: http://localhost:3004"
    echo "   🏭 Cremer Backend:      http://localhost:3005"
    echo "   🏭 Tecnomaco Backend:   http://localhost:3006"
    echo "   📡 Servidor RPS:        http://localhost:3007"
    echo "   🗄️  phpMyAdmin:          http://localhost:8080"
    echo "   📊 Log Monitor:         http://localhost:8081"
    echo "   🌐 Nginx Gateway:       http://localhost:80"
    
    echo ""
    echo "📋 APIs disponibles a través del gateway:"
    echo "   🔐 Auth API:        http://localhost/api/auth"
    echo "   📅 Calendar API:    http://localhost/api/events"
    echo "   🧪 Laboratorio API: http://localhost/api/laboratorio"
    echo "   📋 Solicitudes API: http://localhost/api/solicitudes"
    
    echo ""
    echo "🔍 Comandos útiles:"
    echo "   Ver logs:           sudo docker-compose logs -f"
    echo "   Ver logs específico: sudo docker-compose logs -f [servicio]"
    echo "   Estado servicios:   sudo docker-compose ps"
    echo "   Detener servicios:  sudo docker-compose down"
    echo "   Reiniciar servicio: sudo docker-compose restart [servicio]"
    
    echo ""
    echo "📊 Para monitoreo en tiempo real:"
    echo "   Monitor web: http://localhost:8081"
    echo "   Logs terminal: sudo docker-compose logs -f"
    
    echo ""
    echo "🎉 ¡Sistema NaturePharma iniciado correctamente!"
    
else
    echo ""
    echo "❌ ERROR: Error al construir o iniciar servicios. Ejecuta debug-build-ubuntu.sh para diagnóstico detallado."
    
    echo ""
    echo "🔍 Diagnóstico rápido:"
    echo "   1. Ejecuta: sudo ./debug-build-ubuntu.sh"
    echo "   2. Revisa logs: sudo docker-compose logs"
    echo "   3. Verifica estado: sudo docker-compose ps"
    
    echo ""
    echo "🔧 Comandos de reparación:"
    echo "   - Reparar Dockerfiles: sudo ./fix-missing-dockerfiles-ubuntu.sh"
    echo "   - Limpiar todo: sudo docker system prune -a"
    echo "   - Reintentar: sudo ./start-system-ubuntu.sh"
    
    exit 1
fi

echo ""
echo "=== Sistema iniciado correctamente ==="
echo "Fecha de inicio: $(date)"
echo "Directorio: $(pwd)"
echo "Usuario: $(whoami)"
echo "======================================="