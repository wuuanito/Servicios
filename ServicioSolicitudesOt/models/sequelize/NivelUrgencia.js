const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const NivelUrgencia = sequelize.define('niveles_urgencia', {
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
  prioridad: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  color: {
    type: DataTypes.STRING(7),
    defaultValue: '#28a745'
  }
}, {
  tableName: 'niveles_urgencia',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

module.exports = NivelUrgencia;