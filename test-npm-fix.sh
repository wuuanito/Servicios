#!/bin/bash

# Script de prueba rápida para verificar la corrección de npm
# Autor: Sistema de Automatización NaturePharma
# Fecha: $(date +%Y-%m-%d)

echo "🧪 Probando corrección de npm para servicios problemáticos..."
echo "========================================================"

# Servicios a probar
SERVICES=("servidor-rps" "tecnomaco-backend" "cremer-backend")
DIRECTORIES=("SERVIDOR_RPS" "Tecnomaco-Backend" "Cremer-Backend")

# Función para probar construcción de un servicio
test_service_build() {
    local service_name="$1"
    local service_dir="$2"
    
    echo "🔧 Probando construcción de $service_name..."
    echo "   Directorio: $service_dir"
    
    # Verificar que existe el directorio
    if [ ! -d "$service_dir" ]; then
        echo "❌ Directorio $service_dir no encontrado"
        return 1
    fi
    
    # Verificar que existe Dockerfile
    if [ ! -f "$service_dir/Dockerfile" ]; then
        echo "❌ Dockerfile no encontrado en $service_dir"
        return 1
    fi
    
    # Verificar que existe package.json
    if [ ! -f "$service_dir/package.json" ]; then
        echo "❌ package.json no encontrado en $service_dir"
        return 1
    fi
    
    # Verificar contenido del Dockerfile
    if grep -q "npm ci --only=production" "$service_dir/Dockerfile"; then
        echo "⚠️  Dockerfile aún usa npm ci --only=production (necesita actualización)"
        return 1
    elif grep -q "npm ci --omit=dev" "$service_dir/Dockerfile"; then
        echo "✅ Dockerfile actualizado correctamente (usa estrategia robusta)"
    elif grep -q "npm install --omit=dev" "$service_dir/Dockerfile"; then
        echo "✅ Dockerfile actualizado correctamente (usa estrategia robusta)"
    else
        echo "⚠️  Dockerfile no contiene comando npm esperado"
    fi
    
    # Verificar si existe package-lock.json
    if [ -f "$service_dir/package-lock.json" ]; then
        echo "✅ package-lock.json encontrado"
    else
        echo "ℹ️  package-lock.json no encontrado (Dockerfile debería manejarlo)"
    fi
    
    # Intentar construcción con docker-compose
    echo "🐳 Intentando construcción con docker-compose..."
    
    if timeout 120 docker-compose build "$service_name" 2>/dev/null; then
        echo "✅ $service_name construido exitosamente"
        return 0
    else
        echo "❌ Error construyendo $service_name"
        echo "📋 Intentando construcción directa..."
        
        # Intentar construcción directa
        cd "$service_dir" || return 1
        if timeout 120 docker build -t "test-$service_name" . 2>/dev/null; then
            echo "✅ $service_name construido exitosamente (método directo)"
            # Limpiar imagen de prueba
            docker rmi "test-$service_name" 2>/dev/null || true
            cd ..
            return 0
        else
            echo "❌ Error en construcción directa de $service_name"
            cd ..
            return 1
        fi
    fi
}

# Función principal
main() {
    local success_count=0
    local total_count=${#SERVICES[@]}
    
    echo "🚀 Iniciando pruebas de construcción..."
    echo "Servicios a probar: ${SERVICES[*]}"
    echo ""
    
    # Verificar que Docker está disponible
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado o no está disponible"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ docker-compose no está instalado o no está disponible"
        exit 1
    fi
    
    # Probar cada servicio
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local directory="${DIRECTORIES[$i]}"
        
        echo "📋 Probando servicio: $service"
        echo "================================"
        
        if test_service_build "$service" "$directory"; then
            echo "✅ $service: ÉXITO"
            ((success_count++))
        else
            echo "❌ $service: FALLO"
        fi
        
        echo ""
    done
    
    # Resumen final
    echo "📊 RESUMEN DE PRUEBAS"
    echo "===================="
    echo "✅ Servicios exitosos: $success_count/$total_count"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        echo "🎉 ¡Todas las pruebas pasaron exitosamente!"
        echo "✅ La corrección de npm funciona correctamente"
        echo ""
        echo "📋 PRÓXIMOS PASOS:"
        echo "1. Construir todos los servicios: docker-compose build"
        echo "2. Iniciar servicios: docker-compose up -d"
        echo "3. Verificar estado: docker-compose ps"
    elif [ $success_count -gt 0 ]; then
        echo "⚠️  Algunas pruebas fallaron, pero hay progreso"
        echo ""
        echo "🔧 RECOMENDACIONES:"
        echo "1. Ejecutar: ./generate-lockfiles.sh"
        echo "2. Verificar logs: docker-compose logs <servicio>"
        echo "3. Revisar Dockerfiles manualmente"
    else
        echo "❌ Todas las pruebas fallaron"
        echo ""
        echo "🆘 SOLUCIONES:"
        echo "1. Ejecutar: ./fix-npm-lockfiles.sh"
        echo "2. Verificar que Docker funciona: docker --version"
        echo "3. Verificar docker-compose.yml"
    fi
    
    echo ""
    echo "📝 DETALLES TÉCNICOS:"
    echo "- Docker version: $(docker --version 2>/dev/null || echo 'No disponible')"
    echo "- Docker Compose version: $(docker-compose --version 2>/dev/null || echo 'No disponible')"
    
    for i in "${!SERVICES[@]}"; do
        local directory="${DIRECTORIES[$i]}"
        if [ -f "$directory/package-lock.json" ]; then
            local size=$(du -h "$directory/package-lock.json" 2>/dev/null | cut -f1 || echo "?")
            echo "- $directory/package-lock.json: $size"
        else
            echo "- $directory/package-lock.json: No existe"
        fi
    done
}

# Verificaciones previas
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml"
    echo "   Ejecutar este script desde el directorio raíz del proyecto"
    exit 1
fi

echo "🔍 Verificando entorno..."
echo "Docker: $(docker --version 2>/dev/null || echo 'No disponible')"
echo "Docker Compose: $(docker-compose --version 2>/dev/null || echo 'No disponible')"
echo ""

# Ejecutar función principal
main

echo "🏁 Pruebas completadas."