// config/database.js
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('osmosis_logs', 'root', 'root', {
  host: 'localhost',
  dialect: 'mysql',
  port:3050,
  define: {
    timestamps: true
  },
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  logging: false
});

module.exports = sequelize;