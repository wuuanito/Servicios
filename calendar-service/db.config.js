require('dotenv').config();

module.exports = {
  development: {
    username: process.env.DB_USER || 'naturepharma',
    password: process.env.DB_PASSWORD || 'Root123!',
    database: process.env.DB_NAME || 'calendar_service_db',
    host: process.env.DB_HOST || '192.168.20.158',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: console.log
  },
  test: {
    username: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'Root123!',
    database: process.env.DB_NAME_TEST || 'calendar_service_test',
    host: process.env.DB_HOST || '192.168.20.158',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: false
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: false
  }
};