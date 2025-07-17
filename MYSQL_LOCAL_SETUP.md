# Configuración de MySQL Local para NaturePharma

## 📋 Descripción

Esta guía te ayudará a configurar MySQL local en lugar de usar el contenedor Docker para el sistema NaturePharma.

## 🔧 Instalación de MySQL

### Windows

1. **Descargar MySQL**:
   - Ir a [MySQL Downloads](https://dev.mysql.com/downloads/mysql/)
   - Descargar MySQL Community Server
   - Ejecutar el instalador

2. **Configuración durante la instalación**:
   - Elegir "Server only" o "Developer Default"
   - Configurar puerto: `3306` (por defecto)
   - Configurar contraseña root: `Root123!`
   - Crear usuario: `naturepharma` con contraseña: `Root123!`

### Ubuntu/Linux

```bash
# Actualizar repositorios
sudo apt update

# Instalar MySQL Server
sudo apt install mysql-server

# Configurar MySQL
sudo mysql_secure_installation

# Acceder a MySQL como root
sudo mysql

# Configurar contraseña root
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Root123!';

# Crear usuario naturepharma
CREATE USER 'naturepharma'@'localhost' IDENTIFIED BY 'Root123!';
GRANT ALL PRIVILEGES ON *.* TO 'naturepharma'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;

exit
```

### macOS

```bash
# Instalar usando Homebrew
brew install mysql

# Iniciar MySQL
brew services start mysql

# Configurar MySQL
mysql_secure_installation

# Acceder a MySQL
mysql -u root -p

# Crear usuario naturepharma
CREATE USER 'naturepharma'@'localhost' IDENTIFIED BY 'Root123!';
GRANT ALL PRIVILEGES ON *.* TO 'naturepharma'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;

exit
```

## 🗄️ Creación de Bases de Datos

Una vez instalado MySQL, crear las bases de datos necesarias:

```sql
-- Conectar a MySQL
mysql -u naturepharma -pRoot123!

-- Crear bases de datos
CREATE DATABASE IF NOT EXISTS naturepharma_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS auth_service_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS calendar_service_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS laboratorio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS sistema_solicitudes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Verificar bases de datos creadas
SHOW DATABASES;

exit
```

## ⚙️ Configuración de Variables de Entorno

Asegúrate de que tu archivo `.env` tenga las siguientes configuraciones:

```env
# Base de datos
DB_HOST=localhost
DB_PORT=3306
DB_USER=naturepharma
DB_PASSWORD=Root123!
MYSQL_ROOT_PASSWORD=Root123!

# Otras configuraciones...
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=24h
GMAIL_USER=tu_email@gmail.com
GMAIL_APP_PASSWORD=tu_app_password
```

## 🚀 Inicialización de Datos

Puedes ejecutar los scripts de inicialización manualmente:

```bash
# Ejecutar script de inicialización principal
mysql -u naturepharma -pRoot123! < database/init/01-create-databases.sql

# Ejecutar script específico del laboratorio
mysql -u naturepharma -pRoot123! laboratorio_db < laboratorio-service/scripts/init-mysql.sql

# Ejecutar script de solicitudes
mysql -u naturepharma -pRoot123! sistema_solicitudes < ServicioSolicitudesOt/database/init.sql
```

## 🔍 Verificación

### Verificar que MySQL está corriendo

**Windows:**
```cmd
# Verificar servicio
sc query MySQL80

# O verificar puerto
netstat -an | findstr :3306
```

**Linux/macOS:**
```bash
# Verificar servicio
sudo systemctl status mysql

# O verificar puerto
netstat -tlnp | grep :3306
```

### Verificar conexión

```bash
# Conectar a MySQL
mysql -h localhost -u naturepharma -pRoot123!

# Verificar bases de datos
SHOW DATABASES;

# Verificar usuario
SELECT user, host FROM mysql.user WHERE user = 'naturepharma';
```

## 🛠️ Comandos Útiles

### Backup y Restore

```bash
# Crear backup
mysqldump -h localhost -u naturepharma -pRoot123! --all-databases > backup.sql

# Restaurar backup
mysql -h localhost -u naturepharma -pRoot123! < backup.sql

# Backup de una base específica
mysqldump -h localhost -u naturepharma -pRoot123! naturepharma_db > naturepharma_backup.sql
```

### Gestión del Servicio

**Windows:**
```cmd
# Iniciar servicio
net start MySQL80

# Detener servicio
net stop MySQL80

# Reiniciar servicio
net stop MySQL80 && net start MySQL80
```

**Linux:**
```bash
# Iniciar servicio
sudo systemctl start mysql

# Detener servicio
sudo systemctl stop mysql

# Reiniciar servicio
sudo systemctl restart mysql

# Habilitar inicio automático
sudo systemctl enable mysql
```

**macOS:**
```bash
# Iniciar servicio
brew services start mysql

# Detener servicio
brew services stop mysql

# Reiniciar servicio
brew services restart mysql
```

## 🔧 Solución de Problemas

### Error de conexión

1. **Verificar que MySQL esté corriendo**:
   ```bash
   # Windows
   sc query MySQL80
   
   # Linux
   sudo systemctl status mysql
   
   # macOS
   brew services list | grep mysql
   ```

2. **Verificar puerto 3306**:
   ```bash
   netstat -tlnp | grep :3306
   ```

3. **Verificar credenciales**:
   ```bash
   mysql -h localhost -u naturepharma -pRoot123!
   ```

### Error de permisos

```sql
-- Conectar como root
mysql -u root -pRoot123!

-- Otorgar permisos completos
GRANT ALL PRIVILEGES ON *.* TO 'naturepharma'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

### Resetear contraseña root

**Si olvidaste la contraseña root:**

1. Detener MySQL
2. Iniciar en modo seguro
3. Cambiar contraseña
4. Reiniciar normalmente

```bash
# Linux
sudo systemctl stop mysql
sudo mysqld_safe --skip-grant-tables &
mysql -u root

# En MySQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root123!';
exit

# Reiniciar MySQL normalmente
sudo systemctl restart mysql
```

## 📝 Notas Importantes

1. **Seguridad**: La contraseña `Root123!` es para desarrollo. En producción usa contraseñas más seguras.

2. **Firewall**: Asegúrate de que el puerto 3306 esté abierto si necesitas acceso remoto.

3. **Backup**: Configura backups automáticos para datos importantes.

4. **Logs**: Los logs de MySQL están en:
   - Windows: `C:\ProgramData\MySQL\MySQL Server 8.0\Data\`
   - Linux: `/var/log/mysql/`
   - macOS: `/usr/local/var/mysql/`

5. **Configuración**: El archivo de configuración está en:
   - Windows: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
   - Linux: `/etc/mysql/mysql.conf.d/mysqld.cnf`
   - macOS: `/usr/local/etc/my.cnf`

---

**¡Tu MySQL local está listo para NaturePharma! 🚀**

Para más ayuda, consulta la [documentación oficial de MySQL](https://dev.mysql.com/doc/).