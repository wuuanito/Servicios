# Sistema de Solicitudes en Tiempo Real

Sistema backend completo para gestión de solicitudes entre departamentos (Expediciones, Almacén y Laboratorio) con flujo de trabajo automatizado, subida de archivos y notificaciones en tiempo real.

## 🚀 Características

- **Gestión de Solicitudes**: Creación, seguimiento y gestión completa de solicitudes
- **Flujo de Trabajo**: Automatización del flujo entre Expediciones, Almacén y Laboratorio
- **Tiempo Real**: Notificaciones instantáneas con Socket.IO
- **Subida de Archivos**: Soporte para PDF, imágenes y documentos de Office
- **Necesidades de Laboratorio**: Gestión de análisis y resultados
- **Historial Completo**: Seguimiento detallado de todos los movimientos
- **Dashboard y Reportes**: Estadísticas y métricas en tiempo real
- **API RESTful**: Endpoints completos y documentados

## 📋 Requisitos

- Node.js 16+ 
- MySQL 8.0+
- npm o yarn

## 🛠️ Instalación

### 1. Clonar y configurar el proyecto

```bash
# Instalar dependencias
npm install

# Copiar archivo de configuración
cp .env.example .env
```

### 2. Configurar Base de Datos

1. Crear base de datos MySQL:
```sql
CREATE DATABASE sistema_solicitudes;
```

2. Ejecutar script de inicialización:
```bash
mysql -u root -p sistema_solicitudes < database/init.sql
```

3. Configurar variables de entorno en `.env`:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=sistema_solicitudes
DB_PORT=3306
```

### 3. Configurar directorios

```bash
# Crear directorio para archivos
mkdir uploads
mkdir uploads/solicitud
mkdir uploads/necesidad
mkdir uploads/resultado
```

### 4. Ejecutar el servidor

```bash
# Desarrollo
npm run dev

# Producción
npm start
```

El servidor estará disponible en `http://localhost:3001`

## 🏗️ Estructura del Proyecto

```
├── config/
│   └── database.js          # Configuración de MySQL
├── database/
│   └── init.sql             # Script de inicialización
├── models/
│   ├── Solicitud.js         # Modelo de solicitudes
│   ├── Necesidad.js         # Modelo de necesidades
│   └── Archivo.js           # Modelo de archivos
├── routes/
│   ├── solicitudes.js       # Rutas de solicitudes
│   ├── necesidades.js       # Rutas de necesidades
│   ├── archivos.js          # Rutas de archivos
│   └── departamentos.js     # Rutas de departamentos
├── uploads/                 # Directorio de archivos
├── server.js               # Servidor principal
├── package.json
└── README.md
```

## 📊 Flujo de Trabajo

### 1. Creación de Solicitud
- Se crea una solicitud con destino a Expediciones, Almacén o Laboratorio
- Campos requeridos: solicitante, materia prima, lote, proveedor, urgencia, código artículo
- Se pueden adjuntar archivos PDF o imágenes

### 2. Flujos Posibles

#### A) Expediciones (Flujo Simple)
```
Solicitud → Expediciones → FINALIZADA
```

#### B) Almacén (Flujo Complejo)
```
Solicitud → Almacén → [Opción 1: Finalizar]
                   → [Opción 2: Crear Necesidad → Laboratorio]
                   → [Opción 3: Enviar a Expediciones]
```

#### C) Laboratorio Directo (Flujo Nuevo)
```
Solicitud → Laboratorio → [Opción 1: Finalizar]
                       → [Opción 2: Devolver a Almacén]
```

#### D) Laboratorio (Desde Almacén)
```
Almacén → Necesidad → Laboratorio → Completar Análisis → Almacén → [Finalizar o Expediciones]
```

## 🔌 API Endpoints

### Solicitudes

```http
# Obtener todas las solicitudes
GET /api/solicitudes

# Obtener solicitud por ID
GET /api/solicitudes/:id

# Crear nueva solicitud
POST /api/solicitudes

# Actualizar estado
PUT /api/solicitudes/:id/estado

# Enviar a expediciones
POST /api/solicitudes/:id/enviar-expediciones

# Enviar a almacén
POST /api/solicitudes/:id/enviar-almacen

# Enviar directamente a laboratorio
POST /api/solicitudes/:id/enviar-laboratorio

# Devolver a almacén (desde laboratorio)
POST /api/solicitudes/:id/devolver-almacen

# Crear necesidad para laboratorio (desde almacén)
POST /api/solicitudes/:id/crear-necesidad

# Finalizar solicitud
PUT /api/solicitudes/:id/finalizar

# Obtener historial
GET /api/solicitudes/:id/historial

# Estadísticas
GET /api/solicitudes/stats/general
```

### Necesidades

```http
# Obtener todas las necesidades
GET /api/necesidades

# Obtener necesidad por ID
GET /api/necesidades/:id

# Crear necesidad
POST /api/necesidades

# Actualizar necesidad
PUT /api/necesidades/:id

# Completar necesidad
POST /api/necesidades/:id/completar

# Reabrir necesidad
POST /api/necesidades/:id/reabrir

# Eliminar necesidad
DELETE /api/necesidades/:id

# Obtener necesidades por solicitud
GET /api/necesidades/solicitud/:solicitud_id

# Obtener estadísticas de necesidades
GET /api/necesidades/estadisticas

# Obtener necesidades pendientes por urgencia
GET /api/necesidades/pendientes-urgencia

# Devolver solicitud de laboratorio a almacén
POST /api/necesidades/solicitud/:solicitud_id/devolver-almacen

# Finalizar solicitud desde laboratorio
POST /api/necesidades/solicitud/:solicitud_id/finalizar-laboratorio
```

### Archivos

```http
# Subir archivos
POST /api/archivos/upload

# Descargar archivo
GET /api/archivos/:id/download

# Obtener archivos por solicitud
GET /api/archivos/solicitud/:solicitudId

# Obtener archivos por necesidad
GET /api/archivos/necesidad/:necesidadId

# Eliminar archivo
DELETE /api/archivos/:id
```

### Departamentos

```http
# Obtener departamentos
GET /api/departamentos

# Obtener datos maestros
GET /api/departamentos/maestros/todos

# Dashboard general
GET /api/departamentos/dashboard/general

# Estadísticas por departamento
GET /api/departamentos/:id/estadisticas
```

## 🔄 Eventos en Tiempo Real (Socket.IO)

### Eventos del Cliente
```javascript
// Unirse a un departamento
socket.emit('join_department', 'departamento_1');
```

### Eventos del Servidor
```javascript
// Eventos de Solicitudes
socket.on('nueva_solicitud', (data) => {
  console.log('Nueva solicitud:', data.solicitud);
});

socket.on('solicitud_actualizada', (data) => {
  console.log('Solicitud actualizada:', data.solicitud);
});

socket.on('solicitud_finalizada', (data) => {
  console.log('Solicitud finalizada:', data.solicitud);
});

socket.on('nueva_solicitud_departamento', (data) => {
  console.log('Nueva solicitud para departamento:', data.solicitud);
});

socket.on('solicitud_devuelta_laboratorio', (data) => {
  console.log('Solicitud devuelta de laboratorio a almacén:', data.solicitud);
});

socket.on('solicitud_finalizada_laboratorio', (data) => {
  console.log('Solicitud finalizada desde laboratorio:', data.solicitud);
});

// Eventos de Necesidades
socket.on('nueva_necesidad', (data) => {
  console.log('Nueva necesidad:', data.necesidad);
});

socket.on('necesidad_actualizada', (data) => {
  console.log('Necesidad actualizada:', data.necesidad);
});

socket.on('necesidad_completada', (data) => {
  console.log('Necesidad completada:', data.necesidad);
});

socket.on('necesidad_devuelta', (data) => {
  console.log('Necesidad devuelta a almacén:', data.necesidad);
});

socket.on('necesidad_eliminada', (data) => {
  console.log('Necesidad eliminada:', data.necesidad);
});

socket.on('necesidad_reabierta', (data) => {
  console.log('Necesidad reabierta:', data.necesidad);
});

// Eventos de Archivos
socket.on('archivos_subidos', (data) => {
  console.log('Archivos subidos:', data.archivos);
});

socket.on('archivo_eliminado', (data) => {
  console.log('Archivo eliminado:', data.archivo);
});
```

## 📝 Ejemplos de Uso

### Crear una nueva solicitud
```javascript
const nuevaSolicitud = {
  nombre_solicitante: "Juan Pérez",
  nombre_materia_prima: "Extracto de Ginkgo",
  lote: "LOT001",
  proveedor: "Proveedor ABC",
  urgencia_id: 2, // Normal
  codigo_articulo: "ART001",
  comentarios: "Solicitud para análisis de calidad"
};

fetch('/api/solicitudes', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(nuevaSolicitud)
});
```

### Flujo vía Almacén
```javascript
// 1. Enviar solicitud a Almacén
fetch('/api/solicitudes/123/enviar-almacen', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    comentarios: "Enviado a almacén para revisión"
  })
});

// 2. Crear necesidad para Laboratorio (desde Almacén)
fetch('/api/solicitudes/123/crear-necesidad', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    descripcion: "Análisis microbiológico requerido",
    urgencia_id: 3,
    comentarios: "Prioridad alta por lote crítico"
  })
});
```

### Flujo Directo a Laboratorio
```javascript
// 1. Enviar solicitud directamente a Laboratorio
fetch('/api/solicitudes/123/enviar-laboratorio', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    comentarios: "Análisis urgente requerido"
  })
});

// 2a. Devolver a Almacén (si necesita colaboración)
fetch('/api/necesidades/solicitud/123/devolver-almacen', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    comentarios: "Requiere verificación de stock en almacén"
  })
});

// 2b. Finalizar desde Laboratorio (si no necesita almacén)
fetch('/api/necesidades/solicitud/123/finalizar-laboratorio', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    comentarios: "Análisis completado, resultados satisfactorios"
  })
});
```

### Subir Archivos

```javascript
const formData = new FormData();
formData.append('archivos', file1);
formData.append('archivos', file2);
formData.append('solicitud_id', '1');
formData.append('tipo_adjunto', 'solicitud');

fetch('/api/archivos/upload', {
  method: 'POST',
  body: formData
});
```

### Completar Necesidad

```javascript
const resultado = {
  resultado: "Análisis completado. Parámetros dentro de especificación.",
  observaciones: "Sin observaciones adicionales",
  completed_by: "laboratorista@empresa.com"
};

fetch('/api/necesidades/1/completar', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(resultado)
});
```

## 🔒 Seguridad

- Rate limiting configurado
- Validación de entrada con express-validator
- Helmet para headers de seguridad
- Validación de tipos de archivo
- Límites de tamaño de archivo
- Sanitización de nombres de archivo

## 📈 Monitoreo

- Endpoint de salud: `GET /health`
- Logs detallados en consola
- Métricas de base de datos
- Estadísticas de archivos

## 🚀 Despliegue

### Variables de Entorno de Producción

```env
NODE_ENV=production
PORT=3001
DB_HOST=tu_host_mysql
DB_USER=tu_usuario
DB_PASSWORD=tu_password_seguro
JWT_SECRET=tu_jwt_secret_muy_seguro
FRONTEND_URL=https://tu-frontend.com
```

### Docker (Opcional)

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama de feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 📞 Soporte

Para soporte técnico o consultas, contactar al equipo de desarrollo.

---

**Desarrollado para NaturePharma** 🌿💊