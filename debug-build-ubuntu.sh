#!/bin/bash

# Script de diagnóstico completo para construcción Docker en Ubuntu Server
# Ejecutar con: sudo ./debug-build-ubuntu.sh

echo "=== NaturePharma System - Debug Build Script para Ubuntu ==="
echo "Fecha: $(date)"
echo ""

# Verificar que se ejecute con sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Este script debe ejecutarse con sudo"
    echo "Uso: sudo ./debug-build-ubuntu.sh"
    exit 1
fi

echo "1. Verificando Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker está instalado y ejecutándose"
        echo "   Versión: $(docker --version)"
    else
        echo "❌ Docker está instalado pero no se está ejecutando"
        echo "   Intentando iniciar Docker..."
        systemctl start docker
        sleep 3
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker iniciado correctamente"
        else
            echo "❌ No se pudo iniciar Docker"
            echo "   Ejecuta: sudo systemctl status docker"
            exit 1
        fi
    fi
else
    echo "❌ Docker no está instalado"
    echo "   Instala Docker con: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

echo ""
echo "2. Verificando Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    echo "✅ Docker Compose está instalado"
    echo "   Versión: $(docker-compose --version)"
elif docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose (plugin) está instalado"
    echo "   Versión: $(docker compose version)"
    # Crear alias para compatibilidad
    alias docker-compose='docker compose'
else
    echo "❌ Docker Compose no está instalado"
    echo "   Instala con: sudo apt-get update && sudo apt-get install docker-compose-plugin"
    exit 1
fi

echo ""
echo "3. Verificando directorio de trabajo..."
if [ -f "docker-compose.yml" ]; then
    echo "✅ Archivo docker-compose.yml encontrado"
else
    echo "❌ Archivo docker-compose.yml NO encontrado"
    echo "   Asegúrate de estar en el directorio correcto"
    exit 1
fi

echo "Directorio actual: $(pwd)"
echo "Archivos principales:"
ls -la *.yml *.sh .env* 2>/dev/null | head -10

echo ""
echo "4. Verificando Dockerfiles..."

# Función para verificar Dockerfile
check_dockerfile() {
    local service_dir="$1"
    local service_name="$2"
    
    if [ -d "$service_dir" ]; then
        if [ -f "$service_dir/Dockerfile" ]; then
            echo "✅ $service_name/Dockerfile encontrado (en $service_dir/)"
            
            # Verificar contenido básico del Dockerfile
            if grep -q "FROM" "$service_dir/Dockerfile"; then
                echo "   - Contiene instrucción FROM"
            else
                echo "   ⚠️  No contiene instrucción FROM válida"
            fi
            
            if grep -q "WORKDIR" "$service_dir/Dockerfile"; then
                echo "   - Contiene WORKDIR"
            fi
            
            if grep -q "EXPOSE" "$service_dir/Dockerfile"; then
                echo "   - Contiene EXPOSE"
            fi
            
        else
            echo "❌ ERROR: $service_dir/Dockerfile NO encontrado (buscando en $service_dir/)"
            return 1
        fi
    else
        echo "⚠️  Directorio $service_dir no existe"
        return 1
    fi
    return 0
}

# Verificar todos los servicios
services_with_errors=0

check_dockerfile "auth-service" "auth-service" || ((services_with_errors++))
check_dockerfile "calendar-service" "calendar-service" || ((services_with_errors++))
check_dockerfile "laboratorio-service" "laboratorio-service" || ((services_with_errors++))
check_dockerfile "ServicioSolicitudesOt" "solicitudes-service" || ((services_with_errors++))
check_dockerfile "Cremer-Backend" "cremer-backend" || ((services_with_errors++))
check_dockerfile "Tecnomaco-Backend" "tecnomaco-backend" || ((services_with_errors++))
check_dockerfile "SERVIDOR_RPS" "servidor-rps" || ((services_with_errors++))

echo ""
echo "5. Verificando package.json en servicios..."

# Función para verificar package.json
check_package_json() {
    local service_dir="$1"
    local service_name="$2"
    
    if [ -d "$service_dir" ]; then
        if [ -f "$service_dir/package.json" ]; then
            echo "✅ $service_name/package.json encontrado"
            
            # Verificar scripts de inicio
            if grep -q '"start"' "$service_dir/package.json"; then
                echo "   - Contiene script 'start'"
            else
                echo "   ⚠️  No contiene script 'start'"
            fi
            
        else
            echo "❌ $service_name/package.json NO encontrado"
            return 1
        fi
    fi
    return 0
}

check_package_json "auth-service" "auth-service"
check_package_json "calendar-service" "calendar-service"
check_package_json "laboratorio-service" "laboratorio-service"
check_package_json "ServicioSolicitudesOt" "solicitudes-service"
check_package_json "Cremer-Backend" "cremer-backend"
check_package_json "Tecnomaco-Backend" "tecnomaco-backend"
check_package_json "SERVIDOR_RPS" "servidor-rps"

echo ""
echo "6. Verificando archivo .env..."
if [ -f ".env" ]; then
    echo "✅ Archivo .env encontrado"
    echo "   Variables principales:"
    grep -E "^(DB_HOST|DB_USER|NODE_ENV|.*_PORT)=" .env 2>/dev/null | head -5
else
    echo "⚠️  Archivo .env no encontrado"
    if [ -f ".env.example" ]; then
        echo "   Pero .env.example está disponible"
        echo "   Ejecuta: cp .env.example .env"
    else
        echo "   Tampoco existe .env.example"
    fi
fi

echo ""
echo "7. Verificando conectividad de red..."
echo "Probando conectividad a base de datos..."
if ping -c 1 192.168.20.158 >/dev/null 2>&1; then
    echo "✅ Conectividad a 192.168.20.158 exitosa"
else
    echo "⚠️  No se puede conectar a 192.168.20.158"
    echo "   Verifica la configuración de red"
fi

echo ""
echo "8. Probando construcción individual de servicios..."

# Función para probar construcción
test_build() {
    local service_dir="$1"
    local service_name="$2"
    
    if [ ! -d "$service_dir" ] || [ ! -f "$service_dir/Dockerfile" ]; then
        echo "⏭️  Omitiendo $service_name (no disponible)"
        return
    fi
    
    echo "🔨 Probando construcción de $service_name..."
    
    # Cambiar al directorio del servicio
    cd "$service_dir" || return
    
    # Intentar construir con output detallado
    if docker build -t "naturepharma-$service_name:debug" . 2>&1 | tee "/tmp/build-$service_name.log"; then
        echo "✅ $service_name: Construcción exitosa"
        # Limpiar imagen de prueba
        docker rmi "naturepharma-$service_name:debug" >/dev/null 2>&1
    else
        echo "❌ $service_name: Error en construcción"
        echo "   Log guardado en: /tmp/build-$service_name.log"
        echo "   Últimas líneas del error:"
        tail -10 "/tmp/build-$service_name.log" | sed 's/^/     /'
    fi
    
    # Volver al directorio principal
    cd - >/dev/null
    echo ""
}

# Solo probar servicios que tienen errores o todos si no hay errores específicos
if [ $services_with_errors -gt 0 ]; then
    echo "Probando solo servicios con Dockerfiles faltantes..."
else
    echo "Probando construcción de todos los servicios..."
fi

test_build "auth-service" "auth-service"
test_build "calendar-service" "calendar-service"
test_build "laboratorio-service" "laboratorio-service"
test_build "ServicioSolicitudesOt" "solicitudes-service"
test_build "Cremer-Backend" "cremer-backend"
test_build "Tecnomaco-Backend" "tecnomaco-backend"
test_build "SERVIDOR_RPS" "servidor-rps"

echo "9. Verificando recursos del sistema..."
echo "Espacio en disco:"
df -h / | tail -1
echo "Memoria disponible:"
free -h | grep Mem
echo "Procesos Docker:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | head -10

echo ""
echo "10. Información de red Docker..."
echo "Redes Docker:"
docker network ls
echo ""
echo "Volúmenes Docker:"
docker volume ls | head -5

echo ""
echo "=== RESUMEN DEL DIAGNÓSTICO ==="
if [ $services_with_errors -gt 0 ]; then
    echo "❌ Se encontraron $services_with_errors servicios con Dockerfiles faltantes"
    echo ""
    echo "🔧 SOLUCIÓN RECOMENDADA:"
    echo "   1. Ejecuta: sudo ./fix-missing-dockerfiles-ubuntu.sh"
    echo "   2. Luego ejecuta: sudo docker-compose up -d --build"
    echo ""
     echo -e "${YELLOW}🔧 SOLUCIÓN ESPECÍFICA PARA SERVIDOR-RPS:${NC}"
     echo -e "   Si el error es con servidor-rps (package.json no encontrado):"
     echo -e "   ${GREEN}sudo ./fix-servidor-rps-ubuntu.sh${NC}"
else
    echo "✅ Todos los Dockerfiles están presentes"
    echo ""
    echo "🚀 SIGUIENTE PASO:"
    echo "   Ejecuta: sudo docker-compose up -d --build"
fi

echo ""
echo "📋 COMANDOS ÚTILES PARA DEBUGGING:"
echo "   - Ver logs detallados: sudo docker-compose logs -f [servicio]"
echo "   - Reconstruir un servicio: sudo docker-compose up -d --build [servicio]"
echo "   - Entrar a un contenedor: sudo docker exec -it [contenedor] /bin/sh"
echo "   - Limpiar todo: sudo docker system prune -a"
echo ""
echo "📁 LOGS DE CONSTRUCCIÓN GUARDADOS EN:"
echo "   /tmp/build-*.log"
echo ""
echo "=== Diagnóstico completado ==="