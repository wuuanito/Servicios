const express = require('express');
const { query, validationResult } = require('express-validator');
const { Op } = require('sequelize');
const { AuditoriaAcciones, Solicitud } = require('../models/sequelize');
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

// GET /api/auditoria/solicitud/:id - Obtener historial de auditoría de una solicitud
router.get('/solicitud/:id', [
  query('limite').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  query('accion').optional().isString()
], handleValidationErrors, async (req, res) => {
  try {
    const solicitudId = parseInt(req.params.id);
    const { limite = 50, offset = 0, accion } = req.query;
    
    // Verificar que la solicitud existe
    const solicitud = await Solicitud.findByPk(solicitudId);
    if (!solicitud) {
      return res.status(404).json({
        error: 'Solicitud no encontrada'
      });
    }
    
    const opciones = {
      limite: parseInt(limite),
      offset: parseInt(offset)
    };
    
    if (accion) {
      opciones.accion = accion;
    }
    
    const historial = await AuditoriaAcciones.obtenerHistorialSolicitud(solicitudId, opciones);
    
    res.json({
      success: true,
      data: historial,
      meta: {
        solicitud_id: solicitudId,
        limite: parseInt(limite),
        offset: parseInt(offset),
        total: historial.length
      }
    });
  } catch (error) {
    console.error('Error obteniendo historial de auditoría:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/auditoria/estadisticas - Obtener estadísticas de auditoría
router.get('/estadisticas', [
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('usuario').optional().isString(),
  query('accion').optional().isString()
], handleValidationErrors, async (req, res) => {
  try {
    const filtros = {
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta,
      usuario: req.query.usuario,
      accion: req.query.accion
    };
    
    const estadisticas = await AuditoriaAcciones.obtenerEstadisticas(filtros);
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas de auditoría:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/auditoria/usuario/:usuario - Obtener acciones de un usuario específico
router.get('/usuario/:usuario', [
  query('limite').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('accion').optional().isString()
], handleValidationErrors, async (req, res) => {
  try {
    const usuario = req.params.usuario;
    const { limite = 50, offset = 0, fecha_desde, fecha_hasta, accion } = req.query;
    
    const whereClause = { usuario };
    
    if (fecha_desde && fecha_hasta) {
      whereClause.fecha_accion = {
        [Op.between]: [new Date(fecha_desde), new Date(fecha_hasta)]
      };
    }
    
    if (accion) {
      whereClause.accion = accion;
    }
    
    const acciones = await AuditoriaAcciones.findAll({
      where: whereClause,
      include: [
        {
          model: Solicitud,
          as: 'solicitud',
          attributes: ['id', 'numero_solicitud', 'nombre_materia_prima', 'nombre_solicitante']
        }
      ],
      order: [['fecha_accion', 'DESC']],
      limit: parseInt(limite),
      offset: parseInt(offset)
    });
    
    const total = await AuditoriaAcciones.count({ where: whereClause });
    
    res.json({
      success: true,
      data: acciones,
      meta: {
        usuario,
        limite: parseInt(limite),
        offset: parseInt(offset),
        total
      }
    });
  } catch (error) {
    console.error('Error obteniendo acciones del usuario:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/auditoria/acciones/tipos - Obtener tipos de acciones disponibles
router.get('/acciones/tipos', async (req, res) => {
  try {
    const tiposAcciones = [
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
    ];
    
    res.json({
      success: true,
      data: tiposAcciones
    });
  } catch (error) {
    console.error('Error obteniendo tipos de acciones:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/auditoria/reporte - Generar reporte de auditoría
router.get('/reporte', [
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('usuario').optional().isString(),
  query('accion').optional().isString(),
  query('formato').optional().isIn(['json', 'csv'])
], handleValidationErrors, async (req, res) => {
  try {
    const { fecha_desde, fecha_hasta, usuario, accion, formato = 'json' } = req.query;
    
    const whereClause = {};
    
    if (fecha_desde && fecha_hasta) {
      whereClause.fecha_accion = {
        [Op.between]: [new Date(fecha_desde), new Date(fecha_hasta)]
      };
    }
    
    if (usuario) {
      whereClause.usuario = usuario;
    }
    
    if (accion) {
      whereClause.accion = accion;
    }
    
    const acciones = await AuditoriaAcciones.findAll({
      where: whereClause,
      include: [
        {
          model: Solicitud,
          as: 'solicitud',
          attributes: ['id', 'numero_solicitud', 'nombre_materia_prima', 'nombre_solicitante']
        }
      ],
      order: [['fecha_accion', 'DESC']],
      limit: 1000 // Límite para reportes
    });
    
    if (formato === 'csv') {
      // Generar CSV
      const csvHeader = 'Fecha,Usuario,Acción,Solicitud,Materia Prima,Solicitante,Descripción\n';
      const csvData = acciones.map(accion => {
        const fecha = new Date(accion.fecha_accion).toLocaleString('es-ES');
        const solicitud = accion.solicitud ? accion.solicitud.numero_solicitud : 'N/A';
        const materiaPrima = accion.solicitud ? accion.solicitud.nombre_materia_prima : 'N/A';
        const solicitante = accion.solicitud ? accion.solicitud.nombre_solicitante : 'N/A';
        const descripcion = (accion.descripcion || '').replace(/,/g, ';').replace(/\n/g, ' ');
        
        return `"${fecha}","${accion.usuario}","${accion.accion}","${solicitud}","${materiaPrima}","${solicitante}","${descripcion}"`;
      }).join('\n');
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="reporte_auditoria_${new Date().toISOString().split('T')[0]}.csv"`);
      res.send(csvHeader + csvData);
    } else {
      // Respuesta JSON
      res.json({
        success: true,
        data: acciones,
        meta: {
          total: acciones.length,
          filtros: { fecha_desde, fecha_hasta, usuario, accion },
          generado: new Date().toISOString()
        }
      });
    }
  } catch (error) {
    console.error('Error generando reporte de auditoría:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

module.exports = router;