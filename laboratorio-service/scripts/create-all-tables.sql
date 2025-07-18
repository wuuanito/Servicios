-- Script completo para crear todas las tablas del laboratorio-service
-- Ejecutar este script en la base de datos laboratorio_db

USE laboratorio_db;

-- Eliminar tablas si existen (opcional, comentar si no se quiere recrear)
-- DROP TABLE IF EXISTS tareas;
-- DROP TABLE IF EXISTS Defectos;

-- Crear tabla Defectos con la estructura exacta del modelo Sequelize
CREATE TABLE IF NOT EXISTS Defectos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigoDefecto VARCHAR(50) NOT NULL UNIQUE,
    tipoArticulo VARCHAR(100) NOT NULL,
    descripcionArticulo VARCHAR(500) NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    versionDefecto VARCHAR(10) NOT NULL,
    descripcionDefecto TEXT NULL,
    tipoDesviacion VARCHAR(100) NOT NULL,
    decision VARCHAR(100) NOT NULL,
    imagenFilename VARCHAR(255) NULL,
    imagenOriginalName VARCHAR(255) NULL,
    imagenMimetype VARCHAR(100) NULL,
    imagenSize INT NULL,
    observacionesAdicionales TEXT NULL,
    creadoPor VARCHAR(100) NOT NULL,
    estado ENUM('activo', 'inactivo', 'archivado') NOT NULL DEFAULT 'activo',
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Índices
    INDEX idx_codigoDefecto (codigoDefecto),
    INDEX idx_tipoArticulo (tipoArticulo),
    INDEX idx_tipoDesviacion (tipoDesviacion),
    INDEX idx_decision (decision),
    INDEX idx_createdAt (createdAt),
    INDEX idx_estado (estado),
    INDEX idx_creadoPor (creadoPor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crear tabla tareas con la estructura exacta del modelo Sequelize
CREATE TABLE IF NOT EXISTS tareas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT NULL,
    asignado VARCHAR(255) NOT NULL,
    estado ENUM('pendiente', 'en_progreso', 'completada') NOT NULL DEFAULT 'pendiente',
    prioridad ENUM('baja', 'media', 'alta') NOT NULL DEFAULT 'media',
    fechaVencimiento DATE NULL,
    fechaCreacion DATE NOT NULL,
    fechaCompletada DATETIME NULL,
    comentarios TEXT NULL,
    creadoEn DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizadoEn DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Índices
    INDEX idx_estado (estado),
    INDEX idx_prioridad (prioridad),
    INDEX idx_asignado (asignado),
    INDEX idx_fechaVencimiento (fechaVencimiento),
    INDEX idx_fechaCreacion (fechaCreacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo para Defectos
INSERT IGNORE INTO Defectos (
    codigoDefecto,
    tipoArticulo,
    descripcionArticulo,
    codigo,
    versionDefecto,
    descripcionDefecto,
    tipoDesviacion,
    decision,
    observacionesAdicionales,
    creadoPor,
    estado
) VALUES 
(
    'DEF-001',
    'Materia Prima',
    'Lote de azúcar refinada para producción de jarabe',
    'AZ-2024-001',
    '1.0',
    'Presencia de partículas extrañas en el azúcar, posibles restos de empaque',
    'Físico',
    'Rechazado',
    'Requiere análisis adicional del proveedor',
    'Juan Pérez',
    'activo'
),
(
    'DEF-002',
    'Producto Terminado',
    'Jarabe de glucosa lote JG-240115',
    'JG-240115-QC',
    '1.0',
    'Concentración de glucosa fuera del rango especificado (85-90%). Resultado: 82%',
    'Químico',
    'Reproceso',
    'Ajustar concentración mediante dilución controlada',
    'María García',
    'activo'
),
(
    'DEF-003',
    'Material de Empaque',
    'Etiquetas adhesivas para frascos de 500ml',
    'ET-500ML-001',
    '1.0',
    'Adhesivo defectuoso, las etiquetas se despegan fácilmente',
    'Físico',
    'Rechazado',
    'Contactar proveedor para reemplazo',
    'Carlos López',
    'activo'
),
(
    'DEF-004',
    'Producto Intermedio',
    'Solución base para jarabe sabor fresa',
    'SB-FRESA-024',
    '1.0',
    'Conteo de levaduras superior al límite permitido (>10 UFC/ml)',
    'Microbiológico',
    'Cuarentena',
    'Mantener en cuarentena hasta análisis adicional',
    'Ana Martínez',
    'activo'
),
(
    'DEF-005',
    'Insumo',
    'Colorante rojo carmín para productos',
    'COL-ROJO-003',
    '1.0',
    'Certificado de análisis vencido, falta documentación de trazabilidad',
    'Documental',
    'Pendiente',
    'Solicitar documentación actualizada al proveedor',
    'Roberto Silva',
    'activo'
);

-- Insertar datos de ejemplo para tareas
INSERT IGNORE INTO tareas (
    titulo,
    descripcion,
    asignado,
    estado,
    prioridad,
    fechaVencimiento,
    fechaCreacion,
    comentarios
) VALUES
(
    'Análisis de muestras Q1',
    'Realizar análisis microbiológico de las muestras del primer trimestre',
    'Dr. María González',
    'pendiente',
    'alta',
    '2024-02-15',
    CURDATE(),
    'Urgente para cliente prioritario'
),
(
    'Calibración de equipos',
    'Calibrar espectrofotómetro y balanza analítica',
    'Ing. Carlos Ruiz',
    'en_progreso',
    'media',
    '2024-02-12',
    CURDATE(),
    'Programado para mantenimiento semanal'
),
(
    'Reporte mensual de calidad',
    'Generar reporte de control de calidad del mes anterior',
    'Lic. Ana Pérez',
    'completada',
    'baja',
    '2024-02-05',
    CURDATE(),
    'Completado según cronograma'
),
(
    'Validación de método analítico',
    'Validar nuevo método para determinación de principio activo',
    'Dr. Luis Martínez',
    'pendiente',
    'alta',
    '2024-02-20',
    CURDATE(),
    'Método crítico para nuevos productos'
),
(
    'Mantenimiento preventivo HPLC',
    'Realizar mantenimiento preventivo del equipo HPLC',
    'Téc. Sandra López',
    'pendiente',
    'media',
    '2024-02-18',
    CURDATE(),
    'Incluir cambio de columna'
);

-- Verificar creación de tablas
SELECT 'Tablas creadas exitosamente' AS mensaje;
SELECT TABLE_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'laboratorio_db' 
AND TABLE_NAME IN ('Defectos', 'tareas');

-- Mostrar estadísticas
SELECT 'Estadísticas de Defectos' AS seccion;
SELECT COUNT(*) AS total_defectos FROM Defectos;
SELECT decision, COUNT(*) AS cantidad FROM Defectos GROUP BY decision;
SELECT tipoDesviacion, COUNT(*) AS cantidad FROM Defectos GROUP BY tipoDesviacion;

SELECT 'Estadísticas de Tareas' AS seccion;
SELECT COUNT(*) AS total_tareas FROM tareas;
SELECT estado, COUNT(*) AS cantidad FROM tareas GROUP BY estado;
SELECT prioridad, COUNT(*) AS cantidad FROM tareas GROUP BY prioridad;