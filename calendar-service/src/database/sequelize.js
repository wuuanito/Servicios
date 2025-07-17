const { Sequelize } = require('sequelize');
require('dotenv').config(); // Asegúrate que las variables de entorno estén cargadas

const sequelize = new Sequelize(
  process.env.DB_NAME || 'calendar_service_db', // Database name
  process.env.DB_USER || 'naturepharma', // Username
  process.env.DB_PASSWORD || 'Root123!', // Password
  {
    host: process.env.DB_HOST || '192.168.20.158',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: process.env.NODE_ENV === 'development' ? console.log : false, // Log queries en desarrollo
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true, // Habilita createdAt y updatedAt por defecto
      underscored: true, // Usa snake_case para nombres de columnas generados automáticamente
    }
  }
);
module.exports = sequelize;