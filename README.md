# NaturePharma - Microservicios Dockerizados

## 🏗️ Arquitectura del Sistema

Este proyecto contiene una suite completa de microservicios para NaturePharma, completamente dockerizada y lista para desplegar en servidor Ubuntu.

### Servicios Incluidos

- **Auth Service** (Puerto 4001) - Autenticación y autorización
- **Calendar Service** (Puerto 3003) - Gestión de calendario y eventos
- **Laboratorio Service** (Puerto 3004) - Gestión de defectos de fabricación y tareas
- **Solicitudes Service** (Puerto 3001) - Sistema de solicitudes en tiempo real
- **MySQL Database** (Puerto 3306) - Base de datos compartida
- **phpMyAdmin** (Puerto 8080) - Interfaz web para administración de BD
- **Nginx** (Puerto 80/443) - Reverse proxy y API Gateway

## 🚀 Despliegue Rápido

### Prerrequisitos

- Ubuntu Server 18.04+ o similar
- Docker 20.10+
- Docker Compose 1.29+
- Git

### Instalación de Docker en Ubuntu

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reiniciar sesión para aplicar cambios de grupo
newgrp docker
```

### Despliegue del Sistema

```bash
# 1. Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd Servicios

# 2. Hacer ejecutable el script de despliegue
chmod +x deploy.sh

# 3. Configuración inicial
./deploy.sh setup

# 4. Editar variables de entorno (IMPORTANTE)
nano .env
# Configurar especialmente:
# - JWT_SECRET (cambiar por una clave segura)
# - GMAIL_USER y GMAIL_APP_PASSWORD (para notificaciones)
# - Contraseñas de base de datos si es necesario

# 5. Construir e iniciar servicios
./deploy.sh build
./deploy.sh start
```

## 🔧 Gestión del Sistema

### Comandos Principales

```bash
# Ver estado de servicios
./deploy.sh status

# Ver logs de todos los servicios
./deploy.sh logs

# Ver logs de un servicio específico
./deploy.sh logs auth-service

# Actualizar servicios (después de cambios en código)
./deploy.sh update

# Reiniciar servicios
./deploy.sh restart

# Detener servicios
./deploy.sh stop

# Limpiar recursos Docker
./deploy.sh cleanup
```

### Backup y Restauración

```bash
# Crear backup de la base de datos
./deploy.sh backup

# Restaurar backup
./deploy.sh restore backups/naturepharma_backup_20240101_120000.sql
```

## 🌐 Acceso a los Servicios

Una vez desplegado, los servicios estarán disponibles en:

- **API Gateway (Nginx)**: `http://tu-servidor/`
- **Auth Service**: `http://tu-servidor:4001`
- **Calendar Service**: `http://tu-servidor:3003`
- **Laboratorio Service**: `http://tu-servidor:3004`
- **Solicitudes Service**: `http://tu-servidor:3001`
- **phpMyAdmin**: `http://tu-servidor:8080`

### Rutas de API a través del Gateway

- **Autenticación**: `http://tu-servidor/api/auth/*`
- **Eventos**: `http://tu-servidor/api/events/*`
- **Laboratorio**: `http://tu-servidor/api/laboratorio/*`
- **Solicitudes**: `http://tu-servidor/api/solicitudes/*`
- **Necesidades**: `http://tu-servidor/api/necesidades/*`
- **Archivos**: `http://tu-servidor/api/archivos/*`
- **Departamentos**: `http://tu-servidor/api/departamentos/*`
- **Chat**: `http://tu-servidor/api/chat/*`
- **Auditoría**: `http://tu-servidor/api/auditoria/*`

## 🔒 Configuración de Seguridad

### Variables de Entorno Críticas

Asegúrate de configurar estas variables en el archivo `.env`:

```env
# JWT - CAMBIAR EN PRODUCCIÓN
JWT_SECRET=tu_clave_super_secreta_aqui_minimo_32_caracteres

# Base de datos - CAMBIAR CONTRASEÑAS EN PRODUCCIÓN
DB_PASSWORD=contraseña_segura
MYSQL_ROOT_PASSWORD=contraseña_root_segura

# Email para notificaciones
GMAIL_USER=tu-email@gmail.com
GMAIL_APP_PASSWORD=tu-app-password-de-gmail
```

### Configuración HTTPS (Opcional)

Para habilitar HTTPS:

1. Coloca tus certificados SSL en `nginx/ssl/`:
   ```
   nginx/ssl/cert.pem
   nginx/ssl/key.pem
   ```

2. Modifica `nginx/nginx.conf` para incluir configuración SSL

3. Reinicia los servicios:
   ```bash
   ./deploy.sh restart
   ```

## 📊 Monitoreo y Logs

### Ver Logs en Tiempo Real

```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f auth-service

# Últimas 100 líneas
docker-compose logs --tail=100 calendar-service
```

### Verificar Estado de Contenedores

```bash
# Estado de contenedores
docker-compose ps

# Uso de recursos
docker stats

# Información detallada de un contenedor
docker inspect naturepharma-mysql
```

## 🔄 Actualización del Sistema

### Actualización de Código

```bash
# 1. Hacer pull de los cambios
git pull origin main

# 2. Actualizar servicios
./deploy.sh update
```

### Actualización de Dependencias

```bash
# 1. Actualizar package.json en cada servicio
# 2. Reconstruir imágenes
./deploy.sh build

# 3. Reiniciar servicios
./deploy.sh restart
```

## 🐛 Solución de Problemas

### Problemas Comunes

1. **Error de conexión a base de datos**:
   ```bash
   # Verificar que MySQL esté corriendo
   docker-compose ps mysql
   
   # Ver logs de MySQL
   docker-compose logs mysql
   ```

2. **Puerto ya en uso**:
   ```bash
   # Verificar qué proceso usa el puerto
   sudo netstat -tulpn | grep :3001
   
   # Cambiar puerto en docker-compose.yml si es necesario
   ```

3. **Problemas de permisos**:
   ```bash
   # Verificar permisos de directorios
   ls -la uploads/
   
   # Corregir permisos si es necesario
   sudo chown -R $USER:$USER uploads/
   ```

### Comandos de Diagnóstico

```bash
# Verificar conectividad entre contenedores
docker-compose exec auth-service ping mysql

# Acceder a un contenedor
docker-compose exec auth-service bash

# Verificar logs de un servicio específico
docker-compose logs --tail=50 laboratorio-service
```

## 📁 Estructura del Proyecto

```
Servicios/
├── auth-service/           # Servicio de autenticación
├── calendar-service/       # Servicio de calendario
├── laboratorio-service/    # Servicio de laboratorio
├── ServicioSolicitudesOt/  # Servicio de solicitudes
├── nginx/                  # Configuración de Nginx
├── database/               # Scripts de inicialización de BD
├── docker-compose.yml      # Orquestación de servicios
├── .env.example           # Variables de entorno de ejemplo
├── deploy.sh              # Script de despliegue
└── README.md              # Este archivo
```

## 🤝 Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📞 Soporte

Para soporte técnico:

1. Revisa los logs: `./deploy.sh logs`
2. Verifica el estado: `./deploy.sh status`
3. Consulta la documentación de cada servicio individual
4. Crea un issue en el repositorio con detalles del problema

---

**NaturePharma** - Sistema de Microservicios Dockerizado

*Última actualización: $(date +'%Y-%m-%d')*