const { Sequelize } = require('sequelize');
require('dotenv').config();

// Configuración de Sequelize
const sequelize = new Sequelize(
  process.env.DB_NAME || 'sistema_solicitudes',
  process.env.DB_USER || 'naturepharma',
  process.env.DB_PASSWORD || 'Root123!',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: console.log, // Cambiar a false en producción
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: false,
      freezeTableName: true
    },
    timezone: '-05:00' // Ajustar según tu zona horaria
  }
);

// Función para probar la conexión
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Conexión a MySQL con Sequelize establecida correctamente');
    return true;
  } catch (error) {
    console.error('❌ Error conectando a MySQL con Sequelize:', error.message);
    return false;
  }
};

// Función para sincronizar la base de datos
const syncDatabase = async (force = false) => {
  try {
    await sequelize.sync({ force, alter: !force });
    console.log('✅ Base de datos sincronizada correctamente');
    return true;
  } catch (error) {
    console.error('❌ Error sincronizando la base de dats:', error.message);
    return false;
  }
};

module.exports = {
  sequelize,
  testConnection,
  syncDatabase
};