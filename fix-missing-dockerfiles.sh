#!/bin/bash

# Script para resolver el problema de Dockerfiles faltantes
# NaturePharma System - Fix Missing Dockerfiles

echo "=== NaturePharma System - Reparación de Dockerfiles Faltantes ==="
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

# Función para mostrar error
show_error() {
    echo "❌ $1"
}

# Función para mostrar advertencia
show_warning() {
    echo "⚠️  $1"
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    show_error "No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

# Lista de servicios que necesitan Dockerfile
services=("Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")
ports=("3002" "3006" "4000")

echo "\n🔍 DIAGNÓSTICO INICIAL"
echo "====================="

# Verificar estado actual
missing_dockerfiles=()
for i in "${!services[@]}"; do
    service="${services[$i]}"
    if [ ! -f "$service/Dockerfile" ]; then
        missing_dockerfiles+=("$service")
        show_error "$service/Dockerfile NO encontrado"
    else
        show_success "$service/Dockerfile encontrado"
    fi
done

if [ ${#missing_dockerfiles[@]} -eq 0 ]; then
    show_success "Todos los Dockerfiles están presentes"
    echo "\n🎉 No se requiere reparación"
    exit 0
fi

echo "\n🔧 INICIANDO REPARACIÓN"
echo "======================="

# Crear Dockerfiles faltantes
for i in "${!services[@]}"; do
    service="${services[$i]}"
    port="${ports[$i]}"
    
    if [[ " ${missing_dockerfiles[@]} " =~ " ${service} " ]]; then
        show_info "Creando $service/Dockerfile..."
        
        # Crear directorio si no existe
        mkdir -p "$service"
        
        # Crear Dockerfile
        cat > "$service/Dockerfile" << EOF
# Dockerfile para $service
# NaturePharma System

FROM node:18-alpine

# Información del mantenedor
LABEL maintainer="NaturePharma Team"
LABEL service="$service"
LABEL version="1.0.0"

# Instalar dependencias del sistema
RUN apk add --no-cache \\
    curl \\
    bash \\
    && rm -rf /var/cache/apk/*

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && \\
    adduser -S nodejs -u 1001

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production && \\
    npm cache clean --force

# Copiar código fuente
COPY . .

# Cambiar propietario de archivos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE $port

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
    CMD curl -f http://localhost:$port/health || exit 1

# Comando de inicio
CMD ["npm", "start"]
EOF
        
        show_success "$service/Dockerfile creado"
        
        # Crear package.json básico si no existe
        if [ ! -f "$service/package.json" ]; then
            show_info "Creando $service/package.json básico..."
            
            cat > "$service/package.json" << EOF
{
  "name": "$(echo $service | tr '[:upper:]' '[:lower:]' | tr '_' '-')",
  "version": "1.0.0",
  "description": "Servicio $service del sistema NaturePharma",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest",
    "lint": "eslint .",
    "format": "prettier --write ."
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^6.0.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.20",
    "jest": "^29.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.8.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
            show_success "$service/package.json creado"
        fi
        
        # Crear index.js básico si no existe
        if [ ! -f "$service/index.js" ]; then
            show_info "Creando $service/index.js básico..."
            
            cat > "$service/index.js" << EOF
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || $port;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoints
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: '$service',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'READY',
    service: '$service',
    timestamp: new Date().toISOString()
  });
});

app.get('/live', (req, res) => {
  res.status(200).json({
    status: 'ALIVE',
    service: '$service',
    timestamp: new Date().toISOString()
  });
});

// Ruta principal
app.get('/', (req, res) => {
  res.json({
    message: 'Servicio $service - NaturePharma System',
    version: '1.0.0',
    status: 'running',
    port: PORT
  });
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found'
  });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
  console.log(\`🚀 Servicio $service iniciado en puerto \${PORT}\`);
  console.log(\`📊 Health check: http://localhost:\${PORT}/health\`);
});

// Manejo de señales de terminación
process.on('SIGTERM', () => {
  console.log('🛑 Recibida señal SIGTERM, cerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 Recibida señal SIGINT, cerrando servidor...');
  process.exit(0);
});
EOF
            show_success "$service/index.js creado"
        fi
        
        # Crear .env.example si no existe
        if [ ! -f "$service/.env.example" ]; then
            show_info "Creando $service/.env.example..."
            
            cat > "$service/.env.example" << EOF
# Configuración del servicio $service
# NaturePharma System

# Puerto del servidor
PORT=$port

# Entorno de ejecución
NODE_ENV=development

# Base de datos
DB_HOST=mysql
DB_PORT=3306
DB_NAME=naturepharma
DB_USER=root
DB_PASSWORD=password

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h

# Logs
LOG_LEVEL=info
LOG_FORMAT=combined

# CORS
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
            show_success "$service/.env.example creado"
        fi
        
        # Crear .gitignore si no existe
        if [ ! -f "$service/.gitignore" ]; then
            show_info "Creando $service/.gitignore..."
            
            cat > "$service/.gitignore" << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
package-lock.json
yarn.lock

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
.nyc_output/

# Build outputs
dist/
build/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF
            show_success "$service/.gitignore creado"
        fi
    fi
done

echo "\n🔍 VERIFICACIÓN FINAL"
echo "===================="

# Verificar que todos los Dockerfiles existen ahora
all_present=true
for service in "${services[@]}"; do
    if [ -f "$service/Dockerfile" ]; then
        show_success "$service/Dockerfile ✓"
    else
        show_error "$service/Dockerfile ✗"
        all_present=false
    fi
done

if [ "$all_present" = true ]; then
    echo "\n🎉 REPARACIÓN COMPLETADA EXITOSAMENTE"
    echo "===================================="
    
    show_success "Todos los Dockerfiles han sido creados"
    
    echo "\n📋 ARCHIVOS CREADOS:"
    for i in "${!services[@]}"; do
        service="${services[$i]}"
        port="${ports[$i]}"
        echo "• $service/Dockerfile (Puerto: $port)"
        echo "• $service/package.json"
        echo "• $service/index.js"
        echo "• $service/.env.example"
        echo "• $service/.gitignore"
    done
    
    echo "\n🚀 PRÓXIMOS PASOS:"
    echo "1. Ejecutar diagnóstico: ./debug-build.sh"
    echo "2. Construir servicios: docker-compose build"
    echo "3. Iniciar sistema: docker-compose up -d"
    echo "4. Verificar salud: ./check-health.sh"
    
    echo "\n💡 RECOMENDACIONES:"
    echo "• Personaliza los archivos index.js según tus necesidades"
    echo "• Configura las variables de entorno en archivos .env"
    echo "• Revisa y ajusta las dependencias en package.json"
    echo "• Implementa la lógica específica de cada servicio"
    
else
    echo "\n❌ REPARACIÓN INCOMPLETA"
    echo "========================"
    show_error "Algunos Dockerfiles no pudieron ser creados"
    echo "Revisa los permisos de escritura y el espacio en disco"
    exit 1
fi

echo "\n✅ ¡Problema de Dockerfiles faltantes resuelto!"