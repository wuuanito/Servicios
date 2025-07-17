# Configuración en Servidor Ubuntu

## 📋 Guía Paso a Paso para Servidor Ubuntu

### 1. Preparación del Servidor

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias básicas
sudo apt install -y curl wget git nano htop

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker --version
docker-compose --version

# Reiniciar sesión para aplicar cambios de grupo
newgrp docker
```

### 2. Configuración del Firewall

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH
sudo ufw allow ssh

# Permitir puertos de los servicios
sudo ufw allow 80/tcp      # Nginx HTTP
sudo ufw allow 443/tcp     # Nginx HTTPS
sudo ufw allow 8080/tcp    # phpMyAdmin

# Opcional: permitir acceso directo a servicios (solo para desarrollo)
sudo ufw allow 3001/tcp    # Solicitudes Service
sudo ufw allow 3003/tcp    # Calendar Service
sudo ufw allow 3004/tcp    # Laboratorio Service
sudo ufw allow 4001/tcp    # Auth Service

# Ver estado del firewall
sudo ufw status
```

### 3. Crear Directorio del Proyecto

```bash
# Crear directorio para el proyecto
sudo mkdir -p /opt/naturepharma
sudo chown $USER:$USER /opt/naturepharma
cd /opt/naturepharma

# Clonar el repositorio
git clone <URL_DEL_REPOSITORIO> .

# Hacer ejecutables los scripts
chmod +x deploy.sh
chmod +x dev.sh
chmod +x healthcheck.js
```

### 4. Configuración de Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar variables de entorno
nano .env
```

**Variables críticas a configurar:**

```env
# JWT - GENERAR UNA CLAVE SEGURA
JWT_SECRET=$(openssl rand -base64 32)

# Base de datos - CAMBIAR CONTRASEÑAS
DB_PASSWORD=contraseña_muy_segura_aqui
MYSQL_ROOT_PASSWORD=otra_contraseña_muy_segura

# Email para notificaciones
GMAIL_USER=tu-email@gmail.com
GMAIL_APP_PASSWORD=tu-app-password-de-gmail

# URLs del servidor
FRONTEND_URL=http://tu-dominio.com
```

### 5. Configuración SSL (Opcional pero Recomendado)

#### Opción A: Certificados Let's Encrypt

```bash
# Instalar Certbot
sudo apt install -y certbot

# Generar certificados (reemplaza tu-dominio.com)
sudo certbot certonly --standalone -d tu-dominio.com

# Copiar certificados al proyecto
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem nginx/ssl/key.pem
sudo chown $USER:$USER nginx/ssl/*
```

#### Opción B: Certificados Autofirmados (Solo para Testing)

```bash
# Crear directorio SSL
mkdir -p nginx/ssl

# Generar certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=ES/ST=State/L=City/O=NaturePharma/CN=localhost"
```

### 6. Despliegue Inicial

```bash
# Configuración inicial
./deploy.sh setup

# Construir e iniciar servicios
./deploy.sh build
./deploy.sh start

# Verificar estado
./deploy.sh status

# Ver logs
./deploy.sh logs
```

### 7. Configuración de Monitoreo

```bash
# Instalar Node.js para el script de health check
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Hacer ejecutable el health check
chmod +x healthcheck.js

# Probar health check
node healthcheck.js

# Configurar monitoreo continuo (opcional)
node healthcheck.js --watch
```

### 8. Configuración de Backup Automático

```bash
# Crear directorio de backups
mkdir -p /opt/naturepharma/backups

# Crear script de backup automático
cat > /opt/naturepharma/backup-cron.sh << 'EOF'
#!/bin/bash
cd /opt/naturepharma
./deploy.sh backup
# Mantener solo los últimos 7 backups
find backups/ -name "*.sql" -mtime +7 -delete
EOF

# Hacer ejecutable
chmod +x backup-cron.sh

# Agregar a crontab (backup diario a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/naturepharma/backup-cron.sh") | crontab -
```

### 9. Configuración de Logs

```bash
# Configurar rotación de logs de Docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Reiniciar Docker
sudo systemctl restart docker

# Configurar logrotate para logs de aplicación
sudo tee /etc/logrotate.d/naturepharma > /dev/null <<EOF
/opt/naturepharma/*/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
```

### 10. Configuración de Inicio Automático

```bash
# Crear servicio systemd
sudo tee /etc/systemd/system/naturepharma.service > /dev/null <<EOF
[Unit]
Description=NaturePharma Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/naturepharma
ExecStart=/opt/naturepharma/deploy.sh start
ExecStop=/opt/naturepharma/deploy.sh stop
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

# Habilitar servicio
sudo systemctl enable naturepharma.service
sudo systemctl start naturepharma.service

# Verificar estado
sudo systemctl status naturepharma.service
```

## 🔄 Comandos de Gestión Diaria

### Verificar Estado
```bash
cd /opt/naturepharma
./deploy.sh status
node healthcheck.js
```

### Ver Logs
```bash
# Logs de todos los servicios
./deploy.sh logs

# Logs de un servicio específico
./deploy.sh logs auth-service

# Logs en tiempo real
docker-compose logs -f
```

### Actualizar Servicios
```bash
# Actualizar código
git pull origin main

# Actualizar servicios
./deploy.sh update
```

### Backup Manual
```bash
# Crear backup
./deploy.sh backup

# Listar backups
ls -la backups/
```

### Restaurar Backup
```bash
# Restaurar desde backup
./deploy.sh restore backups/naturepharma_backup_YYYYMMDD_HHMMSS.sql
```

## 🚨 Solución de Problemas

### Servicios No Inician
```bash
# Verificar logs
docker-compose logs

# Verificar recursos del sistema
df -h
free -h
docker system df

# Limpiar recursos si es necesario
docker system prune -f
```

### Problemas de Red
```bash
# Verificar puertos
sudo netstat -tulpn | grep -E ':(80|443|3001|3003|3004|4001|8080)'

# Verificar firewall
sudo ufw status

# Verificar conectividad entre contenedores
docker-compose exec auth-service ping mysql
```

### Problemas de Base de Datos
```bash
# Acceder a MySQL
docker-compose exec mysql mysql -u naturepharma -p

# Ver logs de MySQL
docker-compose logs mysql

# Reiniciar solo MySQL
docker-compose restart mysql
```

### Problemas de Permisos
```bash
# Verificar permisos
ls -la /opt/naturepharma

# Corregir permisos si es necesario
sudo chown -R $USER:$USER /opt/naturepharma
chmod +x deploy.sh dev.sh healthcheck.js
```

## 📊 Monitoreo y Alertas

### Configurar Alertas por Email
```bash
# Instalar mailutils
sudo apt install -y mailutils

# Crear script de alerta
cat > /opt/naturepharma/health-alert.sh << 'EOF'
#!/bin/bash
cd /opt/naturepharma
if ! node healthcheck.js > /dev/null 2>&1; then
    echo "ALERTA: Algunos servicios de NaturePharma no están funcionando correctamente" | \
    mail -s "NaturePharma Health Check Failed" admin@tu-dominio.com
fi
EOF

chmod +x health-alert.sh

# Agregar a crontab (verificar cada 5 minutos)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/naturepharma/health-alert.sh") | crontab -
```

### Configurar Monitoreo con Prometheus (Avanzado)
```bash
# Agregar servicios de monitoreo al docker-compose
# Ver documentación de Prometheus y Grafana para configuración completa
```

---

**¡Tu sistema NaturePharma está listo para producción en Ubuntu Server!**

Para soporte adicional, consulta los logs y la documentación de cada servicio individual.