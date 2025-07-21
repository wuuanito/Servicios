#!/bin/bash

# Script para crear archivos .gitignore estándar
# NaturePharma System - Standard .gitignore Creator

echo "=== Creando archivos .gitignore estándar ==="
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

# Función para crear .gitignore estándar
create_gitignore() {
    local service_dir="$1"
    
    show_info "Creando $service_dir/.gitignore..."
    
    cat > "$service_dir/.gitignore" << 'EOF'
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
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage
.grunt

# Bower dependency directory
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons
build/Release

# Dependency directories
node_modules/
jspm_packages/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test

# parcel-bundler cache
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Storybook build outputs
.out
.storybook-out

# Temporary folders
tmp/
temp/

# Editor directories and files
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

# Database
*.sqlite
*.sqlite3
*.db

# Uploads
uploads/

# Build outputs
build/
dist/
out/

# Test outputs
test-results/
coverage/

# Docker
.dockerignore
Dockerfile.dev

# Local development
.local
*.local
EOF

    show_success "$service_dir/.gitignore creado"
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

# Lista de servicios
services=("auth-service" "calendar-service" "laboratorio-service" "ServicioSolicitudesOt" "Cremer-Backend" "Tecnomaco-Backend" "SERVIDOR_RPS")

echo "\n🔧 Creando archivos .gitignore estándar..."

for service in "${services[@]}"; do
    if [ -d "$service" ]; then
        if [ -f "$service/.gitignore" ]; then
            show_info "$service/.gitignore ya existe, creando backup..."
            cp "$service/.gitignore" "$service/.gitignore.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        create_gitignore "$service"
    else
        echo "⚠️  Directorio $service no existe, saltando..."
    fi
done

# Crear .dockerignore estándar en el directorio raíz si no existe
echo "\n🐳 Verificando .dockerignore en directorio raíz..."
if [ ! -f ".dockerignore" ]; then
    show_info "Creando .dockerignore en directorio raíz..."
    cat > ".dockerignore" << 'EOF'
# Dependencies
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment files
.env
.env.*

# Logs
logs
*.log

# Git
.git
.gitignore

# Documentation
*.md
README*

# Development files
.vscode
.idea
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Test files
test
tests
__tests__
*.test.js
*.spec.js
coverage

# Build tools
.eslintrc*
.prettierrc*
jest.config.*

# Temporary files
tmp
temp

# Docker
Dockerfile.dev
docker-compose.dev.yml
EOF
    show_success ".dockerignore creado en directorio raíz"
else
    show_success ".dockerignore ya existe en directorio raíz"
fi

echo "\n🔍 Verificando archivos creados..."
for service in "${services[@]}"; do
    if [ -f "$service/.gitignore" ]; then
        show_success "$service/.gitignore ✓"
    fi
done

echo "\n💡 RECOMENDACIONES ADICIONALES:"
echo "• Revisa los archivos .gitignore creados y ajústalos según las necesidades específicas de cada servicio"
echo "• Considera agregar patrones específicos para frameworks o librerías que uses"
echo "• Asegúrate de que los archivos sensibles (.env, claves, etc.) estén incluidos"
echo "• Ejecuta 'git status' para verificar que los archivos no deseados estén siendo ignorados"

echo "\n✅ Archivos .gitignore estándar creados exitosamente!"