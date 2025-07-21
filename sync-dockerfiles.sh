#!/bin/bash

# Script para sincronizar y estandarizar Dockerfiles
# Autor: Sistema de Automatización NaturePharma
# Fecha: $(date +%Y-%m-%d)

echo "🔄 Sincronizando Dockerfiles del proyecto..."
echo "==========================================="

# Detectar automáticamente servicios con Dockerfiles
find_dockerfiles() {
    local services=()
    local directories=()
    
    # Buscar directorios con Dockerfiles
    for dir in */; do
        if [ -f "${dir}Dockerfile" ] && [ -f "${dir}package.json" ]; then
            local dir_name="${dir%/}"
            services+=("$dir_name")
            directories+=("$dir_name")
        fi
    done
    
    echo "${services[@]}"
}

# Función para verificar si un Dockerfile necesita actualización
needs_npm_update() {
    local dockerfile="$1"
    
    if [ ! -f "$dockerfile" ]; then
        return 1
    fi
    
    # Verificar si usa npm ci --only=production (versión antigua)
    if grep -q "npm ci --only=production" "$dockerfile"; then
        return 0  # Necesita actualización
    fi
    
    return 1  # No necesita actualización
}

# Función para actualizar un Dockerfile
update_dockerfile() {
    local service_dir="$1"
    local dockerfile="$service_dir/Dockerfile"
    
    echo "🔧 Actualizando $dockerfile..."
    
    if [ ! -f "$dockerfile" ]; then
        echo "❌ Dockerfile no encontrado: $dockerfile"
        return 1
    fi
    
    # Crear backup
    cp "$dockerfile" "$dockerfile.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Actualizar el comando npm
    sed -i 's/RUN npm ci --only=production/# Instalar dependencias (con fallback si no hay package-lock.json)\nRUN if [ -f package-lock.json ]; then \\\n        npm ci --omit=dev; \\\n    else \\\n        npm install --omit=dev; \\\n    fi/' "$dockerfile"
    
    echo "✅ $dockerfile actualizado"
    return 0
}

# Función para verificar consistencia de puertos
check_port_consistency() {
    local service_dir="$1"
    local dockerfile="$service_dir/Dockerfile"
    
    if [ ! -f "$dockerfile" ]; then
        return 1
    fi
    
    local dockerfile_port=$(grep "EXPOSE" "$dockerfile" | awk '{print $2}' | head -1)
    
    # Verificar en docker-compose.yml si existe
    if [ -f "docker-compose.yml" ]; then
        local compose_port=$(grep -A 10 "$service_dir:" docker-compose.yml | grep "ports:" -A 1 | grep -o "[0-9]\+:[0-9]\+" | cut -d: -f1 | head -1)
        
        if [ -n "$dockerfile_port" ] && [ -n "$compose_port" ] && [ "$dockerfile_port" != "$compose_port" ]; then
            echo "⚠️  Puerto inconsistente en $service_dir: Dockerfile($dockerfile_port) vs docker-compose($compose_port)"
        fi
    fi
}

# Función para estandarizar estructura de Dockerfile
standardize_dockerfile_structure() {
    local service_dir="$1"
    local dockerfile="$service_dir/Dockerfile"
    
    echo "📋 Verificando estructura de $dockerfile..."
    
    # Verificar elementos esenciales
    local has_healthcheck=$(grep -c "HEALTHCHECK" "$dockerfile")
    local has_user=$(grep -c "USER" "$dockerfile")
    local has_workdir=$(grep -c "WORKDIR" "$dockerfile")
    
    if [ "$has_healthcheck" -eq 0 ]; then
        echo "ℹ️  $service_dir: Sin HEALTHCHECK definido"
    fi
    
    if [ "$has_user" -eq 0 ]; then
        echo "⚠️  $service_dir: Sin usuario no-root definido"
    fi
    
    if [ "$has_workdir" -eq 0 ]; then
        echo "⚠️  $service_dir: Sin WORKDIR definido"
    fi
}

# Función principal
main() {
    local services_found=($(find_dockerfiles))
    local updated_count=0
    local total_count=${#services_found[@]}
    
    echo "🔍 Servicios encontrados: ${services_found[*]}"
    echo "📊 Total de servicios: $total_count"
    echo ""
    
    if [ $total_count -eq 0 ]; then
        echo "❌ No se encontraron servicios con Dockerfiles"
        exit 1
    fi
    
    # Procesar cada servicio
    for service in "${services_found[@]}"; do
        echo "📋 Procesando servicio: $service"
        echo "--------------------------------"
        
        # Verificar si necesita actualización npm
        if needs_npm_update "$service/Dockerfile"; then
            echo "🔄 $service necesita actualización de npm"
            if update_dockerfile "$service"; then
                ((updated_count++))
            fi
        else
            echo "✅ $service ya está actualizado"
        fi
        
        # Verificar consistencia de puertos
        check_port_consistency "$service"
        
        # Verificar estructura estándar
        standardize_dockerfile_structure "$service"
        
        echo ""
    done
    
    # Resumen final
    echo "📊 RESUMEN DE SINCRONIZACIÓN"
    echo "============================"
    echo "✅ Servicios procesados: $total_count"
    echo "🔄 Servicios actualizados: $updated_count"
    echo "📁 Backups creados: $updated_count"
    echo ""
    
    if [ $updated_count -gt 0 ]; then
        echo "🎉 Sincronización completada con actualizaciones"
        echo ""
        echo "📋 PRÓXIMOS PASOS:"
        echo "1. Probar construcción: ./test-npm-fix.sh"
        echo "2. Construir servicios: docker-compose build"
        echo "3. Verificar funcionamiento: docker-compose up -d"
    else
        echo "✅ Todos los Dockerfiles ya están sincronizados"
    fi
    
    echo ""
    echo "📝 ARCHIVOS MODIFICADOS:"
    for service in "${services_found[@]}"; do
        local backup_files=("$service/Dockerfile.backup."*)
        if [ -f "${backup_files[0]}" ]; then
            echo "  🔄 $service/Dockerfile (backup disponible)"
        else
            echo "  ✅ $service/Dockerfile (sin cambios)"
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
echo "Directorio actual: $(pwd)"
echo "Docker disponible: $(command -v docker >/dev/null && echo 'Sí' || echo 'No')"
echo "docker-compose disponible: $(command -v docker-compose >/dev/null && echo 'Sí' || echo 'No')"
echo ""

# Ejecutar función principal
main

echo "🏁 Sincronización completada."