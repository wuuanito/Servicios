#!/bin/bash

# Script para generar package-lock.json faltantes
# Autor: Sistema de Automatización NaturePharma
# Fecha: $(date +%Y-%m-%d)

echo "📦 Generando package-lock.json faltantes..."
echo "============================================"

# Servicios que necesitan package-lock.json
SERVICES=("SERVIDOR_RPS" "Tecnomaco-Backend")

# Función para generar package-lock.json
generate_lockfile() {
    local service_dir="$1"
    
    echo "🔄 Procesando $service_dir..."
    
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
        echo "✅ package-lock.json ya existe en $service_dir"
        cd ..
        return 0
    fi
    
    echo "📋 Generando package-lock.json para $service_dir..."
    
    # Limpiar node_modules si existe para evitar conflictos
    if [ -d "node_modules" ]; then
        echo "🧹 Limpiando node_modules existente..."
        rm -rf node_modules
    fi
    
    # Generar package-lock.json sin instalar node_modules
    if npm install --package-lock-only; then
        echo "✅ package-lock.json generado exitosamente para $service_dir"
        
        # Verificar que el archivo se creó correctamente
        if [ -f "package-lock.json" ] && [ -s "package-lock.json" ]; then
            echo "✅ Archivo package-lock.json válido creado"
        else
            echo "❌ Error: package-lock.json está vacío o no se creó"
            cd ..
            return 1
        fi
    else
        echo "❌ Error generando package-lock.json para $service_dir"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Función principal
main() {
    local success_count=0
    local total_count=${#SERVICES[@]}
    
    echo "🚀 Iniciando generación de lockfiles..."
    echo "Servicios a procesar: ${SERVICES[*]}"
    echo ""
    
    for service in "${SERVICES[@]}"; do
        echo "📋 Procesando: $service"
        echo "------------------------"
        
        if generate_lockfile "$service"; then
            echo "✅ $service procesado correctamente"
            ((success_count++))
        else
            echo "❌ Error procesando $service"
        fi
        
        echo ""
    done
    
    # Resumen final
    echo "📊 RESUMEN"
    echo "========================"
    echo "✅ Servicios procesados: $success_count/$total_count"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        echo "🎉 ¡Todos los package-lock.json generados exitosamente!"
        echo ""
        echo "📋 PRÓXIMOS PASOS:"
        echo "1. Construir servicios: docker-compose build servidor-rps tecnomaco-backend"
        echo "2. Verificar construcción: ./test-build-services.sh"
        echo "3. Iniciar servicios: docker-compose up -d"
    else
        echo "⚠️  Algunos lockfiles no se pudieron generar."
        echo ""
        echo "🔧 SOLUCIÓN ALTERNATIVA:"
        echo "Los Dockerfiles han sido actualizados para funcionar sin package-lock.json"
        echo "Ejecutar: docker-compose build servidor-rps tecnomaco-backend"
    fi
    
    echo ""
    echo "📝 ARCHIVOS GENERADOS:"
    for service in "${SERVICES[@]}"; do
        if [ -f "$service/package-lock.json" ]; then
            local size=$(du -h "$service/package-lock.json" | cut -f1)
            echo "  ✅ $service/package-lock.json ($size)"
        else
            echo "  ❌ $service/package-lock.json (no generado)"
        fi
    done
}

# Verificaciones previas
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml"
    echo "   Ejecutar este script desde el directorio raíz del proyecto"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm no está instalado o no está en PATH"
    echo "   Instalar Node.js y npm antes de continuar"
    exit 1
fi

echo "🔍 Verificando versión de npm: $(npm --version)"
echo "🔍 Verificando versión de node: $(node --version)"
echo ""

# Ejecutar función principal
main

echo "🏁 Script completado."