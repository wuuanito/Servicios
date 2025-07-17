const { Sequelize } = require('sequelize');
require('dotenv').config(); // Asegúrate que las variables de entorno estén cargadas

const sequelize = new Sequelize(
  'calendar_service_db', // Database name
  'naturepharma', // Username
  'root', // Password
  {
    host: 'localhost',
    port: 3306,
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