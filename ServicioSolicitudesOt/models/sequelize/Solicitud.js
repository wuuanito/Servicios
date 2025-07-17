const { DataTypes, Op } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const Solicitud = sequelize.define('solicitudes', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  numero_solicitud: {
    type: DataTypes.STRING(20),
    allowNull: true, // Permitir null inicialmente, se genera en beforeCreate
    unique: true,
    validate: {
      notEmpty: {
        msg: 'El número de solicitud no puede estar vacío'
      }
    }
  },
  nombre_solicitante: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  nombre_materia_prima: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  lote: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  proveedor: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  codigo_articulo: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  comentarios: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  departamento_destino_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'departamentos',
      key: 'id'
    }
  },
  departamento_actual_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'departamentos',
      key: 'id'
    }
  },
  urgencia_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'niveles_urgencia',
      key: 'id'
    }
  },
  estado_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'estados_solicitud',
      key: 'id'
    }
  },
  fecha_creacion: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  fecha_actualizacion: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  finalizada: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  fecha_finalizacion: {
    type: DataTypes.DATE,
    allowNull: true
  },
  created_by: {
    type: DataTypes.STRING(255),
    allowNull: true
  }
}, {
  tableName: 'solicitudes',
  timestamps: false, // Usamos nuestros propios campos de timestamp
  indexes: [
    {
      fields: ['numero_solicitud']
    },
    {
      fields: ['departamento_actual_id']
    },
    {
      fields: ['estado_id']
    },
    {
      fields: ['fecha_creacion']
    },
    {
      fields: ['finalizada']
    }
  ],
  hooks: {
    beforeCreate: async (solicitud) => {
      try {
        // Siempre generar número de solicitud si no existe
        if (!solicitud.numero_solicitud) {
          const today = new Date();
          const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
          
          // Contar solicitudes del día usando sequelize directamente
          const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
          const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
          
          const [results] = await sequelize.query(
            'SELECT COUNT(*) as count FROM solicitudes WHERE fecha_creacion >= ? AND fecha_creacion < ?',
            {
              replacements: [startOfDay, endOfDay],
              type: sequelize.QueryTypes.SELECT
            }
          );
          
          const count = parseInt(results.count) || 0;
          const contador = String(count + 1).padStart(4, '0');
          solicitud.numero_solicitud = `SOL-${dateStr}-${contador}`;
          
          console.log(`Generando número de solicitud: ${solicitud.numero_solicitud}`);
        }
      } catch (error) {
        console.error('Error generando número de solicitud:', error);
        throw new Error('Error al generar número de solicitud');
      }
    },
    beforeUpdate: (solicitud) => {
      solicitud.fecha_actualizacion = new Date();
    }
  }
});

module.exports = Solicitud;