#!/bin/bash

# Script de validación para SERVIDOR_RPS
# Verifica que todo esté correctamente configurado para Docker Compose

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Función para verificar si un archivo existe
check_file() {
    if [ -f "$1" ]; then
        print_success "Archivo encontrado: $1"
        return 0
    else
        print_error "Archivo faltante: $1"
        return 1
    fi
}

# Función para verificar contenido de archivo
check_file_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        print_success "$description encontrado en $file"
        return 0
    else
        print_error "$description NO encontrado en $file"
        return 1
    fi
}

# Cambiar al directorio del script
cd "$(dirname "$0")"

print_status "=== VALIDACIÓN SERVIDOR RPS ==="
print_status "Directorio actual: $(pwd)"
echo

# Contador de errores
errors=0

# 1. Verificar estructura de archivos
print_status "1. Verificando estructura de archivos..."
check_file "SERVIDOR_RPS/package.json" || ((errors++))
check_file "SERVIDOR_RPS/package-lock.json" || ((errors++))
check_file "SERVIDOR_RPS/server.js" || ((errors++))
check_file "SERVIDOR_RPS/Dockerfile" || ((errors++))
check_file "SERVIDOR_RPS/.dockerignore" || ((errors++))
check_file "SERVIDOR_RPS/healthcheck.js" || ((errors++))
check_file "SERVIDOR_RPS/README.md" || ((errors++))
check_file "docker-compose.yml" || ((errors++))
echo

# 2. Verificar package.json
print_status "2. Verificando package.json..."
if [ -f "SERVIDOR_RPS/package.json" ]; then
    check_file_content "SERVIDOR_RPS/package.json" '"express"' "Dependencia Express" || ((errors++))
    check_file_content "SERVIDOR_RPS/package.json" '"mssql"' "Dependencia MSSQL" || ((errors++))
    check_file_content "SERVIDOR_RPS/package.json" '"cors"' "Dependencia CORS" || ((errors++))
    check_file_content "SERVIDOR_RPS/package.json" '"start".*"node server.js"' "Script de inicio" || ((errors++))
fi
echo

# 3. Verificar server.js
print_status "3. Verificando server.js..."
if [ -f "SERVIDOR_RPS/server.js" ]; then
    check_file_content "SERVIDOR_RPS/server.js" "process.env.PORT" "Configuración de puerto con variable de entorno" || ((errors++))
    check_file_content "SERVIDOR_RPS/server.js" "process.env.DB_SERVER" "Configuración de servidor DB con variable de entorno" || ((errors++))
    check_file_content "SERVIDOR_RPS/server.js" "process.env.DB_USER" "Configuración de usuario DB con variable de entorno" || ((errors++))
    check_file_content "SERVIDOR_RPS/server.js" "/api/search" "Endpoint de búsqueda" || ((errors++))
    check_file_content "SERVIDOR_RPS/server.js" "/api/test-connection" "Endpoint de test de conexión" || ((errors++))
fi
echo

# 4. Verificar Dockerfile
print_status "4. Verificando Dockerfile..."
if [ -f "SERVIDOR_RPS/Dockerfile" ]; then
    check_file_content "SERVIDOR_RPS/Dockerfile" "FROM node:18-alpine" "Imagen base Node.js 18" || ((errors++))
    check_file_content "SERVIDOR_RPS/Dockerfile" "dumb-init" "Dumb-init para manejo de señales" || ((errors++))
    check_file_content "SERVIDOR_RPS/Dockerfile" "USER nodejs" "Usuario no-root" || ((errors++))
    check_file_content "SERVIDOR_RPS/Dockerfile" "--only=production" "Instalación solo dependencias de producción" || ((errors++))
    check_file_content "SERVIDOR_RPS/Dockerfile" "EXPOSE 4000" "Puerto expuesto" || ((errors++))
fi
echo

# 5. Verificar docker-compose.yml
print_status "5. Verificando docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    check_file_content "docker-compose.yml" "servidor-rps:" "Servicio servidor-rps definido" || ((errors++))
    check_file_content "docker-compose.yml" "build: ./SERVIDOR_RPS" "Build context correcto" || ((errors++))
    check_file_content "docker-compose.yml" "4000:4000" "Mapeo de puertos" || ((errors++))
    check_file_content "docker-compose.yml" "DB_SERVER=" "Variable de entorno DB_SERVER" || ((errors++))
    check_file_content "docker-compose.yml" "DB_USER=" "Variable de entorno DB_USER" || ((errors++))
    check_file_content "docker-compose.yml" "healthcheck:" "Health check configurado" || ((errors++))
    check_file_content "docker-compose.yml" "naturepharma-network" "Red configurada" || ((errors++))
fi
echo

# 6. Verificar permisos (solo en sistemas Unix)
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "6. Verificando permisos..."
    if [ -r "SERVIDOR_RPS/package.json" ] && [ -r "SERVIDOR_RPS/server.js" ] && [ -r "SERVIDOR_RPS/Dockerfile" ]; then
        print_success "Permisos de lectura correctos"
    else
        print_error "Problemas con permisos de lectura"
        ((errors++))
    fi
    echo
fi

# 7. Verificar sintaxis JSON
print_status "7. Verificando sintaxis JSON..."
if command -v node >/dev/null 2>&1; then
    if [ -f "SERVIDOR_RPS/package.json" ]; then
        if node -e "JSON.parse(require('fs').readFileSync('SERVIDOR_RPS/package.json', 'utf8'))" 2>/dev/null; then
            print_success "package.json tiene sintaxis JSON válida"
        else
            print_error "package.json tiene sintaxis JSON inválida"
            ((errors++))
        fi
    fi
else
    print_warning "Node.js no disponible, saltando validación de sintaxis JSON"
fi
echo

# Resumen final
print_status "=== RESUMEN DE VALIDACIÓN ==="
if [ $errors -eq 0 ]; then
    print_success "✅ Todas las validaciones pasaron correctamente"
    print_success "El servicio SERVIDOR_RPS está listo para Docker Compose"
    echo
    print_status "Comandos sugeridos para despliegue:"
    echo "  docker-compose build --no-cache servidor-rps"
    echo "  docker-compose up -d servidor-rps"
    echo "  docker-compose logs -f servidor-rps"
    echo
    print_status "URL del servicio: http://localhost:4000"
    print_status "Health check: docker-compose exec servidor-rps node healthcheck.js"
else
    print_error "❌ Se encontraron $errors errores"
    print_error "Por favor, corrija los errores antes del despliegue"
    exit 1
fi

echo
print_status "Validación completada."