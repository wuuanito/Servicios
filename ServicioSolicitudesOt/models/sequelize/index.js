const { sequelize } = require('../../config/sequelize');

// Importar todos los modelos
const Departamento = require('./Departamento');
const EstadoSolicitud = require('./EstadoSolicitud');
const NivelUrgencia = require('./NivelUrgencia');
const Solicitud = require('./Solicitud');
const HistorialSolicitud = require('./HistorialSolicitud');
const Necesidad = require('./Necesidad');
const ArchivoAdjunto = require('./ArchivoAdjunto');
const ChatMensaje = require('./ChatMensaje');
const AuditoriaAcciones = require('./AuditoriaAcciones');

// Definir relaciones

// Solicitud pertenece a Departamento (destino y actual)
Solicitud.belongsTo(Departamento, {
  foreignKey: 'departamento_destino_id',
  as: 'departamentoDestino'
});

Solicitud.belongsTo(Departamento, {
  foreignKey: 'departamento_actual_id',
  as: 'departamentoActual'
});

// Solicitud pertenece a NivelUrgencia
Solicitud.belongsTo(NivelUrgencia, {
  foreignKey: 'urgencia_id',
  as: 'urgencia'
});

// Solicitud pertenece a EstadoSolicitud
Solicitud.belongsTo(EstadoSolicitud, {
  foreignKey: 'estado_id',
  as: 'estado'
});

// Departamento tiene muchas solicitudes
Departamento.hasMany(Solicitud, {
  foreignKey: 'departamento_destino_id',
  as: 'solicitudesDestino'
});

Departamento.hasMany(Solicitud, {
  foreignKey: 'departamento_actual_id',
  as: 'solicitudesActuales'
});

// NivelUrgencia tiene muchas solicitudes
NivelUrgencia.hasMany(Solicitud, {
  foreignKey: 'urgencia_id',
  as: 'solicitudes'
});

// EstadoSolicitud tiene muchas solicitudes
EstadoSolicitud.hasMany(Solicitud, {
  foreignKey: 'estado_id',
  as: 'solicitudes'
});

// HistorialSolicitud pertenece a Solicitud
HistorialSolicitud.belongsTo(Solicitud, {
  foreignKey: 'solicitud_id',
  as: 'solicitud'
});

// HistorialSolicitud pertenece a Departamentos
HistorialSolicitud.belongsTo(Departamento, {
  foreignKey: 'departamento_origen_id',
  as: 'departamentoOrigen'
});

HistorialSolicitud.belongsTo(Departamento, {
  foreignKey: 'departamento_destino_id',
  as: 'departamentoDestino'
});

// HistorialSolicitud pertenece a EstadoSolicitud
HistorialSolicitud.belongsTo(EstadoSolicitud, {
  foreignKey: 'estado_anterior_id',
  as: 'estadoAnterior'
});

HistorialSolicitud.belongsTo(EstadoSolicitud, {
  foreignKey: 'estado_nuevo_id',
  as: 'estadoNuevo'
});

// Solicitud tiene muchos historiales
Solicitud.hasMany(HistorialSolicitud, {
  foreignKey: 'solicitud_id',
  as: 'historial'
});

// Necesidad pertenece a Solicitud
Necesidad.belongsTo(Solicitud, {
  foreignKey: 'solicitud_id',
  as: 'solicitud'
});

// Solicitud tiene muchas necesidades
Solicitud.hasMany(Necesidad, {
  foreignKey: 'solicitud_id',
  as: 'necesidades'
});

// ArchivoAdjunto pertenece a Solicitud y Necesidad
ArchivoAdjunto.belongsTo(Solicitud, {
  foreignKey: 'solicitud_id',
  as: 'solicitud'
});

ArchivoAdjunto.belongsTo(Necesidad, {
  foreignKey: 'necesidad_id',
  as: 'necesidad'
});

// Solicitud y Necesidad tienen muchos archivos adjuntos
Solicitud.hasMany(ArchivoAdjunto, {
  foreignKey: 'solicitud_id',
  as: 'archivos'
});

Necesidad.hasMany(ArchivoAdjunto, {
  foreignKey: 'necesidad_id',
  as: 'archivos'
});

// ChatMensaje pertenece a Solicitud
ChatMensaje.belongsTo(Solicitud, {
  foreignKey: 'solicitud_id',
  as: 'solicitud'
});

// Solicitud tiene muchos mensajes de chat
Solicitud.hasMany(ChatMensaje, {
  foreignKey: 'solicitud_id',
  as: 'mensajes'
});

// AuditoriaAcciones pertenece a Solicitud
AuditoriaAcciones.belongsTo(Solicitud, {
  foreignKey: 'solicitud_id',
  as: 'solicitud'
});

// Solicitud tiene muchas acciones de auditoría
Solicitud.hasMany(AuditoriaAcciones, {
  foreignKey: 'solicitud_id',
  as: 'auditoria'
});

// Función para inicializar datos por defecto
const initializeDefaultData = async () => {
  try {
    // Verificar si ya existen datos
    const departamentosCount = await Departamento.count();
    const estadosCount = await EstadoSolicitud.count();
    const urgenciasCount = await NivelUrgencia.count();

    if (departamentosCount === 0) {
      await Departamento.bulkCreate([
        { nombre: 'Expediciones', descripcion: 'Departamento de expediciones y envíos' },
        { nombre: 'Almacén', descripcion: 'Departamento de almacén y gestión de inventario' },
        { nombre: 'Laboratorio', descripcion: 'Departamento de análisis y control de calidad' },
        { nombre: 'Oficina Técnica', descripcion: 'Departamento de oficina técnica y diseño' }
      ]);
      console.log('✅ Departamentos iniciales creados');
    }

    if (estadosCount === 0) {
      await EstadoSolicitud.bulkCreate([
        { nombre: 'Pendiente', descripcion: 'Solicitud creada, pendiente de procesamiento', color: '#ffc107' },
        { nombre: 'En Proceso', descripcion: 'Solicitud siendo procesada', color: '#007bff' },
        { nombre: 'En Laboratorio', descripcion: 'Solicitud enviada a laboratorio para análisis', color: '#17a2b8' },
        { nombre: 'Completada', descripcion: 'Solicitud completada exitosamente', color: '#28a745' },
        { nombre: 'Rechazada', descripcion: 'Solicitud rechazada', color: '#dc3545' },
        { nombre: 'Esperando Resultado', descripcion: 'Esperando resultado de laboratorio', color: '#6f42c1' },
        { nombre: 'Enviada a Almacén', descripcion: 'Solicitud enviada al departamento de almacén', color: '#fd7e14' },
        { nombre: 'Enviada a Expediciones', descripcion: 'Solicitud enviada al departamento de expediciones', color: '#20c997' },
        { nombre: 'Devuelto a Oficina Técnica', descripcion: 'Solicitud devuelta al departamento de oficina técnica', color: '#6c757d' }
      ]);
      console.log('✅ Estados de solicitud iniciales creados');
    }

    if (urgenciasCount === 0) {
      await NivelUrgencia.bulkCreate([
        { nombre: 'Baja', descripcion: 'Urgencia baja - No crítica', prioridad: 1, color: '#28a745' },
        { nombre: 'Media', descripcion: 'Urgencia media - Importante', prioridad: 2, color: '#ffc107' },
        { nombre: 'Alta', descripcion: 'Urgencia alta - Crítica', prioridad: 3, color: '#fd7e14' },
        { nombre: 'Crítica', descripcion: 'Urgencia crítica - Inmediata', prioridad: 4, color: '#dc3545' }
      ]);
      console.log('✅ Niveles de urgencia iniciales creados');
    }

  } catch (error) {
    console.error('❌ Error inicializando datos por defecto:', error);
  }
};

module.exports = {
  sequelize,
  Departamento,
  EstadoSolicitud,
  NivelUrgencia,
  Solicitud,
  HistorialSolicitud,
  Necesidad,
  ArchivoAdjunto,
  ChatMensaje,
  AuditoriaAcciones,
  initializeDefaultData
};