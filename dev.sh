#!/bin/bash

# Script de desarrollo para NaturePharma Services
# Facilita el desarrollo local con hot-reload

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_message() {
    echo -e "${BLUE}[DEV]${NC} $1"
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

# Función para instalar dependencias en todos los servicios
install_deps() {
    print_message "Instalando dependencias en todos los servicios..."
    
    services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt")
    
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            print_message "Instalando dependencias en $service..."
            cd "$service"
            npm install
            cd ..
            print_success "Dependencias instaladas en $service"
        else
            print_warning "Directorio $service no encontrado"
        fi
    done
}

# Función para iniciar en modo desarrollo
start_dev() {
    print_message "Iniciando servicios en modo desarrollo..."
    
    # Crear archivo .env si no existe
    if [ ! -f .env ]; then
        print_message "Creando archivo .env desde .env.example..."
        cp .env.example .env
        print_warning "Recuerda configurar las variables de entorno en .env"
    fi
    
    # Iniciar con configuración de desarrollo
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
}

# Función para iniciar solo la base de datos
start_db_only() {
    print_message "Iniciando solo la base de datos..."
    docker-compose up -d mysql phpmyadmin
    print_success "Base de datos iniciada. phpMyAdmin disponible en http://localhost:8080"
}

# Función para ejecutar tests
run_tests() {
    print_message "Ejecutando tests en todos los servicios..."
    
    services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt")
    
    for service in "${services[@]}"; do
        if [ -d "$service" ] && [ -f "$service/package.json" ]; then
            print_message "Ejecutando tests en $service..."
            cd "$service"
            if npm run test 2>/dev/null; then
                print_success "Tests pasaron en $service"
            else
                print_warning "No hay tests configurados en $service o fallaron"
            fi
            cd ..
        fi
    done
}

# Función para limpiar todo
clean_all() {
    print_message "Limpiando todo el entorno de desarrollo..."
    
    # Detener contenedores
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v
    
    # Limpiar imágenes
    docker image prune -f
    
    # Limpiar node_modules
    services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt")
    
    for service in "${services[@]}"; do
        if [ -d "$service/node_modules" ]; then
            print_message "Limpiando node_modules en $service..."
            rm -rf "$service/node_modules"
        fi
    done
    
    print_success "Limpieza completada"
}

# Función para ver logs de desarrollo
dev_logs() {
    if [ -z "$1" ]; then
        print_message "Mostrando logs de todos los servicios en desarrollo..."
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
    else
        print_message "Mostrando logs del servicio: $1"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f "$1"
    fi
}

# Función para reiniciar un servicio específico
restart_service() {
    if [ -z "$1" ]; then
        print_error "Por favor especifica el nombre del servicio"
        exit 1
    fi
    
    print_message "Reiniciando servicio: $1"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml restart "$1"
    print_success "Servicio $1 reiniciado"
}

# Función para acceder a un contenedor
exec_service() {
    if [ -z "$1" ]; then
        print_error "Por favor especifica el nombre del servicio"
        exit 1
    fi
    
    print_message "Accediendo al contenedor: $1"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec "$1" bash
}

# Función para mostrar ayuda
show_help() {
    echo "Script de desarrollo para NaturePharma Services"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponibles:"
    echo "  install     - Instalar dependencias en todos los servicios"
    echo "  start       - Iniciar servicios en modo desarrollo"
    echo "  db-only     - Iniciar solo la base de datos"
    echo "  stop        - Detener servicios de desarrollo"
    echo "  restart     - Reiniciar todos los servicios"
    echo "  restart-svc - Reiniciar un servicio específico"
    echo "  logs [srv]  - Ver logs (opcionalmente de un servicio específico)"
    echo "  exec [srv]  - Acceder a un contenedor específico"
    echo "  test        - Ejecutar tests en todos los servicios"
    echo "  clean       - Limpiar todo el entorno"
    echo "  help        - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start"
    echo "  $0 logs auth-service"
    echo "  $0 restart-svc calendar-service"
    echo "  $0 exec mysql"
}

# Función principal
main() {
    case "$1" in
        install)
            install_deps
            ;;
        start)
            start_dev
            ;;
        db-only)
            start_db_only
            ;;
        stop)
            print_message "Deteniendo servicios de desarrollo..."
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
            print_success "Servicios detenidos"
            ;;
        restart)
            print_message "Reiniciando servicios de desarrollo..."
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml restart
            print_success "Servicios reiniciados"
            ;;
        restart-svc)
            restart_service "$2"
            ;;
        logs)
            dev_logs "$2"
            ;;
        exec)
            exec_service "$2"
            ;;
        test)
            run_tests
            ;;
        clean)
            clean_all
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