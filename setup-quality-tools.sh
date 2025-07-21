#!/bin/bash

# Script maestro para configurar herramientas de calidad
# NaturePharma System - Quality Tools Setup

echo "=== NaturePharma System - Configuración de Herramientas de Calidad ==="
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

# Función para mostrar advertencia
show_warning() {
    echo "⚠️  $1"
}

# Función para mostrar sugerencia
show_suggestion() {
    echo "💡 $1"
}

# Función para ejecutar script si existe
run_script_if_exists() {
    local script_name="$1"
    local description="$2"
    
    if [ -f "$script_name" ]; then
        show_info "Ejecutando: $description"
        chmod +x "$script_name"
        ."/$script_name"
        echo ""
    else
        show_warning "Script $script_name no encontrado"
    fi
}

# Verificar directorio actual
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

show_info "Directorio actual: $(pwd)"

echo "\n🚀 EJECUTANDO SCRIPTS DE MEJORA DE CALIDAD"
echo "==========================================="

# 1. Sincronizar Dockerfiles faltantes
echo "\n1️⃣  SINCRONIZACIÓN DE DOCKERFILES"
run_script_if_exists "sync-dockerfiles.sh" "Sincronizando Dockerfiles faltantes"

# 2. Crear archivos .gitignore estándar
echo "\n2️⃣  CONFIGURACIÓN DE .GITIGNORE"
run_script_if_exists "create-standard-gitignore.sh" "Creando archivos .gitignore estándar"

# 3. Crear archivos .env.example
echo "\n3️⃣  CONFIGURACIÓN DE VARIABLES DE ENTORNO"
run_script_if_exists "create-env-examples.sh" "Creando archivos .env.example"

# 4. Agregar health checks
echo "\n4️⃣  IMPLEMENTACIÓN DE HEALTH CHECKS"
run_script_if_exists "add-health-checks.sh" "Agregando health checks a los servicios"

# 5. Crear configuración de ESLint
echo "\n5️⃣  CONFIGURACIÓN DE LINTING"
show_info "Creando configuración de ESLint..."

# Crear .eslintrc.js global
cat > ".eslintrc.js" << 'EOF'
module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es2021: true,
    node: true,
    jest: true
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  rules: {
    'indent': ['error', 2],
    'linebreak-style': ['error', 'unix'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always'],
    'no-unused-vars': ['warn'],
    'no-console': ['warn'],
    'no-debugger': ['error'],
    'no-trailing-spaces': ['error'],
    'eol-last': ['error', 'always'],
    'comma-dangle': ['error', 'never'],
    'object-curly-spacing': ['error', 'always'],
    'array-bracket-spacing': ['error', 'never'],
    'space-before-function-paren': ['error', 'never'],
    'keyword-spacing': ['error', { 'before': true, 'after': true }],
    'space-infix-ops': ['error'],
    'no-multiple-empty-lines': ['error', { 'max': 2, 'maxEOF': 1 }],
    'prefer-const': ['error'],
    'no-var': ['error']
  },
  ignorePatterns: [
    'node_modules/',
    'dist/',
    'build/',
    'coverage/',
    '*.min.js'
  ]
};
EOF

show_success "Configuración de ESLint creada"

# 6. Crear configuración de Prettier
echo "\n6️⃣  CONFIGURACIÓN DE PRETTIER"
show_info "Creando configuración de Prettier..."

cat > ".prettierrc" << 'EOF'
{
  "semi": true,
  "trailingComma": "none",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf"
}
EOF

cat > ".prettierignore" << 'EOF'
node_modules
dist
build
coverage
*.min.js
*.log
package-lock.json
yarn.lock
.env
.env.*
Dockerfile*
docker-compose*.yml
*.md
EOF

show_success "Configuración de Prettier creada"

# 7. Crear configuración de Jest
echo "\n7️⃣  CONFIGURACIÓN DE TESTING"
show_info "Creando configuración de Jest..."

cat > "jest.config.js" << 'EOF'
module.exports = {
  testEnvironment: 'node',
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!src/**/*.spec.js',
    '!src/config/**',
    '!src/database/migrations/**',
    '!src/database/seeders/**'
  ],
  testMatch: [
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
    '/build/'
  ],
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  verbose: true,
  forceExit: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true
};
EOF

cat > "jest.setup.js" << 'EOF'
// Jest setup file
// Configuración global para tests

// Configurar timeout para tests
jest.setTimeout(30000);

// Mock de console para tests
global.console = {
  ...console,
  // Silenciar logs en tests
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
};

// Variables de entorno para testing
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.DB_NAME = 'test_db';
EOF

show_success "Configuración de Jest creada"

# 8. Crear scripts de package.json mejorados
echo "\n8️⃣  MEJORANDO PACKAGE.JSON PRINCIPAL"
show_info "Actualizando package.json principal..."

# Backup del package.json original
if [ -f "package.json" ]; then
    cp "package.json" "package.json.backup.$(date +%Y%m%d_%H%M%S)"
fi

cat > "package.json" << 'EOF'
{
  "name": "naturepharma-system",
  "version": "1.0.0",
  "description": "Sistema de microservicios NaturePharma",
  "main": "index.js",
  "scripts": {
    "start": "node start-services.js",
    "dev": "npm run start:dev",
    "start:dev": "NODE_ENV=development npm start",
    "build": "docker-compose build",
    "up": "docker-compose up -d",
    "down": "docker-compose down",
    "logs": "docker-compose logs -f",
    "ps": "docker-compose ps",
    "restart": "docker-compose restart",
    "clean": "docker-compose down --volumes --remove-orphans && docker system prune -f",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint . --ext .js",
    "lint:fix": "eslint . --ext .js --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "quality": "npm run lint && npm run format:check && npm run test",
    "setup": "./setup-quality-tools.sh",
    "health": "./check-health.sh",
    "backup": "./backup-system.sh",
    "restore": "./restore-system.sh"
  },
  "keywords": [
    "microservices",
    "docker",
    "nodejs",
    "mysql",
    "naturepharma"
  ],
  "author": "NaturePharma Team",
  "license": "MIT",
  "devDependencies": {
    "eslint": "^8.0.0",
    "prettier": "^2.8.0",
    "jest": "^29.0.0",
    "supertest": "^6.3.0",
    "nodemon": "^2.0.20"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^6.0.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
EOF

show_success "Package.json principal actualizado"

# 9. Crear script de verificación de salud
echo "\n9️⃣  CREANDO SCRIPT DE VERIFICACIÓN DE SALUD"
show_info "Creando check-health.sh..."

cat > "check-health.sh" << 'EOF'
#!/bin/bash

# Script de verificación de salud del sistema
echo "=== Verificación de Salud del Sistema NaturePharma ==="
echo "Fecha: $(date)"
echo ""

# Verificar servicios Docker
echo "🐳 Estado de contenedores Docker:"
docker-compose ps
echo ""

# Verificar health checks
echo "🏥 Health Checks:"
services=("auth-service:4001" "calendar-service:4002" "laboratorio-service:4003" "ServicioSolicitudesOt:4004" "Cremer-Backend:3002" "Tecnomaco-Backend:3006" "SERVIDOR_RPS:4000" "log-monitor:8080")

for service_port in "${services[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    echo -n "  $service: "
    if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ OK"
    else
        echo "❌ FAIL"
    fi
done

echo ""
echo "📊 Uso de recursos:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
EOF

chmod +x "check-health.sh"
show_success "Script de verificación de salud creado"

# 10. Crear documentación de calidad
echo "\n🔟 CREANDO DOCUMENTACIÓN DE CALIDAD"
show_info "Creando QUALITY_GUIDE.md..."

cat > "QUALITY_GUIDE.md" << 'EOF'
# Guía de Calidad del Código - NaturePharma System

## Herramientas Configuradas

### 1. ESLint
- **Propósito**: Análisis estático de código JavaScript
- **Configuración**: `.eslintrc.js`
- **Comando**: `npm run lint`
- **Auto-fix**: `npm run lint:fix`

### 2. Prettier
- **Propósito**: Formateo automático de código
- **Configuración**: `.prettierrc`
- **Comando**: `npm run format`
- **Verificación**: `npm run format:check`

### 3. Jest
- **Propósito**: Framework de testing
- **Configuración**: `jest.config.js`
- **Comando**: `npm test`
- **Coverage**: `npm run test:coverage`

### 4. Health Checks
- **Propósito**: Monitoreo de servicios
- **Endpoints**: `/health`, `/ready`, `/live`
- **Verificación**: `npm run health`

## Estándares de Código

### JavaScript
- Usar ES6+ features
- Preferir `const` sobre `let` y `var`
- Usar template literals para strings
- Implementar manejo de errores apropiado
- Documentar funciones complejas

### Estructura de Archivos
```
service/
├── src/
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── middleware/
│   └── utils/
├── tests/
├── .env.example
├── .gitignore
├── Dockerfile
├── package.json
└── README.md
```

### Commits
- Usar conventional commits
- Formato: `type(scope): description`
- Tipos: feat, fix, docs, style, refactor, test, chore

### Testing
- Cobertura mínima: 80%
- Tests unitarios para lógica de negocio
- Tests de integración para APIs
- Mocks para dependencias externas

## Workflow de Desarrollo

1. **Antes de commitear**:
   ```bash
   npm run quality  # lint + format + test
   ```

2. **Antes de hacer push**:
   ```bash
   npm run health   # verificar servicios
   ```

3. **Antes de deploy**:
   ```bash
   npm run test:coverage  # verificar cobertura
   ```

## Scripts Disponibles

- `npm run setup` - Configurar herramientas de calidad
- `npm run quality` - Ejecutar todas las verificaciones
- `npm run health` - Verificar salud del sistema
- `npm run clean` - Limpiar entorno Docker

## Integración Continua

El pipeline de CI/CD debe incluir:
1. Linting
2. Testing con coverage
3. Build de imágenes Docker
4. Health checks
5. Deploy automático

## Monitoreo

- Health checks automáticos cada 30s
- Logs estructurados en JSON
- Métricas de performance
- Alertas para servicios caídos
EOF

show_success "Documentación de calidad creada"

echo "\n🎉 CONFIGURACIÓN COMPLETADA"
echo "==========================="

show_success "Todas las herramientas de calidad han sido configuradas"

echo "\n📋 RESUMEN DE ARCHIVOS CREADOS:"
echo "• .eslintrc.js - Configuración de linting"
echo "• .prettierrc - Configuración de formateo"
echo "• jest.config.js - Configuración de testing"
echo "• package.json - Scripts mejorados"
echo "• check-health.sh - Verificación de salud"
echo "• QUALITY_GUIDE.md - Guía de calidad"
echo "• HEALTH_CHECKS.md - Documentación de health checks"

echo "\n🚀 PRÓXIMOS PASOS:"
echo "1. Instalar dependencias: npm install"
echo "2. Ejecutar verificación: npm run quality"
echo "3. Verificar salud: npm run health"
echo "4. Revisar documentación en QUALITY_GUIDE.md"

echo "\n✅ ¡Sistema de calidad configurado exitosamente!"