const express = require('express');
const { body, validationResult, query } = require('express-validator');
const Necesidad = require('../models/Necesidad');
const Solicitud = require('../models/Solicitud');
const Archivo = require('../models/Archivo');
const router = express.Router();

// Middleware para manejar errores de validación
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Datos de entrada inválidos',
      details: errors.array()
    });
  }
  next();
};

// GET /api/necesidades - Obtener todas las necesidades
router.get('/', [
  query('completada').optional().isBoolean(),
  query('tipo_analisis').optional().isString(),
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('busqueda').optional().isString(),
  query('limite').optional().isInt({ min: 1, max: 100 })
], async (req, res) => {
  try {
    const filtros = {
      completada: req.query.completada,
      tipo_analisis: req.query.tipo_analisis,
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta,
      busqueda: req.query.busqueda,
      limite: req.query.limite || 50
    };

    const necesidades = await Necesidad.obtenerTodas(filtros);
    
    res.json({
      success: true,
      data: necesidades,
      total: necesidades.length
    });
  } catch (error) {
    console.error('Error obteniendo necesidades:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/necesidades/:id - Obtener necesidad por ID
router.get('/:id', async (req, res) => {
  try {
    const necesidad = await Necesidad.obtenerPorId(req.params.id);
    
    if (!necesidad) {
      return res.status(404).json({
        error: 'Necesidad no encontrada'
      });
    }

    // Obtener archivos adjuntos de la necesidad
    const archivos = await Archivo.obtenerPorNecesidad(necesidad.id);
    
    res.json({
      success: true,
      data: {
        ...necesidad,
        archivos
      }
    });
  } catch (error) {
    console.error('Error obteniendo necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/necesidades/solicitud/:solicitudId - Obtener necesidades por solicitud
router.get('/solicitud/:solicitudId', async (req, res) => {
  try {
    const necesidades = await Necesidad.obtenerPorSolicitud(req.params.solicitudId);
    
    res.json({
      success: true,
      data: necesidades,
      total: necesidades.length
    });
  } catch (error) {
    console.error('Error obteniendo necesidades por solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/necesidades - Crear nueva necesidad
router.post('/', [
  body('solicitud_id')
    .isInt({ min: 1 })
    .withMessage('El ID de solicitud debe ser un número válido'),
  body('descripcion')
    .notEmpty()
    .withMessage('La descripción es requerida')
    .isLength({ min: 10, max: 1000 })
    .withMessage('La descripción debe tener entre 10 y 1000 caracteres'),
  body('tipo_analisis')
    .optional()
    .isLength({ max: 255 })
    .withMessage('El tipo de análisis no puede exceder 255 caracteres'),
  body('parametros_requeridos')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Los parámetros requeridos no pueden exceder 1000 caracteres'),
  body('created_by')
    .optional()
    .isLength({ max: 255 })
    .withMessage('El campo created_by no puede exceder 255 caracteres')
], handleValidationErrors, async (req, res) => {
  try {
    // Verificar que la solicitud existe
    const solicitud = await Solicitud.obtenerPorId(req.body.solicitud_id);
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    const necesidad = await Necesidad.crear(req.body);
    
    // Si la solicitud está en laboratorio (departamento 3), transferirla automáticamente a almacén (departamento 2)
    if (solicitud.departamento_actual_id === 3) {
      await Solicitud.actualizarEstado(
        req.body.solicitud_id,
        2, // Estado: En Proceso
        2, // Departamento: Almacén
        `Necesidad de almacén creada desde laboratorio: ${req.body.descripcion.substring(0, 100)}...`
      );
      
      // Emitir evento a almacén sobre la nueva necesidad
      req.io.to('departamento_2').emit('nueva_necesidad_almacen', {
        necesidad,
        solicitud: await Solicitud.obtenerPorId(req.body.solicitud_id)
      });
    } else {
      // Emitir evento en tiempo real al laboratorio (comportamiento original)
      req.io.to('departamento_3').emit('nueva_necesidad', {
        necesidad,
        solicitud
      });
    }
    
    res.status(201).json({
      success: true,
      message: 'Necesidad creada exitosamente y solicitud transferida a almacén',
      data: necesidad
    });
  } catch (error) {
    console.error('Error creando necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// PUT /api/necesidades/:id - Actualizar necesidad
router.put('/:id', [
  body('descripcion')
    .optional()
    .isLength({ min: 10, max: 1000 })
    .withMessage('La descripción debe tener entre 10 y 1000 caracteres'),
  body('tipo_analisis')
    .optional()
    .isLength({ max: 255 })
    .withMessage('El tipo de análisis no puede exceder 255 caracteres'),
  body('parametros_requeridos')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Los parámetros requeridos no pueden exceder 1000 caracteres'),
  body('resultado')
    .optional()
    .isLength({ max: 2000 })
    .withMessage('El resultado no puede exceder 2000 caracteres'),
  body('observaciones')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Las observaciones no pueden exceder 1000 caracteres')
], handleValidationErrors, async (req, res) => {
  try {
    const necesidad = await Necesidad.obtenerPorId(req.params.id);
    
    if (!necesidad) {
      return res.status(404).json({
        error: 'Necesidad no encontrada'
      });
    }

    const necesidadActualizada = await Necesidad.actualizar(req.params.id, req.body);
    
    // Emitir evento en tiempo real
    req.io.emit('necesidad_actualizada', {
      necesidad: necesidadActualizada
    });
    
    res.json({
      success: true,
      message: 'Necesidad actualizada exitosamente',
      data: necesidadActualizada
    });
  } catch (error) {
    console.error('Error actualizando necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/necesidades/:id/completar - Completar necesidad con resultado
router.post('/:id/completar', [
  body('resultado')
    .notEmpty()
    .withMessage('El resultado es requerido')
    .isLength({ min: 10, max: 2000 })
    .withMessage('El resultado debe tener entre 10 y 2000 caracteres'),
  body('observaciones')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Las observaciones no pueden exceder 1000 caracteres'),
  body('completed_by')
    .optional()
    .isLength({ max: 255 })
    .withMessage('El campo completed_by no puede exceder 255 caracteres')
], handleValidationErrors, async (req, res) => {
  try {
    const necesidad = await Necesidad.obtenerPorId(req.params.id);
    
    if (!necesidad) {
      return res.status(404).json({
        error: 'Necesidad no encontrada'
      });
    }

    if (necesidad.completada) {
      return res.status(400).json({
        error: 'La necesidad ya está completada'
      });
    }

    const { resultado, observaciones, completed_by } = req.body;
    
    const necesidadCompletada = await Necesidad.completar(
      req.params.id,
      resultado,
      observaciones,
      completed_by
    );

    // Actualizar solicitud de vuelta a almacén
    await Solicitud.actualizarEstado(
      necesidad.solicitud_id,
      2, // Estado: En Proceso
      2, // Departamento: Almacén
      'Necesidad completada por laboratorio'
    );

    // Emitir evento en tiempo real
    req.io.emit('necesidad_completada', {
      necesidad: necesidadCompletada,
      solicitud_id: necesidad.solicitud_id
    });
    
    // Notificar a almacén
    req.io.to('departamento_2').emit('necesidad_devuelta', {
      necesidad: necesidadCompletada,
      solicitud_id: necesidad.solicitud_id
    });
    
    res.json({
      success: true,
      message: 'Necesidad completada y devuelta a almacén',
      data: necesidadCompletada
    });
  } catch (error) {
    console.error('Error completando necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// DELETE /api/necesidades/:id - Eliminar necesidad
router.delete('/:id', async (req, res) => {
  try {
    const necesidad = await Necesidad.obtenerPorId(req.params.id);
    
    if (!necesidad) {
      return res.status(404).json({
        error: 'Necesidad no encontrada'
      });
    }

    if (necesidad.completada) {
      return res.status(400).json({
        error: 'No se puede eliminar una necesidad completada'
      });
    }

    const eliminada = await Necesidad.eliminar(req.params.id);
    
    if (eliminada) {
      // Emitir evento en tiempo real
      req.io.emit('necesidad_eliminada', {
        necesidad_id: req.params.id,
        solicitud_id: necesidad.solicitud_id
      });
      
      res.json({
        success: true,
        message: 'Necesidad eliminada exitosamente'
      });
    } else {
      res.status(500).json({
        error: 'No se pudo eliminar la necesidad'
      });
    }
  } catch (error) {
    console.error('Error eliminando necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/necesidades/stats/general - Obtener estadísticas de necesidades
router.get('/stats/general', [
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate()
], async (req, res) => {
  try {
    const filtros = {
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta
    };

    const estadisticas = await Necesidad.obtenerEstadisticas(filtros);
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas de necesidades:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/necesidades/stats/urgencia - Obtener necesidades pendientes por urgencia
router.get('/stats/urgencia', async (req, res) => {
  try {
    const estadisticas = await Necesidad.obtenerPendientesPorUrgencia();
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas por urgencia:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/necesidades/:id/reabrir - Reabrir necesidad completada
router.post('/:id/reabrir', [
  body('motivo')
    .notEmpty()
    .withMessage('El motivo para reabrir es requerido')
    .isLength({ min: 10, max: 500 })
    .withMessage('El motivo debe tener entre 10 y 500 caracteres')
], handleValidationErrors, async (req, res) => {
  try {
    const necesidad = await Necesidad.obtenerPorId(req.params.id);
    
    if (!necesidad) {
      return res.status(404).json({
        error: 'Necesidad no encontrada'
      });
    }

    if (!necesidad.completada) {
      return res.status(400).json({
        error: 'La necesidad no está completada'
      });
    }

    const necesidadReabierta = await Necesidad.actualizar(req.params.id, {
      completada: false,
      fecha_completada: null,
      observaciones: `${necesidad.observaciones || ''}\n\n[REABIERTA] ${req.body.motivo}`
    });

    // Actualizar solicitud de vuelta a laboratorio
    await Solicitud.actualizarEstado(
      necesidad.solicitud_id,
      3, // Estado: En Laboratorio
      3, // Departamento: Laboratorio
      `Necesidad reabierta: ${req.body.motivo}`
    );

    // Emitir evento en tiempo real
    req.io.emit('necesidad_reabierta', {
      necesidad: necesidadReabierta,
      motivo: req.body.motivo
    });
    
    // Notificar a laboratorio
    req.io.to('departamento_3').emit('necesidad_reabierta', {
      necesidad: necesidadReabierta,
      motivo: req.body.motivo
    });
    
    res.json({
      success: true,
      message: 'Necesidad reabierta y enviada de vuelta a laboratorio',
      data: necesidadReabierta
    });
  } catch (error) {
    console.error('Error reabriendo necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/necesidades/solicitud/:solicitud_id/devolver-almacen - Devolver solicitud de laboratorio a almacén
router.post('/solicitud/:solicitud_id/devolver-almacen', [
  body('comentarios').optional().isString().withMessage('Los comentarios deben ser texto')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { solicitud_id } = req.params;
    const { comentarios } = req.body;

    const solicitud = await Solicitud.obtenerPorId(solicitud_id);
    
    if (!solicitud) {
      return res.status(404).json({ error: 'Solicitud no encontrada' });
    }

    if (solicitud.departamento_actual !== 3) { // 3 = Laboratorio
      return res.status(400).json({ error: 'La solicitud no está en Laboratorio' });
    }

    // Devolver solicitud a Almacén
    await Solicitud.actualizarEstado(
      solicitud_id, 
      2, // Estado: En Proceso
      2, // Departamento: Almacén
      comentarios || 'Solicitud devuelta desde Laboratorio a Almacén'
    );

    const solicitudActualizada = await Solicitud.obtenerPorId(solicitud_id);

    // Emitir eventos
    req.io.emit('solicitud_actualizada', solicitudActualizada);
    req.io.to('departamento_2').emit('solicitud_devuelta_laboratorio', solicitudActualizada);

    res.json({
      success: true,
      message: 'Solicitud devuelta a Almacén exitosamente',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error devolviendo solicitud a Almacén:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// POST /api/necesidades/solicitud/:solicitud_id/finalizar-laboratorio - Finalizar solicitud desde laboratorio
router.post('/solicitud/:solicitud_id/finalizar-laboratorio', [
  body('comentarios').optional().isString().withMessage('Los comentarios deben ser texto')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { solicitud_id } = req.params;
    const { comentarios } = req.body;

    const solicitud = await Solicitud.obtenerPorId(solicitud_id);
    
    if (!solicitud) {
      return res.status(404).json({ error: 'Solicitud no encontrada' });
    }

    if (solicitud.departamento_actual !== 3) { // 3 = Laboratorio
      return res.status(400).json({ error: 'La solicitud no está en Laboratorio' });
    }

    // Finalizar solicitud desde Laboratorio
    await Solicitud.finalizar(
      solicitud_id, 
      comentarios || 'Solicitud finalizada desde Laboratorio'
    );

    const solicitudFinalizada = await Solicitud.obtenerPorId(solicitud_id);

    // Emitir eventos
    req.io.emit('solicitud_finalizada', solicitudFinalizada);
    req.io.to('departamento_3').emit('solicitud_finalizada_laboratorio', solicitudFinalizada);

    res.json({
      success: true,
      message: 'Solicitud finalizada exitosamente desde Laboratorio',
      data: solicitudFinalizada
    });
  } catch (error) {
    console.error('Error finalizando solicitud desde Laboratorio:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;