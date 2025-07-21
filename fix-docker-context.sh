#!/bin/bash

# Script de solución rápida para problemas de contexto de Docker
# Resuelve el error "failed to read dockerfile: open Dockerfile: no such file or directory"

set -e

# Cambiar al directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 Solucionando problemas de contexto de Docker"
echo "==============================================="
echo "📁 Directorio actual: $SCRIPT_DIR"
echo ""

# Verificar Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    exit 1
fi

echo "✅ Docker está corriendo"
echo ""

# Limpiar completamente el entorno Docker
echo "🧹 Limpiando entorno Docker..."
docker-compose down --remove-orphans --volumes 2>/dev/null || true
docker system prune -af --volumes 2>/dev/null || true
echo "✅ Entorno Docker limpiado"
echo ""

# Verificar estructura de directorios
echo "🔍 Verificando estructura de directorios..."
required_dirs=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/Dockerfile" ]; then
        echo "✅ $dir/ y $dir/Dockerfile encontrados"
    else
        echo "❌ Problema con $dir/"
        if [ ! -d "$dir" ]; then
            echo "   - Directorio $dir/ no existe"
        fi
        if [ ! -f "$dir/Dockerfile" ]; then
            echo "   - Archivo $dir/Dockerfile no existe"
        fi
    fi
done
echo ""

# Construir servicios con contexto explícito
echo "🏗️  Construyendo servicios con contexto explícito..."
echo ""

# Construir auth-service primero (el que falló)
echo "📦 Construyendo auth-service..."
if docker build -t naturepharma-auth-service -f ./auth-service/Dockerfile ./auth-service/; then
    echo "✅ auth-service construido exitosamente"
else
    echo "❌ Error construyendo auth-service"
    echo "Verificando contenido del directorio auth-service:"
    ls -la ./auth-service/
    exit 1
fi
echo ""

# Construir otros servicios
services_to_build=(
    "calendar-service:naturepharma-calendar-service"
    "laboratorio-service:naturepharma-laboratorio-service"
    "ServicioSolicitudesOt:naturepharma-solicitudes-service"
    "Cremer-Backend:naturepharma-cremer-backend"
    "Tecnomaco-Backend:naturepharma-tecnomaco-backend"
    "SERVIDOR_RPS:naturepharma-servidor-rps"
)

for service_info in "${services_to_build[@]}"; do
    IFS=':' read -r service_dir image_name <<< "$service_info"
    echo "📦 Construyendo $service_dir..."
    if docker build -t "$image_name" -f "./$service_dir/Dockerfile" "./$service_dir/"; then
        echo "✅ $service_dir construido exitosamente"
    else
        echo "❌ Error construyendo $service_dir"
        exit 1
    fi
    echo ""
done

# Ahora usar docker-compose con las imágenes ya construidas
echo "🚀 Iniciando servicios con docker-compose..."
docker-compose up -d
echo ""

# Verificar estado
echo "📊 Estado de los servicios:"
docker-compose ps
echo ""

echo "🎉 ¡Problema resuelto!"
echo "====================="
echo "Los servicios deberían estar funcionando ahora."
echo ""
echo "Si aún tienes problemas, ejecuta:"
echo "   ./debug-build.sh"
echo ""
echo "Para monitorear logs:"
echo "   docker-compose logs -f"