#!/bin/bash

# Script de despliegue para NaturePharma Services
# Este script facilita el despliegue y actualización en servidor Ubuntu

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si Docker y Docker Compose están instalados
check_dependencies() {
    print_message "Verificando dependencias..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado. Por favor instala Docker primero."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        exit 1
    fi
    
    print_success "Dependencias verificadas correctamente"
}

# Crear archivo .env si no existe
setup_env() {
    if [ ! -f .env ]; then
        print_message "Creando archivo .env desde .env.example..."
        cp .env.example .env
        print_warning "Por favor, edita el archivo .env con tus configuraciones específicas"
        print_warning "Especialmente las credenciales de email y JWT_SECRET"
    else
        print_message "Archivo .env ya existe"
    fi
}

# Crear directorios necesarios
setup_directories() {
    print_message "Creando directorios necesarios..."
    
    # Directorios para uploads
    mkdir -p laboratorio-service/uploads/defectos
    mkdir -p ServicioSolicitudesOt/uploads
    
    # Directorios para logs
    mkdir -p auth-service/logs
    
    # Directorios para SSL (si se necesita HTTPS)
    mkdir -p nginx/ssl
    
    print_success "Directorios creados correctamente"
}

# Función para construir las imágenes
build_images() {
    print_message "Construyendo imágenes Docker..."
    docker-compose build --no-cache
    print_success "Imágenes construidas correctamente"
}

# Función para iniciar los servicios
start_services() {
    print_message "Iniciando servicios..."
    docker-compose up -d
    print_success "Servicios iniciados correctamente"
}

# Función para detener los servicios
stop_services() {
    print_message "Deteniendo servicios..."
    docker-compose down
    print_success "Servicios detenidos correctamente"
}

# Función para actualizar los servicios
update_services() {
    print_message "Actualizando servicios..."
    
    # Detener servicios
    docker-compose down
    
    # Reconstruir imágenes
    docker-compose build --no-cache
    
    # Iniciar servicios
    docker-compose up -d
    
    print_success "Servicios actualizados correctamente"
}

# Función para ver logs
view_logs() {
    if [ -z "$1" ]; then
        print_message "Mostrando logs de todos los servicios..."
        docker-compose logs -f
    else
        print_message "Mostrando logs del servicio: $1"
        docker-compose logs -f "$1"
    fi
}

# Función para ver el estado de los servicios
status() {
    print_message "Estado de los servicios:"
    docker-compose ps
}

# Función para limpiar recursos Docker
cleanup() {
    print_message "Limpiando recursos Docker..."
    
    # Detener y eliminar contenedores
    docker-compose down -v
    
    # Eliminar imágenes no utilizadas
    docker image prune -f
    
    # Eliminar volúmenes no utilizados
    docker volume prune -f
    
    print_success "Limpieza completada"
}

# Función para hacer backup de la base de datos
backup_database() {
    print_message "Creando backup de la base de datos..."
    
    BACKUP_DIR="backups"
    mkdir -p $BACKUP_DIR
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/naturepharma_backup_$TIMESTAMP.sql"
    
    # Backup para MySQL local (requiere que MySQL esté instalado localmente)
    mysqldump -h localhost -u naturepharma -pRoot123! --all-databases > "$BACKUP_FILE"
    
    print_success "Backup creado: $BACKUP_FILE"
}

# Función para restaurar backup de la base de datos
restore_database() {
    if [ -z "$1" ]; then
        print_error "Por favor especifica el archivo de backup a restaurar"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        print_error "El archivo de backup no existe: $1"
        exit 1
    fi
    
    print_message "Restaurando backup: $1"
    # Restore para MySQL local (requiere que MySQL esté instalado localmente)
    mysql -h localhost -u naturepharma -pRoot123! < "$1"
    print_success "Backup restaurado correctamente"
}

# Función para mostrar ayuda
show_help() {
    echo "Script de despliegue para NaturePharma Services"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponibles:"
    echo "  setup       - Configuración inicial (crear .env, directorios)"
    echo "  build       - Construir imágenes Docker"
    echo "  start       - Iniciar todos los servicios"
    echo "  stop        - Detener todos los servicios"
    echo "  restart     - Reiniciar todos los servicios"
    echo "  update      - Actualizar servicios (rebuild + restart)"
    echo "  logs [srv]  - Ver logs (opcionalmente de un servicio específico)"
    echo "  status      - Ver estado de los servicios"
    echo "  cleanup     - Limpiar recursos Docker"
    echo "  backup      - Crear backup de la base de datos"
    echo "  restore     - Restaurar backup de la base de datos"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 setup"
    echo "  $0 start"
    echo "  $0 logs auth-service"
    echo "  $0 restore backups/naturepharma_backup_20240101_120000.sql"
}

# Función principal
main() {
    case "$1" in
        setup)
            check_dependencies
            setup_env
            setup_directories
            print_success "Configuración inicial completada"
            print_message "Ahora puedes ejecutar: $0 build && $0 start"
            ;;
        build)
            check_dependencies
            build_images
            ;;
        start)
            check_dependencies
            start_services
            print_message "Servicios disponibles en:"
            echo "  - Auth Service: http://localhost:4001"
            echo "  - Calendar Service: http://localhost:3003"
            echo "  - Laboratorio Service: http://localhost:3004"
            echo "  - Solicitudes Service: http://localhost:3001"
            echo "  - phpMyAdmin: http://localhost:8080"
            echo "  - API Gateway (Nginx): http://localhost:80"
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            start_services
            ;;
        update)
            check_dependencies
            update_services
            ;;
        logs)
            view_logs "$2"
            ;;
        status)
            status
            ;;
        cleanup)
            cleanup
            ;;
        backup)
            backup_database
            ;;
        restore)
            restore_database "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            print_error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal con todos los argumentos
main "$@"