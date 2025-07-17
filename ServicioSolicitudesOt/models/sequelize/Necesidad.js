const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const Necesidad = sequelize.define('necesidades', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  solicitud_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'solicitudes',
      key: 'id'
    }
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  tipo_analisis: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  parametros_requeridos: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  fecha_creacion: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  fecha_completada: {
    type: DataTypes.DATE,
    allowNull: true
  },
  completada: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  resultado: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  observaciones: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  created_by: {
    type: DataTypes.STRING(255),
    allowNull: true
  }
}, {
  tableName: 'necesidades',
  timestamps: false,
  indexes: [
    {
      fields: ['solicitud_id']
    },
    {
      fields: ['completada']
    }
  ]
});

module.exports = Necesidad;