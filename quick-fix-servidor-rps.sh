#!/bin/bash

# Script de solución rápida para servidor-rps
# Ejecutar con: sudo ./quick-fix-servidor-rps.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 SOLUCIÓN RÁPIDA SERVIDOR-RPS${NC}"
echo

# Verificar sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Ejecuta con sudo: sudo $0${NC}"
    exit 1
fi

# Ir al directorio del proyecto
cd /home/$(logname)/Desktop/Servicios

echo -e "${YELLOW}1. Deteniendo servidor-rps...${NC}"
docker-compose stop servidor-rps 2>/dev/null || true
docker rm servidor-rps 2>/dev/null || true

echo -e "${YELLOW}2. Eliminando imagen anterior...${NC}"
docker rmi servicios_servidor-rps 2>/dev/null || true
docker rmi servicios-servidor-rps 2>/dev/null || true

echo -e "${YELLOW}3. Estableciendo permisos...${NC}"
chmod -R 777 SERVIDOR_RPS/

echo -e "${YELLOW}4. Limpiando caché Docker...${NC}"
docker builder prune -f

echo -e "${YELLOW}5. Construyendo servidor-rps...${NC}"
if docker-compose build --no-cache servidor-rps; then
    echo -e "${GREEN}✅ Construcción exitosa${NC}"
    
    echo -e "${YELLOW}6. Iniciando servidor-rps...${NC}"
    if docker-compose up -d servidor-rps; then
        echo -e "${GREEN}✅ Servidor-rps iniciado correctamente${NC}"
        echo
        echo -e "${BLUE}📊 Estado del servicio:${NC}"
        docker-compose ps servidor-rps
        echo
        echo -e "${BLUE}📋 Para ver logs:${NC}"
        echo -e "   ${GREEN}sudo docker-compose logs -f servidor-rps${NC}"
        echo
        echo -e "${BLUE}🌐 URL del servicio:${NC}"
        echo -e "   ${GREEN}http://localhost:4000${NC}"
    else
        echo -e "${RED}❌ Error al iniciar servidor-rps${NC}"
        echo -e "${YELLOW}💡 Ver logs: sudo docker-compose logs servidor-rps${NC}"
    fi
else
    echo -e "${RED}❌ Error en la construcción${NC}"
    echo -e "${YELLOW}💡 Ejecuta para diagnóstico completo: sudo ./fix-servidor-rps-ubuntu.sh${NC}"
fi

echo
echo -e "${BLUE}🔧 Solución rápida completada${NC}"