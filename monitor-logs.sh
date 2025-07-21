#!/bin/bash

# Script de monitoreo de logs del sistema NaturePharma
# Permite monitorear logs de servicios específicos o todos

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "📊 Monitor de Logs - Sistema NaturePharma"
    echo "========================================="
    echo ""
    echo "Uso: $0 [OPCIÓN] [SERVICIO]"
    echo ""
    echo "Opciones:"
    echo "  -a, --all           Ver logs de todos los servicios"
    echo "  -f, --follow        Seguir logs en tiempo real"
    echo "  -t, --tail N        Mostrar últimas N líneas (default: 100)"
    echo "  -s, --since FECHA   Logs desde fecha específica"
    echo "  -e, --export        Exportar logs a archivos"
    echo "  -h, --help          Mostrar esta ayuda"
    echo ""
    echo "Servicios disponibles:"
    echo "  • auth-service"
    echo "  • calendar-service"
    echo "  • laboratorio-service"
    echo "  • solicitudes-service"
    echo "  • cremer-backend"
    echo "  • tecnomaco-backend"
    echo "  • servidor-rps"
    echo "  • phpmyadmin"
    echo "  • nginx"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -a -f                    # Todos los logs en tiempo real"
    echo "  $0 -f cremer-backend        # Logs de Cremer en tiempo real"
    echo "  $0 -t 50 tecnomaco-backend  # Últimas 50 líneas de Tecnomaco"
    echo "  $0 -e                       # Exportar todos los logs"
    echo "  $0 -s '2024-01-01' auth-service  # Logs desde fecha específica"
}

# Función para verificar que Docker esté corriendo
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker no está corriendo${NC}"
        exit 1
    fi
}

# Función para verificar que los servicios estén corriendo
check_services() {
    if [ $(docker-compose ps -q | wc -l) -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Advertencia: No hay servicios corriendo${NC}"
        echo "Ejecuta 'docker-compose up -d' para iniciar los servicios"
        exit 1
    fi
}

# Función para mostrar logs de todos los servicios
show_all_logs() {
    local follow_flag="$1"
    local tail_lines="$2"
    local since_date="$3"
    
    echo -e "${GREEN}📊 Mostrando logs de todos los servicios${NC}"
    echo "=========================================="
    
    cmd="docker-compose logs"
    
    if [ "$follow_flag" = "true" ]; then
        cmd="$cmd -f"
    fi
    
    if [ ! -z "$tail_lines" ]; then
        cmd="$cmd --tail=$tail_lines"
    fi
    
    if [ ! -z "$since_date" ]; then
        cmd="$cmd --since='$since_date'"
    fi
    
    cmd="$cmd -t"
    
    eval $cmd
}

# Función para mostrar logs de un servicio específico
show_service_logs() {
    local service="$1"
    local follow_flag="$2"
    local tail_lines="$3"
    local since_date="$4"
    
    echo -e "${BLUE}📊 Mostrando logs de: $service${NC}"
    echo "=========================================="
    
    cmd="docker-compose logs"
    
    if [ "$follow_flag" = "true" ]; then
        cmd="$cmd -f"
    fi
    
    if [ ! -z "$tail_lines" ]; then
        cmd="$cmd --tail=$tail_lines"
    fi
    
    if [ ! -z "$since_date" ]; then
        cmd="$cmd --since='$since_date'"
    fi
    
    cmd="$cmd -t $service"
    
    eval $cmd
}

# Función para exportar logs
export_logs() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local logs_dir="logs_export_$timestamp"
    
    echo -e "${PURPLE}📁 Exportando logs a directorio: $logs_dir${NC}"
    mkdir -p "$logs_dir"
    
    services=("auth-service" "calendar-service" "laboratorio-service" "solicitudes-service" "cremer-backend" "tecnomaco-backend" "servidor-rps" "phpmyadmin" "nginx")
    
    for service in "${services[@]}"; do
        echo -e "${CYAN}  📄 Exportando logs de $service...${NC}"
        docker-compose logs "$service" > "$logs_dir/${service}_logs.txt" 2>/dev/null || echo "    ⚠️  Servicio $service no encontrado"
    done
    
    echo -e "${GREEN}✅ Logs exportados exitosamente en: $logs_dir${NC}"
    echo "📊 Archivos generados:"
    ls -la "$logs_dir/"
}

# Variables por defecto
FOLLOW=false
TAIL_LINES=""
SINCE_DATE=""
EXPORT=false
SHOW_ALL=false
SERVICE=""

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            SHOW_ALL=true
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -t|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        -s|--since)
            SINCE_DATE="$2"
            shift 2
            ;;
        -e|--export)
            EXPORT=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Opción desconocida: $1"
            show_help
            exit 1
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

# Verificaciones
check_docker
check_services

# Ejecutar acción solicitada
if [ "$EXPORT" = "true" ]; then
    export_logs
elif [ "$SHOW_ALL" = "true" ]; then
    show_all_logs "$FOLLOW" "$TAIL_LINES" "$SINCE_DATE"
elif [ ! -z "$SERVICE" ]; then
    show_service_logs "$SERVICE" "$FOLLOW" "$TAIL_LINES" "$SINCE_DATE"
else
    echo -e "${YELLOW}⚠️  Debes especificar un servicio o usar -a para todos${NC}"
    echo ""
    show_help
    exit 1
fi