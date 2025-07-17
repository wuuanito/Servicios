# 🐳 NaturePharma - Sistema Dockerizado

## 📋 Descripción

Sistema completo de microservicios NaturePharma dockerizado para fácil despliegue y gestión en servidores Ubuntu. Este proyecto incluye todos los servicios necesarios para el funcionamiento completo del sistema de gestión farmacéutica.

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │     Nginx       │    │   phpMyAdmin    │
│   (Externo)     │◄──►│ Reverse Proxy   │◄──►│   (Puerto 8080) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐
        │ Auth Service │ │Cal. Service │ │Lab. Service│
        │ (Puerto 4001)│ │(Puerto 3003)│ │(Puerto 3004│
        └──────────────┘ └─────────────┘ └────────────┘
                │               │               │
                └───────────────┼───────────────┘
                                │
                        ┌───────▼──────┐
                        │Sol. Service  │
                        │(Puerto 3001) │
                        └──────────────┘
                                │
                        ┌───────▼──────┐
                        │    MySQL     │
                        │ (Puerto 3306)│
                        └──────────────┘
```

## 🚀 Servicios Incluidos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **Auth Service** | 4001 | Autenticación y autorización |
| **Calendar Service** | 3003 | Gestión de calendario y citas |
| **Laboratorio Service** | 3004 | Gestión de laboratorio |
| **Solicitudes Service** | 3001 | Gestión de solicitudes y órdenes |
| **MySQL Database** | 3306 | Base de datos local (no dockerizada) |
| **phpMyAdmin** | 8080 | Administración de base de datos |
| **Nginx** | 80/443 | Proxy reverso y balanceador |

## 📦 Instalación Rápida

### Opción 1: Instalación Automática (Recomendada)

```bash
# Descargar e instalar automáticamente
wget https://raw.githubusercontent.com/tu-repo/naturepharma/main/install-ubuntu.sh
chmod +x install-ubuntu.sh
./install-ubuntu.sh https://github.com/tu-repo/naturepharma.git tu-dominio.com admin@tu-dominio.com
```

### Opción 2: Instalación Manual

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-repo/naturepharma.git
cd naturepharma

# 2. Configurar variables de entorno
cp .env.example .env
nano .env  # Editar según tus necesidades

# 3. Ejecutar instalación
./deploy.sh setup
./deploy.sh build
./deploy.sh start
```

## 🔧 Configuración

### Variables de Entorno Principales

```env
# Base de datos
DB_HOST=localhost
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!

# JWT
JWT_SECRET=tu_jwt_secret_muy_seguro

# Email
GMAIL_USER=tu-email@gmail.com
GMAIL_APP_PASSWORD=tu-app-password

# URLs
FRONTEND_URL=https://tu-dominio.com
```

### Certificados SSL

```bash
# Let's Encrypt (Recomendado para producción)
sudo certbot certonly --standalone -d tu-dominio.com

# Autofirmados (Para desarrollo)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem -out nginx/ssl/cert.pem
```

## 🛠️ Comandos de Gestión

### Comandos Principales

```bash
# Estado de servicios
./deploy.sh status

# Ver logs
./deploy.sh logs [servicio]

# Actualizar servicios
./deploy.sh update

# Reiniciar servicios
./deploy.sh restart [servicio]

# Parar servicios
./deploy.sh stop

# Limpiar sistema
./deploy.sh cleanup
```

### Backup y Restauración

```bash
# Crear backup
./deploy.sh backup

# Restaurar backup
./deploy.sh restore backups/archivo_backup.sql

# Listar backups
ls -la backups/
```

### Monitoreo

```bash
# Health check manual
node healthcheck.js

# Monitoreo continuo
node healthcheck.js --watch

# Ver recursos del sistema
docker stats
docker system df
```

## 🔍 Desarrollo Local

### Configuración de Desarrollo

```bash
# Instalar dependencias
./dev.sh install

# Iniciar en modo desarrollo
./dev.sh start

# Solo base de datos
./dev.sh database

# Ejecutar tests
./dev.sh test

# Ver logs de desarrollo
./dev.sh logs [servicio]
```

### Estructura de Archivos

```
naturepharma/
├── auth-service/           # Servicio de autenticación
├── calendar-service/       # Servicio de calendario
├── laboratorio-service/    # Servicio de laboratorio
├── ServicioSolicitudesOt/  # Servicio de solicitudes
├── nginx/                  # Configuración Nginx
├── database/               # Scripts de base de datos
├── .github/workflows/      # CI/CD con GitHub Actions
├── docker-compose.yml      # Configuración principal
├── docker-compose.dev.yml  # Configuración desarrollo
├── deploy.sh              # Script de despliegue
├── dev.sh                 # Script de desarrollo
├── healthcheck.js         # Monitor de salud
├── install-ubuntu.sh      # Instalador automático
└── .env.example           # Variables de entorno ejemplo
```

## 🌐 URLs de Acceso

### Producción
- **Aplicación**: `https://tu-dominio.com`
- **API Auth**: `https://tu-dominio.com/api/auth`
- **API Calendar**: `https://tu-dominio.com/api/calendar`
- **API Laboratorio**: `https://tu-dominio.com/api/laboratorio`
- **API Solicitudes**: `https://tu-dominio.com/api/solicitudes`
- **phpMyAdmin**: `https://tu-dominio.com:8080`

### Desarrollo Local
- **Auth Service**: `http://localhost:4001`
- **Calendar Service**: `http://localhost:3003`
- **Laboratorio Service**: `http://localhost:3004`
- **Solicitudes Service**: `http://localhost:3001`
- **phpMyAdmin**: `http://localhost:8080`
- **Adminer**: `http://localhost:8081`

## 🔒 Seguridad

### Configuraciones Implementadas

- ✅ Usuarios no-root en contenedores
- ✅ Secrets y variables de entorno seguras
- ✅ Certificados SSL/TLS
- ✅ Firewall configurado (UFW)
- ✅ Rate limiting en APIs
- ✅ CORS configurado
- ✅ Headers de seguridad (Helmet)
- ✅ Logs rotados y limitados

### Recomendaciones Adicionales

```bash
# Cambiar contraseñas por defecto
# Configurar fail2ban
sudo apt install fail2ban

# Configurar actualizaciones automáticas
sudo apt install unattended-upgrades

# Monitoreo de logs
sudo apt install logwatch
```

## 📊 CI/CD

### GitHub Actions

El proyecto incluye workflows automáticos:

- **Test**: Ejecuta tests en cada push/PR
- **Build**: Construye imágenes Docker
- **Deploy**: Despliega automáticamente en servidor
- **Notify**: Envía notificaciones de estado

### Configuración de Secrets

```yaml
# En GitHub Settings > Secrets
HOST: tu-servidor.com
USERNAME: usuario-servidor
SSH_KEY: tu-clave-ssh-privada
SLACK_WEBHOOK: webhook-de-slack
```

## 🚨 Solución de Problemas

### Problemas Comunes

#### Servicios no inician
```bash
# Verificar logs
docker-compose logs

# Verificar recursos
df -h && free -h

# Limpiar sistema
docker system prune -f
```

#### Problemas de red
```bash
# Verificar puertos
sudo netstat -tulpn | grep -E ':(80|443|3001|3003|3004|4001)'

# Verificar firewall
sudo ufw status
```

#### Problemas de base de datos
```bash
# Acceder a MySQL
docker-compose exec mysql mysql -u root -p

# Reiniciar MySQL
docker-compose restart mysql
```

### Logs Importantes

```bash
# Logs de aplicación
tail -f */logs/*.log

# Logs de sistema
sudo journalctl -u naturepharma.service

# Logs de Docker
sudo journalctl -u docker.service
```

## 📈 Monitoreo y Métricas

### Health Checks

```bash
# Manual
node healthcheck.js

# Automático (cada 5 minutos)
crontab -l | grep healthcheck
```

### Métricas del Sistema

```bash
# Uso de recursos
docker stats --no-stream

# Espacio en disco
docker system df

# Logs de contenedores
docker-compose logs --tail=100
```

## 🔄 Actualizaciones

### Actualización Manual

```bash
# 1. Backup
./deploy.sh backup

# 2. Actualizar código
git pull origin main

# 3. Actualizar servicios
./deploy.sh update

# 4. Verificar
./deploy.sh status
node healthcheck.js
```

### Actualización Automática

Las actualizaciones se pueden automatizar mediante:
- GitHub Actions (recomendado)
- Webhooks
- Cron jobs

## 📞 Soporte

### Documentación Adicional

- [Guía de Ubuntu](./UBUNTU_SETUP.md)
- [Documentación de APIs](./docs/api/)
- [Guía de desarrollo](./docs/development/)

### Contacto

- **Issues**: GitHub Issues
- **Email**: admin@naturepharma.com
- **Documentación**: Wiki del proyecto

---

## 🎯 Características Principales

- ✅ **Fácil despliegue**: Un comando para instalar todo
- ✅ **Escalable**: Microservicios independientes
- ✅ **Seguro**: Configuraciones de seguridad implementadas
- ✅ **Monitoreable**: Health checks y logs centralizados
- ✅ **Mantenible**: Scripts de gestión automatizados
- ✅ **Respaldable**: Backups automáticos configurados
- ✅ **Actualizable**: CI/CD y scripts de actualización
- ✅ **Documentado**: Documentación completa incluida

**¡Tu sistema NaturePharma está listo para producción! 🚀**