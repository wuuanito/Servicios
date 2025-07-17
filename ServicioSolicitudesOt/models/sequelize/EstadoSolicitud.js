const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const EstadoSolicitud = sequelize.define('estados_solicitud', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  nombre: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  color: {
    type: DataTypes.STRING(7),
    defaultValue: '#007bff'
  },
  activo: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  tableName: 'estados_solicitud',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

module.exports = EstadoSolicitud;