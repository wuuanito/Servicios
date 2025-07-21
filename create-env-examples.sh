#!/bin/bash

# Script para crear archivos .env.example estándar
# NaturePharma System - Environment Examples Creator

echo "=== Creando archivos .env.example estándar ==="
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

# Función para crear .env.example para servicios de backend
create_backend_env_example() {
    local service_dir="$1"
    local service_name="$2"
    local port="$3"
    
    show_info "Creando $service_dir/.env.example..."
    
    cat > "$service_dir/.env.example" << EOF
# $service_name Service Configuration
# Copia este archivo como .env y configura los valores apropiados

# Server Configuration
PORT=$port
NODE_ENV=development
API_VERSION=v1

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=naturepharma_${service_dir,,}
DB_USER=root
DB_PASSWORD=your_password_here
DB_DIALECT=mysql

# Database Connection Pool
DB_POOL_MAX=5
DB_POOL_MIN=0
DB_POOL_ACQUIRE=30000
DB_POOL_IDLE=10000

# JWT Configuration
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# CORS Configuration
CORS_ORIGIN=http://localhost:3000
CORS_CREDENTIALS=true

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=combined
LOG_FILE_ENABLED=true
LOG_FILE_PATH=./logs/app.log

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# File Upload Configuration
UPLOAD_MAX_SIZE=10485760
UPLOAD_ALLOWED_TYPES=image/jpeg,image/png,application/pdf
UPLOAD_DEST=./uploads

# Email Configuration (if applicable)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
SMTP_FROM=noreply@naturepharma.com

# External APIs (if applicable)
EXTERNAL_API_URL=https://api.example.com
EXTERNAL_API_KEY=your_api_key_here
EXTERNAL_API_TIMEOUT=5000

# Security
BCRYPT_ROUNDS=12
SESSION_SECRET=your_session_secret_here
CSRF_PROTECTION=true

# Health Check
HEALTH_CHECK_ENDPOINT=/health
HEALTH_CHECK_INTERVAL=30000

# Monitoring
MONITORING_ENABLED=true
METRICS_PORT=9090

# Development
DEBUG_MODE=false
VERBOSE_LOGGING=false
EOF

    show_success "$service_dir/.env.example creado"
}

# Función para crear .env.example específico para auth-service
create_auth_env_example() {
    show_info "Creando auth-service/.env.example específico..."
    
    cat > "auth-service/.env.example" << 'EOF'
# Auth Service Configuration
# Servicio de autenticación y autorización

# Server Configuration
PORT=4001
NODE_ENV=development
API_VERSION=v1

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=naturepharma_auth
DB_USER=root
DB_PASSWORD=your_password_here
DB_DIALECT=mysql

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=your_refresh_secret_here
JWT_REFRESH_EXPIRES_IN=7d
JWT_ALGORITHM=HS256

# Password Security
BCRYPT_ROUNDS=12
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SYMBOLS=true

# Account Security
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_TIME=900000
PASSWORD_RESET_EXPIRES=3600000

# Session Configuration
SESSION_SECRET=your_session_secret_here
SESSION_MAX_AGE=86400000
SESSION_SECURE=false

# CORS Configuration
CORS_ORIGIN=http://localhost:3000
CORS_CREDENTIALS=true

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
SMTP_FROM=noreply@naturepharma.com

# Two-Factor Authentication
TOTP_SERVICE_NAME=NaturePharma
TOTP_WINDOW=1

# OAuth Configuration (if applicable)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=http://localhost:4001/auth/google/callback

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_LOGIN_WINDOW_MS=900000
RATE_LIMIT_LOGIN_MAX_REQUESTS=5

# Logging
LOG_LEVEL=info
LOG_AUTH_EVENTS=true
LOG_FAILED_ATTEMPTS=true

# Health Check
HEALTH_CHECK_ENDPOINT=/health
HEALTH_CHECK_DB=true

# Development
DEBUG_MODE=false
VERBOSE_LOGGING=false
EOF

    show_success "auth-service/.env.example específico creado"
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

# Configuración de servicios
declare -A service_ports
service_ports["auth-service"]="4001"
service_ports["calendar-service"]="4002"
service_ports["laboratorio-service"]="4003"
service_ports["ServicioSolicitudesOt"]="4004"
service_ports["Cremer-Backend"]="3002"
service_ports["Tecnomaco-Backend"]="3006"
service_ports["SERVIDOR_RPS"]="4000"

declare -A service_names
service_names["auth-service"]="Authentication"
service_names["calendar-service"]="Calendar"
service_names["laboratorio-service"]="Laboratory"
service_names["ServicioSolicitudesOt"]="Solicitudes OT"
service_names["Cremer-Backend"]="Cremer Backend"
service_names["Tecnomaco-Backend"]="Tecnomaco Backend"
service_names["SERVIDOR_RPS"]="RPS Server"

echo "\n🔧 Creando archivos .env.example..."

for service in "${!service_ports[@]}"; do
    if [ -d "$service" ]; then
        if [ -f "$service/.env.example" ]; then
            show_info "$service/.env.example ya existe, creando backup..."
            cp "$service/.env.example" "$service/.env.example.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        if [ "$service" = "auth-service" ]; then
            create_auth_env_example
        else
            create_backend_env_example "$service" "${service_names[$service]}" "${service_ports[$service]}"
        fi
    else
        echo "⚠️  Directorio $service no existe, saltando..."
    fi
done

# Crear .env.example principal si no existe
echo "\n🌍 Verificando .env.example principal..."
if [ ! -f ".env.example" ]; then
    show_info "Creando .env.example principal..."
    cat > ".env.example" << 'EOF'
# NaturePharma System - Global Configuration
# Variables de entorno globales para todo el sistema

# Environment
NODE_ENV=development

# Database Configuration
MYSQL_ROOT_PASSWORD=your_root_password_here
MYSQL_DATABASE=naturepharma
MYSQL_USER=naturepharma_user
MYSQL_PASSWORD=your_mysql_password_here

# phpMyAdmin Configuration
PMA_HOST=mysql
PMA_PORT=3306
PMA_USER=root
PMA_PASSWORD=your_root_password_here

# Network Configuration
DOCKER_NETWORK=naturepharma_network

# Volumes
MYSQL_DATA_VOLUME=mysql_data
LOGS_VOLUME=logs_data

# External Ports
PHPMYADMIN_PORT=8081
LOG_MONITOR_PORT=8080

# Security
SECRET_KEY=your_global_secret_key_here
ENCRYPTION_KEY=your_encryption_key_here

# Monitoring
LOG_LEVEL=info
MONITORING_ENABLED=true

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
EOF
    show_success ".env.example principal creado"
else
    show_success ".env.example principal ya existe"
fi

echo "\n🔍 Verificando archivos creados..."
for service in "${!service_ports[@]}"; do
    if [ -f "$service/.env.example" ]; then
        show_success "$service/.env.example ✓"
    fi
done

echo "\n💡 INSTRUCCIONES DE USO:"
echo "1. Copia cada .env.example como .env en su respectivo directorio:"
for service in "${!service_ports[@]}"; do
    echo "   cp $service/.env.example $service/.env"
done
echo "   cp .env.example .env"
echo ""
echo "2. Edita cada archivo .env con los valores apropiados para tu entorno"
echo "3. NUNCA commitees archivos .env al repositorio (deben estar en .gitignore)"
echo "4. Documenta cualquier nueva variable de entorno en el .env.example correspondiente"

echo "\n✅ Archivos .env.example creados exitosamente!"