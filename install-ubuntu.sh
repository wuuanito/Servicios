#!/bin/bash

# Script de instalación automática para NaturePharma en Ubuntu Server
# Autor: Sistema de Dockerización NaturePharma
# Versión: 1.0

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Verificar si se ejecuta como root
if [[ $EUID -eq 0 ]]; then
   print_error "Este script no debe ejecutarse como root"
   exit 1
fi

# Verificar Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_error "Este script está diseñado para Ubuntu"
    exit 1
fi

print_step "Iniciando instalación de NaturePharma en Ubuntu Server"

# Variables
PROJECT_DIR="/opt/naturepharma"
REPO_URL="${1:-}"
DOMAIN="${2:-localhost}"
EMAIL="${3:-admin@localhost}"

if [ -z "$REPO_URL" ]; then
    print_warning "Uso: $0 <URL_REPOSITORIO> [DOMINIO] [EMAIL]"
    print_warning "Ejemplo: $0 https://github.com/usuario/naturepharma.git mi-dominio.com admin@mi-dominio.com"
    read -p "Ingresa la URL del repositorio: " REPO_URL
    read -p "Ingresa el dominio (opcional, presiona Enter para localhost): " DOMAIN_INPUT
    read -p "Ingresa el email del administrador (opcional): " EMAIL_INPUT
    
    DOMAIN=${DOMAIN_INPUT:-localhost}
    EMAIL=${EMAIL_INPUT:-admin@localhost}
fi

print_step "Actualizando sistema"
sudo apt update && sudo apt upgrade -y

print_step "Instalando dependencias básicas"
sudo apt install -y curl wget git nano htop ufw openssl mailutils

print_step "Instalando Docker"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_message "Docker instalado correctamente"
else
    print_message "Docker ya está instalado"
fi

print_step "Instalando Docker Compose"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_message "Docker Compose instalado correctamente"
else
    print_message "Docker Compose ya está instalado"
fi

print_step "Configurando firewall"
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
print_message "Firewall configurado"

print_step "Instalando Node.js"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_message "Node.js instalado correctamente"
else
    print_message "Node.js ya está instalado"
fi

print_step "Creando directorio del proyecto"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

print_step "Clonando repositorio"
if [ -d ".git" ]; then
    print_message "Repositorio ya existe, actualizando..."
    git pull origin main || git pull origin master
else
    git clone $REPO_URL .
fi

print_step "Configurando permisos"
chmod +x deploy.sh dev.sh healthcheck.js

print_step "Configurando variables de entorno"
if [ ! -f ".env" ]; then
    cp .env.example .env
    
    # Generar JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Generar contraseñas seguras
    DB_PASSWORD=$(openssl rand -base64 16)
    ROOT_PASSWORD=$(openssl rand -base64 16)
    
    # Actualizar .env
    sed -i "s/your-super-secret-jwt-key-here/$JWT_SECRET/g" .env
    sed -i "s/Root123!/$DB_PASSWORD/g" .env
    sed -i "s/Root123!/$ROOT_PASSWORD/g" .env
    sed -i "s/localhost/$DOMAIN/g" .env
    sed -i "s/tu-email@gmail.com/$EMAIL/g" .env
    
    print_message "Archivo .env configurado con valores seguros"
    print_warning "IMPORTANTE: Guarda estas credenciales:"
    echo "Database Password: $DB_PASSWORD"
    echo "Root Password: $ROOT_PASSWORD"
    echo "JWT Secret: $JWT_SECRET"
else
    print_message "Archivo .env ya existe"
fi

print_step "Configurando certificados SSL"
if [ "$DOMAIN" != "localhost" ]; then
    read -p "¿Quieres configurar SSL con Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install -y certbot
        sudo certbot certonly --standalone -d $DOMAIN --email $EMAIL --agree-tos --non-interactive
        
        mkdir -p nginx/ssl
        sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/cert.pem
        sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/key.pem
        sudo chown $USER:$USER nginx/ssl/*
        
        print_message "Certificados SSL configurados"
    else
        print_message "Generando certificados autofirmados..."
        mkdir -p nginx/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout nginx/ssl/key.pem \
          -out nginx/ssl/cert.pem \
          -subj "/C=ES/ST=State/L=City/O=NaturePharma/CN=$DOMAIN"
        print_message "Certificados autofirmados generados"
    fi
else
    print_message "Generando certificados para localhost..."
    mkdir -p nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout nginx/ssl/key.pem \
      -out nginx/ssl/cert.pem \
      -subj "/C=ES/ST=State/L=City/O=NaturePharma/CN=localhost"
fi

print_step "Configurando Docker daemon"
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

print_step "Configurando logrotate"
sudo tee /etc/logrotate.d/naturepharma > /dev/null <<EOF
$PROJECT_DIR/*/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

print_step "Configurando backup automático"
cat > backup-cron.sh << 'EOF'
#!/bin/bash
cd /opt/naturepharma
./deploy.sh backup
find backups/ -name "*.sql" -mtime +7 -delete
EOF

chmod +x backup-cron.sh

# Agregar a crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/backup-cron.sh") | crontab -

print_step "Configurando servicio systemd"
sudo tee /etc/systemd/system/naturepharma.service > /dev/null <<EOF
[Unit]
Description=NaturePharma Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/deploy.sh start
ExecStop=$PROJECT_DIR/deploy.sh stop
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable naturepharma.service

print_step "Configurando monitoreo de salud"
cat > health-alert.sh << 'EOF'
#!/bin/bash
cd /opt/naturepharma
if ! node healthcheck.js > /dev/null 2>&1; then
    echo "ALERTA: Algunos servicios de NaturePharma no están funcionando correctamente" | \
    mail -s "NaturePharma Health Check Failed" $EMAIL
fi
EOF

chmod +x health-alert.sh

# Agregar monitoreo cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/health-alert.sh") | crontab -

print_step "Reiniciando Docker"
sudo systemctl restart docker

# Esperar a que Docker se reinicie
sleep 5

print_step "Desplegando servicios"
./deploy.sh setup
./deploy.sh build
./deploy.sh start

print_step "Verificando instalación"
sleep 10

if ./deploy.sh status > /dev/null 2>&1; then
    print_message "✅ Instalación completada exitosamente"
else
    print_warning "⚠️  Algunos servicios pueden no estar funcionando correctamente"
fi

print_step "Información de acceso"
echo -e "\n${GREEN}🎉 NaturePharma instalado correctamente!${NC}\n"
echo -e "${BLUE}URLs de acceso:${NC}"
echo "  • Aplicación principal: http://$DOMAIN"
echo "  • phpMyAdmin: http://$DOMAIN:8080"
echo "  • API Auth: http://$DOMAIN/api/auth"
echo "  • API Calendar: http://$DOMAIN/api/calendar"
echo "  • API Laboratorio: http://$DOMAIN/api/laboratorio"
echo "  • API Solicitudes: http://$DOMAIN/api/solicitudes"

echo -e "\n${BLUE}Comandos útiles:${NC}"
echo "  • Ver estado: cd $PROJECT_DIR && ./deploy.sh status"
echo "  • Ver logs: cd $PROJECT_DIR && ./deploy.sh logs"
echo "  • Actualizar: cd $PROJECT_DIR && ./deploy.sh update"
echo "  • Health check: cd $PROJECT_DIR && node healthcheck.js"
echo "  • Backup: cd $PROJECT_DIR && ./deploy.sh backup"

echo -e "\n${YELLOW}Notas importantes:${NC}"
echo "  • Reinicia tu sesión para aplicar los cambios de grupo de Docker"
echo "  • Configura las variables de entorno en $PROJECT_DIR/.env según tus necesidades"
echo "  • Los backups automáticos se ejecutan diariamente a las 2 AM"
echo "  • El monitoreo de salud se ejecuta cada 5 minutos"

if [ "$DOMAIN" != "localhost" ]; then
    echo "  • Asegúrate de que tu dominio $DOMAIN apunte a esta IP"
fi

print_message "\n¡Instalación completada! 🚀"
print_warning "Se recomienda reiniciar la sesión para aplicar todos los cambios."

exit 0