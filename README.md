# NaturePharma - Sistema de Microservicios Completo

## 🏗️ Arquitectura del Sistema

Este proyecto contiene una suite completa de microservicios para NaturePharma, incluyendo servicios dockerizados y servicios backend especializados gestionados con PM2.

### Servicios Incluidos

#### Servicios Dockerizados
- **Auth Service** (Puerto 4001) - Autenticación y autorización
- **Calendar Service** (Puerto 3003) - Gestión de calendario y eventos
- **Laboratorio Service** (Puerto 3004) - Gestión de defectos de fabricación y tareas
- **Solicitudes Service** (Puerto 3001) - Sistema de solicitudes en tiempo real
- **MySQL Database** (Puerto 3306) - Base de datos local (no dockerizada)
- **phpMyAdmin** (Puerto 8080) - Interfaz web para administración de BD
- **Nginx** (Puerto 80/443) - Reverse proxy y API Gateway

#### Servicios Backend con PM2
- **Cremer Backend** (Puerto 3002) - Sistema de órdenes de fabricación para Cremer
- **Tecnomaco Backend** (Puerto 3006) - Sistema de órdenes de fabricación para Tecnomaco
- **Servidor RPS** (Puerto 4000) - Servidor de autocompletado SQL Server

## 🚀 Instalación y Configuración Completa

### Prerrequisitos

- **Ubuntu Server 18.04+** o Windows 10/11
- **Docker 20.10+**
- **Docker Compose 1.29+**
- **Node.js 16+**
- **PM2** (Process Manager)
- **MySQL 8.0+** instalado localmente
- **Git**

### 1. Instalación de Dependencias

#### En Ubuntu:
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalar Node.js y PM2
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Instalar MySQL
sudo apt install mysql-server
sudo mysql_secure_installation
```

#### En Windows:
```powershell
# Instalar Node.js desde https://nodejs.org
# Instalar Docker Desktop desde https://docker.com
# Instalar MySQL desde https://dev.mysql.com/downloads/installer/

# Instalar PM2
npm install -g pm2
```

### 2. Configuración del Proyecto

```bash
# 1. Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd Servicios

# 2. Hacer ejecutable el script de despliegue (Linux/Mac)
chmod +x deploy.sh

# 3. Configuración inicial
./deploy.sh setup  # Linux/Mac
# o manualmente copiar .env.example a .env en Windows

# 4. Editar variables de entorno
nano .env  # Linux/Mac
# o editar .env con tu editor favorito en Windows
```

### 3. Configuración de MySQL

```sql
-- Conectar a MySQL como root
mysql -u root -p

-- Crear usuario para NaturePharma
CREATE USER 'naturepharma'@'localhost' IDENTIFIED BY 'Root123!';
GRANT ALL PRIVILEGES ON *.* TO 'naturepharma'@'localhost' WITH GRANT OPTION;

-- Crear bases de datos
CREATE DATABASE naturepharma_auth;
CREATE DATABASE naturepharma_calendar;
CREATE DATABASE naturepharma_laboratorio;
CREATE DATABASE naturepharma_solicitudes;
CREATE DATABASE cremer;
CREATE DATABASE tecnomaco;

FLUSH PRIVILEGES;
exit
```

### 4. Configuración de Variables de Entorno

Edita el archivo `.env` con las siguientes configuraciones críticas:

```env
# JWT - CAMBIAR EN PRODUCCIÓN
JWT_SECRET=tu_clave_super_secreta_aqui_minimo_32_caracteres

# Base de datos - CAMBIAR CONTRASEÑAS EN PRODUCCIÓN
DB_HOST=localhost
DB_USER=naturepharma
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!

# Email para notificaciones
GMAIL_USER=notificacionesnaturepharma@gmail.com
GMAIL_APP_PASSWORD=ziuv kuih rwbp onlm

# Puertos de servicios
AUTH_SERVICE_PORT=4001
CALENDAR_SERVICE_PORT=3003
LABORATORIO_SERVICE_PORT=3004
SOLICITUDES_SERVICE_PORT=3001
CREMER_BACKEND_PORT=3002
TECNOMACO_BACKEND_PORT=3006
SERVIDOR_RPS_PORT=4000
```

### 5. Instalación de Dependencias de Servicios

```bash
# Instalar dependencias para servicios dockerizados
cd auth-service && npm install && cd ..
cd calendar-service && npm install && cd ..
cd laboratorio-service && npm install && cd ..
cd ServicioSolicitudesOt && npm install && cd ..

# Instalar dependencias para servicios PM2
cd Cremer-Backend && npm install && cd ..
cd Tecnomaco-Backend && npm install && cd ..
cd SERVIDOR_RPS && npm install && cd ..
```

## 🔧 Gestión del Sistema

### Comandos para Servicios Dockerizados

```bash
# Construir e iniciar servicios dockerizados
./deploy.sh build
./deploy.sh start

# Ver estado de servicios
./deploy.sh status

# Ver logs
./deploy.sh logs
./deploy.sh logs auth-service  # Servicio específico

# Actualizar servicios
./deploy.sh update

# Reiniciar servicios
./deploy.sh restart

# Detener servicios
./deploy.sh stop

# Limpiar recursos Docker
./deploy.sh cleanup
```

### Comandos para Servicios PM2

```bash
# Iniciar todos los servicios PM2
pm2 start ecosystem.config.js

# Ver estado de servicios PM2
pm2 status
pm2 list

# Ver logs de servicios PM2
pm2 logs
pm2 logs cremer-backend  # Servicio específico
pm2 logs tecnomaco-backend
pm2 logs servidor-rps

# Reiniciar servicios PM2
pm2 restart all
pm2 restart cremer-backend  # Servicio específico

# Detener servicios PM2
pm2 stop all
pm2 stop cremer-backend  # Servicio específico

# Eliminar servicios PM2
pm2 delete all
pm2 delete cremer-backend  # Servicio específico

# Monitoreo en tiempo real
pm2 monit

# Guardar configuración PM2
pm2 save

# Configurar PM2 para inicio automático
pm2 startup
# Seguir las instrucciones que aparezcan
```

### Comandos Combinados (Docker + PM2)

```bash
# Iniciar todo el sistema
./deploy.sh start  # Servicios dockerizados
pm2 start ecosystem.config.js  # Servicios PM2

# Detener todo el sistema
pm2 stop all
./deploy.sh stop

# Reiniciar todo el sistema
pm2 restart all
./deploy.sh restart
```

## 🌐 Acceso a los Servicios

Una vez desplegado, los servicios estarán disponibles en:

### Servicios Dockerizados
- **API Gateway (Nginx)**: `http://localhost/` o `http://tu-servidor/`
- **Auth Service**: `http://localhost:4001`
- **Calendar Service**: `http://localhost:3003`
- **Laboratorio Service**: `http://localhost:3004`
- **Solicitudes Service**: `http://localhost:3001`
- **phpMyAdmin**: `http://localhost:8080`

### Servicios PM2
- **Cremer Backend**: `http://localhost:3002`
- **Tecnomaco Backend**: `http://localhost:3006`
- **Servidor RPS**: `http://localhost:4000`

### Rutas de API a través del Gateway

- **Autenticación**: `http://localhost/api/auth/*`
- **Eventos**: `http://localhost/api/events/*`
- **Laboratorio**: `http://localhost/api/laboratorio/*`
- **Solicitudes**: `http://localhost/api/solicitudes/*`
- **Necesidades**: `http://localhost/api/necesidades/*`
- **Archivos**: `http://localhost/api/archivos/*`
- **Departamentos**: `http://localhost/api/departamentos/*`
- **Chat**: `http://localhost/api/chat/*`
- **Auditoría**: `http://localhost/api/auditoria/*`

## 📊 Monitoreo y Logs

### Logs de Servicios Dockerizados

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Servicio específico
docker-compose logs -f auth-service

# Últimas 100 líneas
docker-compose logs --tail=100 calendar-service
```

### Logs de Servicios PM2

```bash
# Ver logs en tiempo real
pm2 logs

# Logs de servicio específico
pm2 logs cremer-backend --lines 100

# Limpiar logs
pm2 flush
```

### Estado de Contenedores y Procesos

```bash
# Estado de contenedores Docker
docker-compose ps
docker stats

# Estado de procesos PM2
pm2 status
pm2 monit  # Monitoreo interactivo
```

## 🔄 Actualización del Sistema

### Actualización de Código

```bash
# 1. Hacer pull de los cambios
git pull origin main

# 2. Actualizar servicios dockerizados
./deploy.sh update

# 3. Reiniciar servicios PM2
pm2 restart all
```

### Actualización de Dependencias

```bash
# 1. Actualizar dependencias en cada servicio
cd auth-service && npm update && cd ..
cd calendar-service && npm update && cd ..
cd laboratorio-service && npm update && cd ..
cd ServicioSolicitudesOt && npm update && cd ..
cd Cremer-Backend && npm update && cd ..
cd Tecnomaco-Backend && npm update && cd ..
cd SERVIDOR_RPS && npm update && cd ..

# 2. Reconstruir imágenes Docker
./deploy.sh build

# 3. Reiniciar todos los servicios
./deploy.sh restart
pm2 restart all
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### 1. Error de conexión a base de datos
```bash
# Verificar que MySQL esté corriendo
sudo systemctl status mysql  # Linux
# o verificar en Servicios de Windows

# Verificar conexión
mysql -u naturepharma -pRoot123! -e "SHOW DATABASES;"

# Ver logs de MySQL
sudo tail -f /var/log/mysql/error.log  # Linux
```

#### 2. Puerto ya en uso
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tulpn | grep :3001  # Linux
netstat -ano | findstr :3001  # Windows

# Matar proceso si es necesario
sudo kill -9 <PID>  # Linux
taskkill /PID <PID> /F  # Windows
```

#### 3. Servicios PM2 no inician
```bash
# Verificar logs de PM2
pm2 logs

# Verificar configuración
pm2 show cremer-backend

# Reiniciar PM2
pm2 kill
pm2 start ecosystem.config.js
```

#### 4. Problemas de permisos (Linux)
```bash
# Verificar permisos de directorios
ls -la uploads/

# Corregir permisos si es necesario
sudo chown -R $USER:$USER uploads/
sudo chmod -R 755 uploads/
```

### Comandos de Diagnóstico

```bash
# Verificar conectividad entre contenedores
docker-compose exec auth-service ping mysql

# Acceder a un contenedor
docker-compose exec auth-service bash

# Verificar logs específicos
docker-compose logs --tail=50 laboratorio-service
pm2 logs cremer-backend --lines 50

# Verificar uso de recursos
docker stats
pm2 monit

# Verificar puertos en uso
sudo netstat -tulpn  # Linux
netstat -ano  # Windows
```

## 📁 Estructura del Proyecto

```
Servicios/
├── auth-service/              # Servicio de autenticación (Docker)
├── calendar-service/          # Servicio de calendario (Docker)
├── laboratorio-service/       # Servicio de laboratorio (Docker)
├── ServicioSolicitudesOt/     # Servicio de solicitudes (Docker)
├── Cremer-Backend/            # Backend Cremer (PM2)
├── Tecnomaco-Backend/         # Backend Tecnomaco (PM2)
├── SERVIDOR_RPS/              # Servidor RPS (PM2)
├── nginx/                     # Configuración de Nginx
├── database/                  # Scripts de inicialización de BD
├── docker-compose.yml         # Orquestación de servicios Docker
├── ecosystem.config.js        # Configuración de PM2
├── .env.example              # Variables de entorno de ejemplo
├── deploy.sh                 # Script de despliegue Docker
└── README.md                 # Este archivo
```

## 🔒 Configuración de Seguridad

### Variables de Entorno Críticas

**IMPORTANTE**: Cambia estas configuraciones en producción:

```env
# JWT - GENERAR CLAVE SEGURA
JWT_SECRET=clave_super_secreta_minimo_32_caracteres_aqui

# Base de datos - USAR CONTRASEÑAS FUERTES
DB_PASSWORD=contraseña_segura_aqui
MYSQL_ROOT_PASSWORD=contraseña_root_segura

# Email - CONFIGURAR CORRECTAMENTE
GMAIL_USER=notificacionesnaturepharma@gmail.com
GMAIL_APP_PASSWORD=ziuv kuih rwbp onlm
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

## 🚀 Despliegue en Producción

### Lista de Verificación Pre-Despliegue

- [ ] Configurar variables de entorno de producción
- [ ] Cambiar contraseñas por defecto
- [ ] Configurar certificados SSL
- [ ] Configurar backups automáticos
- [ ] Configurar monitoreo
- [ ] Probar todos los servicios
- [ ] Configurar firewall
- [ ] Configurar PM2 para inicio automático

### Comandos de Despliegue

```bash
# 1. Configurar PM2 para inicio automático
pm2 startup
pm2 save

# 2. Configurar servicios Docker para inicio automático
sudo systemctl enable docker

# 3. Crear script de inicio automático
sudo nano /etc/systemd/system/naturepharma.service
```

### Backup y Restauración

```bash
# Crear backup de la base de datos
mysqldump -u naturepharma -pRoot123! --all-databases > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup de archivos de configuración
tar -czf config_backup_$(date +%Y%m%d_%H%M%S).tar.gz .env ecosystem.config.js docker-compose.yml

# Restaurar backup
mysql -u naturepharma -pRoot123! < backup_20240101_120000.sql
```

## 📞 Soporte y Mantenimiento

### Comandos de Mantenimiento Rutinario

```bash
# Limpiar logs antiguos
pm2 flush
docker system prune -f

# Actualizar sistema
sudo apt update && sudo apt upgrade -y  # Linux

# Verificar estado general
pm2 status
docker-compose ps
./deploy.sh status
```

### Para Soporte Técnico

1. **Revisar logs**:
   ```bash
   ./deploy.sh logs
   pm2 logs
   ```

2. **Verificar estado**:
   ```bash
   ./deploy.sh status
   pm2 status
   ```

3. **Generar reporte de diagnóstico**:
   ```bash
   echo "=== ESTADO DOCKER ===" > diagnostico.txt
   docker-compose ps >> diagnostico.txt
   echo "\n=== ESTADO PM2 ===" >> diagnostico.txt
   pm2 status >> diagnostico.txt
   echo "\n=== PUERTOS EN USO ===" >> diagnostico.txt
   netstat -tulpn >> diagnostico.txt
   ```

4. **Contactar soporte** con el archivo `diagnostico.txt` y descripción del problema

---

**NaturePharma** - Sistema Completo de Microservicios

*Incluye servicios dockerizados y backends especializados gestionados con PM2*

*Última actualización: $(date +'%Y-%m-%d')*