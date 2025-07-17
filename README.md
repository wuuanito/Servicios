# Gestión de Microservicios con PM2

Este proyecto contiene 3 microservicios que se pueden gestionar fácilmente usando PM2.

## Servicios Incluidos

1. **ServicioSolicitudesOt** - Puerto 3003
2. **calendar-service** - Puerto 3004
3. **laboratorio-service** - Puerto 3005

## Instalación

PM2 ya está instalado globalmente. Si necesitas reinstalarlo:

```bash
npm install -g pm2
```

## Comandos Disponibles

### Inicio Rápido
```bash
# Iniciar todos los servicios
npm start

# O directamente con PM2
pm2 start ecosystem.config.js
```

### Gestión de Servicios
```bash
# Ver estado de todos los servicios
npm run status
# o
pm2 status

# Detener todos los servicios
npm run stop
# o
pm2 stop all

# Reiniciar todos los servicios
npm run restart
# o
pm2 restart all

# Eliminar todos los servicios de PM2
npm run delete
# o
pm2 delete all
```

### Monitoreo y Logs
```bash
# Ver logs en tiempo real
npm run logs
# o
pm2 logs

# Monitor interactivo
npm run monit
# o
pm2 monit

# Ver logs de un servicio específico
pm2 logs solicitudes-service
pm2 logs calendar-service
pm2 logs laboratorio-service
```

### Gestión Individual de Servicios
```bash
# Iniciar un servicio específico
pm2 start solicitudes-service
pm2 start calendar-service
pm2 start laboratorio-service

# Detener un servicio específico
pm2 stop solicitudes-service
pm2 stop calendar-service
pm2 stop laboratorio-service

# Reiniciar un servicio específico
pm2 restart solicitudes-service
pm2 restart calendar-service
pm2 restart laboratorio-service
```

### Configuración de Inicio Automático
```bash
# Guardar configuración actual
pm2 save

# Configurar inicio automático del sistema
pm2 startup

# Restaurar servicios guardados
pm2 resurrect
```

## Configuración

La configuración de PM2 se encuentra en `ecosystem.config.js`. Puedes modificar:

- Puertos de los servicios
- Variables de entorno
- Número de instancias
- Límites de memoria
- Configuraciones de desarrollo/producción

## Estructura de Archivos

```
Servicios/
├── ecosystem.config.js     # Configuración de PM2
├── start-services.js       # Script de inicio automatizado
├── package.json           # Scripts npm para gestión
├── README.md             # Esta documentación
├── ServicioSolicitudesOt/ # Servicio de solicitudes
├── calendar-service/      # Servicio de calendario
└── laboratorio-service/   # Servicio de laboratorio
```

## Comandos Útiles de PM2

```bash
# Ver información detallada
pm2 show <service-name>

# Recargar sin downtime (solo para aplicaciones que lo soporten)
pm2 reload all

# Flush logs
pm2 flush

# Ver métricas en tiempo real
pm2 monit

# Listar todos los procesos
pm2 list
```

## Solución de Problemas

1. **Servicios no inician**: Verifica que las dependencias estén instaladas en cada servicio
2. **Puertos ocupados**: Cambia los puertos en `ecosystem.config.js`
3. **Errores de permisos**: Ejecuta como administrador si es necesario
4. **Logs no aparecen**: Usa `pm2 flush` para limpiar logs antiguos

## Entornos

- **Desarrollo**: `pm2 start ecosystem.config.js`
- **Producción**: `pm2 start ecosystem.config.js --env production`