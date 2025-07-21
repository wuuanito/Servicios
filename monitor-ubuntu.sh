#!/bin/bash

# Script de monitoreo del sistema NaturePharma para Ubuntu Server
# Ejecutar con: sudo ./monitor-ubuntu.sh

echo "=== Monitor del Sistema NaturePharma - Ubuntu Server ==="
echo "Fecha: $(date)"
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"
echo ""

# Verificar que se ejecute con sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Este script debe ejecutarse con sudo"
    echo "Uso: sudo ./monitor-ubuntu.sh"
    exit 1
fi

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar estado con colores
show_status() {
    local service=$1
    local status=$2
    local port=$3
    
    if [ "$status" = "running" ]; then
        printf "${GREEN}✅ %-20s${NC} ${GREEN}%s${NC}" "$service" "$status"
        if [ ! -z "$port" ]; then
            printf "${BLUE} (Puerto: %s)${NC}" "$port"
        fi
        echo ""
    elif [ "$status" = "exited" ] || [ "$status" = "dead" ]; then
        printf "${RED}❌ %-20s${NC} ${RED}%s${NC}\n" "$service" "$status"
    else
        printf "${YELLOW}⚠️  %-20s${NC} ${YELLOW}%s${NC}\n" "$service" "$status"
    fi
}

# Función para verificar conectividad de puerto
check_port() {
    local port=$1
    local timeout=3
    
    if timeout $timeout bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        echo "${GREEN}✅${NC}"
    else
        echo "${RED}❌${NC}"
    fi
}

# Función para obtener uso de CPU y memoria de un contenedor
get_container_stats() {
    local container_name=$1
    
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        local stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" "$container_name" 2>/dev/null | tail -n 1)
        if [ ! -z "$stats" ]; then
            echo "$stats"
        else
            echo "N/A\tN/A"
        fi
    else
        echo "N/A\tN/A"
    fi
}

echo "🔍 Verificando Docker..."
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker está ejecutándose"
        echo "   Versión: $(docker --version)"
    else
        echo "❌ Docker no está ejecutándose"
        echo "   Intenta: sudo systemctl start docker"
        exit 1
    fi
else
    echo "❌ Docker no está instalado"
    echo "   Ejecuta: sudo ./install-docker-ubuntu.sh"
    exit 1
fi

echo ""
echo "🔍 Verificando Docker Compose..."
if command -v docker-compose >/dev/null 2>&1; then
    echo "✅ Docker Compose disponible: $(docker-compose --version)"
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    echo "✅ Docker Compose disponible: $(docker compose version)"
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose no está disponible"
    exit 1
fi

echo ""
echo "📊 Estado de los Contenedores:"
echo "================================================"

# Verificar si hay contenedores ejecutándose
if [ $(docker ps -q | wc -l) -eq 0 ]; then
    echo "⚠️  No hay contenedores ejecutándose"
    echo "   Ejecuta: sudo ./start-system-ubuntu.sh"
else
    # Mostrar estado de contenedores
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -n 1
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while read line; do
        if [ ! -z "$line" ]; then
            echo "$line"
        fi
    done
fi

echo ""
echo "🌐 Estado de los Servicios NaturePharma:"
echo "================================================"

# Lista de servicios a verificar
declare -A services=(
    ["naturepharma-auth"]="3001"
    ["naturepharma-calendar"]="3002"
    ["naturepharma-laboratorio"]="3003"
    ["naturepharma-solicitudes"]="3004"
    ["naturepharma-cremer"]="3005"
    ["naturepharma-tecnomaco"]="3006"
    ["naturepharma-servidor-rps"]="3007"
    ["naturepharma-phpmyadmin"]="8080"
    ["naturepharma-log-monitor"]="8081"
    ["naturepharma-nginx"]="80"
)

printf "%-25s %-15s %-10s %-15s %-15s\n" "Servicio" "Estado" "Puerto" "CPU" "Memoria"
echo "---------------------------------------------------------------------------------"

for service in "${!services[@]}"; do
    port=${services[$service]}
    
    # Verificar si el contenedor existe y está ejecutándose
    if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
        status="running"
        port_status=$(check_port $port)
        stats=$(get_container_stats $service)
        cpu=$(echo $stats | cut -f1)
        memory=$(echo $stats | cut -f2)
        
        printf "%-25s ${GREEN}%-15s${NC} %-10s %-15s %-15s\n" "$service" "$status" "$port $port_status" "$cpu" "$memory"
    elif docker ps -a --format "{{.Names}}" | grep -q "^$service$"; then
        status=$(docker ps -a --format "{{.Names}}\t{{.Status}}" | grep "^$service" | cut -f2 | cut -d' ' -f1)
        printf "%-25s ${RED}%-15s${NC} %-10s %-15s %-15s\n" "$service" "$status" "$port ❌" "N/A" "N/A"
    else
        printf "%-25s ${YELLOW}%-15s${NC} %-10s %-15s %-15s\n" "$service" "no existe" "$port ❌" "N/A" "N/A"
    fi
done

echo ""
echo "🔗 Verificación de Conectividad:"
echo "================================================"

# URLs principales
declare -A urls=(
    ["Auth Service"]="http://localhost:3001"
    ["Calendar Service"]="http://localhost:3002"
    ["Laboratorio Service"]="http://localhost:3003"
    ["Solicitudes Service"]="http://localhost:3004"
    ["Cremer Backend"]="http://localhost:3005"
    ["Tecnomaco Backend"]="http://localhost:3006"
    ["Servidor RPS"]="http://localhost:3007"
    ["phpMyAdmin"]="http://localhost:8080"
    ["Log Monitor"]="http://localhost:8081"
    ["Nginx Gateway"]="http://localhost:80"
)

for service in "${!urls[@]}"; do
    url=${urls[$service]}
    port=$(echo $url | sed 's/.*://' | sed 's/\/.*//')
    
    printf "%-20s %-30s " "$service" "$url"
    
    if timeout 3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        echo -e "${GREEN}✅ Disponible${NC}"
    else
        echo -e "${RED}❌ No disponible${NC}"
    fi
done

echo ""
echo "📈 Recursos del Sistema:"
echo "================================================"

# Información del sistema
echo "💾 Memoria:"
free -h | grep -E "Mem|Swap"

echo ""
echo "💿 Espacio en Disco:"
df -h / | grep -v "Filesystem"

echo ""
echo "🔥 CPU:"
echo "   Carga promedio: $(uptime | awk -F'load average:' '{print $2}')"
echo "   Procesos activos: $(ps aux | wc -l)"

echo ""
echo "🐳 Estadísticas Docker:"
echo "   Contenedores ejecutándose: $(docker ps -q | wc -l)"
echo "   Contenedores totales: $(docker ps -a -q | wc -l)"
echo "   Imágenes: $(docker images -q | wc -l)"
echo "   Volúmenes: $(docker volume ls -q | wc -l)"
echo "   Redes: $(docker network ls -q | wc -l)"

echo ""
echo "📋 Logs Recientes (últimas 5 líneas por servicio):"
echo "================================================"

for service in "${!services[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
        echo -e "\n${CYAN}📄 $service:${NC}"
        docker logs --tail 5 "$service" 2>/dev/null | sed 's/^/   /'
    fi
done

echo ""
echo "🔧 Comandos Útiles:"
echo "================================================"
echo "   Ver todos los logs:        sudo docker-compose logs -f"
echo "   Ver logs de un servicio:   sudo docker-compose logs -f [servicio]"
echo "   Reiniciar un servicio:     sudo docker-compose restart [servicio]"
echo "   Detener todos:             sudo docker-compose down"
echo "   Iniciar todos:             sudo docker-compose up -d"
echo "   Estado detallado:          sudo docker-compose ps"
echo "   Limpiar sistema:           sudo docker system prune"
echo "   Reconstruir servicio:      sudo docker-compose up -d --build [servicio]"

echo ""
echo "🌐 URLs de Acceso Directo:"
echo "================================================"
echo "   🔐 Auth API:        http://localhost/api/auth"
echo "   📅 Calendar API:    http://localhost/api/events"
echo "   🧪 Laboratorio API: http://localhost/api/laboratorio"
echo "   📋 Solicitudes API: http://localhost/api/solicitudes"
echo "   🗄️  Base de Datos:   http://localhost:8080 (phpMyAdmin)"
echo "   📊 Monitor Logs:    http://localhost:8081"

echo ""
echo "⚡ Acciones Rápidas:"
echo "================================================"
echo "   [1] Ver logs en tiempo real:    sudo docker-compose logs -f"
echo "   [2] Reiniciar todos:             sudo docker-compose restart"
echo "   [3] Verificar salud:             sudo docker-compose ps"
echo "   [4] Limpiar y reiniciar:         sudo docker-compose down && sudo docker-compose up -d"
echo "   [5] Diagnóstico completo:        sudo ./debug-build-ubuntu.sh"

echo ""
echo "=== Monitor completado ==="
echo "Fecha: $(date)"
echo "========================="

# Opción interactiva
echo ""
read -p "¿Deseas ejecutar alguna acción? (1-5, o Enter para salir): " choice

case $choice in
    1)
        echo "Mostrando logs en tiempo real (Ctrl+C para salir)..."
        $COMPOSE_CMD logs -f
        ;;
    2)
        echo "Reiniciando todos los servicios..."
        $COMPOSE_CMD restart
        echo "✅ Servicios reiniciados"
        ;;
    3)
        echo "Estado detallado de servicios:"
        $COMPOSE_CMD ps
        ;;
    4)
        echo "Deteniendo servicios..."
        $COMPOSE_CMD down
        echo "Iniciando servicios..."
        $COMPOSE_CMD up -d
        echo "✅ Servicios reiniciados completamente"
        ;;
    5)
        echo "Ejecutando diagnóstico completo..."
        if [ -f "debug-build-ubuntu.sh" ]; then
            chmod +x debug-build-ubuntu.sh
            ./debug-build-ubuntu.sh
        else
            echo "❌ Archivo debug-build-ubuntu.sh no encontrado"
        fi
        ;;
    *)
        echo "Saliendo del monitor..."
        ;;
esac