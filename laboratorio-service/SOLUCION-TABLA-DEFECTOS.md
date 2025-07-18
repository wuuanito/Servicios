# Solución para el Error ER_NO_SUCH_TABLE - Tabla 'Defectos' no existe

## Problema Identificado

El servicio `laboratorio-service` está generando el error:
```
ER_NO_SUCH_TABLE: Table 'laboratorio_db.Defectos' doesn't exist
```

Este error ocurre porque las tablas no se han creado en la base de datos MySQL.

## Causa del Problema

1. **Sincronización de Modelos**: La sincronización automática de Sequelize no está funcionando correctamente
2. **Tablas Faltantes**: Las tablas `Defectos` y `tareas` no existen en la base de datos `laboratorio_db`
3. **Configuración de Entorno**: Aunque `NODE_ENV=development`, la sincronización no se ejecuta correctamente

## Soluciones Implementadas

### 1. Scripts de Creación Manual

Se han creado varios scripts para resolver el problema:

#### A. Script SQL Completo (`scripts/create-all-tables.sql`)
```bash
# Ejecutar en MySQL Workbench o línea de comandos
mysql -h 192.168.20.158 -u naturepharma -p laboratorio_db < scripts/create-all-tables.sql
```

#### B. Script de Verificación (`test-db-connection.js`)
```bash
# Verificar conexión y crear tablas automáticamente
node test-db-connection.js
```

#### C. Script de Sincronización (`sync-database.js`)
```bash
# Sincronizar modelos de Sequelize
node sync-database.js
```

### 2. Mejoras en el Código

#### A. Configuración de Base de Datos (`src/config/database.js`)
- ✅ Agregado logging detallado de conexión
- ✅ Verificación de tablas existentes
- ✅ Mejor manejo de errores

#### B. Inicialización de Aplicación (`src/app.js`)
- ✅ Sincronización forzada de modelos (`alter: true`)
- ✅ Logging detallado de errores
- ✅ Mejor manejo de excepciones

#### C. Índice de Modelos (`src/models/index.js`)
- ✅ Función `syncModels` para sincronización manual
- ✅ Verificación de tablas después de sincronización

## Pasos para Resolver el Problema

### Opción 1: Ejecución Manual de SQL (Recomendado)

1. **Conectar a MySQL**:
   ```bash
   mysql -h 192.168.20.158 -u naturepharma -p
   ```

2. **Seleccionar base de datos**:
   ```sql
   USE laboratorio_db;
   ```

3. **Ejecutar script de creación**:
   ```sql
   SOURCE /ruta/completa/a/scripts/create-all-tables.sql;
   ```

### Opción 2: Script de Verificación Automática

1. **Ejecutar script de prueba**:
   ```bash
   cd /ruta/al/laboratorio-service
   node test-db-connection.js
   ```

### Opción 3: Reiniciar Servicio con Sincronización

1. **Detener servicio actual**
2. **Ejecutar sincronización**:
   ```bash
   node sync-database.js
   ```
3. **Reiniciar servicio**:
   ```bash
   npm start
   ```

## Verificación de la Solución

### 1. Verificar Tablas Creadas
```sql
USE laboratorio_db;
SHOW TABLES;
DESCRIBE Defectos;
DESCRIBE tareas;
```

### 2. Probar Endpoints
```bash
# Verificar salud del servicio
curl http://192.168.20.158:3005/health

# Probar endpoint de defectos
curl "http://192.168.20.158:3005/api/laboratorio/defectos?page=1&limit=10"

# Probar endpoint de tareas
curl "http://192.168.20.158:3005/api/laboratorio/tareas?page=1&limit=10"
```

## Estructura de Tablas Creadas

### Tabla `Defectos`
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `codigoDefecto` (VARCHAR(50), UNIQUE, NOT NULL)
- `tipoArticulo` (VARCHAR(100), NOT NULL)
- `descripcionArticulo` (VARCHAR(500), NOT NULL)
- `codigo` (VARCHAR(20), NOT NULL)
- `versionDefecto` (VARCHAR(10), NOT NULL)
- `descripcionDefecto` (TEXT, NULL)
- `tipoDesviacion` (VARCHAR(100), NOT NULL)
- `decision` (VARCHAR(100), NOT NULL)
- Campos de imagen: `imagenFilename`, `imagenOriginalName`, `imagenMimetype`, `imagenSize`
- `observacionesAdicionales` (TEXT, NULL)
- `creadoPor` (VARCHAR(100), NOT NULL)
- `estado` (ENUM: 'activo', 'inactivo', 'archivado', DEFAULT 'activo')
- `createdAt`, `updatedAt` (TIMESTAMP)

### Tabla `tareas`
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `titulo` (VARCHAR(255), NOT NULL)
- `descripcion` (TEXT, NULL)
- `asignado` (VARCHAR(255), NOT NULL)
- `estado` (ENUM: 'pendiente', 'en_progreso', 'completada', DEFAULT 'pendiente')
- `prioridad` (ENUM: 'baja', 'media', 'alta', DEFAULT 'media')
- `fechaVencimiento` (DATE, NULL)
- `fechaCreacion` (DATE, NOT NULL)
- `fechaCompletada` (DATETIME, NULL)
- `comentarios` (TEXT, NULL)
- `creadoEn`, `actualizadoEn` (DATETIME)

## Datos de Ejemplo

Ambas tablas incluyen datos de ejemplo para pruebas:
- **Defectos**: 5 registros de ejemplo con diferentes tipos de desviaciones
- **Tareas**: 5 registros de ejemplo con diferentes estados y prioridades

## Prevención de Problemas Futuros

1. **Verificar Sincronización**: Asegurar que `syncModels()` se ejecute correctamente
2. **Logging**: Monitorear logs de inicialización de base de datos
3. **Scripts de Backup**: Mantener scripts SQL actualizados
4. **Documentación**: Mantener este documento actualizado con cambios en el esquema

## Contacto

Si el problema persiste, verificar:
- Conectividad de red a `192.168.20.158:3306`
- Credenciales de base de datos
- Permisos del usuario `naturepharma`
- Estado del servicio MySQL

---

**Fecha de creación**: $(date)
**Versión del servicio**: 1.0.0
**Base de datos**: laboratorio_db
**Servidor**: 192.168.20.158:3306