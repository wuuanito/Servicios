const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/sequelize');

const AuditoriaAcciones = sequelize.define('AuditoriaAcciones', {
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
  usuario: {
    type: DataTypes.STRING(255),
    allowNull: false,
    comment: 'Usuario que realizó la acción'
  },
  accion: {
    type: DataTypes.ENUM(
      'crear_solicitud',
      'actualizar_solicitud', 
      'cambiar_estado',
      'mover_departamento',
      'agregar_comentario',
      'subir_archivo',
      'eliminar_archivo',
      'crear_necesidad',
      'completar_necesidad',
      'finalizar_solicitud',
      'enviar_email',
      'ver_solicitud',
      'descargar_archivo'
    ),
    allowNull: false,
    comment: 'Tipo de acción realizada'
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Descripción detallada de la acción'
  },
  datos_anteriores: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Estado anterior de los datos (para cambios)'
  },
  datos_nuevos: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Estado nuevo de los datos (para cambios)'
  },
  ip_address: {
    type: DataTypes.STRING(45),
    allowNull: true,
    comment: 'Dirección IP del usuario'
  },
  user_agent: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'User agent del navegador'
  },
  fecha_accion: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    comment: 'Fecha y hora de la acción'
  },
  metadata: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Información adicional sobre la acción'
  }
}, {
  tableName: 'auditoria_acciones',
  timestamps: false,
  indexes: [
    {
      fields: ['solicitud_id']
    },
    {
      fields: ['usuario']
    },
    {
      fields: ['accion']
    },
    {
      fields: ['fecha_accion']
    },
    {
      fields: ['solicitud_id', 'fecha_accion']
    }
  ]
});

// Métodos estáticos para registrar acciones
AuditoriaAcciones.registrarAccion = async function({
  solicitud_id,
  usuario,
  accion,
  descripcion = null,
  datos_anteriores = null,
  datos_nuevos = null,
  ip_address = null,
  user_agent = null,
  metadata = null
}) {
  try {
    return await this.create({
      solicitud_id,
      usuario,
      accion,
      descripcion,
      datos_anteriores,
      datos_nuevos,
      ip_address,
      user_agent,
      metadata,
      fecha_accion: new Date()
    });
  } catch (error) {
    console.error('Error registrando acción de auditoría:', error);
    throw error;
  }
};

// Obtener historial de auditoría para una solicitud
AuditoriaAcciones.obtenerHistorialSolicitud = async function(solicitud_id, opciones = {}) {
  const { limite = 50, offset = 0, accion = null } = opciones;
  
  const whereClause = { solicitud_id };
  if (accion) {
    whereClause.accion = accion;
  }
  
  return await this.findAll({
    where: whereClause,
    order: [['fecha_accion', 'DESC']],
    limit: limite,
    offset: offset
  });
};

// Obtener estadísticas de auditoría
AuditoriaAcciones.obtenerEstadisticas = async function(filtros = {}) {
  const { fecha_desde, fecha_hasta, usuario, accion } = filtros;
  
  const whereClause = {};
  
  if (fecha_desde && fecha_hasta) {
    whereClause.fecha_accion = {
      [sequelize.Sequelize.Op.between]: [new Date(fecha_desde), new Date(fecha_hasta)]
    };
  }
  
  if (usuario) {
    whereClause.usuario = usuario;
  }
  
  if (accion) {
    whereClause.accion = accion;
  }
  
  const [totalAcciones, accionesPorTipo, accionesPorUsuario] = await Promise.all([
    this.count({ where: whereClause }),
    this.findAll({
      where: whereClause,
      attributes: [
        'accion',
        [sequelize.fn('COUNT', sequelize.col('id')), 'cantidad']
      ],
      group: ['accion'],
      raw: true
    }),
    this.findAll({
      where: whereClause,
      attributes: [
        'usuario',
        [sequelize.fn('COUNT', sequelize.col('id')), 'cantidad']
      ],
      group: ['usuario'],
      order: [[sequelize.fn('COUNT', sequelize.col('id')), 'DESC']],
      limit: 10,
      raw: true
    })
  ]);
  
  return {
    totalAcciones,
    accionesPorTipo,
    accionesPorUsuario
  };
};

module.exports = AuditoriaAcciones;