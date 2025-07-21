#!/bin/bash

# Script de inicio rápido para NaturePharma en Ubuntu Server
# Ejecutar con: sudo ./quick-start-ubuntu.sh

SCRIPT_VERSION="1.0.0"

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
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    🏥 NATUREPHARMA SYSTEM                    ║"
    echo "║                     Quick Start - Ubuntu Server              ║"
    echo "║                           v$SCRIPT_VERSION                            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}Fecha: $(date)${NC}"
    echo -e "${BLUE}Usuario: $(whoami)${NC}"
    echo -e "${BLUE}Directorio: $(pwd)${NC}"
    echo ""
}

# Verificar que se ejecute con sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ ERROR: Este script debe ejecutarse con sudo${NC}"
        echo "Uso: sudo ./quick-start-ubuntu.sh"
        exit 1
    fi
}

# Función para mostrar progreso con animación
show_progress() {
    local message="$1"
    local duration=${2:-3}
    
    echo -ne "${BLUE}🔄 $message${NC}"
    
    for i in $(seq 1 $duration); do
        for char in '|' '/' '-' '\\'; do
            echo -ne "\r${BLUE}🔄 $message $char${NC}"
            sleep 0.1
        done
    done
    
    echo -ne "\r${GREEN}✅ $message ✓${NC}\n"
}

# Función para verificar dependencias
check_dependencies() {
    echo -e "${CYAN}🔍 Verificando dependencias...${NC}"
    
    # Verificar Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Docker está ejecutándose${NC}"
        else
            echo -e "   ${YELLOW}🔄 Iniciando Docker...${NC}"
            systemctl start docker
            sleep 3
            if docker info >/dev/null 2>&1; then
                echo -e "   ${GREEN}✅ Docker iniciado correctamente${NC}"
            else
                echo -e "   ${RED}❌ Error al iniciar Docker${NC}"
                return 1
            fi
        fi
    else
        echo -e "   ${RED}❌ Docker no está instalado${NC}"
        echo -e "   ${YELLOW}💡 Ejecuta: sudo ./install-docker-ubuntu.sh${NC}"
        return 1
    fi
    
    # Verificar Docker Compose
    if command -v docker-compose >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Docker Compose disponible${NC}"
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Docker Compose (plugin) disponible${NC}"
        COMPOSE_CMD="docker compose"
    else
        echo -e "   ${RED}❌ Docker Compose no está disponible${NC}"
        return 1
    fi
    
    # Verificar archivos necesarios
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "   ${RED}❌ docker-compose.yml no encontrado${NC}"
        return 1
    fi
    
    echo -e "   ${GREEN}✅ Todas las dependencias están disponibles${NC}"
    return 0
}

# Función para configurar entorno
setup_environment() {
    echo -e "${CYAN}⚙️  Configurando entorno...${NC}"
    
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
    
    # Configurar .env
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            chmod 777 .env
            echo -e "   ${GREEN}✅ Archivo .env creado desde .env.example${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Creando archivo .env básico...${NC}"
            cat > .env << 'EOF'
# Configuración NaturePharma - Ubuntu Server
NODE_ENV=production
DB_HOST=192.168.20.158
DB_PORT=3306
DB_USER=naturepharma
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!
AUTH_DB_NAME=naturepharma_auth
CALENDAR_DB_NAME=naturepharma_calendar
LABORATORIO_DB_NAME=naturepharma_laboratorio
SOLICITUDES_DB_NAME=naturepharma_solicitudes
JWT_SECRET=naturepharma_jwt_secret_key_2024
JWT_EXPIRES_IN=24h
GMAIL_USER=
GMAIL_APP_PASSWORD=
AUTH_SERVICE_URL=http://localhost:3001
CALENDAR_SERVICE_URL=http://localhost:3002
LABORATORIO_SERVICE_URL=http://localhost:3003
SOLICITUDES_SERVICE_URL=http://localhost:3004
AUTH_PORT=3001
CALENDAR_PORT=3002
LABORATORIO_PORT=3003
SOLICITUDES_PORT=3004
CREMER_PORT=3005
TECNOMACO_PORT=3006
SERVIDOR_RPS_PORT=3007
EOF
            chmod 777 .env
            echo -e "   ${GREEN}✅ Archivo .env básico creado${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ Archivo .env ya existe${NC}"
    fi
    
    echo -e "   ${GREEN}✅ Entorno configurado correctamente${NC}"
}

# Función para mostrar menú principal
show_main_menu() {
    echo -e "${CYAN}🚀 ¿Qué deseas hacer?${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} 🏭 Iniciar en modo PRODUCCIÓN (Recomendado)"
    echo -e "${GREEN}[2]${NC} 🔧 Iniciar en modo DESARROLLO"
    echo -e "${GREEN}[3]${NC} 🗄️  Solo iniciar phpMyAdmin"
    echo -e "${GREEN}[4]${NC} 📊 Monitor del sistema"
    echo -e "${GREEN}[5]${NC} 🔧 Gestión avanzada"
    echo -e "${GREEN}[6]${NC} 🛠️  Instalar dependencias"
    echo -e "${GREEN}[7]${NC} 🔍 Diagnóstico del sistema"
    echo -e "${GREEN}[8]${NC} ❓ Ayuda"
    echo -e "${GREEN}[0]${NC} 🚪 Salir"
    echo ""
    echo -ne "${YELLOW}Selecciona una opción [1-8, 0 para salir]: ${NC}"
}

# Función para iniciar en modo producción
start_production() {
    echo -e "${CYAN}🏭 Iniciando NaturePharma en modo PRODUCCIÓN...${NC}"
    echo ""
    
    # Detener servicios existentes
    echo -e "${BLUE}🔄 Deteniendo servicios existentes...${NC}"
    $COMPOSE_CMD down >/dev/null 2>&1
    
    # Verificar Dockerfiles
    echo -e "${BLUE}🔍 Verificando Dockerfiles...${NC}"
    missing_dockerfiles=0
    
    for service_dir in auth-service calendar-service laboratorio-service ServicioSolicitudesOt Cremer-Backend Tecnomaco-Backend SERVIDOR_RPS; do
        if [ -d "$service_dir" ] && [ ! -f "$service_dir/Dockerfile" ]; then
            ((missing_dockerfiles++))
        fi
    done
    
    if [ $missing_dockerfiles -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Se encontraron $missing_dockerfiles Dockerfiles faltantes${NC}"
        echo -e "   ${BLUE}🔧 Ejecutando reparación automática...${NC}"
        
        if [ -f "fix-missing-dockerfiles-ubuntu.sh" ]; then
            chmod +x fix-missing-dockerfiles-ubuntu.sh
            ./fix-missing-dockerfiles-ubuntu.sh >/dev/null 2>&1
            echo -e "   ${GREEN}✅ Dockerfiles reparados${NC}"
        fi
    else
        echo -e "   ${GREEN}✅ Todos los Dockerfiles están presentes${NC}"
    fi
    
    # Limpiar sistema
    echo -e "${BLUE}🧹 Limpiando recursos Docker...${NC}"
    docker system prune -f >/dev/null 2>&1
    
    # Iniciar servicios
    echo -e "${BLUE}🚀 Construyendo e iniciando servicios...${NC}"
    echo -e "   ${YELLOW}⏳ Este proceso puede tomar varios minutos...${NC}"
    
    if $COMPOSE_CMD up -d --build; then
        echo -e "${GREEN}✅ Servicios iniciados exitosamente${NC}"
        
        echo -e "${BLUE}⏳ Esperando que los servicios estén listos...${NC}"
        sleep 10
        
        show_service_urls
        show_success_message
    else
        echo -e "${RED}❌ Error al iniciar servicios${NC}"
        echo -e "${YELLOW}💡 Ejecuta 'sudo ./debug-build-ubuntu.sh' para diagnóstico${NC}"
        return 1
    fi
}

# Función para iniciar en modo desarrollo
start_development() {
    echo -e "${CYAN}🔧 Iniciando NaturePharma en modo DESARROLLO...${NC}"
    echo ""
    
    if [ ! -f "docker-compose.dev.yml" ]; then
        echo -e "${RED}❌ Archivo docker-compose.dev.yml no encontrado${NC}"
        return 1
    fi
    
    # Detener servicios existentes
    echo -e "${BLUE}🔄 Deteniendo servicios existentes...${NC}"
    $COMPOSE_CMD down >/dev/null 2>&1
    
    # Iniciar en modo desarrollo
    echo -e "${BLUE}🚀 Iniciando servicios en modo desarrollo...${NC}"
    
    if $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml up -d --build; then
        echo -e "${GREEN}✅ Modo desarrollo iniciado${NC}"
        
        sleep 5
        show_service_urls
        
        echo -e "${CYAN}🔧 Características del modo desarrollo:${NC}"
        echo -e "   • Hot reload habilitado"
        echo -e "   • Volúmenes de código fuente montados"
        echo -e "   • Variables de entorno de desarrollo"
        echo -e "   • Logs detallados"
    else
        echo -e "${RED}❌ Error al iniciar modo desarrollo${NC}"
        return 1
    fi
}

# Función para iniciar solo phpMyAdmin
start_phpmyadmin_only() {
    echo -e "${CYAN}🗄️  Iniciando solo phpMyAdmin...${NC}"
    echo ""
    
    if $COMPOSE_CMD up -d naturepharma-phpmyadmin; then
        echo -e "${GREEN}✅ phpMyAdmin iniciado${NC}"
        echo ""
        echo -e "${CYAN}🌐 Acceso a phpMyAdmin:${NC}"
        echo -e "   URL: ${YELLOW}http://localhost:8080${NC}"
        echo -e "   Servidor: ${YELLOW}192.168.20.158:3306${NC}"
        echo -e "   Usuario: ${YELLOW}naturepharma${NC}"
        echo -e "   Contraseña: ${YELLOW}Root123!${NC}"
    else
        echo -e "${RED}❌ Error al iniciar phpMyAdmin${NC}"
        return 1
    fi
}

# Función para mostrar URLs de servicios
show_service_urls() {
    echo ""
    echo -e "${CYAN}🌐 URLs de Acceso:${NC}"
    echo -e "   🔐 Auth Service:        ${YELLOW}http://localhost:3001${NC}"
    echo -e "   📅 Calendar Service:    ${YELLOW}http://localhost:3002${NC}"
    echo -e "   🧪 Laboratorio Service: ${YELLOW}http://localhost:3003${NC}"
    echo -e "   📋 Solicitudes Service: ${YELLOW}http://localhost:3004${NC}"
    echo -e "   🏭 Cremer Backend:      ${YELLOW}http://localhost:3005${NC}"
    echo -e "   🏭 Tecnomaco Backend:   ${YELLOW}http://localhost:3006${NC}"
    echo -e "   📡 Servidor RPS:        ${YELLOW}http://localhost:3007${NC}"
    echo -e "   🗄️  phpMyAdmin:          ${YELLOW}http://localhost:8080${NC}"
    echo -e "   📊 Log Monitor:         ${YELLOW}http://localhost:8081${NC}"
    echo -e "   🌐 Nginx Gateway:       ${YELLOW}http://localhost:80${NC}"
    echo ""
    echo -e "${CYAN}📋 APIs (a través del gateway):${NC}"
    echo -e "   🔐 Auth API:        ${YELLOW}http://localhost/api/auth${NC}"
    echo -e "   📅 Calendar API:    ${YELLOW}http://localhost/api/events${NC}"
    echo -e "   🧪 Laboratorio API: ${YELLOW}http://localhost/api/laboratorio${NC}"
    echo -e "   📋 Solicitudes API: ${YELLOW}http://localhost/api/solicitudes${NC}"
}

# Función para mostrar mensaje de éxito
show_success_message() {
    echo ""
    echo -e "${GREEN}🎉 ¡Sistema NaturePharma iniciado correctamente!${NC}"
    echo ""
    echo -e "${CYAN}🔍 Comandos útiles:${NC}"
    echo -e "   Ver estado:         ${YELLOW}sudo docker-compose ps${NC}"
    echo -e "   Ver logs:           ${YELLOW}sudo docker-compose logs -f${NC}"
    echo -e "   Detener servicios:  ${YELLOW}sudo docker-compose down${NC}"
    echo -e "   Monitor completo:   ${YELLOW}sudo ./monitor-ubuntu.sh${NC}"
    echo -e "   Gestión avanzada:   ${YELLOW}sudo ./manage-ubuntu.sh${NC}"
}

# Función para mostrar ayuda
show_help() {
    echo -e "${CYAN}❓ Ayuda - NaturePharma Quick Start${NC}"
    echo ""
    echo -e "${YELLOW}Scripts disponibles:${NC}"
    echo -e "   ${GREEN}./quick-start-ubuntu.sh${NC}     - Este script (inicio rápido)"
    echo -e "   ${GREEN}./manage-ubuntu.sh${NC}          - Gestión completa del sistema"
    echo -e "   ${GREEN}./monitor-ubuntu.sh${NC}         - Monitor en tiempo real"
    echo -e "   ${GREEN}./start-system-ubuntu.sh${NC}    - Inicio automático completo"
    echo -e "   ${GREEN}./debug-build-ubuntu.sh${NC}     - Diagnóstico y reparación"
    echo -e "   ${GREEN}./install-docker-ubuntu.sh${NC}  - Instalación de Docker"
    echo ""
    echo -e "${YELLOW}Comandos Docker útiles:${NC}"
    echo -e "   ${GREEN}sudo docker-compose ps${NC}              - Ver estado de servicios"
    echo -e "   ${GREEN}sudo docker-compose logs -f${NC}         - Ver logs en tiempo real"
    echo -e "   ${GREEN}sudo docker-compose down${NC}            - Detener todos los servicios"
    echo -e "   ${GREEN}sudo docker-compose up -d${NC}           - Iniciar todos los servicios"
    echo -e "   ${GREEN}sudo docker-compose restart [servicio]${NC} - Reiniciar un servicio"
    echo ""
    echo -e "${YELLOW}Estructura de servicios:${NC}"
    echo -e "   • ${GREEN}auth-service${NC}        - Autenticación y usuarios"
    echo -e "   • ${GREEN}calendar-service${NC}    - Gestión de calendario"
    echo -e "   • ${GREEN}laboratorio-service${NC} - Gestión de laboratorio"
    echo -e "   • ${GREEN}solicitudes-service${NC} - Gestión de solicitudes"
    echo -e "   • ${GREEN}cremer-backend${NC}      - Backend Cremer"
    echo -e "   • ${GREEN}tecnomaco-backend${NC}   - Backend Tecnomaco"
    echo -e "   • ${GREEN}servidor-rps${NC}        - Servidor RPS"
    echo -e "   • ${GREEN}nginx${NC}               - Gateway y proxy reverso"
    echo -e "   • ${GREEN}phpmyadmin${NC}          - Administración de base de datos"
    echo -e "   • ${GREEN}log-monitor${NC}         - Monitor de logs en tiempo real"
}

# Función principal
main() {
    show_banner
    check_sudo
    
    if ! check_dependencies; then
        echo ""
        echo -e "${RED}❌ Dependencias faltantes. Instala las dependencias primero.${NC}"
        echo -e "${YELLOW}💡 Ejecuta: sudo ./install-docker-ubuntu.sh${NC}"
        exit 1
    fi
    
    setup_environment
    
    while true; do
        echo ""
        show_main_menu
        read -r choice
        
        case $choice in
            1)
                start_production
                ;;
            2)
                start_development
                ;;
            3)
                start_phpmyadmin_only
                ;;
            4)
                if [ -f "monitor-ubuntu.sh" ]; then
                    chmod +x monitor-ubuntu.sh
                    ./monitor-ubuntu.sh
                else
                    echo -e "${RED}❌ Script de monitoreo no encontrado${NC}"
                fi
                ;;
            5)
                if [ -f "manage-ubuntu.sh" ]; then
                    chmod +x manage-ubuntu.sh
                    echo -e "${CYAN}🔧 Iniciando gestión avanzada...${NC}"
                    ./manage-ubuntu.sh help
                else
                    echo -e "${RED}❌ Script de gestión no encontrado${NC}"
                fi
                ;;
            6)
                if [ -f "install-docker-ubuntu.sh" ]; then
                    chmod +x install-docker-ubuntu.sh
                    ./install-docker-ubuntu.sh
                else
                    echo -e "${RED}❌ Script de instalación no encontrado${NC}"
                fi
                ;;
            7)
                if [ -f "debug-build-ubuntu.sh" ]; then
                    chmod +x debug-build-ubuntu.sh
                    ./debug-build-ubuntu.sh
                else
                    echo -e "${RED}❌ Script de diagnóstico no encontrado${NC}"
                fi
                ;;
            8)
                show_help
                ;;
            0)
                echo -e "${CYAN}👋 ¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción inválida. Por favor selecciona 1-8 o 0 para salir.${NC}"
                ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Presiona Enter para continuar...${NC}"
        read -r
        show_banner
    done
}

# Ejecutar función principal
main "$@"