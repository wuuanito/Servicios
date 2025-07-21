#!/bin/bash

# Script de verificación integral de salud del proyecto NaturePharma
# Autor: Sistema de Automatización NaturePharma
# Fecha: $(date +%Y-%m-%d)

echo "🏥 Verificación Integral de Salud del Proyecto NaturePharma"
echo "========================================================="
echo "Fecha: $(date)"
echo "Directorio: $(pwd)"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores globales
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

# Función para mostrar resultados
show_result() {
    local status="$1"
    local message="$2"
    ((TOTAL_CHECKS++))
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ((PASSED_CHECKS++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ((WARNING_CHECKS++))
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ((FAILED_CHECKS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
    esac
}

# 1. Verificación de entorno
echo "🔍 1. VERIFICACIÓN DE ENTORNO"
echo "============================="

# Verificar Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null)
    show_result "PASS" "Docker instalado: $DOCKER_VERSION"
else
    show_result "FAIL" "Docker no está instalado"
fi

# Verificar Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version 2>/dev/null)
    show_result "PASS" "Docker Compose instalado: $COMPOSE_VERSION"
else
    show_result "FAIL" "Docker Compose no está instalado"
fi

# Verificar Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null)
    show_result "PASS" "Node.js instalado: $NODE_VERSION"
else
    show_result "WARN" "Node.js no está instalado (opcional para desarrollo)"
fi

# Verificar npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version 2>/dev/null)
    show_result "PASS" "npm instalado: $NPM_VERSION"
else
    show_result "WARN" "npm no está instalado (opcional para desarrollo)"
fi

echo ""

# 2. Verificación de archivos de configuración
echo "📁 2. VERIFICACIÓN DE ARCHIVOS DE CONFIGURACIÓN"
echo "==============================================="

# Verificar docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    show_result "PASS" "docker-compose.yml encontrado"
    
    # Verificar sintaxis
    if docker-compose config &> /dev/null; then
        show_result "PASS" "docker-compose.yml tiene sintaxis válida"
    else
        show_result "FAIL" "docker-compose.yml tiene errores de sintaxis"
    fi
else
    show_result "FAIL" "docker-compose.yml no encontrado"
fi

# Verificar .env
if [ -f ".env" ]; then
    show_result "PASS" ".env encontrado"
else
    if [ -f ".env.example" ]; then
        show_result "WARN" ".env no encontrado, pero .env.example disponible"
    else
        show_result "FAIL" ".env y .env.example no encontrados"
    fi
fi

# Verificar README.md
if [ -f "README.md" ]; then
    show_result "PASS" "README.md encontrado"
else
    show_result "WARN" "README.md no encontrado"
fi

echo ""

# 3. Verificación de servicios y Dockerfiles
echo "🐳 3. VERIFICACIÓN DE SERVICIOS Y DOCKERFILES"
echo "============================================="

# Detectar servicios automáticamente
SERVICES=()
for dir in */; do
    if [ -f "${dir}Dockerfile" ] && [ -f "${dir}package.json" ]; then
        SERVICES+=("${dir%/}")
    fi
done

show_result "INFO" "Servicios detectados: ${SERVICES[*]}"

# Verificar cada servicio
for service in "${SERVICES[@]}"; do
    echo "\n📋 Verificando servicio: $service"
    echo "--------------------------------"
    
    # Verificar Dockerfile
    if [ -f "$service/Dockerfile" ]; then
        show_result "PASS" "$service: Dockerfile encontrado"
        
        # Verificar comando npm actualizado
        if grep -q "npm ci --only=production" "$service/Dockerfile"; then
            show_result "WARN" "$service: Dockerfile usa npm ci --only=production (necesita actualización)"
        elif grep -q "npm ci --omit=dev\|npm install --omit=dev" "$service/Dockerfile"; then
            show_result "PASS" "$service: Dockerfile usa estrategia npm robusta"
        else
            show_result "WARN" "$service: Dockerfile no contiene comando npm reconocido"
        fi
        
        # Verificar usuario no-root
        if grep -q "USER" "$service/Dockerfile"; then
            show_result "PASS" "$service: Dockerfile usa usuario no-root"
        else
            show_result "WARN" "$service: Dockerfile no define usuario no-root"
        fi
        
        # Verificar WORKDIR
        if grep -q "WORKDIR" "$service/Dockerfile"; then
            show_result "PASS" "$service: Dockerfile define WORKDIR"
        else
            show_result "WARN" "$service: Dockerfile no define WORKDIR"
        fi
    else
        show_result "FAIL" "$service: Dockerfile no encontrado"
    fi
    
    # Verificar package.json
    if [ -f "$service/package.json" ]; then
        show_result "PASS" "$service: package.json encontrado"
    else
        show_result "FAIL" "$service: package.json no encontrado"
    fi
    
    # Verificar package-lock.json
    if [ -f "$service/package-lock.json" ]; then
        show_result "PASS" "$service: package-lock.json encontrado"
    else
        show_result "WARN" "$service: package-lock.json no encontrado (se generará automáticamente)"
    fi
done

echo ""

# 4. Verificación de scripts de automatización
echo "🔧 4. VERIFICACIÓN DE SCRIPTS DE AUTOMATIZACIÓN"
echo "==============================================="

SCRIPTS=(
    "start-system.sh:Script de inicio del sistema"
    "debug-build.sh:Script de diagnóstico de construcción"
    "deploy.sh:Script de despliegue"
    "fix-service-names.sh:Script de corrección de nombres"
    "test-build-services.sh:Script de prueba de construcción"
    "generate-lockfiles.sh:Script de generación de lockfiles"
    "fix-npm-lockfiles.sh:Script de corrección npm"
    "test-npm-fix.sh:Script de prueba de corrección npm"
    "sync-dockerfiles.sh:Script de sincronización de Dockerfiles"
)

for script_info in "${SCRIPTS[@]}"; do
    script_name="${script_info%%:*}"
    script_desc="${script_info##*:}"
    
    if [ -f "$script_name" ]; then
        if [ -x "$script_name" ]; then
            show_result "PASS" "$script_desc ($script_name) - ejecutable"
        else
            show_result "WARN" "$script_desc ($script_name) - no ejecutable"
        fi
    else
        show_result "WARN" "$script_desc ($script_name) - no encontrado"
    fi
done

echo ""

# 5. Verificación de construcción de servicios
echo "🏗️  5. VERIFICACIÓN DE CONSTRUCCIÓN (OPCIONAL)"
echo "==============================================="

read -p "¿Deseas probar la construcción de servicios? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Probando construcción de servicios..."
    
    for service in "${SERVICES[@]}"; do
        echo "\n🔧 Construyendo $service..."
        
        if timeout 60 docker-compose build "$service" &> /dev/null; then
            show_result "PASS" "$service: Construcción exitosa"
        else
            show_result "FAIL" "$service: Error en construcción"
        fi
    done
else
    show_result "INFO" "Verificación de construcción omitida"
fi

echo ""

# 6. Resumen final
echo "📊 RESUMEN FINAL"
echo "================"
echo -e "Total de verificaciones: $TOTAL_CHECKS"
echo -e "${GREEN}✅ Exitosas: $PASSED_CHECKS${NC}"
echo -e "${YELLOW}⚠️  Advertencias: $WARNING_CHECKS${NC}"
echo -e "${RED}❌ Fallidas: $FAILED_CHECKS${NC}"
echo ""

# Calcular porcentaje de salud
if [ $TOTAL_CHECKS -gt 0 ]; then
    HEALTH_PERCENTAGE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    
    if [ $HEALTH_PERCENTAGE -ge 90 ]; then
        echo -e "${GREEN}🎉 ESTADO DEL PROYECTO: EXCELENTE ($HEALTH_PERCENTAGE%)${NC}"
    elif [ $HEALTH_PERCENTAGE -ge 75 ]; then
        echo -e "${YELLOW}👍 ESTADO DEL PROYECTO: BUENO ($HEALTH_PERCENTAGE%)${NC}"
    elif [ $HEALTH_PERCENTAGE -ge 50 ]; then
        echo -e "${YELLOW}⚠️  ESTADO DEL PROYECTO: REGULAR ($HEALTH_PERCENTAGE%)${NC}"
    else
        echo -e "${RED}🚨 ESTADO DEL PROYECTO: NECESITA ATENCIÓN ($HEALTH_PERCENTAGE%)${NC}"
    fi
fi

echo ""

# 7. Recomendaciones
echo "💡 RECOMENDACIONES"
echo "=================="

if [ $FAILED_CHECKS -gt 0 ]; then
    echo "🔧 Para corregir errores críticos:"
    echo "   1. Ejecutar: ./sync-dockerfiles.sh"
    echo "   2. Ejecutar: ./fix-npm-lockfiles.sh"
    echo "   3. Verificar instalación de Docker y Docker Compose"
fi

if [ $WARNING_CHECKS -gt 0 ]; then
    echo "⚠️  Para mejorar el proyecto:"
    echo "   1. Generar lockfiles: ./generate-lockfiles.sh"
    echo "   2. Hacer scripts ejecutables: chmod +x *.sh"
    echo "   3. Crear archivo .env desde .env.example"
fi

echo "\n📋 Para verificación completa:"
echo "   1. Probar construcción: ./test-npm-fix.sh"
echo "   2. Probar servicios: ./test-build-services.sh"
echo "   3. Iniciar sistema: ./start-system.sh"

echo ""
echo "🏁 Verificación integral completada."
echo "Fecha de finalización: $(date)"