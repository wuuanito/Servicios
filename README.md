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

# Instalar dependencias necesarias
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Agregar clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Actualizar índice de paquetes
sudo apt update

# Instalar Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker-compose --version

# Reiniciar sesión o ejecutar:
newgrp docker

# Instalar MySQL
sudo apt install mysql-server
sudo mysql_secure_installation
```

#### En Windows:
```powershell
# Instalar Docker Desktop desde https://docker.com
# Instalar MySQL desde https://dev.mysql.com/downloads/installer/

# Verificar instalación de Docker
docker --version
docker-compose --version
```

### 2. Configuración del Proyecto

```bash
# Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
cd Servicios

# Copiar archivo de variables de entorno
cp .env.example .env

# Editar variables de entorno según tu configuración
nano .env

# El sistema está completamente dockerizado
# No es necesario instalar dependencias manualmente
# Docker se encargará de todo durante la construcción
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
sudo cd auth-service && npm install && cd ..
sudo cd calendar-service && npm install && cd ..
sudo cd laboratorio-service && npm install && cd ..
sudo cd ServicioSolicitudesOt && npm install && cd ..

# Instalar dependencias para servicios PM2
cd Cremer-Backend && npm install && cd ..
cd Tecnomaco-Backend && npm install && cd ..
cd SERVIDOR_RPS && npm install && cd ..
```

## 🚀 Inicio Automático del Sistema

### Script de Inicio Rápido

```bash
# Hacer ejecutable el script
chmod +x start-system.sh

# Iniciar todo el sistema
./start-system.sh
```

### Configurar Inicio Automático en el Servidor (Linux)

```bash
# 1. Copiar el archivo de servicio systemd
sudo cp naturepharma.service /etc/systemd/system/

# 2. Editar el archivo para ajustar la ruta
sudo nano /etc/systemd/system/naturepharma.service
# Cambiar '/path/to/Servicios' por la ruta real de tu proyecto

# 3. Recargar systemd
sudo systemctl daemon-reload

# 4. Habilitar el servicio para inicio automático
sudo systemctl enable naturepharma.service

# 5. Iniciar el servicio
sudo systemctl start naturepharma.service

# 6. Verificar estado
sudo systemctl status naturepharma.service
```

### Comandos del Servicio Systemd

```bash
# Iniciar el sistema
sudo systemctl start naturepharma

# Detener el sistema
sudo systemctl stop naturepharma

# Reiniciar el sistema
sudo systemctl restart naturepharma

# Ver estado del sistema
sudo systemctl status naturepharma

# Ver logs del servicio
sudo journalctl -u naturepharma -f

# Deshabilitar inicio automático
sudo systemctl disable naturepharma
```

## 🔧 Gestión del Sistema

### Comandos para Servicios Dockerizados

#### Servicios disponibles en Docker

- **auth-service**: Puerto 4001 - Servicio de autenticación
- **calendar-service**: Puerto 3003 - Servicio de calendario
- **laboratorio-service**: Puerto 3004 - Servicio de laboratorio
- **solicitudes-service**: Puerto 3001 - Servicio de solicitudes
- **phpmyadmin**: Puerto 8080 - Administración de base de datos
- **nginx**: Puertos 80/443 - Proxy reverso

#### Comandos básicos de Docker Compose

```bash
# Construir e iniciar todos los servicios
docker-compose up -d

# Construir e iniciar servicios específicos
docker-compose up -d auth-service calendar-service
docker-compose up -d laboratorio-service solicitudes-service

# Ver logs de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f auth-service
docker-compose logs -f calendar-service

# Detener todos los servicios
docker-compose down

# Detener servicios específicos
docker-compose stop auth-service calendar-service

# Reiniciar todos los servicios
docker-compose restart

# Reiniciar servicios específicos
docker-compose restart auth-service calendar-service

# Reconstruir servicios después de cambios en el código
docker-compose up -d --build

# Reconstruir servicios específicos
docker-compose up -d --build auth-service calendar-service

# Ver estado de los servicios
docker-compose ps
```

#### Comandos con script de despliegue

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

### Comandos de Gestión con Docker

```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver estado de todos los servicios
docker-compose ps

# Ver logs en tiempo real de todos los servicios
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f cremer-backend
docker-compose logs -f tecnomaco-backend
docker-compose logs -f servidor-rps

# Reiniciar todos los servicios
docker-compose restart

# Reiniciar servicio específico
docker-compose restart cremer-backend

# Detener todos los servicios
docker-compose down

# Detener servicio específico
docker-compose stop cremer-backend

# Reconstruir e iniciar servicios
docker-compose up -d --build

# Ver uso de recursos
docker stats
```

### Gestión Completa del Sistema

```bash
# Iniciar todo el sistema completo
docker-compose up -d

# Iniciar servicios específicos
docker-compose up -d auth-service calendar-service laboratorio-service
docker-compose up -d cremer-backend tecnomaco-backend servidor-rps

# Detener todo el sistema
docker-compose down

# Reiniciar todo el sistema
docker-compose restart

# Monitoreo completo del sistema
docker-compose logs -f  # Logs de todos los servicios
docker stats  # Uso de recursos en tiempo real
docker-compose ps  # Estado de todos los contenedores
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

### Servicios Backend

- **Cremer Backend**: `http://localhost:3002`
- **Tecnomaco Backend**: `http://localhost:3006`
- **Servidor RPS**: `http://localhost:4000`

### 🖥️ Servicios de Monitoreo

- **Dashboard de Logs**: `http://192.168.20.158:8080` (Accesible desde toda la red)
- **PHPMyAdmin**: `http://localhost:8081`

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
# Ver logs en tiempo real de todos los servicios
docker-compose logs -f

# Servicios principales
docker-compose logs -f auth-service
docker-compose logs -f calendar-service
docker-compose logs -f laboratorio-service
docker-compose logs -f solicitudes-service

# Servicios backend dockerizados
docker-compose logs -f cremer-backend
docker-compose logs -f tecnomaco-backend
docker-compose logs -f servidor-rps

# Últimas 100 líneas de un servicio específico
docker-compose logs --tail=100 cremer-backend

# Ver logs de múltiples servicios backend
docker-compose logs -f cremer-backend tecnomaco-backend servidor-rps
```

### 📊 Monitoreo Avanzado de Logs por Servicio

#### 🌐 Dashboard Web de Monitoreo (RECOMENDADO)

```bash
# Hacer ejecutable el script del monitor web
chmod +x start-log-monitor.sh

# Iniciar el dashboard web de monitoreo
./start-log-monitor.sh

# Acceder al dashboard desde cualquier dispositivo en la red
# http://192.168.20.158:8080
```

**Características del Dashboard Web:**
- 🎯 **Monitoreo en tiempo real** de todos los servicios
- 📊 **Estadísticas visuales** (servicios activos, detenidos, etc.)
- 🔄 **Auto-refresh configurable** (5s, 10s, 30s, 1min)
- 📱 **Responsive design** - funciona en móviles y tablets
- 🎨 **Interfaz moderna** con logs coloreados por tipo
- ⚡ **Acceso desde cualquier dispositivo** en la red interna
- 🔍 **Filtros por cantidad de líneas** (50, 100, 200, 500)
- 📈 **Estado en tiempo real** de cada contenedor

#### Script de Monitoreo por Terminal

```bash
# Hacer ejecutable el script de monitoreo
chmod +x monitor-logs.sh

# Ver ayuda del monitor
./monitor-logs.sh --help

# Monitorear todos los servicios en tiempo real
./monitor-logs.sh -a -f

# Monitorear servicio específico en tiempo real
./monitor-logs.sh -f cremer-backend
./monitor-logs.sh -f tecnomaco-backend
./monitor-logs.sh -f servidor-rps

# Ver últimas 50 líneas de un servicio
./monitor-logs.sh -t 50 cremer-backend

# Logs desde una fecha específica
./monitor-logs.sh -s "2024-01-01" auth-service

# Exportar todos los logs a archivos
./monitor-logs.sh -e
```

#### Comandos Docker Compose Directos

```bash
# Logs en tiempo real con timestamps
docker-compose logs -f -t

# Logs de servicio específico con timestamps
docker-compose logs -f -t cremer-backend
docker-compose logs -f -t tecnomaco-backend
docker-compose logs -f -t servidor-rps

# Últimas N líneas de logs
docker-compose logs --tail=100 cremer-backend
docker-compose logs --tail=50 tecnomaco-backend

# Logs desde una fecha específica
docker-compose logs --since="2024-01-01T00:00:00" cremer-backend

# Logs hasta una fecha específica
docker-compose logs --until="2024-12-31T23:59:59" servidor-rps

# Filtrar logs por múltiples servicios
docker-compose logs -f cremer-backend tecnomaco-backend servidor-rps

# Exportar logs a archivo
docker-compose logs cremer-backend > cremer-backend-logs.txt
docker-compose logs tecnomaco-backend > tecnomaco-backend-logs.txt
docker-compose logs servidor-rps > servidor-rps-logs.txt
```

### Estado y Monitoreo de Contenedores

```bash
# Estado detallado de todos los contenedores
docker-compose ps

# Uso de recursos en tiempo real
docker stats

# Información detallada de un contenedor específico
docker inspect <container_name>

# Procesos ejecutándose en un contenedor
docker-compose exec cremer-backend ps aux
docker-compose exec tecnomaco-backend ps aux
docker-compose exec servidor-rps ps aux

# Información de salud de los servicios
docker-compose ps --services
docker-compose ps --filter "status=running"

# Monitoreo de eventos en tiempo real
docker events --filter container=cremer-backend
docker events --filter container=tecnomaco-backend
docker events --filter container=servidor-rps
```

## 🔄 Actualización del Sistema

### Actualización de Código

```bash
# 1. Hacer pull de los cambios
git pull origin main

# 2. Reconstruir y reiniciar servicios
docker-compose down
docker-compose up -d --build

# 3. Verificar que todos los servicios estén funcionando
docker-compose ps
docker-compose logs -f --tail=50
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

# 2. Reconstruir todas las imágenes Docker
docker-compose build --no-cache

# 3. Reiniciar todos los servicios con las nuevas imágenes
docker-compose down
docker-compose up -d

# 4. Verificar que todo funcione correctamente
docker-compose ps
docker-compose logs -f --tail=100
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

#### 3. Contenedores no inician correctamente
```bash
# Verificar logs de contenedores
docker-compose logs cremer-backend
docker-compose logs tecnomaco-backend
docker-compose logs servidor-rps

# Verificar estado de contenedores
docker-compose ps

# Reiniciar contenedores específicos
docker-compose restart cremer-backend
docker-compose restart tecnomaco-backend
docker-compose restart servidor-rps

# Reconstruir contenedores problemáticos
docker-compose up -d --build cremer-backend
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
│   └── Dockerfile            # Configuración Docker
├── calendar-service/          # Servicio de calendario (Docker)
│   └── Dockerfile            # Configuración Docker
├── laboratorio-service/       # Servicio de laboratorio (Docker)
│   └── Dockerfile            # Configuración Docker
├── ServicioSolicitudesOt/     # Servicio de solicitudes (Docker)
│   └── Dockerfile            # Configuración Docker
├── Cremer-Backend/            # Backend Cremer (Docker)
│   └── Dockerfile            # Configuración Docker
├── Tecnomaco-Backend/         # Backend Tecnomaco (Docker)
│   └── Dockerfile            # Configuración Docker
├── SERVIDOR_RPS/              # Servidor RPS (Docker)
│   └── Dockerfile            # Configuración Docker
├── public/                    # Dashboard web de monitoreo
│   └── dashboard.html        # Interfaz web para logs
├── nginx/                     # Configuración de Nginx
├── database/                  # Scripts de inicialización de BD
├── docker-compose.yml         # Orquestación completa del sistema
├── start-system.sh           # Script de inicio automático
├── start-log-monitor.sh      # Script de inicio del monitor web
├── monitor-logs.sh           # Script de monitoreo de logs por terminal
├── log-monitor-service.js    # Servicio backend del monitor web
├── log-monitor-package.json  # Dependencias del monitor web
├── Dockerfile.log-monitor    # Docker para el monitor web
├── naturepharma.service      # Servicio systemd para inicio automático
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