const { sequelize } = require('../config/database');
const Defecto = require('./Defecto');
const Tarea = require('./Tarea');

// Importar todos los modelos
const models = {
  Defecto,
  Tarea
};

// Configurar asociaciones si las hay
// (Actualmente no hay asociaciones entre Defecto y Tarea)

// Función para sincronizar todos los modelos
const syncModels = async (options = {}) => {
  try {
    console.log('🔄 Sincronizando modelos con la base de datos...');
    
    // Sincronizar modelos
    await sequelize.sync(options);
    
    console.log('✅ Modelos sincronizados exitosamente');
    
    // Verificar que las tablas existen
    const [tables] = await sequelize.query("SHOW TABLES");
    console.log('📋 Tablas disponibles:', tables.map(t => Object.values(t)[0]));
    
  } catch (error) {
    console.error('❌ Error sincronizando modelos:', error.message);
    throw error;
  }
};

module.exports = {
  sequelize,
  models,
  syncModels,
  ...models
};