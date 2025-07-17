-- Crear base de datos
CREATE DATABASE IF NOT EXISTS sistema_solicitudes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_solicitudes;

-- Tabla de departamentos
CREATE TABLE IF NOT EXISTS departamentos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de estados de solicitud
CREATE TABLE IF NOT EXISTS estados_solicitud (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    color VARCHAR(7) DEFAULT '#007bff',
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de niveles de urgencia
CREATE TABLE IF NOT EXISTS niveles_urgencia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    prioridad INT NOT NULL,
    color VARCHAR(7) DEFAULT '#28a745',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla principal de solicitudes
CREATE TABLE IF NOT EXISTS solicitudes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_solicitud VARCHAR(20) UNIQUE NOT NULL,
    nombre_solicitante VARCHAR(255) NOT NULL,
    nombre_materia_prima VARCHAR(255) NOT NULL,
    lote VARCHAR(100) NOT NULL,
    proveedor VARCHAR(255) NOT NULL,
    codigo_articulo VARCHAR(100) NOT NULL,
    comentarios TEXT,
    departamento_destino_id INT NOT NULL,
    departamento_actual_id INT NOT NULL,
    urgencia_id INT NOT NULL,
    estado_id INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    finalizada BOOLEAN DEFAULT FALSE,
    fecha_finalizacion TIMESTAMP NULL,
    created_by VARCHAR(255),
    
    FOREIGN KEY (departamento_destino_id) REFERENCES departamentos(id),
    FOREIGN KEY (departamento_actual_id) REFERENCES departamentos(id),
    FOREIGN KEY (urgencia_id) REFERENCES niveles_urgencia(id),
    FOREIGN KEY (estado_id) REFERENCES estados_solicitud(id),
    
    INDEX idx_numero_solicitud (numero_solicitud),
    INDEX idx_departamento_actual (departamento_actual_id),
    INDEX idx_estado (estado_id),
    INDEX idx_fecha_creacion (fecha_creacion),
    INDEX idx_finalizada (finalizada)
);

-- Tabla de historial de movimientos de solicitudes
CREATE TABLE IF NOT EXISTS historial_solicitudes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    solicitud_id INT NOT NULL,
    departamento_origen_id INT,
    departamento_destino_id INT NOT NULL,
    estado_anterior_id INT,
    estado_nuevo_id INT NOT NULL,
    comentario TEXT,
    usuario VARCHAR(255),
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (solicitud_id) REFERENCES solicitudes(id) ON DELETE CASCADE,
    FOREIGN KEY (departamento_origen_id) REFERENCES departamentos(id),
    FOREIGN KEY (departamento_destino_id) REFERENCES departamentos(id),
    FOREIGN KEY (estado_anterior_id) REFERENCES estados_solicitud(id),
    FOREIGN KEY (estado_nuevo_id) REFERENCES estados_solicitud(id),
    
    INDEX idx_solicitud_id (solicitud_id),
    INDEX idx_fecha_movimiento (fecha_movimiento)
);

-- Tabla de necesidades (cuando almacén envía a laboratorio)
CREATE TABLE IF NOT EXISTS necesidades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    solicitud_id INT NOT NULL,
    descripcion TEXT NOT NULL,
    tipo_analisis VARCHAR(255),
    parametros_requeridos TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_completada TIMESTAMP NULL,
    completada BOOLEAN DEFAULT FALSE,
    resultado TEXT,
    observaciones TEXT,
    created_by VARCHAR(255),
    
    FOREIGN KEY (solicitud_id) REFERENCES solicitudes(id) ON DELETE CASCADE,
    
    INDEX idx_solicitud_id (solicitud_id),
    INDEX idx_completada (completada)
);

-- Tabla de archivos adjuntos
CREATE TABLE IF NOT EXISTS archivos_adjuntos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    solicitud_id INT,
    necesidad_id INT,
    nombre_original VARCHAR(255) NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    tipo_mime VARCHAR(100) NOT NULL,
    tamaño INT NOT NULL,
    tipo_adjunto ENUM('solicitud', 'necesidad', 'resultado') DEFAULT 'solicitud',
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(255),
    
    FOREIGN KEY (solicitud_id) REFERENCES solicitudes(id) ON DELETE CASCADE,
    FOREIGN KEY (necesidad_id) REFERENCES necesidades(id) ON DELETE CASCADE,
    
    INDEX idx_solicitud_id (solicitud_id),
    INDEX idx_necesidad_id (necesidad_id),
    INDEX idx_tipo_adjunto (tipo_adjunto)
);

-- Insertar datos iniciales

-- Departamentos
INSERT INTO departamentos (nombre, descripcion) VALUES 
('Expediciones', 'Departamento de expediciones y envíos'),
('Almacén', 'Departamento de almacén y gestión de inventario'),
('Laboratorio', 'Departamento de análisis y control de calidad'),
('Oficina Técnica', 'Departamento de oficina técnica y diseño');

-- Estados de solicitud
INSERT INTO estados_solicitud (nombre, descripcion, color) VALUES 
('Pendiente', 'Solicitud creada, pendiente de procesamiento', '#ffc107'),
('En Proceso', 'Solicitud siendo procesada', '#007bff'),
('En Laboratorio', 'Solicitud enviada a laboratorio para análisis', '#17a2b8'),
('Completada', 'Solicitud completada exitosamente', '#28a745'),
('Rechazada', 'Solicitud rechazada', '#dc3545'),
('Esperando Resultado', 'Esperando resultado de laboratorio', '#6f42c1'),
('Enviada a Almacén', 'Solicitud enviada al departamento de almacén', '#fd7e14'),
('Enviada a Expediciones', 'Solicitud enviada al departamento de expediciones', '#20c997'),
('Devuelto a Oficina Técnica', 'Solicitud devuelta al departamento de oficina técnica', '#6c757d');

-- Niveles de urgencia
INSERT INTO niveles_urgencia (nombre, descripcion, prioridad, color) VALUES 
('Baja', 'Urgencia baja - No crítica', 1, '#28a745'),
('Media', 'Urgencia media - Importante', 2, '#ffc107'),
('Alta', 'Urgencia alta - Crítica', 3, '#fd7e14'),
('Crítica', 'Urgencia crítica - Inmediata', 4, '#dc3545');

-- Crear función para generar número de solicitud
DELIMITER //
CREATE FUNCTION IF NOT EXISTS generar_numero_solicitud() 
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE nuevo_numero VARCHAR(20);
    DECLARE contador INT;
    
    SELECT COUNT(*) + 1 INTO contador FROM solicitudes WHERE DATE(fecha_creacion) = CURDATE();
    
    SET nuevo_numero = CONCAT('SOL-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(contador, 4, '0'));
    
    RETURN nuevo_numero;
END//
DELIMITER ;

-- Trigger para asignar número de solicitud automáticamente
DELIMITER //
CREATE TRIGGER IF NOT EXISTS before_insert_solicitud
BEFORE INSERT ON solicitudes
FOR EACH ROW
BEGIN
    IF NEW.numero_solicitud IS NULL OR NEW.numero_solicitud = '' THEN
        SET NEW.numero_solicitud = generar_numero_solicitud();
    END IF;
END//
DELIMITER ;

-- Trigger para registrar historial automáticamente
DELIMITER //
CREATE TRIGGER IF NOT EXISTS after_insert_solicitud
AFTER INSERT ON solicitudes
FOR EACH ROW
BEGIN
    INSERT INTO historial_solicitudes (
        solicitud_id, 
        departamento_destino_id, 
        estado_nuevo_id, 
        comentario, 
        usuario
    ) VALUES (
        NEW.id, 
        NEW.departamento_actual_id, 
        NEW.estado_id, 
        'Solicitud creada', 
        NEW.created_by
    );
END//
DELIMITER ;

-- Trigger para registrar cambios en el historial
DELIMITER //
CREATE TRIGGER IF NOT EXISTS after_update_solicitud
AFTER UPDATE ON solicitudes
FOR EACH ROW
BEGIN
    IF OLD.departamento_actual_id != NEW.departamento_actual_id OR OLD.estado_id != NEW.estado_id THEN
        INSERT INTO historial_solicitudes (
            solicitud_id, 
            departamento_origen_id, 
            departamento_destino_id, 
            estado_anterior_id, 
            estado_nuevo_id, 
            comentario
        ) VALUES (
            NEW.id, 
            OLD.departamento_actual_id, 
            NEW.departamento_actual_id, 
            OLD.estado_id, 
            NEW.estado_id, 
            'Solicitud actualizada'
        );
    END IF;
END//
DELIMITER ;