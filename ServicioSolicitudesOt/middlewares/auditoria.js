const { AuditoriaAcciones } = require('../models/sequelize');

// Middleware para registrar acciones de auditoría
const registrarAuditoria = (accion, descripcionTemplate = null) => {
  return async (req, res, next) => {
    // Guardar el método original de res.json
    const originalJson = res.json;
    
    // Sobrescribir res.json para capturar la respuesta
    res.json = function(data) {
      // Solo registrar si la operación fue exitosa
      if (data && data.success) {
        // Ejecutar el registro de auditoría de forma asíncrona
        setImmediate(async () => {
          try {
            await registrarAccionAuditoria(req, res, accion, descripcionTemplate, data);
          } catch (error) {
            console.error('Error registrando auditoría:', error);
          }
        });
      }
      
      // Llamar al método original
      return originalJson.call(this, data);
    };
    
    next();
  };
};

// Función para registrar la acción de auditoría
const registrarAccionAuditoria = async (req, res, accion, descripcionTemplate, responseData) => {
  try {
    // Extraer información del usuario (puedes ajustar según tu sistema de autenticación)
    const usuario = req.headers['x-user-name'] || req.body.created_by || req.query.usuario || 'Sistema';
    const ipAddress = req.ip || req.connection.remoteAddress;
    const userAgent = req.get('User-Agent');
    
    // Determinar solicitud_id según la ruta y parámetros
    let solicitudId = null;
    
    // Extraer solicitud_id de diferentes fuentes
    if (req.params.id && req.route.path.includes('solicitudes')) {
      solicitudId = parseInt(req.params.id);
    } else if (req.body.solicitud_id) {
      solicitudId = req.body.solicitud_id;
    } else if (responseData.data && responseData.data.id && accion === 'crear_solicitud') {
      solicitudId = responseData.data.id;
    } else if (responseData.data && responseData.data.solicitud_id) {
      solicitudId = responseData.data.solicitud_id;
    }
    
    // Si no hay solicitud_id, no registrar (algunas acciones no están relacionadas con solicitudes específicas)
    if (!solicitudId) {
      return;
    }
    
    // Generar descripción
    let descripcion = descripcionTemplate;
    if (descripcionTemplate && typeof descripcionTemplate === 'function') {
      descripcion = descripcionTemplate(req, responseData);
    } else if (!descripcion) {
      descripcion = generarDescripcionPorDefecto(accion, req, responseData);
    }
    
    // Preparar datos para auditoría
    const datosAuditoria = {
      solicitud_id: solicitudId,
      usuario,
      accion,
      descripcion,
      ip_address: ipAddress,
      user_agent: userAgent,
      metadata: {
        metodo: req.method,
        ruta: req.originalUrl,
        parametros: req.params,
        query: req.query,
        timestamp: new Date().toISOString()
      }
    };
    
    // Agregar datos anteriores y nuevos para acciones de actualización
    if (accion.includes('actualizar') || accion.includes('cambiar')) {
      if (req.datosAnteriores) {
        datosAuditoria.datos_anteriores = req.datosAnteriores;
      }
      if (responseData.data) {
        datosAuditoria.datos_nuevos = responseData.data;
      }
    }
    
    // Registrar en la base de datos
    await AuditoriaAcciones.registrarAccion(datosAuditoria);
    
  } catch (error) {
    console.error('Error en registrarAccionAuditoria:', error);
  }
};

// Generar descripción por defecto según el tipo de acción
const generarDescripcionPorDefecto = (accion, req, responseData) => {
  const usuario = req.headers['x-user-name'] || req.body.created_by || 'Usuario';
  
  switch (accion) {
    case 'crear_solicitud':
      return `${usuario} creó una nueva solicitud`;
    case 'actualizar_solicitud':
      return `${usuario} actualizó la solicitud`;
    case 'cambiar_estado':
      return `${usuario} cambió el estado de la solicitud`;
    case 'mover_departamento':
      return `${usuario} movió la solicitud a otro departamento`;
    case 'agregar_comentario':
      return `${usuario} agregó un comentario`;
    case 'subir_archivo':
      return `${usuario} subió un archivo`;
    case 'eliminar_archivo':
      return `${usuario} eliminó un archivo`;
    case 'crear_necesidad':
      return `${usuario} creó una nueva necesidad`;
    case 'completar_necesidad':
      return `${usuario} completó una necesidad`;
    case 'finalizar_solicitud':
      return `${usuario} finalizó la solicitud`;
    case 'enviar_email':
      return `${usuario} envió una notificación por email`;
    case 'ver_solicitud':
      return `${usuario} visualizó la solicitud`;
    case 'descargar_archivo':
      return `${usuario} descargó un archivo`;
    default:
      return `${usuario} realizó la acción: ${accion}`;
  }
};

// Middleware específico para capturar datos anteriores antes de una actualización
const capturarDatosAnteriores = (modelo, campoId = 'id') => {
  return async (req, res, next) => {
    try {
      const id = req.params[campoId] || req.body[campoId];
      if (id && modelo) {
        const registro = await modelo.findByPk(id);
        if (registro) {
          req.datosAnteriores = registro.toJSON();
        }
      }
    } catch (error) {
      console.error('Error capturando datos anteriores:', error);
    }
    next();
  };
};

// Middleware para registrar visualizaciones
const registrarVisualizacion = async (req, res, next) => {
  // Solo registrar para métodos GET de solicitudes específicas
  if (req.method === 'GET' && req.params.id && req.route.path.includes('solicitudes')) {
    try {
      const usuario = req.headers['x-user-name'] || 'Usuario anónimo';
      const solicitudId = parseInt(req.params.id);
      const ipAddress = req.ip || req.connection.remoteAddress;
      const userAgent = req.get('User-Agent');
      
      // Registrar visualización de forma asíncrona
      setImmediate(async () => {
        try {
          await AuditoriaAcciones.registrarAccion({
            solicitud_id: solicitudId,
            usuario,
            accion: 'ver_solicitud',
            descripcion: `${usuario} visualizó la solicitud`,
            ip_address: ipAddress,
            user_agent: userAgent,
            metadata: {
              metodo: req.method,
              ruta: req.originalUrl,
              timestamp: new Date().toISOString()
            }
          });
        } catch (error) {
          console.error('Error registrando visualización:', error);
        }
      });
    } catch (error) {
      console.error('Error en middleware de visualización:', error);
    }
  }
  next();
};

module.exports = {
  registrarAuditoria,
  capturarDatosAnteriores,
  registrarVisualizacion,
  registrarAccionAuditoria
};