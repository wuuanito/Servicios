#!/bin/bash

# Script de reparación para Dockerfiles faltantes en Ubuntu Server
# Ejecutar con: sudo ./fix-missing-dockerfiles-ubuntu.sh

echo "=== NaturePharma - Reparación de Dockerfiles Faltantes para Ubuntu ==="
echo "Fecha: $(date)"
echo ""

# Verificar que se ejecute con sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: Este script debe ejecutarse con sudo"
    echo "Uso: sudo ./fix-missing-dockerfiles-ubuntu.sh"
    exit 1
fi

echo "✅ Ejecutándose con privilegios de administrador"
echo ""

# Función para crear Dockerfile estándar
create_standard_dockerfile() {
    local service_dir="$1"
    local service_name="$2"
    local port="$3"
    local dockerfile_path="$service_dir/Dockerfile"
    
    echo "📝 Creando Dockerfile para $service_name..."
    
    cat > "$dockerfile_path" << 'EOF'
# Dockerfile estándar para NaturePharma Services
FROM node:18-alpine

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 -G nodejs

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias con fallback
RUN if [ -f package-lock.json ]; then \
        npm ci --omit=dev && npm cache clean --force; \
    else \
        npm install --omit=dev && npm cache clean --force; \
    fi

# Copiar código fuente
COPY . .

# Crear directorios necesarios
RUN mkdir -p uploads logs temp && \
    chown -R appuser:nodejs /app

# Cambiar a usuario no-root
USER appuser

# Exponer puerto
EXPOSE PORT_PLACEHOLDER

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=PORT_PLACEHOLDER

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:PORT_PLACEHOLDER/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Comando de inicio
CMD ["npm", "start"]
EOF

    # Reemplazar placeholder del puerto
    sed -i "s/PORT_PLACEHOLDER/$port/g" "$dockerfile_path"
    
    # Dar permisos completos como solicita el usuario
    chmod 777 "$dockerfile_path"
    
    echo "✅ Dockerfile creado: $dockerfile_path"
}

# Función para verificar y crear Dockerfile si no existe
check_and_create_dockerfile() {
    local service_dir="$1"
    local service_name="$2"
    local port="$3"
    
    if [ ! -d "$service_dir" ]; then
        echo "⚠️  Directorio $service_dir no encontrado, omitiendo..."
        return
    fi
    
    if [ ! -f "$service_dir/Dockerfile" ]; then
        echo "❌ Dockerfile faltante en $service_dir"
        create_standard_dockerfile "$service_dir" "$service_name" "$port"
    else
        echo "✅ Dockerfile ya existe en $service_dir"
        # Dar permisos como solicita el usuario
        chmod 777 "$service_dir/Dockerfile"
    fi
}

echo "🔍 Verificando Dockerfiles en todos los servicios..."
echo ""

# Verificar servicios principales
check_and_create_dockerfile "auth-service" "auth-service" "3001"
check_and_create_dockerfile "calendar-service" "calendar-service" "3002"
check_and_create_dockerfile "laboratorio-service" "laboratorio-service" "3003"
check_and_create_dockerfile "ServicioSolicitudesOt" "solicitudes-service" "3004"

# Verificar servicios backend
check_and_create_dockerfile "Cremer-Backend" "cremer-backend" "3005"
check_and_create_dockerfile "Tecnomaco-Backend" "tecnomaco-backend" "3006"
check_and_create_dockerfile "SERVIDOR_RPS" "servidor-rps" "3007"

echo ""
echo "🔧 Aplicando permisos chmod 777 a archivos críticos..."

# Dar permisos a archivos de configuración
chmod 777 docker-compose.yml 2>/dev/null || echo "⚠️  docker-compose.yml no encontrado"
chmod 777 docker-compose.dev.yml 2>/dev/null || echo "⚠️  docker-compose.dev.yml no encontrado"
chmod 777 .env.example 2>/dev/null || echo "⚠️  .env.example no encontrado"

# Dar permisos a scripts
find . -name "*.sh" -type f -exec chmod 777 {} \; 2>/dev/null

# Dar permisos a package.json de todos los servicios
find . -name "package.json" -type f -exec chmod 777 {} \; 2>/dev/null

echo "✅ Permisos aplicados"
echo ""

echo "🧪 Probando construcción de servicios..."
echo ""

# Función para probar construcción individual
test_service_build() {
    local service_dir="$1"
    local service_name="$2"
    
    if [ ! -d "$service_dir" ]; then
        return
    fi
    
    echo "🔨 Probando construcción de $service_name..."
    
    # Cambiar al directorio del servicio
    cd "$service_dir" || return
    
    # Intentar construir la imagen
    if docker build -t "naturepharma-$service_name:test" . >/dev/null 2>&1; then
        echo "✅ $service_name: Construcción exitosa"
        # Limpiar imagen de prueba
        docker rmi "naturepharma-$service_name:test" >/dev/null 2>&1
    else
        echo "❌ $service_name: Error en construcción"
        echo "   Ejecuta: cd $service_dir && docker build -t test . para ver detalles"
    fi
    
    # Volver al directorio principal
    cd - >/dev/null
}

# Probar construcción de cada servicio
test_service_build "auth-service" "auth-service"
test_service_build "calendar-service" "calendar-service"
test_service_build "laboratorio-service" "laboratorio-service"
test_service_build "ServicioSolicitudesOt" "solicitudes-service"
test_service_build "Cremer-Backend" "cremer-backend"
test_service_build "Tecnomaco-Backend" "tecnomaco-backend"
test_service_build "SERVIDOR_RPS" "servidor-rps"

echo ""
echo "🎯 Creando archivo .env si no existe..."

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        chmod 777 .env
        echo "✅ Archivo .env creado desde .env.example"
    else
        echo "⚠️  .env.example no encontrado, creando .env básico..."
        cat > .env << 'EOF'
# Configuración básica para NaturePharma Services
NODE_ENV=production

# Base de datos MySQL
DB_HOST=192.168.20.158
DB_PORT=3306
DB_USER=naturepharma
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!

# Bases de datos específicas
AUTH_DB_NAME=naturepharma_auth
CALENDAR_DB_NAME=naturepharma_calendar
LABORATORIO_DB_NAME=naturepharma_laboratorio
SOLICITUDES_DB_NAME=naturepharma_solicitudes

# JWT
JWT_SECRET=naturepharma_jwt_secret_key_2024
JWT_EXPIRES_IN=24h

# Email (Gmail)
GMAIL_USER=
GMAIL_APP_PASSWORD=

# URLs de servicios
AUTH_SERVICE_URL=http://localhost:3001
CALENDAR_SERVICE_URL=http://localhost:3002
LABORATORIO_SERVICE_URL=http://localhost:3003
SOLICITUDES_SERVICE_URL=http://localhost:3004

# Puertos
AUTH_PORT=3001
CALENDAR_PORT=3002
LABORATORIO_PORT=3003
SOLICITUDES_PORT=3004
CREMER_PORT=3005
TECNOMACO_PORT=3006
SERVIDOR_RPS_PORT=3007
EOF
        chmod 777 .env
        echo "✅ Archivo .env básico creado"
    fi
else
    echo "✅ Archivo .env ya existe"
    chmod 777 .env
fi

echo ""
echo "📁 Creando directorios necesarios..."

# Crear directorios con permisos completos
mkdir -p uploads logs ssl backups
chmod 777 uploads logs ssl backups

# Crear directorios específicos para cada servicio
for service in auth-service calendar-service laboratorio-service ServicioSolicitudesOt Cremer-Backend Tecnomaco-Backend SERVIDOR_RPS; do
    if [ -d "$service" ]; then
        mkdir -p "$service/uploads" "$service/logs" "$service/temp"
        chmod 777 "$service/uploads" "$service/logs" "$service/temp" 2>/dev/null
    fi
done

echo "✅ Directorios creados"
echo ""

echo "🧹 Limpiando recursos Docker anteriores..."

# Detener contenedores existentes
docker-compose down >/dev/null 2>&1

# Limpiar imágenes huérfanas
docker image prune -f >/dev/null 2>&1

echo "✅ Limpieza completada"
echo ""

echo "=== RESUMEN DE REPARACIÓN ==="
echo "✅ Dockerfiles verificados y creados donde faltaban"
echo "✅ Permisos chmod 777 aplicados a archivos críticos"
echo "✅ Archivo .env configurado"
echo "✅ Directorios necesarios creados"
echo "✅ Recursos Docker limpiados"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Ejecuta: sudo docker-compose up -d --build"
echo ""
echo "📊 MONITOREO:"
echo "   Ejecuta: sudo docker-compose logs -f"
echo ""
echo "🔍 VERIFICAR SERVICIOS:"
echo "   Ejecuta: sudo docker-compose ps"
echo ""
echo "=== Reparación completada exitosamente ==="