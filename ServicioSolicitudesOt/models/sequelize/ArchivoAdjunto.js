const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const ArchivoAdjunto = sequelize.define('archivos_adjuntos', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  solicitud_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'solicitudes',
      key: 'id'
    }
  },
  necesidad_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'necesidades',
      key: 'id'
    }
  },
  nombre_original: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  nombre_archivo: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  ruta_archivo: {
    type: DataTypes.STRING(500),
    allowNull: false
  },
  tipo_mime: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  tamaño: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  tipo_adjunto: {
    type: DataTypes.ENUM('solicitud', 'necesidad', 'resultado'),
    defaultValue: 'solicitud'
  },
  fecha_subida: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  uploaded_by: {
    type: DataTypes.STRING(255),
    allowNull: true
  }
}, {
  tableName: 'archivos_adjuntos',
  timestamps: false,
  indexes: [
    {
      fields: ['solicitud_id']
    },
    {
      fields: ['necesidad_id']
    },
    {
      fields: ['tipo_adjunto']
    }
  ]
});

module.exports = ArchivoAdjunto;