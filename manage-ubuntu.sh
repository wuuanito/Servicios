#!/bin/bash

# Script de gestión completa del sistema NaturePharma para Ubuntu Server
# Ejecutar con: sudo ./manage-ubuntu.sh [comando]

SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="NaturePharma Management Script"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    🏥 NATUREPHARMA SYSTEM                    "
    echo "                   Management Script v$SCRIPT_VERSION                  "
    echo "                      Ubuntu Server Edition                   "
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
    echo "Directorio: $(pwd)"
    echo ""
}

# Función para mostrar ayuda
show_help() {
    echo -e "${YELLOW}Uso: sudo ./manage-ubuntu.sh [comando]${NC}"
    echo ""
    echo -e "${CYAN}Comandos disponibles:${NC}"
    echo ""
    echo -e "${GREEN}🚀 INICIO Y CONTROL:${NC}"
    echo "   start           - Iniciar todos los servicios"
    echo "   stop            - Detener todos los servicios"
    echo "   restart         - Reiniciar todos los servicios"
    echo "   status          - Ver estado de todos los servicios"
    echo "   monitor         - Monitor en tiempo real"
    echo ""
    echo -e "${GREEN}🔧 CONSTRUCCIÓN Y DESARROLLO:${NC}"
    echo "   build           - Construir todas las imágenes"
    echo "   rebuild         - Reconstruir completamente"
    echo "   dev             - Modo desarrollo"
    echo "   prod            - Modo producción"
    echo ""
    echo -e "${GREEN}📊 LOGS Y DIAGNÓSTICO:${NC}"
    echo "   logs            - Ver logs de todos los servicios"
    echo "   logs [servicio] - Ver logs de un servicio específico"
    echo "   debug           - Diagnóstico completo del sistema"
    echo "   health          - Verificar salud de servicios"
    echo ""
    echo -e "${GREEN}🧹 MANTENIMIENTO:${NC}"
    echo "   clean           - Limpiar recursos Docker"
    echo "   reset           - Resetear completamente el sistema"
    echo "   update          - Actualizar y reconstruir"
    echo "   backup          - Crear respaldo de configuración"
    echo ""
    echo -e "${GREEN}⚙️  CONFIGURACIÓN:${NC}"
    echo "   setup           - Configuración inicial"
    echo "   env             - Configurar variables de entorno"
    echo "   permissions     - Configurar permisos"
    echo "   install         - Instalar dependencias"
    echo ""
    echo -e "${GREEN}ℹ️  INFORMACIÓN:${NC}"
    echo "   info            - Información del sistema"
    echo "   urls            - Mostrar URLs de servicios"
    echo "   version         - Versión del script"
    echo "   help            - Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "   sudo ./manage-ubuntu.sh start"
    echo "   sudo ./manage-ubuntu.sh logs auth-service"
    echo "   sudo ./manage-ubuntu.sh monitor"
    echo ""
}

# Verificar que se ejecute con sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ ERROR: Este script debe ejecutarse con sudo${NC}"
        echo "Uso: sudo ./manage-ubuntu.sh [comando]"
        exit 1
    fi
}

# Verificar Docker
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker no está instalado${NC}"
        echo "Ejecuta: sudo ./install-docker-ubuntu.sh"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}🔄 Iniciando Docker...${NC}"
        systemctl start docker
        sleep 3
        if ! docker info >/dev/null 2>&1; then
            echo -e "${RED}❌ No se pudo iniciar Docker${NC}"
            exit 1
        fi
    fi
}

# Verificar Docker Compose
check_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        echo -e "${RED}❌ Docker Compose no está disponible${NC}"
        exit 1
    fi
}

# Función para mostrar progreso
show_progress() {
    echo -e "${BLUE}🔄 $1...${NC}"
}

# Función para mostrar éxito
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar error
show_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

# Función para mostrar advertencia
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función para mostrar información
show_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Inicializar sistema
setup_system() {
    show_progress "Configurando sistema inicial"
    
    # Crear directorios necesarios
    mkdir -p uploads logs ssl backups
    chmod 777 uploads logs ssl backups
    
    # Configurar permisos para scripts
    for script in *.sh; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            chmod 777 "$script"
        fi
    done
    
    # Crear .env si no existe
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            chmod 777 .env
            show_success "Archivo .env creado desde .env.example"
        else
            show_warning "Archivo .env.example no encontrado"
        fi
    fi
    
    show_success "Sistema configurado"
}

# Iniciar servicios
start_services() {
    show_progress "Iniciando servicios NaturePharma"
    
    if $COMPOSE_CMD up -d; then
        show_success "Servicios iniciados"
        sleep 5
        show_urls
    else
        show_error "Error al iniciar servicios"
        exit 1
    fi
}

# Detener servicios
stop_services() {
    show_progress "Deteniendo servicios"
    
    if $COMPOSE_CMD down; then
        show_success "Servicios detenidos"
    else
        show_error "Error al detener servicios"
    fi
}

# Reiniciar servicios
restart_services() {
    show_progress "Reiniciando servicios"
    
    $COMPOSE_CMD down
    sleep 2
    if $COMPOSE_CMD up -d; then
        show_success "Servicios reiniciados"
        sleep 5
        show_urls
    else
        show_error "Error al reiniciar servicios"
    fi
}

# Ver estado
show_status() {
    echo -e "${CYAN}📊 Estado de los servicios:${NC}"
    $COMPOSE_CMD ps
    
    echo ""
    echo -e "${CYAN}🐳 Estadísticas Docker:${NC}"
    echo "   Contenedores ejecutándose: $(docker ps -q | wc -l)"
    echo "   Contenedores totales: $(docker ps -a -q | wc -l)"
    echo "   Imágenes: $(docker images -q | wc -l)"
}

# Construir imágenes
build_images() {
    show_progress "Construyendo imágenes Docker"
    
    if $COMPOSE_CMD build; then
        show_success "Imágenes construidas"
    else
        show_error "Error al construir imágenes"
    fi
}

# Reconstruir completamente
rebuild_system() {
    show_progress "Reconstruyendo sistema completo"
    
    $COMPOSE_CMD down
    docker system prune -f
    
    if $COMPOSE_CMD up -d --build; then
        show_success "Sistema reconstruido"
        sleep 5
        show_urls
    else
        show_error "Error al reconstruir sistema"
    fi
}

# Modo desarrollo
dev_mode() {
    if [ -f "docker-compose.dev.yml" ]; then
        show_progress "Iniciando en modo desarrollo"
        
        if $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml up -d --build; then
            show_success "Modo desarrollo iniciado"
            show_urls
        else
            show_error "Error al iniciar modo desarrollo"
        fi
    else
        show_error "Archivo docker-compose.dev.yml no encontrado"
    fi
}

# Modo producción
prod_mode() {
    show_progress "Iniciando en modo producción"
    
    if $COMPOSE_CMD up -d --build; then
        show_success "Modo producción iniciado"
        show_urls
    else
        show_error "Error al iniciar modo producción"
    fi
}

# Ver logs
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${CYAN}📄 Logs de todos los servicios:${NC}"
        $COMPOSE_CMD logs -f
    else
        echo -e "${CYAN}📄 Logs de $service:${NC}"
        $COMPOSE_CMD logs -f "$service"
    fi
}

# Diagnóstico
run_debug() {
    if [ -f "debug-build-ubuntu.sh" ]; then
        chmod +x debug-build-ubuntu.sh
        ./debug-build-ubuntu.sh
    else
        show_error "Script de diagnóstico no encontrado"
    fi
}

# Verificar salud
check_health() {
    echo -e "${CYAN}🏥 Verificación de salud:${NC}"
    
    # Verificar puertos
    declare -A ports=(["3001"]="Auth" ["3002"]="Calendar" ["3003"]="Laboratorio" ["3004"]="Solicitudes" ["3005"]="Cremer" ["3006"]="Tecnomaco" ["3007"]="RPS" ["8080"]="phpMyAdmin" ["8081"]="Monitor" ["80"]="Nginx")
    
    for port in "${!ports[@]}"; do
        service=${ports[$port]}
        if timeout 3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
            echo -e "   ${GREEN}✅ $service (Puerto $port)${NC}"
        else
            echo -e "   ${RED}❌ $service (Puerto $port)${NC}"
        fi
    done
}

# Limpiar sistema
clean_system() {
    show_progress "Limpiando sistema Docker"
    
    docker system prune -f
    docker volume prune -f
    docker network prune -f
    
    show_success "Sistema limpiado"
}

# Resetear sistema
reset_system() {
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Esto eliminará todos los contenedores, imágenes y volúmenes${NC}"
    read -p "¿Estás seguro? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        show_progress "Reseteando sistema completo"
        
        $COMPOSE_CMD down -v
        docker system prune -a -f
        docker volume prune -f
        
        show_success "Sistema reseteado"
    else
        show_info "Operación cancelada"
    fi
}

# Actualizar sistema
update_system() {
    show_progress "Actualizando sistema"
    
    git pull 2>/dev/null || show_warning "No es un repositorio Git"
    
    $COMPOSE_CMD down
    $COMPOSE_CMD pull
    $COMPOSE_CMD up -d --build
    
    show_success "Sistema actualizado"
}

# Crear backup
create_backup() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    show_progress "Creando backup en $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Backup de configuración
    cp .env "$backup_dir/" 2>/dev/null || true
    cp docker-compose.yml "$backup_dir/" 2>/dev/null || true
    cp docker-compose.dev.yml "$backup_dir/" 2>/dev/null || true
    cp nginx.conf "$backup_dir/" 2>/dev/null || true
    
    # Backup de logs
    cp -r logs "$backup_dir/" 2>/dev/null || true
    
    show_success "Backup creado en $backup_dir"
}

# Configurar variables de entorno
setup_env() {
    if [ -f ".env.example" ]; then
        show_progress "Configurando variables de entorno"
        
        if [ ! -f ".env" ]; then
            cp .env.example .env
            chmod 777 .env
        fi
        
        echo -e "${CYAN}Archivo .env actual:${NC}"
        cat .env
        
        echo ""
        read -p "¿Deseas editar el archivo .env? (y/N): " edit_env
        
        if [ "$edit_env" = "y" ] || [ "$edit_env" = "Y" ]; then
            nano .env 2>/dev/null || vi .env 2>/dev/null || echo "Editor no disponible"
        fi
        
        show_success "Variables de entorno configuradas"
    else
        show_error "Archivo .env.example no encontrado"
    fi
}

# Configurar permisos
setup_permissions() {
    show_progress "Configurando permisos"
    
    # Permisos para directorios
    chmod 777 uploads logs ssl backups 2>/dev/null || true
    
    # Permisos para scripts
    chmod +x *.sh 2>/dev/null || true
    chmod 777 *.sh 2>/dev/null || true
    
    # Permisos para archivos de configuración
    chmod 777 .env 2>/dev/null || true
    chmod 644 docker-compose*.yml 2>/dev/null || true
    
    show_success "Permisos configurados"
}

# Instalar dependencias
install_dependencies() {
    if [ -f "install-docker-ubuntu.sh" ]; then
        chmod +x install-docker-ubuntu.sh
        ./install-docker-ubuntu.sh
    else
        show_error "Script de instalación no encontrado"
    fi
}

# Mostrar información del sistema
show_info_system() {
    echo -e "${CYAN}📋 Información del Sistema:${NC}"
    echo "   OS: $(lsb_release -d | cut -f2 2>/dev/null || echo 'Ubuntu')"
    echo "   Kernel: $(uname -r)"
    echo "   Arquitectura: $(uname -m)"
    echo "   Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "   Docker: $(docker --version 2>/dev/null || echo 'No instalado')"
    echo "   Docker Compose: $(docker-compose --version 2>/dev/null || echo 'No instalado')"
    echo ""
    echo -e "${CYAN}💾 Recursos:${NC}"
    echo "   Memoria: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "   Disco: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5" usado)"}')"
    echo "   CPU: $(nproc) cores"
}

# Mostrar URLs
show_urls() {
    echo ""
    echo -e "${CYAN}🌐 URLs de Acceso:${NC}"
    echo "   🔐 Auth Service:        http://localhost:3001"
    echo "   📅 Calendar Service:    http://localhost:3002"
    echo "   🧪 Laboratorio Service: http://localhost:3003"
    echo "   📋 Solicitudes Service: http://localhost:3004"
    echo "   🏭 Cremer Backend:      http://localhost:3005"
    echo "   🏭 Tecnomaco Backend:   http://localhost:3006"
    echo "   📡 Servidor RPS:        http://localhost:3007"
    echo "   🗄️  phpMyAdmin:          http://localhost:8080"
    echo "   📊 Log Monitor:         http://localhost:8081"
    echo "   🌐 Nginx Gateway:       http://localhost:80"
    echo ""
    echo -e "${CYAN}📋 APIs (a través del gateway):${NC}"
    echo "   🔐 Auth API:        http://localhost/api/auth"
    echo "   📅 Calendar API:    http://localhost/api/events"
    echo "   🧪 Laboratorio API: http://localhost/api/laboratorio"
    echo "   📋 Solicitudes API: http://localhost/api/solicitudes"
}

# Monitor en tiempo real
run_monitor() {
    if [ -f "monitor-ubuntu.sh" ]; then
        chmod +x monitor-ubuntu.sh
        ./monitor-ubuntu.sh
    else
        show_error "Script de monitoreo no encontrado"
    fi
}

# Función principal
main() {
    local command=$1
    
    # Verificaciones iniciales
    check_sudo
    check_docker
    check_compose
    
    case $command in
        "start")
            show_banner
            setup_system
            start_services
            ;;
        "stop")
            show_banner
            stop_services
            ;;
        "restart")
            show_banner
            restart_services
            ;;
        "status")
            show_banner
            show_status
            ;;
        "monitor")
            run_monitor
            ;;
        "build")
            show_banner
            build_images
            ;;
        "rebuild")
            show_banner
            rebuild_system
            ;;
        "dev")
            show_banner
            setup_system
            dev_mode
            ;;
        "prod")
            show_banner
            setup_system
            prod_mode
            ;;
        "logs")
            show_logs $2
            ;;
        "debug")
            show_banner
            run_debug
            ;;
        "health")
            show_banner
            check_health
            ;;
        "clean")
            show_banner
            clean_system
            ;;
        "reset")
            show_banner
            reset_system
            ;;
        "update")
            show_banner
            update_system
            ;;
        "backup")
            show_banner
            create_backup
            ;;
        "setup")
            show_banner
            setup_system
            ;;
        "env")
            show_banner
            setup_env
            ;;
        "permissions")
            show_banner
            setup_permissions
            ;;
        "install")
            show_banner
            install_dependencies
            ;;
        "info")
            show_banner
            show_info_system
            ;;
        "urls")
            show_banner
            show_urls
            ;;
        "version")
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            ;;
        "help"|"")
            show_banner
            show_help
            ;;
        *)
            show_banner
            show_error "Comando desconocido: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"