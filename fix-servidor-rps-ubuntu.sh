#!/bin/bash

# Script para diagnosticar y corregir problemas con servidor-rps
# Optimizado para Ubuntu Server con sudo y chmod 777

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    🔧 DIAGNÓSTICO SERVIDOR-RPS - UBUNTU       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo

# Verificar sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Este script debe ejecutarse con sudo${NC}"
    echo -e "${YELLOW}💡 Ejecuta: sudo $0${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Ejecutándose con privilegios sudo${NC}"
echo

# Función para verificar Docker
check_docker() {
    echo -e "${BLUE}🔍 Verificando Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no está instalado${NC}"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}⚠️  Docker no está ejecutándose, iniciando...${NC}"
        systemctl start docker
        sleep 3
    fi
    
    echo -e "${GREEN}✅ Docker está funcionando${NC}"
    return 0
}

# Función para verificar archivos del SERVIDOR_RPS
check_servidor_rps_files() {
    echo -e "${BLUE}🔍 Verificando archivos de SERVIDOR_RPS...${NC}"
    
    local base_dir="/home/$(logname)/Desktop/Servicios"
    local rps_dir="$base_dir/SERVIDOR_RPS"
    
    if [ ! -d "$rps_dir" ]; then
        echo -e "${RED}❌ Directorio SERVIDOR_RPS no encontrado en $rps_dir${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Directorio SERVIDOR_RPS encontrado${NC}"
    
    # Verificar archivos esenciales
    local files=("package.json" "package-lock.json" "server.js" "Dockerfile")
    for file in "${files[@]}"; do
        if [ -f "$rps_dir/$file" ]; then
            echo -e "${GREEN}✅ $file encontrado${NC}"
        else
            echo -e "${RED}❌ $file no encontrado${NC}"
            if [ "$file" = "package.json" ]; then
                echo -e "${RED}🚨 CRÍTICO: package.json es requerido${NC}"
                return 1
            fi
        fi
    done
    
    return 0
}

# Función para verificar contenido de package.json
check_package_json_content() {
    echo -e "${BLUE}🔍 Verificando contenido de package.json...${NC}"
    
    local base_dir="/home/$(logname)/Desktop/Servicios"
    local package_file="$base_dir/SERVIDOR_RPS/package.json"
    
    if [ ! -f "$package_file" ]; then
        echo -e "${RED}❌ package.json no encontrado${NC}"
        return 1
    fi
    
    # Verificar que es JSON válido
    if ! python3 -m json.tool "$package_file" > /dev/null 2>&1; then
        echo -e "${RED}❌ package.json no es JSON válido${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ package.json es JSON válido${NC}"
    
    # Mostrar contenido
    echo -e "${YELLOW}📄 Contenido de package.json:${NC}"
    cat "$package_file"
    echo
    
    return 0
}

# Función para limpiar Docker
clean_docker() {
    echo -e "${BLUE}🧹 Limpiando recursos Docker...${NC}"
    
    # Detener contenedor si existe
    if docker ps -a --format "table {{.Names}}" | grep -q "servidor-rps"; then
        echo -e "${YELLOW}🛑 Deteniendo contenedor servidor-rps...${NC}"
        docker stop servidor-rps 2>/dev/null || true
        docker rm servidor-rps 2>/dev/null || true
    fi
    
    # Eliminar imagen si existe
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "servicios[_-]servidor-rps"; then
        echo -e "${YELLOW}🗑️  Eliminando imagen servidor-rps...${NC}"
        docker rmi $(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "servicios[_-]servidor-rps" | awk '{print $1}') 2>/dev/null || true
    fi
    
    # Limpiar caché de construcción
    echo -e "${YELLOW}🧹 Limpiando caché de Docker...${NC}"
    docker builder prune -f
    
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función para construir servidor-rps individualmente
build_servidor_rps() {
    echo -e "${BLUE}🔨 Construyendo servidor-rps individualmente...${NC}"
    
    local base_dir="/home/$(logname)/Desktop/Servicios"
    cd "$base_dir"
    
    # Establecer permisos
    echo -e "${YELLOW}🔐 Estableciendo permisos 777...${NC}"
    chmod -R 777 SERVIDOR_RPS/
    
    # Construir con logs detallados
    echo -e "${YELLOW}🔨 Iniciando construcción...${NC}"
    if docker build -t test-servidor-rps ./SERVIDOR_RPS --no-cache --progress=plain; then
        echo -e "${GREEN}✅ Construcción exitosa${NC}"
        return 0
    else
        echo -e "${RED}❌ Error en la construcción${NC}"
        return 1
    fi
}

# Función para probar el contenedor
test_container() {
    echo -e "${BLUE}🧪 Probando contenedor...${NC}"
    
    # Ejecutar contenedor de prueba
    if docker run --rm -d --name test-servidor-rps -p 4001:4000 test-servidor-rps; then
        echo -e "${GREEN}✅ Contenedor iniciado correctamente${NC}"
        
        # Esperar un momento
        sleep 5
        
        # Verificar que está ejecutándose
        if docker ps | grep -q "test-servidor-rps"; then
            echo -e "${GREEN}✅ Contenedor ejecutándose correctamente${NC}"
            docker stop test-servidor-rps
            return 0
        else
            echo -e "${RED}❌ Contenedor se detuvo inesperadamente${NC}"
            docker logs test-servidor-rps
            return 1
        fi
    else
        echo -e "${RED}❌ Error al iniciar contenedor${NC}"
        return 1
    fi
}

# Función para corregir Dockerfile
fix_dockerfile() {
    echo -e "${BLUE}🔧 Corrigiendo Dockerfile...${NC}"
    
    local base_dir="/home/$(logname)/Desktop/Servicios"
    local dockerfile="$base_dir/SERVIDOR_RPS/Dockerfile"
    
    # Crear backup
    cp "$dockerfile" "$dockerfile.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Crear Dockerfile corregido
    cat > "$dockerfile" << 'EOF'
# Usar Node.js 18 como imagen base
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Verificar que los archivos se copiaron correctamente
RUN ls -la /app/

# Instalar dependencias
RUN if [ -f package-lock.json ]; then \
        npm ci --only=production && npm cache clean --force; \
    else \
        npm install --only=production && npm cache clean --force; \
    fi

# Copiar el código fuente
COPY . .

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Cambiar propiedad de archivos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE 4000

# Comando para iniciar la aplicación
CMD ["node", "server.js"]
EOF

    echo -e "${GREEN}✅ Dockerfile corregido${NC}"
}

# Función principal
main() {
    echo -e "${BLUE}🚀 Iniciando diagnóstico de servidor-rps...${NC}"
    echo
    
    # Verificaciones
    check_docker || exit 1
    echo
    
    check_servidor_rps_files || exit 1
    echo
    
    check_package_json_content || exit 1
    echo
    
    # Limpiar Docker
    clean_docker
    echo
    
    # Corregir Dockerfile
    fix_dockerfile
    echo
    
    # Construir
    if build_servidor_rps; then
        echo
        test_container
        echo
        
        echo -e "${GREEN}🎉 ¡Diagnóstico y corrección completados!${NC}"
        echo -e "${YELLOW}💡 Ahora puedes ejecutar:${NC}"
        echo -e "   sudo docker-compose up -d servidor-rps"
        echo -e "   sudo docker-compose logs -f servidor-rps"
    else
        echo
        echo -e "${RED}❌ La construcción falló${NC}"
        echo -e "${YELLOW}💡 Revisa los logs arriba para más detalles${NC}"
        exit 1
    fi
}

# Ejecutar función principal
main

echo
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}           DIAGNÓSTICO COMPLETADO              ${NC}"
echo -e "${BLUE}================================================${NC}"