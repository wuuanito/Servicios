#!/bin/bash

# Script para generar package-lock.json faltantes y corregir Dockerfiles
# Autor: Sistema de Automatización NaturePharma
# Fecha: $(date +%Y-%m-%d)

echo "🔧 Generando package-lock.json faltantes y corrigiendo Dockerfiles..."
echo "================================================"

# Servicios que necesitan package-lock.json
SERVICES=("SERVIDOR_RPS" "Tecnomaco-Backend")

# Función para generar package-lock.json
generate_lockfile() {
    local service_dir="$1"
    local service_name="$2"
    
    echo "📦 Procesando $service_name..."
    
    if [ ! -d "$service_dir" ]; then
        echo "❌ Directorio $service_dir no encontrado"
        return 1
    fi
    
    if [ ! -f "$service_dir/package.json" ]; then
        echo "❌ package.json no encontrado en $service_dir"
        return 1
    fi
    
    cd "$service_dir" || return 1
    
    # Verificar si ya existe package-lock.json
    if [ -f "package-lock.json" ]; then
        echo "✅ package-lock.json ya existe en $service_name"
    else
        echo "🔄 Generando package-lock.json para $service_name..."
        
        # Limpiar node_modules si existe
        if [ -d "node_modules" ]; then
            echo "🧹 Limpiando node_modules existente..."
            rm -rf node_modules
        fi
        
        # Generar package-lock.json
        if npm install --package-lock-only; then
            echo "✅ package-lock.json generado exitosamente para $service_name"
        else
            echo "❌ Error generando package-lock.json para $service_name"
            cd ..
            return 1
        fi
    fi
    
    cd ..
    return 0
}

# Función para actualizar Dockerfile
update_dockerfile() {
    local service_dir="$1"
    local service_name="$2"
    
    echo "🐳 Actualizando Dockerfile de $service_name..."
    
    if [ ! -f "$service_dir/Dockerfile" ]; then
        echo "❌ Dockerfile no encontrado en $service_dir"
        return 1
    fi
    
    # Crear backup del Dockerfile original
    cp "$service_dir/Dockerfile" "$service_dir/Dockerfile.backup"
    
    # Reemplazar npm ci con npm install y agregar verificación
    sed -i 's/RUN npm ci --only=production/# Instalar dependencias (con fallback si no hay package-lock.json)\nRUN if [ -f package-lock.json ]; then \\\n        npm ci --omit=dev; \\\n    else \\\n        npm install --omit=dev; \\\n    fi/' "$service_dir/Dockerfile"
    
    echo "✅ Dockerfile actualizado para $service_name"
    return 0
}

# Función principal
main() {
    local base_dir="$(pwd)"
    local success_count=0
    local total_count=${#SERVICES[@]}
    
    echo "🚀 Iniciando corrección de dependencias npm..."
    echo "Servicios a procesar: ${SERVICES[*]}"
    echo ""
    
    for service in "${SERVICES[@]}"; do
        echo "📋 Procesando servicio: $service"
        echo "----------------------------------------"
        
        # Generar package-lock.json
        if generate_lockfile "$service" "$service"; then
            echo "✅ Lockfile procesado correctamente para $service"
        else
            echo "⚠️  Error procesando lockfile para $service"
        fi
        
        # Actualizar Dockerfile
        if update_dockerfile "$service" "$service"; then
            echo "✅ Dockerfile actualizado correctamente para $service"
            ((success_count++))
        else
            echo "⚠️  Error actualizando Dockerfile para $service"
        fi
        
        echo ""
    done
    
    # Resumen final
    echo "📊 RESUMEN DE CORRECCIONES"
    echo "================================================"
    echo "✅ Servicios procesados exitosamente: $success_count/$total_count"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        echo "🎉 ¡Todas las correcciones completadas exitosamente!"
        echo ""
        echo "📋 PRÓXIMOS PASOS:"
        echo "1. Ejecutar: docker-compose build servidor-rps tecnomaco-backend"
        echo "2. Verificar construcción: ./test-build-services.sh"
        echo "3. Si hay errores, revisar logs con: docker-compose logs"
    else
        echo "⚠️  Algunas correcciones fallaron. Revisar errores arriba."
        echo ""
        echo "🔧 SOLUCIÓN MANUAL:"
        echo "1. Navegar a cada directorio con errores"
        echo "2. Ejecutar: npm install --package-lock-only"
        echo "3. Verificar que se genere package-lock.json"
        echo "4. Reconstruir: docker-compose build <servicio>"
    fi
    
    echo ""
    echo "📝 ARCHIVOS MODIFICADOS:"
    for service in "${SERVICES[@]}"; do
        if [ -f "$service/Dockerfile.backup" ]; then
            echo "  - $service/Dockerfile (backup: $service/Dockerfile.backup)"
        fi
        if [ -f "$service/package-lock.json" ]; then
            echo "  - $service/package-lock.json (generado)"
        fi
    done
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml"
    echo "   Ejecutar este script desde el directorio raíz del proyecto"
    exit 1
fi

# Verificar que npm está disponible
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm no está instalado o no está en PATH"
    echo "   Instalar Node.js y npm antes de continuar"
    exit 1
fi

# Ejecutar función principal
main

echo "🏁 Script completado."