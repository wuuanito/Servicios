#!/bin/bash

# Script para corregir específicamente el Dockerfile de servidor-rps
# Ejecutar con: sudo ./fix-dockerfile-servidor-rps.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRECCIÓN DOCKERFILE SERVIDOR-RPS${NC}"
echo

# Verificar sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Ejecuta con sudo: sudo $0${NC}"
    exit 1
fi

# Ir al directorio del script
cd "$(dirname "$0")"

echo -e "${YELLOW}📁 Directorio actual: $(pwd)${NC}"
echo

# Verificar que existe el directorio SERVIDOR_RPS
if [ ! -d "SERVIDOR_RPS" ]; then
    echo -e "${RED}❌ Directorio SERVIDOR_RPS no encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Directorio SERVIDOR_RPS encontrado${NC}"

# Crear backup del Dockerfile actual
if [ -f "SERVIDOR_RPS/Dockerfile" ]; then
    echo -e "${YELLOW}💾 Creando backup del Dockerfile...${NC}"
    cp "SERVIDOR_RPS/Dockerfile" "SERVIDOR_RPS/Dockerfile.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Crear nuevo Dockerfile optimizado
echo -e "${YELLOW}🔧 Creando Dockerfile corregido...${NC}"
cat > "SERVIDOR_RPS/Dockerfile" << 'EOF'
# Usar Node.js 18 como imagen base
FROM node:18-alpine

# Crear usuario no-root primero
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Establecer directorio de trabajo
WORKDIR /app

# Cambiar a usuario root temporalmente para copiar archivos
USER root

# Copiar package.json y package-lock.json
COPY package*.json ./

# Verificar que los archivos se copiaron correctamente
RUN ls -la /app/ && echo "Archivos copiados correctamente"

# Instalar dependencias
RUN if [ -f package-lock.json ]; then \
        echo "Usando npm ci" && npm ci --only=production; \
    else \
        echo "Usando npm install" && npm install --only=production; \
    fi && \
    npm cache clean --force

# Copiar el código fuente
COPY . .

# Cambiar propiedad de archivos al usuario nodejs
RUN chown -R nodejs:nodejs /app

# Cambiar a usuario no-root
USER nodejs

# Exponer puerto
EXPOSE 4000

# Comando para iniciar la aplicación
CMD ["node", "server.js"]
EOF

echo -e "${GREEN}✅ Dockerfile corregido${NC}"

# Establecer permisos
echo -e "${YELLOW}🔐 Estableciendo permisos...${NC}"
chmod -R 777 SERVIDOR_RPS/

# Limpiar Docker
echo -e "${YELLOW}🧹 Limpiando recursos Docker...${NC}"
docker-compose stop servidor-rps 2>/dev/null || true
docker rm servidor-rps 2>/dev/null || true
docker rmi servicios_servidor-rps servicios-servidor-rps 2>/dev/null || true
docker builder prune -f

# Construir imagen
echo -e "${YELLOW}🔨 Construyendo imagen...${NC}"
if docker-compose build --no-cache servidor-rps; then
    echo -e "${GREEN}✅ Construcción exitosa${NC}"
    
    # Iniciar servicio
    echo -e "${YELLOW}🚀 Iniciando servidor-rps...${NC}"
    if docker-compose up -d servidor-rps; then
        echo -e "${GREEN}✅ Servidor-rps iniciado correctamente${NC}"
        echo
        echo -e "${BLUE}📊 Estado del servicio:${NC}"
        docker-compose ps servidor-rps
        echo
        echo -e "${BLUE}🌐 Servicio disponible en: http://localhost:4000${NC}"
        echo -e "${BLUE}📋 Ver logs: sudo docker-compose logs -f servidor-rps${NC}"
    else
        echo -e "${RED}❌ Error al iniciar servidor-rps${NC}"
        echo -e "${YELLOW}💡 Ver logs: sudo docker-compose logs servidor-rps${NC}"
    fi
else
    echo -e "${RED}❌ Error en la construcción${NC}"
    echo -e "${YELLOW}💡 Revisa los logs arriba para más detalles${NC}"
fi

echo
echo -e "${BLUE}🔧 Corrección completada${NC}"