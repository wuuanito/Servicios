const { connectDB } = require('./src/config/database');
const { syncModels } = require('./src/models');

// Script para sincronizar la base de datos y crear las tablas
const syncDatabase = async () => {
  try {
    console.log('🔄 Iniciando sincronización de base de datos...');
    
    // Conectar a la base de datos
    await connectDB();
    
    // Sincronizar modelos con force: true para recrear las tablas
    console.log('📋 Creando/actualizando tablas...');
    await syncModels({ 
      force: false, // Cambiar a true si quieres recrear las tablas
      alter: true   // Actualizar estructura de tablas existentes
    });
    
    console.log('✅ Base de datos sincronizada exitosamente');
    console.log('🎯 Las tablas Defectos y tareas han sido creadas/actualizadas');
    
    // Verificar que las tablas existen
    const { sequelize } = require('./src/config/database');
    const [tables] = await sequelize.query("SHOW TABLES");
    console.log('📊 Tablas disponibles en la base de datos:');
    tables.forEach(table => {
      console.log(`  - ${Object.values(table)[0]}`);
    });
    
    // Verificar estructura de la tabla Defectos
    console.log('\n🔍 Estructura de la tabla Defectos:');
    const [defectosStructure] = await sequelize.query("DESCRIBE Defectos");
    defectosStructure.forEach(column => {
      console.log(`  - ${column.Field}: ${column.Type} ${column.Null === 'NO' ? '(NOT NULL)' : '(NULL)'} ${column.Key ? `[${column.Key}]` : ''}`);
    });
    
    // Verificar estructura de la tabla tareas
    console.log('\n🔍 Estructura de la tabla tareas:');
    const [tareasStructure] = await sequelize.query("DESCRIBE tareas");
    tareasStructure.forEach(column => {
      console.log(`  - ${column.Field}: ${column.Type} ${column.Null === 'NO' ? '(NOT NULL)' : '(NULL)'} ${column.Key ? `[${column.Key}]` : ''}`);
    });
    
    console.log('\n🎉 Sincronización completada exitosamente');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error durante la sincronización:', error.message);
    console.error('📋 Stack trace:', error.stack);
    process.exit(1);
  }
};

// Ejecutar sincronización
syncDatabase();