#!/bin/bash

# Script para corregir inconsistencias de nombres de servicios
# NaturePharma System - Fix Service Names

echo "=== NaturePharma System - Corrección de Nombres de Servicios ==="
echo "Fecha: $(date)"
echo ""

# Función para mostrar información
show_info() {
    echo "ℹ️  $1"
}

# Función para mostrar éxito
show_success() {
    echo "✅ $1"
}

# Función para mostrar error
show_error() {
    echo "❌ $1"
}

# Función para mostrar advertencia
show_warning() {
    echo "⚠️  $1"
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    show_error "No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

echo "\n🔍 DIAGNÓSTICO DEL PROBLEMA"
echo "==========================="

show_info "Analizando inconsistencias entre nombres de servicios y directorios..."

# Mapeo correcto de servicios
declare -A service_mapping
service_mapping["auth-service"]="auth-service"
service_mapping["calendar-service"]="calendar-service"
service_mapping["laboratorio-service"]="laboratorio-service"
service_mapping["solicitudes-service"]="ServicioSolicitudesOt"
service_mapping["cremer-backend"]="Cremer-Backend"
service_mapping["tecnomaco-backend"]="Tecnomaco-Backend"
service_mapping["servidor-rps"]="SERVIDOR_RPS"

echo "\n📋 MAPEO DE SERVICIOS:"
for service in "${!service_mapping[@]}"; do
    dir="${service_mapping[$service]}"
    echo "   • Servicio: $service → Directorio: $dir"
done

echo "\n🔧 VERIFICANDO DOCKER-COMPOSE.YML"
echo "================================="

# Verificar servicios en docker-compose.yml
show_info "Verificando nombres de servicios en docker-compose.yml..."

if grep -q "solicitudes-service:" docker-compose.yml; then
    show_success "Servicio 'solicitudes-service' encontrado en docker-compose.yml"
else
    show_error "Servicio 'solicitudes-service' NO encontrado en docker-compose.yml"
fi

if grep -q "cremer-backend:" docker-compose.yml; then
    show_success "Servicio 'cremer-backend' encontrado en docker-compose.yml"
else
    show_error "Servicio 'cremer-backend' NO encontrado en docker-compose.yml"
fi

if grep -q "tecnomaco-backend:" docker-compose.yml; then
    show_success "Servicio 'tecnomaco-backend' encontrado en docker-compose.yml"
else
    show_error "Servicio 'tecnomaco-backend' NO encontrado en docker-compose.yml"
fi

if grep -q "servidor-rps:" docker-compose.yml; then
    show_success "Servicio 'servidor-rps' encontrado en docker-compose.yml"
else
    show_error "Servicio 'servidor-rps' NO encontrado en docker-compose.yml"
fi

echo "\n🔧 VERIFICANDO DIRECTORIOS"
echo "=========================="

# Verificar que los directorios existen
for service in "${!service_mapping[@]}"; do
    dir="${service_mapping[$service]}"
    if [ -d "$dir" ]; then
        show_success "Directorio $dir existe (para servicio $service)"
        if [ -f "$dir/Dockerfile" ]; then
            show_success "$dir/Dockerfile existe"
        else
            show_error "$dir/Dockerfile NO existe"
        fi
    else
        show_error "Directorio $dir NO existe (para servicio $service)"
    fi
done

echo "\n🛠️  PROBANDO CONSTRUCCIÓN DE SERVICIOS"
echo "====================================="

# Probar construcción individual de cada servicio
for service in "${!service_mapping[@]}"; do
    dir="${service_mapping[$service]}"
    
    if [ -f "$dir/Dockerfile" ]; then
        show_info "Probando construcción de $service (directorio: $dir)..."
        
        # Intentar construcción con docker-compose
        if docker-compose build "$service" 2>/dev/null; then
            show_success "$service se construye correctamente con docker-compose"
        else
            show_error "$service FALLA al construirse con docker-compose"
            
            # Intentar construcción directa con docker
            show_info "Intentando construcción directa con docker..."
            if docker build -t "naturepharma-$service:test" "$dir/" 2>/dev/null; then
                show_success "$service se construye correctamente con docker build directo"
                # Limpiar imagen de prueba
                docker rmi "naturepharma-$service:test" 2>/dev/null || true
            else
                show_error "$service FALLA también con docker build directo"
            fi
        fi
    else
        show_warning "Saltando $service - Dockerfile no encontrado en $dir/"
    fi
    echo ""
done

echo "\n📊 RESUMEN DE DIAGNÓSTICO"
echo "========================"

# Contar problemas
problems=0

# Verificar cada servicio
for service in "${!service_mapping[@]}"; do
    dir="${service_mapping[$service]}"
    
    if [ ! -d "$dir" ]; then
        show_error "Problema: Directorio $dir no existe para servicio $service"
        ((problems++))
    elif [ ! -f "$dir/Dockerfile" ]; then
        show_error "Problema: Dockerfile no existe en $dir/ para servicio $service"
        ((problems++))
    fi
done

if [ $problems -eq 0 ]; then
    show_success "No se encontraron problemas estructurales"
    
    echo "\n🚀 RECOMENDACIONES"
    echo "================="
    echo "1. Usar nombres de servicios consistentes en scripts:"
    echo "   • solicitudes-service (no ServicioSolicitudesOt)"
    echo "   • cremer-backend (no Cremer-Backend)"
    echo "   • tecnomaco-backend (no Tecnomaco-Backend)"
    echo "   • servidor-rps (no SERVIDOR_RPS)"
    echo ""
    echo "2. Al construir servicios, usar:"
    echo "   docker-compose build solicitudes-service"
    echo "   docker-compose build cremer-backend"
    echo "   docker-compose build tecnomaco-backend"
    echo "   docker-compose build servidor-rps"
    echo ""
    echo "3. Los scripts de diagnóstico ya han sido actualizados para manejar"
    echo "   correctamente el mapeo entre nombres de servicios y directorios."
    
else
    show_error "Se encontraron $problems problemas que necesitan resolución"
    
    echo "\n🔧 ACCIONES RECOMENDADAS"
    echo "======================="
    echo "1. Ejecutar: ./fix-missing-dockerfiles.sh"
    echo "2. Verificar: ./debug-build.sh"
    echo "3. Construir: docker-compose build"
fi

echo "\n💡 INFORMACIÓN ADICIONAL"
echo "======================="
echo "• Los nombres de servicios en docker-compose.yml deben ser consistentes"
echo "• Los directorios pueden tener nombres diferentes (por compatibilidad)"
echo "• Los scripts han sido actualizados para manejar esta diferencia"
echo "• Usa 'docker-compose build [nombre-servicio]' para construcción individual"

echo "\n✅ Diagnóstico completado"