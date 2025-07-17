const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const ChatMensaje = sequelize.define('ChatMensaje', {
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
  usuario_id: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'ID del usuario que envía el mensaje'
  },
  usuario_nombre: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Nombre del usuario que envía el mensaje'
  },
  mensaje: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 1000]
    }
  },
  tipo: {
    type: DataTypes.ENUM('mensaje', 'sistema', 'archivo'),
    defaultValue: 'mensaje',
    comment: 'Tipo de mensaje: mensaje normal, notificación del sistema o archivo adjunto'
  },
  archivo_url: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'URL del archivo adjunto si el tipo es archivo'
  },
  archivo_nombre: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Nombre original del archivo adjunto'
  },
  leido_por: {
    type: DataTypes.JSON,
    defaultValue: [],
    comment: 'Array de IDs de usuarios que han leído el mensaje'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'chat_mensajes',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      fields: ['solicitud_id']
    },
    {
      fields: ['usuario_id']
    },
    {
      fields: ['created_at']
    }
  ]
});

module.exports = ChatMensaje;