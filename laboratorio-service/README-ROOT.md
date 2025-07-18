# 🔐 Guía para Usuarios ROOT - Laboratorio Service

## 📋 Información de Acceso
- **Usuario Linux**: `root`
- **Contraseña**: `root`
- **Usuario RNP**: `root`
- **Contraseña RNP**: `root`

## 🚀 Despliegue Rápido para Usuarios ROOT

### Linux/macOS (Recomendado)
```bash
# Despliegue automático completo
chmod +x deploy-root.sh
./deploy-root.sh
```

### Windows (PowerShell como Administrador)
```powershell
# Ejecutar PowerShell como Administrador
.\deploy-root.ps1
```

## 🔧 Scripts Específicos para ROOT

### 1. `deploy-root.sh` (Linux/macOS)
**Despliegue automático completo con permisos root**
- ✅ Detiene servicios existentes
- ✅ Limpia imágenes Docker antiguas
- ✅ Corrige permisos como root (UID 1001:1001)
- ✅ Configura SELinux si está activo
- ✅ Construye imagen sin caché
- ✅ Inicia servicios
- ✅ Verifica funcionamiento
- ✅ Muestra URLs de acceso

### 2. `fix-root-permissions.sh` (Linux/macOS)
**Solo corrección de permisos con acceso root**
- ✅ Crea directorio `uploads/defectos`
- ✅ Establece propietario `1001:1001`
- ✅ Configura permisos `775` para directorios
- ✅ Configura permisos `664` para archivos
- ✅ Configura contexto SELinux
- ✅ Prueba escritura

### 3. `deploy-root.ps1` (Windows)
**Despliegue automático para Windows con permisos de administrador**
- ✅ Detiene servicios existentes
- ✅ Limpia imágenes Docker antiguas
- ✅ Configura permisos de Windows
- ✅ Construye imagen sin caché
- ✅ Inicia servicios
- ✅ Verifica funcionamiento

## 🎯 Uso Paso a Paso

### Opción 1: Despliegue Automático (Recomendado)

#### En Linux/macOS:
```bash
# 1. Navegar al directorio del proyecto
cd /ruta/al/laboratorio-service

# 2. Dar permisos de ejecución
chmod +x deploy-root.sh

# 3. Ejecutar despliegue completo
./deploy-root.sh
```

#### En Windows (PowerShell como Administrador):
```powershell
# 1. Navegar al directorio del proyecto
cd C:\ruta\al\laboratorio-service

# 2. Ejecutar despliegue
.\deploy-root.ps1
```

### Opción 2: Solo Corrección de Permisos

#### En Linux/macOS:
```bash
# 1. Ejecutar corrección de permisos
chmod +x fix-root-permissions.sh
./fix-root-permissions.sh

# 2. Desplegar manualmente
docker-compose build --no-cache
docker-compose up -d
```

### Opción 3: Corrección Manual Directa

```bash
# Crear directorio
mkdir -p ./uploads/defectos

# Establecer propietario y permisos
chown -R 1001:1001 ./uploads/
find ./uploads -type d -exec chmod 775 {} \;
find ./uploads -type f -exec chmod 664 {} \;

# Configurar SELinux (si está activo)
if command -v getenforce >/dev/null 2>&1; then
    chcon -Rt svirt_sandbox_file_t ./uploads/
    setsebool -P container_manage_cgroup on
fi

# Desplegar
docker-compose build --no-cache
docker-compose up -d
```

## 📊 URLs de Acceso Después del Despliegue

- **Health Check**: http://localhost:3004/health
- **API Defectos**: http://localhost:3004/api/laboratorio/defectos
- **API Tareas**: http://localhost:3004/api/laboratorio/tareas
- **phpMyAdmin**: http://localhost:8081
  - Usuario: `root`
  - Contraseña: `root`

## 🔍 Verificación del Despliegue

### 1. Verificar Estado de Servicios
```bash
docker-compose ps
```

### 2. Verificar Logs
```bash
# Logs en tiempo real
docker-compose logs -f laboratorio-service

# Últimas 50 líneas
docker-compose logs --tail=50 laboratorio-service
```

### 3. Verificar Permisos en el Contenedor
```bash
# Listar permisos
docker exec -it laboratorio-service ls -la /app/uploads/

# Probar escritura
docker exec -it laboratorio-service touch /app/uploads/defectos/test.txt
docker exec -it laboratorio-service rm /app/uploads/defectos/test.txt
```

### 4. Probar API
```bash
# Health check
curl http://localhost:3004/health

# Listar defectos
curl http://localhost:3004/api/laboratorio/defectos
```

## 🛠️ Comandos Útiles

```bash
# Reiniciar solo el laboratorio-service
docker-compose restart laboratorio-service

# Acceder al contenedor
docker exec -it laboratorio-service sh

# Ver logs de MySQL
docker-compose logs mysql

# Detener todos los servicios
docker-compose down

# Limpiar todo (contenedores, imágenes, volúmenes)
docker-compose down -v
docker system prune -a
```

## 🚨 Troubleshooting

### Problema: Error de permisos persistente
```bash
# Verificar propietario en el host
ls -la uploads/

# Corrección directa
chown -R 1001:1001 ./uploads/
chmod -R 775 ./uploads/

# Reiniciar contenedor
docker-compose restart laboratorio-service
```

### Problema: Puerto 3004 ocupado
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tlnp | grep :3004
# o
sudo ss -tlnp | grep :3004

# Matar proceso si es necesario
sudo kill -9 <PID>
```

### Problema: SELinux bloquea acceso
```bash
# Verificar estado de SELinux
getenforce

# Configurar contexto
chcon -Rt svirt_sandbox_file_t ./uploads/
setsebool -P container_manage_cgroup on

# Temporalmente deshabilitar (solo para pruebas)
sudo setenforce 0
```

## 📚 Documentación Adicional

- **Solución completa**: `SOLUCION-PERMISOS-CORS.md`
- **Configuración Docker**: `Dockerfile`
- **Configuración servicios**: `docker-compose.yml`
- **Scripts de inicialización**: `init-container.sh`
- **Corrección de permisos**: `fix-permissions.js`

## ✅ Configuración Final Aplicada

- **Puerto del servicio**: 3004
- **CORS**: Habilitado para todos los orígenes (*)
- **Uploads**: `./uploads/defectos` (host) ↔ `/app/uploads/defectos` (contenedor)
- **Permisos**: `1001:1001` con `775/664`
- **Usuario del contenedor**: `laboratorio` (UID 1001)
- **SELinux**: Configurado automáticamente si está activo
- **Límite de archivos**: 5MB
- **Tipos permitidos**: Imágenes (jpg, jpeg, png, gif, webp)

---

**🎯 Con acceso root, todos los problemas de permisos deberían resolverse automáticamente usando los scripts proporcionados.**