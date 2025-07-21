#!/bin/bash

# Script de diagnóstico y construcción del sistema NaturePharma
# Este script ayuda a identificar y resolver problemas de construcción

set -e

# Cambiar al directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Diagnóstico del Sistema NaturePharma"
echo "======================================"
echo "📁 Directorio de trabajo: $SCRIPT_DIR"
echo ""

# Verificar que Docker esté corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "Por favor, inicia Docker y vuelve a intentar"
    exit 1
fi

# Verificar que docker-compose esté disponible
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose no está instalado"
    exit 1
fi

echo "✅ Docker está corriendo"
echo "✅ Docker Compose está disponible"
echo ""

# Verificar que exista docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml en el directorio actual"
    exit 1
fi

echo "✅ docker-compose.yml encontrado"
echo ""

# Verificar que existan los Dockerfiles
echo "🔍 Verificando Dockerfiles..."
services=("auth-service" "calendar-service" "laboratorio-service" "solicitudes-service" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")
missing_dockerfiles=()

# Mapeo de nombres de servicios a directorios
declare -A service_dirs
service_dirs["auth-service"]="auth-service"
service_dirs["calendar-service"]="calendar-service"
service_dirs["laboratorio-service"]="laboratorio-service"
service_dirs["solicitudes-service"]="ServicioSolicitudesOt"
service_dirs["Cremer-Backend"]="Cremer-Backend"
service_dirs["Tecnomaco-Backend"]="Tecnomaco-Backend"
service_dirs["SERVIDOR_RPS"]="SERVIDOR_RPS"

for service in "${services[@]}"; do
    # Obtener el directorio correspondiente
    if [[ "$service" == "solicitudes-service" ]]; then
        dir="ServicioSolicitudesOt"
    else
        dir="$service"
    fi
    
    if [ -f "$dir/Dockerfile" ]; then
        echo "✅ $service/Dockerfile encontrado (en $dir/)"
    else
        echo "❌ $service/Dockerfile NO encontrado (buscando en $dir/)"
        missing_dockerfiles+=("$service")
    fi
done

if [ ${#missing_dockerfiles[@]} -gt 0 ]; then
    echo ""
    echo "❌ Error: Faltan los siguientes Dockerfiles:"
    for missing in "${missing_dockerfiles[@]}"; do
        echo "   • $missing/Dockerfile"
    done
    echo ""
    echo "Por favor, crea los Dockerfiles faltantes antes de continuar."
    exit 1
fi

echo ""
echo "✅ Todos los Dockerfiles están presentes"
echo ""

# Detener servicios existentes
echo "🔄 Deteniendo servicios existentes..."
docker-compose down --remove-orphans
echo ""

# Limpiar imágenes anteriores (opcional)
echo "🧹 Limpiando imágenes anteriores..."
docker system prune -f
echo ""

# Construir servicios uno por uno para mejor diagnóstico
echo "🏗️  Construyendo servicios individualmente..."
echo ""

for service in "${services[@]}"; do
    echo "📦 Construyendo $service..."
    if docker-compose build "$service"; then
        echo "✅ $service construido exitosamente"
    else
        echo "❌ Error construyendo $service"
        echo "Revisa los logs arriba para más detalles"
        exit 1
    fi
    echo ""
done

# Construir servicios restantes
echo "📦 Construyendo servicios restantes..."
docker-compose build log-monitor
echo ""

# Iniciar todos los servicios
echo "🚀 Iniciando todos los servicios..."
docker-compose up -d
echo ""

# Esperar un momento para que los servicios se inicien
echo "⏳ Esperando que los servicios se inicien..."
sleep 15
echo ""

# Verificar estado de los servicios
echo "📊 Estado de los servicios:"
docker-compose ps
echo ""

# Verificar logs de servicios que puedan tener problemas
echo "📋 Verificando logs de servicios..."
echo ""

for service in "auth-service" "calendar-service" "laboratorio-service" "solicitudes-service"; do
    echo "📄 Últimas líneas de $service:"
    docker-compose logs --tail=5 "$service" || echo "⚠️  No se pudieron obtener logs de $service"
    echo ""
done

echo "🎉 Proceso de construcción completado!"
echo "======================================"
echo "📱 Servicios disponibles:"
echo "   • Auth Service: http://localhost:4001"
echo "   • Calendar Service: http://localhost:3003"
echo "   • Laboratorio Service: http://localhost:3004"
echo "   • Solicitudes Service: http://localhost:3001"
echo "   • Cremer Backend: http://localhost:3002"
echo "   • Tecnomaco Backend: http://localhost:3006"
echo "   • Servidor RPS: http://localhost:4000"
echo "   • Log Monitor: http://localhost:8080"
echo "   • phpMyAdmin: http://localhost:8081"
echo "   • Nginx Gateway: http://localhost"
echo ""
echo "📋 Comandos útiles:"
echo "   • Ver logs: docker-compose logs -f [servicio]"
echo "   • Ver estado: docker-compose ps"
echo "   • Detener sistema: docker-compose down"
echo "   • Reiniciar servicio: docker-compose restart [servicio]"
echo ""
echo "✨ ¡Sistema listo para usar!"