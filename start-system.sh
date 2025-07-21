#!/bin/bash

# Script de inicio automático del sistema NaturePharma
# Este script inicia todos los servicios dockerizados

set -e

echo "🚀 Iniciando Sistema NaturePharma..."
echo "======================================"

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

# Detener servicios existentes si están corriendo
echo "🔄 Deteniendo servicios existentes..."
docker-compose down --remove-orphans

# Construir e iniciar todos los servicios
echo "🏗️  Construyendo e iniciando servicios..."
docker-compose up -d --build

# Esperar un momento para que los servicios se inicien
echo "⏳ Esperando que los servicios se inicien..."
sleep 10

# Verificar estado de los servicios
echo "📊 Estado de los servicios:"
docker-compose ps

echo ""
echo "🎉 Sistema NaturePharma iniciado exitosamente!"
echo "======================================"
echo "📱 Servicios disponibles:"
echo "   • Auth Service: http://localhost:4001"
echo "   • Calendar Service: http://localhost:3003"
echo "   • Laboratorio Service: http://localhost:3004"
echo "   • Solicitudes Service: http://localhost:3001"
echo "   • Cremer Backend: http://localhost:3002"
echo "   • Tecnomaco Backend: http://localhost:3006"
echo "   • Servidor RPS: http://localhost:4000"
echo "   • phpMyAdmin: http://localhost:8080"
echo "   • Nginx Gateway: http://localhost"
echo ""
echo "📋 Comandos útiles:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Ver estado: docker-compose ps"
echo "   • Detener sistema: docker-compose down"
echo "   • Reiniciar sistema: docker-compose restart"
echo ""
echo "✨ ¡Listo para usar!"