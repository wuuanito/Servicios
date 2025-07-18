const mysql = require('mysql2/promise');
require('dotenv').config();

// Script para probar la conexión a la base de datos y crear tablas si es necesario
const testConnection = async () => {
  let connection;
  
  try {
    console.log('🔍 Probando conexión a la base de datos...');
    console.log('📋 Configuración:');
    console.log(`   Host: ${process.env.DB_HOST || '192.168.20.158'}`);
    console.log(`   Puerto: ${process.env.DB_PORT || 3306}`);
    console.log(`   Base de datos: ${process.env.DB_NAME || 'laboratorio_db'}`);
    console.log(`   Usuario: ${process.env.DB_USER || 'naturepharma'}`);
    
    // Crear conexión
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || '192.168.20.158',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'naturepharma',
      password: process.env.DB_PASSWORD || 'Root123!',
      database: process.env.DB_NAME || 'laboratorio_db'
    });
    
    console.log('✅ Conexión exitosa a la base de datos');
    
    // Verificar base de datos actual
    const [dbResult] = await connection.execute('SELECT DATABASE() as current_db');
    console.log('📦 Base de datos actual:', dbResult[0].current_db);
    
    // Verificar tablas existentes
    const [tables] = await connection.execute('SHOW TABLES');
    console.log('📋 Tablas existentes:');
    if (tables.length === 0) {
      console.log('   ⚠️  No hay tablas en la base de datos');
    } else {
      tables.forEach(table => {
        console.log(`   - ${Object.values(table)[0]}`);
      });
    }
    
    // Verificar si existe la tabla Defectos
    const [defectosExists] = await connection.execute(
      "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = ? AND table_name = 'Defectos'",
      [process.env.DB_NAME || 'laboratorio_db']
    );
    
    if (defectosExists[0].count === 0) {
      console.log('❌ La tabla Defectos NO existe');
      console.log('💡 Ejecutando script de creación de tablas...');
      
      // Crear tabla Defectos
      await connection.execute(`
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
          
          INDEX idx_codigoDefecto (codigoDefecto),
          INDEX idx_tipoArticulo (tipoArticulo),
          INDEX idx_tipoDesviacion (tipoDesviacion),
          INDEX idx_decision (decision),
          INDEX idx_createdAt (createdAt),
          INDEX idx_estado (estado),
          INDEX idx_creadoPor (creadoPor)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      
      console.log('✅ Tabla Defectos creada exitosamente');
    } else {
      console.log('✅ La tabla Defectos existe');
      
      // Mostrar estructura de la tabla
      const [structure] = await connection.execute('DESCRIBE Defectos');
      console.log('📋 Estructura de la tabla Defectos:');
      structure.forEach(column => {
        console.log(`   - ${column.Field}: ${column.Type} ${column.Null === 'NO' ? '(NOT NULL)' : '(NULL)'} ${column.Key ? `[${column.Key}]` : ''}`);
      });
    }
    
    // Verificar si existe la tabla tareas
    const [tareasExists] = await connection.execute(
      "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = ? AND table_name = 'tareas'",
      [process.env.DB_NAME || 'laboratorio_db']
    );
    
    if (tareasExists[0].count === 0) {
      console.log('❌ La tabla tareas NO existe');
      console.log('💡 Creando tabla tareas...');
      
      // Crear tabla tareas
      await connection.execute(`
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
          
          INDEX idx_estado (estado),
          INDEX idx_prioridad (prioridad),
          INDEX idx_asignado (asignado),
          INDEX idx_fechaVencimiento (fechaVencimiento),
          INDEX idx_fechaCreacion (fechaCreacion)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      
      console.log('✅ Tabla tareas creada exitosamente');
    } else {
      console.log('✅ La tabla tareas existe');
    }
    
    // Verificar tablas finales
    const [finalTables] = await connection.execute('SHOW TABLES');
    console.log('\n🎯 Tablas finales en la base de datos:');
    finalTables.forEach(table => {
      console.log(`   ✅ ${Object.values(table)[0]}`);
    });
    
    console.log('\n🎉 Verificación completada exitosamente');
    
  } catch (error) {
    console.error('❌ Error durante la verificación:', error.message);
    console.error('📋 Código de error:', error.code);
    console.error('📋 Número de error:', error.errno);
    if (error.sqlMessage) {
      console.error('📋 Mensaje SQL:', error.sqlMessage);
    }
    console.error('📋 Stack trace:', error.stack);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Conexión cerrada');
    }
  }
};

// Ejecutar verificación
testConnection();