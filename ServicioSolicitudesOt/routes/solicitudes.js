const express = require('express');
const { body, validationResult, query } = require('express-validator');
const { Op } = require('sequelize');
const { sequelize } = require('../config/sequelize');
const {
  Solicitud,
  Departamento,
  EstadoSolicitud,
  NivelUrgencia,
  HistorialSolicitud,
  Necesidad,
  ArchivoAdjunto
} = require('../models/sequelize');
const { enviarNotificacionAlmacen, enviarNotificacionExpediciones, probarConectividad, enviarCorreoPrueba } = require('../services/emailService');
const { registrarAuditoria, registrarAccionAuditoria, registrarVisualizacion } = require('../middlewares/auditoria');
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

// Validaciones para crear solicitud
const validarCrearSolicitud = [
  body('nombre_solicitante')
    .notEmpty()
    .withMessage('El nombre del solicitante es requerido')
    .isLength({ min: 2, max: 255 })
    .withMessage('El nombre debe tener entre 2 y 255 caracteres'),
  body('nombre_materia_prima')
    .notEmpty()
    .withMessage('El nombre de la materia prima es requerido')
    .isLength({ min: 2, max: 255 })
    .withMessage('El nombre de la materia prima debe tener entre 2 y 255 caracteres'),
  body('lote')
    .notEmpty()
    .withMessage('El lote es requerido')
    .isLength({ min: 1, max: 100 })
    .withMessage('El lote debe tener entre 1 y 100 caracteres'),
  body('proveedor')
    .notEmpty()
    .withMessage('El proveedor es requerido')
    .isLength({ min: 2, max: 255 })
    .withMessage('El proveedor debe tener entre 2 y 255 caracteres'),
  body('codigo_articulo')
    .notEmpty()
    .withMessage('El código del artículo es requerido')
    .isLength({ min: 1, max: 100 })
    .withMessage('El código del artículo debe tener entre 1 y 100 caracteres'),
  body('departamento_destino_id')
    .isInt({ min: 1 })
    .withMessage('El departamento destino debe ser un ID válido'),
  body('urgencia_id')
    .isInt({ min: 1 })
    .withMessage('El nivel de urgencia debe ser un ID válido'),
  body('comentarios')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Los comentarios no pueden exceder 1000 caracteres'),
  body('created_by')
    .optional()
    .isLength({ max: 255 })
    .withMessage('El campo created_by no puede exceder 255 caracteres')
];

// GET /api/solicitudes - Obtener todas las solicitudes
router.get('/', [
  query('departamento_actual_id').optional().isInt(),
  query('departamento_relacionado_id').optional().isInt(),
  query('estado_id').optional().isInt(),
  query('urgencia_id').optional().isInt(),
  query('finalizada').optional().isBoolean(),
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('busqueda').optional().isString(),
  query('limite').optional().isInt({ min: 1, max: 100 }),
  query('con_necesidades_laboratorio').optional().isBoolean(),
  query('sin_necesidades_laboratorio').optional().isBoolean()
], async (req, res) => {
  try {
    const filtros = {
      departamento_actual_id: req.query.departamento_actual_id,
      departamento_relacionado_id: req.query.departamento_relacionado_id,
      estado_id: req.query.estado_id,
      urgencia_id: req.query.urgencia_id,
      finalizada: req.query.finalizada,
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta,
      busqueda: req.query.busqueda,
      limite: req.query.limite || 50,
      con_necesidades_laboratorio: req.query.con_necesidades_laboratorio,
      sin_necesidades_laboratorio: req.query.sin_necesidades_laboratorio
    };

    // Construir filtros para Sequelize
    const whereClause = {};
    const includeClause = [
      { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
      { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
      { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
      { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
    ];

    // Filtro por departamento relacionado (actual, destino o que haya estado en el historial)
    if (filtros.departamento_relacionado_id) {
      const departamentoId = parseInt(filtros.departamento_relacionado_id);
      
      // Buscar solicitudes que estén actualmente en el departamento
      // O que hayan pasado por el departamento (en historial)
      // O que tengan como destino el departamento
      const solicitudesIds = await sequelize.query(`
        SELECT DISTINCT s.id 
        FROM solicitudes s
        LEFT JOIN historial_solicitudes h ON s.id = h.solicitud_id
        WHERE s.departamento_actual_id = :departamentoId
           OR s.departamento_destino_id = :departamentoId
           OR h.departamento_origen_id = :departamentoId
           OR h.departamento_destino_id = :departamentoId
      `, {
        replacements: { departamentoId },
        type: sequelize.QueryTypes.SELECT
      });
      
      const ids = solicitudesIds.map(row => row.id);
      if (ids.length > 0) {
        whereClause.id = { [Op.in]: ids };
      } else {
        // Si no hay IDs, devolver array vacío
        whereClause.id = { [Op.in]: [-1] };
      }
    } else if (filtros.departamento_actual_id) {
      whereClause.departamento_actual_id = filtros.departamento_actual_id;
    }
    
    if (filtros.estado_id) {
      whereClause.estado_id = filtros.estado_id;
    }
    if (filtros.urgencia_id) {
      whereClause.urgencia_id = filtros.urgencia_id;
    }
    if (filtros.finalizada !== undefined) {
      whereClause.finalizada = filtros.finalizada === 'true';
    }
    if (filtros.fecha_desde && filtros.fecha_hasta) {
      whereClause.fecha_creacion = {
        [Op.between]: [new Date(filtros.fecha_desde), new Date(filtros.fecha_hasta)]
      };
    }
    if (filtros.busqueda) {
      whereClause[Op.or] = [
        { numero_solicitud: { [Op.like]: `%${filtros.busqueda}%` } },
        { nombre_solicitante: { [Op.like]: `%${filtros.busqueda}%` } },
        { nombre_materia_prima: { [Op.like]: `%${filtros.busqueda}%` } },
        { lote: { [Op.like]: `%${filtros.busqueda}%` } },
        { proveedor: { [Op.like]: `%${filtros.busqueda}%` } },
        { codigo_articulo: { [Op.like]: `%${filtros.busqueda}%` } }
      ];
    }

    // Filtros para necesidades de laboratorio
    if (filtros.con_necesidades_laboratorio === 'true' || filtros.sin_necesidades_laboratorio === 'true') {
      // Incluir necesidades para poder filtrar
      includeClause.push({
        model: Necesidad,
        as: 'necesidades',
        required: filtros.con_necesidades_laboratorio === 'true' ? true : false,
        where: filtros.con_necesidades_laboratorio === 'true' ? {
          tipo_analisis: 'Necesidad de Almacén'
        } : undefined
      });
      
      // Si queremos excluir necesidades de laboratorio, usar subconsulta
      if (filtros.sin_necesidades_laboratorio === 'true') {
        const solicitudesConNecesidades = await sequelize.query(`
          SELECT DISTINCT s.id 
          FROM solicitudes s
          INNER JOIN necesidades n ON s.id = n.solicitud_id
          WHERE n.tipo_analisis = 'Necesidad de Almacén'
        `, {
          type: sequelize.QueryTypes.SELECT
        });
        
        const idsConNecesidades = solicitudesConNecesidades.map(row => row.id);
        if (idsConNecesidades.length > 0) {
          whereClause.id = whereClause.id ? 
            { [Op.and]: [whereClause.id, { [Op.notIn]: idsConNecesidades }] } :
            { [Op.notIn]: idsConNecesidades };
        }
      }
    } else {
      // Incluir necesidades por defecto para compatibilidad
      includeClause.push({
        model: Necesidad,
        as: 'necesidades',
        required: false
      });
    }

    const solicitudes = await Solicitud.findAll({
      where: whereClause,
      include: includeClause,
      order: [['urgencia', 'prioridad', 'DESC'], ['fecha_creacion', 'DESC']],
      limit: parseInt(filtros.limite)
    });

    res.json({
      success: true,
      data: solicitudes,
      total: solicitudes.length
    });
  } catch (error) {
    console.error('Error obteniendo solicitudes:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/solicitudes/:id - Obtener solicitud por ID
router.get('/:id', registrarVisualizacion, async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] },
        { model: ArchivoAdjunto, as: 'archivos' },
        { model: Necesidad, as: 'necesidades' },
        {
          model: HistorialSolicitud,
          as: 'historial',
          include: [
            { model: Departamento, as: 'departamentoOrigen', attributes: ['id', 'nombre'] },
            { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
            { model: EstadoSolicitud, as: 'estadoAnterior', attributes: ['id', 'nombre'] },
            { model: EstadoSolicitud, as: 'estadoNuevo', attributes: ['id', 'nombre'] }
          ],
          order: [['fecha_movimiento', 'DESC']]
        }
      ]
    });
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    res.json({
      success: true,
      data: solicitud
    });
  } catch (error) {
    console.error('Error obteniendo solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes - Crear nueva solicitud
router.post('/', validarCrearSolicitud, handleValidationErrors, registrarAuditoria('crear_solicitud'), async (req, res) => {
  try {
    // Establecer departamento actual igual al destino inicialmente
    const datosCreacion = {
      ...req.body,
      departamento_actual_id: req.body.departamento_destino_id,
      estado_id: req.body.estado_id || 1 // Usar estado enviado o Pendiente por defecto
    };
    
    const solicitud = await Solicitud.create(datosCreacion);
    
    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: solicitud.id,
      departamento_destino_id: solicitud.departamento_actual_id,
      estado_nuevo_id: solicitud.estado_id,
      comentario: 'Solicitud creada',
      usuario: solicitud.created_by
    });
    
    // Obtener solicitud completa con relaciones
    const solicitudCompleta = await Solicitud.findByPk(solicitud.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });
    
    // Emitir evento en tiempo real
    req.io.emit('nueva_solicitud', {
      solicitud: solicitudCompleta,
      departamento: solicitudCompleta.departamento_actual_id
    });
    
    // Emitir a departamento específico
    req.io.to(`departamento_${solicitudCompleta.departamento_actual_id}`).emit('solicitud_recibida', solicitudCompleta);

    // Enviar notificación por correo si la solicitud se crea directamente para almacén o expediciones
    try {
      if (solicitudCompleta.departamento_actual_id === 2) { // Almacén
        await enviarNotificacionAlmacen(solicitudCompleta);
        console.log('Notificación de correo enviada para nueva solicitud en almacén');
      } else if (solicitudCompleta.departamento_actual_id === 1) { // Expediciones
        await enviarNotificacionExpediciones(solicitudCompleta);
        console.log('Notificación de correo enviada para nueva solicitud en expediciones');
      }
    } catch (emailError) {
      console.error('Error enviando notificación por correo:', emailError);
      // No fallar la creación de la solicitud por errores de correo
    }

    res.status(201).json({
      success: true,
      message: 'Solicitud creada exitosamente',
      data: solicitudCompleta
    });
  } catch (error) {
    console.error('Error creando solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// PUT /api/solicitudes/:id/estado - Actualizar estado de solicitud
router.put('/:id/estado', [
  body('estado_id').isInt({ min: 1 }).withMessage('El estado debe ser un ID válido'),
  body('departamento_id').optional().isInt({ min: 1 }).withMessage('El departamento debe ser un ID válido'),
  body('comentario').optional().isLength({ max: 500 }).withMessage('El comentario no puede exceder 500 caracteres')
], handleValidationErrors, registrarAuditoria('cambiar_estado'), async (req, res) => {
  try {
    const { estado_id, departamento_id, comentario } = req.body;
    
    // Buscar solicitud
    const solicitud = await Solicitud.findByPk(req.params.id);
    if (!solicitud) {
      return res.status(404).json({ error: 'Solicitud no encontrada' });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Actualizar solicitud
    const datosActualizacion = {
      estado_id,
      fecha_actualizacion: new Date()
    };
    
    if (departamento_id) {
      datosActualizacion.departamento_actual_id = departamento_id;
    }

    await solicitud.update(datosActualizacion);

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: departamento_id || departamentoAnterior,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: estado_id,
      comentario: comentario || 'Estado actualizado',
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.emit('solicitud_actualizada', {
      solicitud: solicitudActualizada,
      cambio: 'estado'
    });
    
    // Emitir a departamentos involucrados
    if (departamento_id) {
      req.io.to(`departamento_${departamento_id}`).emit('solicitud_recibida', solicitudActualizada);
    }

    res.json({
      success: true,
      message: 'Estado de solicitud actualizado exitosamente',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error actualizando estado:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes/:id/enviar-expediciones - Enviar solicitud a expediciones
router.post('/:id/enviar-expediciones', registrarAuditoria('mover_departamento'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Actualizar a departamento expediciones (ID: 1) y finalizar
    await solicitud.update({
      estado_id: 4, // Estado: Completada
      departamento_actual_id: 1, // Departamento: Expediciones
      finalizada: true,
      fecha_finalizacion: new Date(),
      fecha_actualizacion: new Date()
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: 1,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: 4,
      comentario: 'Solicitud enviada a expediciones y finalizada',
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.emit('solicitud_finalizada', {
      solicitud: solicitudActualizada,
      destino: 'expediciones'
    });

    // Enviar notificación por correo electrónico
    try {
      await enviarNotificacionExpediciones(solicitudActualizada);
      console.log('Notificación de expediciones enviada exitosamente');
    } catch (emailError) {
      console.error('Error enviando notificación de expediciones:', emailError);
      // No fallar la operación principal por error de email
    }

    res.json({
      success: true,
      message: 'Solicitud enviada a expediciones y finalizada',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error enviando a expediciones:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes/:id/enviar-almacen - Enviar solicitud a almacén
router.post('/:id/enviar-almacen', registrarAuditoria('mover_departamento'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Actualizar a departamento almacén (ID: 2)
    await solicitud.update({
      estado_id: 2, // Estado: En Proceso
      departamento_actual_id: 2, // Departamento: Almacén
      fecha_actualizacion: new Date()
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: 2,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: 2,
      comentario: 'Solicitud enviada a almacén',
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.to('departamento_2').emit('solicitud_recibida', solicitudActualizada);

    // Enviar notificación por correo electrónico
    try {
      await enviarNotificacionAlmacen(solicitudActualizada);
      console.log('Notificación de almacén enviada exitosamente');
    } catch (emailError) {
      console.error('Error enviando notificación de almacén:', emailError);
      // No fallar la operación principal por error de email
    }

    res.json({
      success: true,
      message: 'Solicitud enviada a almacén',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error enviando a almacén:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes/:id/enviar-laboratorio - Enviar solicitud directamente a laboratorio
router.post('/:id/enviar-laboratorio', registrarAuditoria('mover_departamento'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Actualizar a departamento laboratorio (ID: 3)
    await solicitud.update({
      estado_id: 3, // Estado: En Laboratorio
      departamento_actual_id: 3, // Departamento: Laboratorio
      fecha_actualizacion: new Date()
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: 3,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: 3,
      comentario: 'Solicitud enviada directamente a laboratorio',
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.to('departamento_3').emit('solicitud_recibida', solicitudActualizada);

    res.json({
      success: true,
      message: 'Solicitud enviada a laboratorio',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error enviando a laboratorio:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes/:id/crear-necesidad - Crear necesidad para laboratorio
router.post('/:id/crear-necesidad', [
  body('descripcion').notEmpty().withMessage('La descripción es requerida'),
  body('tipo_analisis').optional().isString(),
  body('parametros_requeridos').optional().isString(),
  body('created_by').optional().isString()
], handleValidationErrors, registrarAuditoria('crear_necesidad'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Crear necesidad
    const necesidad = await Necesidad.create({
      solicitud_id: req.params.id,
      ...req.body
    });

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Actualizar solicitud a laboratorio
    await solicitud.update({
      estado_id: 3, // Estado: En Laboratorio
      departamento_actual_id: 3, // Departamento: Laboratorio
      fecha_actualizacion: new Date()
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: 3,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: 3,
      comentario: `Necesidad para laboratorio: ${req.body.descripcion}`,
      usuario: req.body.created_by || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.to('departamento_3').emit('nueva_necesidad', {
      necesidad,
      solicitud: solicitudActualizada
    });

    res.status(201).json({
      success: true,
      message: 'Necesidad creada y enviada a laboratorio',
      data: {
        necesidad,
        solicitud: solicitudActualizada
      }
    });
  } catch (error) {
    console.error('Error creando necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// PUT /api/solicitudes/:id/transferir - Transferir solicitud a otro departamento
router.put('/:id/transferir', [
  body('departamento_destino').isInt({ min: 1 }).withMessage('El departamento destino es requerido'),
  body('comentario').optional().isLength({ max: 500 }),
  body('usuario').optional().isString()
], handleValidationErrors, registrarAuditoria('mover_departamento'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Verificar que no esté finalizada
    if (solicitud.finalizada) {
      return res.status(400).json({
        error: 'No se puede transferir una solicitud finalizada'
      });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;
    const departamentoDestino = parseInt(req.body.departamento_destino);

    // Determinar nuevo estado según departamento destino
    let nuevoEstado;
    switch (departamentoDestino) {
      case 1: // Expediciones
        nuevoEstado = 5; // Enviada a Expediciones
        break;
      case 2: // Almacén
        nuevoEstado = 2; // En Proceso
        break;
      case 3: // Laboratorio
        nuevoEstado = 3; // En Laboratorio
        break;
      case 4: // Oficina Técnica
        nuevoEstado = 9; // Devuelto a Oficina Técnica
        break;
      default:
        nuevoEstado = 2; // En Proceso por defecto
    }

    // Actualizar solicitud
    await solicitud.update({
      estado_id: nuevoEstado,
      departamento_actual_id: departamentoDestino,
      fecha_actualizacion: new Date()
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: departamentoDestino,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: nuevoEstado,
      comentario: req.body.comentario || `Transferida desde ${departamentoAnterior} a ${departamentoDestino}`,
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud actualizada con relaciones
    const solicitudActualizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real al departamento destino
    req.io.to(`departamento_${departamentoDestino}`).emit('solicitud_recibida', solicitudActualizada);
    
    // Emitir evento de actualización al departamento origen
    req.io.to(`departamento_${departamentoAnterior}`).emit('solicitud_actualizada', solicitudActualizada);

    res.json({
      success: true,
      message: 'Solicitud transferida exitosamente',
      data: solicitudActualizada
    });
  } catch (error) {
    console.error('Error transfiriendo solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// PUT /api/solicitudes/:id/finalizar - Finalizar solicitud
router.put('/:id/finalizar', [
  body('comentario').optional().isLength({ max: 500 })
], handleValidationErrors, registrarAuditoria('finalizar_solicitud'), async (req, res) => {
  try {
    const solicitud = await Solicitud.findByPk(req.params.id);
    
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }

    // Guardar estado anterior para historial
    const estadoAnterior = solicitud.estado_id;
    const departamentoAnterior = solicitud.departamento_actual_id;

    // Finalizar solicitud
    await solicitud.update({
      finalizada: true,
      fecha_finalizacion: new Date(),
      fecha_actualizacion: new Date(),
      estado_id: 4 // Estado: Completada
    });

    // Crear entrada en historial
    await HistorialSolicitud.create({
      solicitud_id: req.params.id,
      departamento_origen_id: departamentoAnterior,
      departamento_destino_id: departamentoAnterior,
      estado_anterior_id: estadoAnterior,
      estado_nuevo_id: 4,
      comentario: req.body.comentario || 'Solicitud finalizada',
      usuario: req.body.usuario || 'Sistema'
    });

    // Obtener solicitud finalizada con relaciones
    const solicitudFinalizada = await Solicitud.findByPk(req.params.id, {
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Emitir evento en tiempo real
    req.io.emit('solicitud_finalizada', {
      solicitud: solicitudFinalizada
    });

    res.json({
      success: true,
      message: 'Solicitud finalizada exitosamente',
      data: solicitudFinalizada
    });
  } catch (error) {
    console.error('Error finalizando solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/solicitudes/:id/historial - Obtener historial completo de solicitud (movimientos + necesidades)
router.get('/:id/historial', async (req, res) => {
  try {
    // Obtener historial de movimientos
    const historialMovimientos = await HistorialSolicitud.findAll({
      where: { solicitud_id: req.params.id },
      include: [
        { model: Departamento, as: 'departamentoOrigen', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: EstadoSolicitud, as: 'estadoAnterior', attributes: ['id', 'nombre', 'color'] },
        { model: EstadoSolicitud, as: 'estadoNuevo', attributes: ['id', 'nombre', 'color'] }
      ]
    });

    // Obtener necesidades creadas para esta solicitud
    const necesidades = await Necesidad.findAll({
      where: { solicitud_id: req.params.id },
      attributes: ['id', 'descripcion', 'tipo_analisis', 'fecha_creacion', 'created_by', 'completada', 'fecha_completada']
    });

    // Combinar historial de movimientos y necesidades en un solo array
    const historialCompleto = [];

    // Agregar movimientos al historial
    historialMovimientos.forEach(movimiento => {
      historialCompleto.push({
        tipo: 'movimiento',
        fecha_movimiento: new Date(movimiento.fecha_movimiento).toISOString(),
        comentario: movimiento.comentario,
        usuario: movimiento.usuario,
        departamentoOrigen: movimiento.departamentoOrigen,
        departamentoDestino: movimiento.departamentoDestino,
        estadoAnterior: movimiento.estadoAnterior,
        estadoNuevo: movimiento.estadoNuevo
      });
    });

    // Agregar necesidades al historial
    necesidades.forEach(necesidad => {
      // Evento de creación de necesidad
      historialCompleto.push({
        tipo: 'necesidad_creada',
        fecha_movimiento: new Date(necesidad.fecha_creacion).toISOString(),
        comentario: `Necesidad creada: ${necesidad.descripcion}`,
        usuario: necesidad.created_by,
        necesidad_id: necesidad.id,
        tipo_analisis: necesidad.tipo_analisis,
        departamentoOrigen: null,
        departamentoDestino: { id: 2, nombre: 'Almacén' }, // Las necesidades van dirigidas al almacén
        estadoAnterior: null,
        estadoNuevo: null
      });

      // Si la necesidad está completada, agregar evento de completado
      if (necesidad.completada && necesidad.fecha_completada) {
        historialCompleto.push({
          tipo: 'necesidad_completada',
          fecha_movimiento: new Date(necesidad.fecha_completada).toISOString(),
          comentario: `Necesidad completada: ${necesidad.descripcion}`,
          usuario: necesidad.created_by,
          necesidad_id: necesidad.id,
          tipo_analisis: necesidad.tipo_analisis,
          departamentoOrigen: { id: 2, nombre: 'Almacén' },
          departamentoDestino: { id: 3, nombre: 'Laboratorio' },
          estadoAnterior: null,
          estadoNuevo: null
        });
      }
    });

    // Ordenar todo el historial por fecha
    historialCompleto.sort((a, b) => new Date(a.fecha_movimiento) - new Date(b.fecha_movimiento));
    
    res.json({
      success: true,
      data: historialCompleto
    });
  } catch (error) {
    console.error('Error obteniendo historial:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/solicitudes/estadisticas/generales - Obtener estadísticas generales
router.get('/estadisticas/generales', async (req, res) => {
  try {
    const hoy = new Date();
    const inicioHoy = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());
    const finHoy = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate(), 23, 59, 59);

    // Obtener estadísticas básicas
    const [totalSolicitudes, solicitudesPendientes, solicitudesEnProceso, solicitudesCompletadas, solicitudesHoy, solicitudesUrgentes] = await Promise.all([
      Solicitud.count(),
      Solicitud.count({ where: { finalizada: false, estado_id: 1 } }),
      Solicitud.count({ where: { finalizada: false, estado_id: 2 } }),
      Solicitud.count({ where: { finalizada: true } }),
      Solicitud.count({ 
        where: { 
          fecha_creacion: {
            [Op.between]: [inicioHoy, finHoy]
          }
        }
      }),
      Solicitud.count({ where: { urgencia_id: 3 } }) // Asumiendo que 3 es urgente
    ]);

    const estadisticas = {
      totalSolicitudes,
      solicitudesPendientes,
      solicitudesEnProceso,
      solicitudesCompletadas,
      solicitudesHoy,
      solicitudesUrgentes
    };
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas generales:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/solicitudes/stats/general - Obtener estadísticas detalladas
router.get('/stats/general', [
  query('departamento_id').optional().isInt(),
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate()
], async (req, res) => {
  try {
    const { departamento_id, fecha_desde, fecha_hasta } = req.query;
    
    // Construir filtros WHERE
    const whereClause = {};
    
    if (departamento_id) {
      whereClause.departamento_actual_id = departamento_id;
    }
    
    if (fecha_desde && fecha_hasta) {
      whereClause.fecha_creacion = {
        [Op.between]: [new Date(fecha_desde), new Date(fecha_hasta)]
      };
    } else if (fecha_desde) {
      whereClause.fecha_creacion = {
        [Op.gte]: new Date(fecha_desde)
      };
    } else if (fecha_hasta) {
      whereClause.fecha_creacion = {
        [Op.lte]: new Date(fecha_hasta)
      };
    }

    // Obtener estadísticas básicas
    const [total, finalizadas, pendientes, enProceso] = await Promise.all([
      Solicitud.count({ where: whereClause }),
      Solicitud.count({ where: { ...whereClause, finalizada: true } }),
      Solicitud.count({ where: { ...whereClause, estado_id: 1 } }),
      Solicitud.count({ where: { ...whereClause, estado_id: 2 } })
    ]);

    // Estadísticas por estado
    const porEstado = await Solicitud.findAll({
      where: whereClause,
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('solicitudes.id')), 'cantidad']
      ],
      include: [
        {
          model: EstadoSolicitud,
          as: 'estado',
          attributes: ['id', 'nombre', 'color']
        }
      ],
      group: ['estado.id'],
      raw: false
    });

    // Estadísticas por departamento
    const porDepartamento = await Solicitud.findAll({
      where: whereClause,
      attributes: [
        [sequelize.fn('COUNT', sequelize.col('solicitudes.id')), 'cantidad']
      ],
      include: [
        {
          model: Departamento,
          as: 'departamentoActual',
          attributes: ['id', 'nombre']
        }
      ],
      group: ['departamentoActual.id'],
      raw: false
    });

    const estadisticas = {
      resumen: {
        total,
        finalizadas,
        pendientes,
        enProceso,
        porcentajeFinalizadas: total > 0 ? Math.round((finalizadas / total) * 100) : 0
      },
      porEstado: porEstado.map(item => ({
        estado: item.estado,
        cantidad: parseInt(item.dataValues.cantidad)
      })),
      porDepartamento: porDepartamento.map(item => ({
        departamento: item.departamentoActual,
        cantidad: parseInt(item.dataValues.cantidad)
      }))
    };
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/solicitudes/test/email-connectivity - Probar conectividad del correo
router.get('/test/email-connectivity', async (req, res) => {
  try {
    const resultado = await probarConectividad();
    
    if (resultado.success) {
      res.json({
        success: true,
        message: 'Conectividad del correo verificada exitosamente',
        data: resultado
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error de conectividad del correo',
        details: resultado.error
      });
    }
  } catch (error) {
    console.error('Error probando conectividad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/solicitudes/test/send-email - Enviar correo de prueba
router.post('/test/send-email', async (req, res) => {
  try {
    const resultado = await enviarCorreoPrueba();
    
    if (resultado.success) {
      res.json({
        success: true,
        message: 'Correo de prueba enviado exitosamente',
        data: {
          messageId: resultado.messageId,
          timestamp: new Date().toISOString()
        }
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error enviando correo de prueba',
        details: resultado.error
      });
    }
  } catch (error) {
    console.error('Error enviando correo de prueba:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

module.exports = router;