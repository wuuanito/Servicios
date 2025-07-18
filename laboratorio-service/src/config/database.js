const { Sequelize } = require('sequelize');
require('dotenv').config();

// Configuración de la base de datos
const sequelize = new Sequelize(
  process.env.DB_NAME || 'laboratorio_db',
  process.env.DB_USER || 'naturepharma',
  process.env.DB_PASSWORD || 'Root123!',
  {
    host: process.env.DB_HOST || '192.168.20.158',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
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
    }
  }
);

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('📦 MySQL conectado exitosamente');
    
    // Verificar conexión a la base de datos
    const [results] = await sequelize.query('SELECT DATABASE() as db_name');
    console.log('📦 Base de datos actual:', results[0].db_name);
    
    // Verificar si las tablas existen
    const [tables] = await sequelize.query('SHOW TABLES');
    console.log('📦 Tablas existentes:', tables.map(t => Object.values(t)[0]));

    // Manejo de cierre graceful
    process.on('SIGINT', async () => {
      await sequelize.close();
      console.log('📦 Conexión MySQL cerrada debido a terminación de la aplicación');
      process.exit(0);
    });

  } catch (error) {
    console.error('❌ Error conectando a MySQL:', error.message);
    console.error('❌ Stack trace:', error.stack);
    process.exit(1);
  }
};

module.exports = { connectDB, sequelize };