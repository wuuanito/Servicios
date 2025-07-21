#!/bin/bash

# Script de prueba rápida para verificar construcción de servicios
# NaturePharma System - Test Build Services

echo "=== Prueba Rápida de Construcción de Servicios ==="
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

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    show_error "No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

# Verificar Docker
if ! docker info > /dev/null 2>&1; then
    show_error "Docker no está corriendo"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    show_error "docker-compose no está instalado"
    exit 1
fi

show_info "Docker y docker-compose están disponibles"

# Lista de servicios con sus directorios correspondientes
declare -A services
services["auth-service"]="auth-service"
services["calendar-service"]="calendar-service"
services["laboratorio-service"]="laboratorio-service"
services["solicitudes-service"]="ServicioSolicitudesOt"
services["cremer-backend"]="Cremer-Backend"
services["tecnomaco-backend"]="Tecnomaco-Backend"
services["servidor-rps"]="SERVIDOR_RPS"

echo "\n🔍 VERIFICACIÓN PREVIA"
echo "====================="

# Verificar que todos los Dockerfiles existen
all_dockerfiles_exist=true
for service in "${!services[@]}"; do
    dir="${services[$service]}"
    if [ -f "$dir/Dockerfile" ]; then
        show_success "$service: Dockerfile encontrado en $dir/"
    else
        show_error "$service: Dockerfile NO encontrado en $dir/"
        all_dockerfiles_exist=false
    fi
done

if [ "$all_dockerfiles_exist" = false ]; then
    show_error "Faltan Dockerfiles. Ejecuta ./fix-missing-dockerfiles.sh primero."
    exit 1
fi

echo "\n🧪 PRUEBA DE CONSTRUCCIÓN INDIVIDUAL"
echo "===================================="

# Probar construcción de cada servicio individualmente
success_count=0
fail_count=0
failed_services=()

for service in "${!services[@]}"; do
    dir="${services[$service]}"
    
    echo "\n📦 Probando construcción de $service..."
    show_info "Servicio: $service"
    show_info "Directorio: $dir"
    
    # Intentar construcción
    if timeout 300 docker-compose build "$service" > /tmp/build_${service}.log 2>&1; then
        show_success "$service construido exitosamente"
        ((success_count++))
    else
        show_error "$service FALLÓ al construirse"
        failed_services+=("$service")
        ((fail_count++))
        
        # Mostrar últimas líneas del log de error
        echo "   📄 Últimas líneas del error:"
        tail -5 "/tmp/build_${service}.log" | sed 's/^/      /'
    fi
done

echo "\n📊 RESULTADOS DE LA PRUEBA"
echo "=========================="

show_info "Servicios probados: $((success_count + fail_count))"
show_success "Construcciones exitosas: $success_count"

if [ $fail_count -gt 0 ]; then
    show_error "Construcciones fallidas: $fail_count"
    echo "\n❌ Servicios que fallaron:"
    for failed_service in "${failed_services[@]}"; do
        echo "   • $failed_service"
        echo "     Log: /tmp/build_${failed_service}.log"
    done
    
    echo "\n🔧 ACCIONES RECOMENDADAS:"
    echo "1. Revisar los logs de error arriba"
    echo "2. Verificar dependencias en package.json"
    echo "3. Comprobar sintaxis de Dockerfiles"
    echo "4. Ejecutar: docker system prune -f"
    echo "5. Intentar: docker-compose build --no-cache [servicio]"
    
    exit 1
else
    show_success "¡Todos los servicios se construyeron exitosamente!"
    
    echo "\n🚀 PRÓXIMOS PASOS:"
    echo "1. Iniciar servicios: docker-compose up -d"
    echo "2. Verificar estado: docker-compose ps"
    echo "3. Ver logs: docker-compose logs -f"
    echo "4. Probar endpoints: ./check-health.sh"
fi

echo "\n🧹 LIMPIEZA"
echo "=========="
show_info "Eliminando logs temporales..."
rm -f /tmp/build_*.log
show_success "Limpieza completada"

echo "\n✅ Prueba de construcción completada"