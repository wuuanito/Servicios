#!/bin/bash

# Script de mejora de calidad y mantenibilidad del proyecto
# NaturePharma System - Project Quality Improvement

echo "=== NaturePharma System - Mejora de Calidad del Proyecto ==="
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

# Función para mostrar advertencia
show_warning() {
    echo "⚠️  $1"
}

# Función para mostrar sugerencia
show_suggestion() {
    echo "💡 $1"
}

echo "🔍 ANÁLISIS DE CALIDAD DEL CÓDIGO"
echo "================================="

# 1. Verificar estructura de .gitignore
echo "\n1. Verificando archivos .gitignore..."
services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")

for service in "${services[@]}"; do
    if [ -f "$service/.gitignore" ]; then
        # Verificar contenido básico
        if grep -q "node_modules" "$service/.gitignore"; then
            show_success "$service/.gitignore incluye node_modules"
        else
            show_warning "$service/.gitignore no incluye node_modules"
        fi
        
        if grep -q ".env" "$service/.gitignore"; then
            show_success "$service/.gitignore incluye .env"
        else
            show_warning "$service/.gitignore no incluye .env"
        fi
    else
        show_warning "$service/.gitignore no existe"
    fi
done

# 2. Verificar archivos .env.example
echo "\n2. Verificando archivos .env.example..."
for service in "${services[@]}"; do
    if [ -f "$service/.env.example" ]; then
        show_success "$service/.env.example existe"
    else
        show_warning "$service/.env.example no existe"
    fi
done

# 3. Verificar documentación README
echo "\n3. Verificando documentación README..."
for service in "${services[@]}"; do
    if [ -f "$service/README.md" ]; then
        show_success "$service/README.md existe"
    else
        show_warning "$service/README.md no existe"
    fi
done

# 4. Verificar package.json
echo "\n4. Verificando package.json..."
for service in "${services[@]}"; do
    if [ -f "$service/package.json" ]; then
        show_success "$service/package.json existe"
        
        # Verificar scripts básicos
        if grep -q '"start"' "$service/package.json"; then
            show_success "$service tiene script 'start'"
        else
            show_warning "$service no tiene script 'start'"
        fi
        
        if grep -q '"dev"' "$service/package.json"; then
            show_success "$service tiene script 'dev'"
        else
            show_warning "$service no tiene script 'dev'"
        fi
    else
        show_warning "$service/package.json no existe"
    fi
done

# 5. Verificar Dockerfiles
echo "\n5. Verificando Dockerfiles..."
for service in "${services[@]}"; do
    if [ -f "$service/Dockerfile" ]; then
        show_success "$service/Dockerfile existe"
        
        # Verificar mejores prácticas en Dockerfile
        if grep -q "USER" "$service/Dockerfile"; then
            show_success "$service/Dockerfile usa usuario no-root"
        else
            show_warning "$service/Dockerfile no especifica usuario no-root"
        fi
        
        if grep -q "EXPOSE" "$service/Dockerfile"; then
            show_success "$service/Dockerfile expone puerto"
        else
            show_warning "$service/Dockerfile no expone puerto"
        fi
    else
        show_warning "$service/Dockerfile no existe"
    fi
done

echo "\n💡 SUGERENCIAS DE MEJORA"
echo "========================"

show_suggestion "Estructura de Proyecto:"
echo "   • Crear .gitignore estándar para todos los servicios"
echo "   • Agregar .env.example con variables documentadas"
echo "   • Crear README.md específico para cada servicio"
echo "   • Estandarizar scripts de package.json"

show_suggestion "Seguridad:"
echo "   • Todos los Dockerfiles deben usar usuarios no-root"
echo "   • Implementar health checks en Dockerfiles"
echo "   • Usar .dockerignore para optimizar builds"
echo "   • Validar variables de entorno requeridas"

show_suggestion "Monitoreo y Logs:"
echo "   • Implementar logging estructurado (JSON)"
echo "   • Agregar métricas de aplicación"
echo "   • Configurar health checks HTTP"
echo "   • Implementar graceful shutdown"

show_suggestion "Testing:"
echo "   • Agregar scripts de testing en package.json"
echo "   • Implementar tests unitarios"
echo "   • Configurar linting (ESLint)"
echo "   • Agregar tests de integración"

show_suggestion "CI/CD:"
echo "   • Mejorar pipeline de GitHub Actions"
echo "   • Agregar stages de testing"
echo "   • Implementar análisis de código"
echo "   • Configurar deployment automático"

show_suggestion "Documentación:"
echo "   • Documentar APIs con OpenAPI/Swagger"
echo "   • Crear guías de desarrollo"
echo "   • Documentar arquitectura del sistema"
echo "   • Agregar ejemplos de uso"

echo "\n🔧 ACCIONES RECOMENDADAS"
echo "========================"

echo "\n1. Ejecutar script de sincronización:"
echo "   ./sync-dockerfiles.sh"

echo "\n2. Crear archivos .gitignore estándar:"
echo "   ./create-standard-gitignore.sh"

echo "\n3. Generar .env.example para todos los servicios:"
echo "   ./create-env-examples.sh"

echo "\n4. Implementar health checks:"
echo "   ./add-health-checks.sh"

echo "\n5. Configurar linting y testing:"
echo "   ./setup-quality-tools.sh"

echo "\n✅ Análisis de calidad completado!"
echo "Revisa las sugerencias y ejecuta los scripts recomendados."