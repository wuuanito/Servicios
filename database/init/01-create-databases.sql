-- Script de inicialización para crear todas las bases de datos necesarias
-- Este script se ejecuta automáticamente cuando se inicia el contenedor MySQL

-- Crear base de datos para auth-service
CREATE DATABASE IF NOT EXISTS auth_service_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para calendar-service
CREATE DATABASE IF NOT EXISTS calendar_service_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para laboratorio-service
CREATE DATABASE IF NOT EXISTS laboratorio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear base de datos para solicitudes-service
CREATE DATABASE IF NOT EXISTS sistema_solicitudes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Otorgar permisos al usuario naturepharma en todas las bases de datos
GRANT ALL PRIVILEGES ON auth_service_db.* TO 'naturepharma'@'localhost';
GRANT ALL PRIVILEGES ON calendar_service_db.* TO 'naturepharma'@'localhost';
GRANT ALL PRIVILEGES ON laboratorio_db.* TO 'naturepharma'@'localhost';
GRANT ALL PRIVILEGES ON sistema_solicitudes.* TO 'naturepharma'@'localhost';

-- Aplicar los cambios
FLUSH PRIVILEGES;

-- Mostrar las bases de datos creadas
SHOW DATABASES;

SELECT 'Bases de datos inicializadas correctamente para NaturePharma' AS mensaje;