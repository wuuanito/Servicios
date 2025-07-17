# 📮 Guía de Colección Postman - Sistema de Solicitudes

## 🚀 Configuración Inicial

### 1. Importar la Colección
1. Abrir Postman
2. Hacer clic en **Import**
3. Seleccionar el archivo `postman_collection.json`
4. La colección se importará con todas las carpetas organizadas

### 2. Variables de Entorno
La colección incluye las siguientes variables que se configuran automáticamente:

```
base_url: http://localhost:3001
solicitud_id: (se establece automáticamente)
solicitud_almacen_id: (se establece automáticamente)
solicitud_lab_id: (se establece automáticamente)
necesidad_id: (se establece automáticamente)
archivo_id: (se establece automáticamente)
```

### 3. Verificar Servidor
Antes de usar la colección, asegúrate de que el servidor esté ejecutándose:
```bash
npm run dev
```

## 📁 Estructura de la Colección

### 🏗️ Setup & Configuration
- **Health Check**: Verificar que el servidor esté funcionando
- **Get Master Data**: Obtener departamentos, estados y niveles de urgencia

### 📝 Solicitudes - CRUD
Operaciones básicas para gestionar solicitudes:
- Crear, obtener, actualizar solicitudes
- Obtener historial y estadísticas

### 🔄 Flujos de Trabajo

#### Flujo 1: Directo a Expediciones
1. **Crear Solicitud** → Guarda `solicitud_id`
2. **Enviar a Expediciones** → Finaliza el proceso

#### Flujo 2: Vía Almacén
1. **Crear Solicitud** → Guarda `solicitud_almacen_id`
2. **Enviar a Almacén**
3. **Crear Necesidad para Laboratorio** → Guarda `necesidad_id`
4. **Completar Necesidad en Laboratorio**
5. **Finalizar desde Almacén** O **Enviar a Expediciones**

#### Flujo 3: Directo a Laboratorio
1. **Crear Solicitud** → Guarda `solicitud_lab_id`
2. **Enviar Directamente a Laboratorio**
3. **Finalizar desde Laboratorio** O **Devolver a Almacén**

### 🧬 Necesidades - CRUD
Gestión completa de necesidades de laboratorio:
- CRUD completo
- Reabrir necesidades
- Estadísticas y reportes

### 📁 Archivos
Subida y gestión de archivos adjuntos:
- Subir archivos a solicitudes o necesidades
- Descargar y eliminar archivos
- Estadísticas de archivos

### 🏢 Departamentos & Reportes
Reportes y estadísticas del sistema:
- Estadísticas por departamento
- Dashboard general
- Reportes de flujo entre departamentos

## 🎯 Casos de Uso Recomendados

### Prueba Completa del Sistema
1. **Setup**: Ejecutar "Health Check" y "Get Master Data"
2. **Flujo Expediciones**: Ejecutar toda la carpeta "Flujo 1"
3. **Flujo Almacén**: Ejecutar toda la carpeta "Flujo 2"
4. **Flujo Laboratorio**: Ejecutar toda la carpeta "Flujo 3"
5. **Verificar**: Usar endpoints de estadísticas y reportes

### Prueba de Archivos
1. Crear una solicitud
2. Subir archivos (PDF, imágenes)
3. Verificar descarga
4. Eliminar archivos

### Prueba de Reportes
1. Crear varias solicitudes con diferentes flujos
2. Consultar dashboard general
3. Verificar estadísticas por departamento
4. Generar reporte de flujo

## 🔧 Scripts Automáticos

La colección incluye scripts que:
- **Guardan automáticamente IDs** de solicitudes y necesidades creadas
- **Configuran variables** para usar en requests posteriores
- **Validan respuestas** y muestran información en la consola

### Ejemplo de Script
```javascript
if (pm.response.code === 201) {
    const response = pm.response.json();
    pm.environment.set('solicitud_id', response.data.id);
    console.log('Solicitud creada con ID:', response.data.id);
}
```

## 📊 Monitoreo en Tiempo Real

Para ver los eventos Socket.IO en tiempo real:
1. Abrir las herramientas de desarrollador del navegador
2. Ir a `http://localhost:3001`
3. En la consola, ejecutar:
```javascript
const socket = io();
socket.on('nueva_solicitud', (data) => console.log('Nueva solicitud:', data));
socket.on('solicitud_actualizada', (data) => console.log('Solicitud actualizada:', data));
// ... otros eventos
```

## 🚨 Solución de Problemas

### Error de Conexión
- Verificar que el servidor esté ejecutándose en puerto 3001
- Comprobar la variable `base_url` en Postman

### Variables No Se Establecen
- Verificar que los scripts de "Test" estén habilitados
- Comprobar que las respuestas sean exitosas (código 200/201)

### Archivos No Se Suben
- Verificar que el directorio `uploads` exista
- Comprobar permisos de escritura
- Verificar tamaño del archivo (máximo según configuración)

## 📝 Notas Importantes

1. **Orden de Ejecución**: Los flujos están diseñados para ejecutarse en orden
2. **Variables Automáticas**: Los IDs se guardan automáticamente para usar en requests posteriores
3. **Datos de Prueba**: Cada flujo usa datos diferentes para facilitar la identificación
4. **Validaciones**: El sistema valida estados y transiciones automáticamente

## 🎉 ¡Listo para Probar!

La colección está completamente configurada para probar todos los aspectos del sistema de solicitudes. Simplemente importa el archivo JSON y comienza a ejecutar los requests en el orden sugerido.

¿Necesitas ayuda? Consulta la documentación principal en `README.md` o revisa los logs del servidor para más detalles.