const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const HistorialSolicitud = sequelize.define('historial_solicitudes', {
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
  departamento_origen_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'departamentos',
      key: 'id'
    }
  },
  departamento_destino_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'departamentos',
      key: 'id'
    }
  },
  estado_anterior_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'estados_solicitud',
      key: 'id'
    }
  },
  estado_nuevo_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'estados_solicitud',
      key: 'id'
    }
  },
  comentario: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  usuario: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  fecha_movimiento: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'historial_solicitudes',
  timestamps: false,
  indexes: [
    {
      fields: ['solicitud_id']
    },
    {
      fields: ['fecha_movimiento']
    }
  ]
});

module.exports = HistorialSolicitud;