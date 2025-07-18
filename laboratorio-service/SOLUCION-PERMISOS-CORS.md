# Solución a Problemas de Permisos y CORS - Laboratorio Service

## 🚨 Problema Identificado

### Error de Permisos
```
Error: EACCES: permission denied, open '/app/uploads/defectos/defecto_f5e53c06-c976-4719-85ea-a39c3569a2c5.png'
```

### Error CORS
- El frontend en `http://localhost:5173` no puede acceder al servicio en `http://192.168.20.158:3004`
- Necesidad de permitir todos los orígenes (CORS all origins)

## 🔧 Soluciones Implementadas

### 1. Corrección de Permisos en Docker

#### Archivos Modificados:
- **Dockerfile**: Mejorado para manejar permisos correctamente
- **docker-compose.yml**: Configuración actualizada con volúmenes y permisos
- **init-container.sh**: Script de inicialización del contenedor
- **fix-permissions.js**: Script de verificación y corrección de permisos

#### Cambios en Dockerfile:
```dockerfile
# Copiar y dar permisos al script de inicialización
COPY init-container.sh /usr/local/bin/init-container.sh
RUN chmod +x /usr/local/bin/init-container.sh

# Crear directorio para uploads con permisos correctos
RUN mkdir -p /app/uploads/defectos
RUN chown -R laboratorio:nodejs /app
RUN chmod -R 755 /app
RUN chmod -R 775 /app/uploads

# Comando para iniciar la aplicación con script de inicialización
ENTRYPOINT ["/usr/local/bin/init-container.sh"]
CMD ["npm", "start"]
```

#### Cambios en docker-compose.yml:
```yaml
laboratorio-service:
  ports:
    - "3004:3004"  # Puerto corregido
  environment:
    - PORT=3004
    - FRONTEND_URL=http://localhost:5173
    - BASE_URL=http://192.168.20.158:3004
    - MAX_FILE_SIZE=5242880
    - UPLOAD_PATH=/app/uploads/defectos
  volumes:
    - ./uploads:/app/uploads:rw  # Permisos de lectura/escritura
    - ./src:/app/src:ro          # Solo lectura para código fuente
  user: "1001:1001"              # Usuario específico
  tmpfs:
    - /tmp                       # Directorio temporal en memoria
```

### 2. Configuración CORS Completa

#### En app.js:
```javascript
app.use(cors({
  origin: '*', // Permite todos los orígenes
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-user-id', 'x-username', 'x-departamento', 'x-email', 'x-first-name', 'x-last-name'],
  credentials: false // Cambiar a false cuando origin es '*'
}));
```

### 3. Scripts de Verificación y Corrección

#### fix-permissions.js
- Verifica permisos de directorios de upload
- Crea directorios si no existen
- Corrige permisos automáticamente
- Proporciona logging detallado

#### init-container.sh
- Script de inicialización del contenedor
- Configura permisos al arrancar
- Verifica configuración antes de iniciar la aplicación

## 🚀 Cómo Usar las Soluciones

### Opción 1: Despliegue automático para usuarios ROOT
```bash
# Para usuarios con acceso root (recomendado)
chmod +x deploy-root.sh
./deploy-root.sh
```

### Opción 2: Corrección específica de permisos ROOT
```bash
# Solo corrección de permisos como root
chmod +x fix-root-permissions.sh
./fix-root-permissions.sh

# Luego desplegar manualmente
docker-compose build --no-cache
docker-compose up -d
```

### Opción 3: Despliegue automático completo (usuarios no-root)
```bash
# Para usuarios sin acceso root
chmod +x deploy-fix.sh
./deploy-fix.sh
```

### Opción 4: Corrección Manual de Permisos del Host + Despliegue
```bash
# Paso 1: Corregir permisos en el host
chmod +x fix-host-permissions.sh
./fix-host-permissions.sh

# Paso 2: Reconstruir contenedor
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Opción 5: Solo Reconstruir el Contenedor
```bash
# Detener servicios actuales
docker-compose down

# Reconstruir con los cambios
docker-compose build --no-cache

# Iniciar servicios
docker-compose up -d
```

### Opción 6: Corrección de Emergencia (Si persisten problemas)
```bash
# Corregir permisos del host como root
sudo chown -R 1001:1001 ./uploads/
sudo chmod -R 777 ./uploads/

# Reiniciar contenedor
docker-compose restart laboratorio-service
```

## 🔍 Verificación de la Solución

### 1. Verificar Permisos
```bash
# Dentro del contenedor
ls -la /app/uploads/
ls -la /app/uploads/defectos/

# Probar escritura
touch /app/uploads/defectos/test.txt
rm /app/uploads/defectos/test.txt
```

### 2. Verificar CORS
```bash
# Desde el navegador o Postman
curl -H "Origin: http://localhost:5173" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://192.168.20.158:3004/api/laboratorio/defectos
```

### 3. Probar Upload de Imagen
```bash
# Test endpoint
POST http://192.168.20.158:3004/api/laboratorio/defectos
Content-Type: multipart/form-data

# Con archivo de imagen adjunto
```

## 📊 Logs de Verificación

El servicio ahora incluye logging detallado:

```
🚀 Iniciando configuración del contenedor laboratorio-service...
📁 Creando directorio de uploads...
🔐 Configurando permisos del directorio uploads...
✅ Verificando configuración:
👤 Usuario actual: laboratorio
🆔 ID del usuario: uid=1001(laboratorio) gid=1001(nodejs)
📝 Probando permisos de escritura...
✅ Permisos de escritura OK
🎯 Configuración del contenedor completada exitosamente
🚀 Iniciando aplicación...
```

## 🛡️ Medidas Preventivas

1. **Monitoreo de Permisos**: El script `fix-permissions.js` se ejecuta automáticamente al iniciar
2. **Logging Detallado**: Todos los errores de permisos se registran con stack trace completo
3. **Verificación Automática**: El contenedor verifica permisos al arrancar
4. **Volúmenes Persistentes**: Los uploads se mantienen entre reinicios del contenedor

## 🔧 Troubleshooting

### Problemas de Permisos en Servidor Linux

#### Diagnóstico:
```bash
# 1. Verificar permisos del directorio host
ls -la ./uploads/
ls -la ./uploads/defectos/

# 2. Verificar usuario del contenedor
docker exec -it laboratorio-service whoami
docker exec -it laboratorio-service id

# 3. Verificar permisos dentro del contenedor
docker exec -it laboratorio-service ls -la /app/uploads/

# 4. Probar escritura desde el contenedor
docker exec -it laboratorio-service touch /app/uploads/defectos/test.txt
docker exec -it laboratorio-service rm /app/uploads/defectos/test.txt
```

#### Soluciones Específicas para Linux:

**Problema: Directorio propiedad de root**
```bash
# Solución: Cambiar propietario a UID 1001 (usuario laboratorio del contenedor)
sudo chown -R 1001:1001 ./uploads/
sudo chmod -R 775 ./uploads/
```

**Problema: SELinux bloqueando acceso**
```bash
# Verificar si SELinux está activo
getenforce

# Si está activo, configurar contexto para Docker
sudo setsebool -P container_manage_cgroup on
sudo chcon -Rt svirt_sandbox_file_t ./uploads/
```

**Problema: AppArmor bloqueando acceso**
```bash
# Verificar estado de AppArmor
sudo aa-status

# Temporalmente deshabilitar para Docker (no recomendado para producción)
sudo aa-complain /etc/apparmor.d/docker
```

**Problema: Filesystem con noexec**
```bash
# Verificar montajes
mount | grep uploads

# Si está montado con noexec, remontar
sudo mount -o remount,exec ./uploads
```

### Problemas de CORS:
1. Verificar que el frontend esté accediendo a `http://192.168.20.158:3004`
2. Comprobar que no hay proxies o firewalls bloqueando
3. Verificar logs del navegador para errores específicos de CORS
4. Probar con curl:
```bash
curl -H "Origin: http://localhost:5173" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     http://192.168.20.158:3004/api/laboratorio/defectos
```

## 📝 Notas Importantes

- El puerto del servicio es **3004**, no 3003
- El frontend debe estar en `http://localhost:5173`
- Los uploads se guardan en `/app/uploads/defectos/` dentro del contenedor
- El usuario del contenedor es `laboratorio` (UID 1001)
- CORS está configurado para permitir **todos los orígenes** (`origin: '*'`)

## ✅ Estado de la Solución

- ✅ Permisos de archivos corregidos
- ✅ CORS configurado para todos los orígenes
- ✅ Scripts de verificación implementados
- ✅ Logging detallado activado
- ✅ Documentación completa
- ✅ Medidas preventivas implementadas