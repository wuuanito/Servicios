#!/bin/bash

# Script para sincronizar Dockerfiles faltantes
# NaturePharma System - Sync Missing Dockerfiles

echo "=== Sincronizando Dockerfiles Faltantes ==="
echo "Fecha: $(date)"
echo ""

# Función para mostrar información
show_info() {
    echo "ℹ️  $1"
}

# Función para mostrar éxito
show_success() {
    echo "✅ $1"
}

# Función para crear Dockerfile
create_dockerfile() {
    local service_dir="$1"
    local port="$2"
    local start_command="$3"
    
    show_info "Creando $service_dir/Dockerfile..."
    
    mkdir -p "$service_dir"
    
    cat > "$service_dir/Dockerfile" << EOF
# Usar Node.js 18 como imagen base
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar el código fuente
COPY . .

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Cambiar propiedad de archivos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE $port

# Comando para iniciar la aplicación
CMD ["$start_command"]
EOF

    show_success "$service_dir/Dockerfile creado"
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

# Crear Dockerfiles faltantes
echo "\n🔧 Creando Dockerfiles faltantes..."

# Cremer-Backend
if [ ! -f "Cremer-Backend/Dockerfile" ]; then
    create_dockerfile "Cremer-Backend" "3002" "npm start"
else
    show_success "Cremer-Backend/Dockerfile ya existe"
fi

# Tecnomaco-Backend
if [ ! -f "Tecnomaco-Backend/Dockerfile" ]; then
    create_dockerfile "Tecnomaco-Backend" "3006" "npm start"
else
    show_success "Tecnomaco-Backend/Dockerfile ya existe"
fi

# SERVIDOR_RPS
if [ ! -f "SERVIDOR_RPS/Dockerfile" ]; then
    create_dockerfile "SERVIDOR_RPS" "4000" "node server.js"
else
    show_success "SERVIDOR_RPS/Dockerfile ya existe"
fi

echo "\n🔍 Verificando Dockerfiles creados..."
for service in "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS"; do
    if [ -f "$service/Dockerfile" ]; then
        show_success "$service/Dockerfile ✓"
    else
        echo "❌ $service/Dockerfile NO encontrado"
    fi
done

echo "\n✅ Sincronización completada!"
echo "Ahora puedes ejecutar: ./debug-build-ubuntu.sh"