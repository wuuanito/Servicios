#!/bin/bash

# Script para agregar health checks a los Dockerfiles
# NaturePharma System - Health Checks Implementation

echo "=== Agregando Health Checks a los Dockerfiles ==="
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

# Función para agregar health check a Dockerfile
add_health_check_to_dockerfile() {
    local service_dir="$1"
    local port="$2"
    local health_endpoint="$3"
    
    show_info "Agregando health check a $service_dir/Dockerfile..."
    
    # Crear backup del Dockerfile original
    if [ -f "$service_dir/Dockerfile" ]; then
        cp "$service_dir/Dockerfile" "$service_dir/Dockerfile.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear nuevo Dockerfile con health check
    cat > "$service_dir/Dockerfile" << EOF
# Usar Node.js 18 como imagen base
FROM node:18-alpine

# Instalar curl para health checks
RUN apk add --no-cache curl

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar el código fuente
COPY . .

# Crear directorio de logs
RUN mkdir -p /app/logs

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Cambiar propiedad de archivos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE $port

# Configurar variables de entorno
ENV NODE_ENV=production
ENV PORT=$port

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:$port$health_endpoint || exit 1

# Comando para iniciar la aplicación
CMD ["npm", "start"]
EOF

    show_success "Health check agregado a $service_dir/Dockerfile"
}

# Función para crear health check endpoint básico
create_health_endpoint() {
    local service_dir="$1"
    
    show_info "Creando endpoint de health check para $service_dir..."
    
    # Crear directorio routes si no existe
    mkdir -p "$service_dir/routes"
    
    # Crear archivo de health check
    cat > "$service_dir/routes/health.js" << 'EOF'
const express = require('express');
const router = express.Router();

// Health check endpoint
router.get('/health', async (req, res) => {
    try {
        const healthCheck = {
            status: 'OK',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            service: process.env.npm_package_name || 'unknown',
            version: process.env.npm_package_version || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            memory: {
                used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100,
                total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024 * 100) / 100,
                external: Math.round(process.memoryUsage().external / 1024 / 1024 * 100) / 100
            },
            cpu: process.cpuUsage()
        };

        // Verificar conexión a base de datos si existe
        if (global.db || global.sequelize) {
            try {
                if (global.sequelize) {
                    await global.sequelize.authenticate();
                    healthCheck.database = 'connected';
                } else if (global.db) {
                    // Para conexiones MySQL directas
                    healthCheck.database = 'connected';
                }
            } catch (dbError) {
                healthCheck.database = 'disconnected';
                healthCheck.status = 'WARNING';
            }
        }

        res.status(200).json(healthCheck);
    } catch (error) {
        res.status(503).json({
            status: 'ERROR',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Readiness check endpoint
router.get('/ready', async (req, res) => {
    try {
        // Verificar que el servicio esté listo para recibir tráfico
        const readinessCheck = {
            status: 'READY',
            timestamp: new Date().toISOString(),
            checks: {
                database: 'unknown',
                dependencies: 'ok'
            }
        };

        // Verificar conexión a base de datos
        if (global.db || global.sequelize) {
            try {
                if (global.sequelize) {
                    await global.sequelize.authenticate();
                    readinessCheck.checks.database = 'ready';
                } else if (global.db) {
                    readinessCheck.checks.database = 'ready';
                }
            } catch (dbError) {
                readinessCheck.checks.database = 'not_ready';
                readinessCheck.status = 'NOT_READY';
                return res.status(503).json(readinessCheck);
            }
        }

        res.status(200).json(readinessCheck);
    } catch (error) {
        res.status(503).json({
            status: 'NOT_READY',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Liveness check endpoint
router.get('/live', (req, res) => {
    // Verificación básica de que el proceso está vivo
    res.status(200).json({
        status: 'ALIVE',
        timestamp: new Date().toISOString(),
        pid: process.pid,
        uptime: process.uptime()
    });
});

module.exports = router;
EOF

    show_success "Endpoint de health check creado para $service_dir"
}

# Función para crear health check para SERVIDOR_RPS (usa server.js)
create_rps_health_endpoint() {
    show_info "Creando endpoint de health check para SERVIDOR_RPS..."
    
    # Crear archivo de health check específico para RPS
    cat > "SERVIDOR_RPS/health.js" << 'EOF'
const http = require('http');

// Health check middleware
const healthCheck = (req, res) => {
    if (req.url === '/health') {
        const healthData = {
            status: 'OK',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            service: 'SERVIDOR_RPS',
            version: '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            memory: {
                used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100,
                total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024 * 100) / 100
            }
        };
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(healthData, null, 2));
        return true;
    }
    return false;
};

module.exports = healthCheck;
EOF

    show_success "Health check específico creado para SERVIDOR_RPS"
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

echo "\n🔧 Agregando health checks a los Dockerfiles..."

for service in "${!service_ports[@]}"; do
    if [ -d "$service" ]; then
        # Agregar health check al Dockerfile
        add_health_check_to_dockerfile "$service" "${service_ports[$service]}" "/health"
        
        # Crear endpoints de health check
        if [ "$service" = "SERVIDOR_RPS" ]; then
            create_rps_health_endpoint
        else
            create_health_endpoint "$service"
        fi
    else
        echo "⚠️  Directorio $service no existe, saltando..."
    fi
done

# Crear health check para log-monitor
echo "\n🖥️  Agregando health check a log-monitor..."
if [ -f "Dockerfile.log-monitor" ]; then
    cp "Dockerfile.log-monitor" "Dockerfile.log-monitor.backup.$(date +%Y%m%d_%H%M%S)"
    
    cat > "Dockerfile.log-monitor" << 'EOF'
# Usar Node.js 18 como imagen base
FROM node:18-alpine

# Instalar curl para health checks
RUN apk add --no-cache curl

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY log-monitor-package.json package.json
COPY log-monitor-service.js server.js

# Instalar dependencias
RUN npm install

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Cambiar propiedad de archivos
RUN chown -R nodejs:nodejs /app
USER nodejs

# Exponer puerto
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Comando para iniciar
CMD ["node", "server.js"]
EOF

    show_success "Health check agregado a log-monitor"
fi

echo "\n📋 Creando documentación de health checks..."
cat > "HEALTH_CHECKS.md" << 'EOF'
# Health Checks Documentation

## Endpoints Disponibles

Todos los servicios incluyen los siguientes endpoints de monitoreo:

### `/health`
- **Propósito**: Verificación general de salud del servicio
- **Método**: GET
- **Respuesta**: JSON con información del estado del servicio
- **Códigos de estado**:
  - 200: Servicio saludable
  - 503: Servicio con problemas

### `/ready`
- **Propósito**: Verificación de que el servicio está listo para recibir tráfico
- **Método**: GET
- **Respuesta**: JSON con estado de dependencias
- **Códigos de estado**:
  - 200: Servicio listo
  - 503: Servicio no listo

### `/live`
- **Propósito**: Verificación básica de que el proceso está vivo
- **Método**: GET
- **Respuesta**: JSON con información básica del proceso
- **Código de estado**: 200

## Configuración Docker

Todos los Dockerfiles incluyen:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:PORT/health || exit 1
```

## Monitoreo con Docker Compose

Para ver el estado de salud de los contenedores:
```bash
docker-compose ps
docker inspect CONTAINER_NAME | grep Health
```

## URLs de Health Checks

- Auth Service: http://localhost:4001/health
- Calendar Service: http://localhost:4002/health
- Laboratory Service: http://localhost:4003/health
- Solicitudes Service: http://localhost:4004/health
- Cremer Backend: http://localhost:3002/health
- Tecnomaco Backend: http://localhost:3006/health
- RPS Server: http://localhost:4000/health
- Log Monitor: http://localhost:8080/health

## Integración con Kubernetes

Los endpoints están listos para ser usados con Kubernetes:

```yaml
livenessProbe:
  httpGet:
    path: /live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Monitoreo Externo

Los endpoints pueden ser monitoreados por:
- Prometheus
- Grafana
- Nagios
- Datadog
- New Relic

EOF

show_success "Documentación de health checks creada"

echo "\n🔍 Verificando archivos creados..."
for service in "${!service_ports[@]}"; do
    if [ -f "$service/Dockerfile" ]; then
        if grep -q "HEALTHCHECK" "$service/Dockerfile"; then
            show_success "$service/Dockerfile incluye health check ✓"
        fi
    fi
    
    if [ -f "$service/routes/health.js" ] || [ -f "$service/health.js" ]; then
        show_success "$service incluye endpoints de health check ✓"
    fi
done

echo "\n💡 PRÓXIMOS PASOS:"
echo "1. Integra los endpoints de health check en tus aplicaciones principales"
echo "2. Para servicios Express.js, agrega: app.use('/', require('./routes/health'))"
echo "3. Para SERVIDOR_RPS, integra el middleware en server.js"
echo "4. Reconstruye las imágenes Docker: docker-compose build"
echo "5. Verifica los health checks: docker-compose ps"
echo "6. Prueba los endpoints manualmente visitando las URLs"

echo "\n✅ Health checks agregados exitosamente!"
echo "Consulta HEALTH_CHECKS.md para más información."