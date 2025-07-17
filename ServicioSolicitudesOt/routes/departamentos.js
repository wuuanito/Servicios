const express = require('express');
const { Op } = require('sequelize');
const {
  Departamento,
  Solicitud,
  EstadoSolicitud,
  NivelUrgencia,
  sequelize
} = require('../models/sequelize');
const router = express.Router();

// GET /api/departamentos - Obtener todos los departamentos
router.get('/', async (req, res) => {
  try {
    const departamentos = await Departamento.findAll({
      where: { activo: true },
      order: [['nombre', 'ASC']],
      attributes: ['id', 'nombre', 'descripcion', 'activo', 'created_at', 'updated_at']
    });
    
    res.json({
      success: true,
      data: departamentos
    });
  } catch (error) {
    console.error('Error obteniendo departamentos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/:id - Obtener departamento por ID
router.get('/:id', async (req, res) => {
  try {
    const departamento = await Departamento.findByPk(req.params.id, {
      attributes: ['id', 'nombre', 'descripcion', 'activo', 'created_at', 'updated_at']
    });
    
    if (!departamento) {
      return res.status(404).json({
        error: 'Departamento no encontrado'
      });
    }
    
    res.json({
      success: true,
      data: departamento
    });
  } catch (error) {
    console.error('Error obteniendo departamento:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/:id/solicitudes - Obtener solicitudes por departamento
router.get('/:id/solicitudes', async (req, res) => {
  try {
    const solicitudes = await Solicitud.findAll({
      where: { departamento_actual_id: req.params.id },
      include: [
        { model: Departamento, as: 'departamentoDestino', attributes: ['id', 'nombre'] },
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: NivelUrgencia, as: 'urgencia', attributes: ['id', 'nombre', 'color', 'prioridad'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre', 'color'] }
      ],
      order: [['urgencia', 'prioridad', 'DESC'], ['fecha_creacion', 'DESC']]
    });
    
    res.json({
      success: true,
      data: solicitudes,
      total: solicitudes.length
    });
  } catch (error) {
    console.error('Error obteniendo solicitudes del departamento:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/:id/estadisticas - Obtener estadísticas por departamento
router.get('/:id/estadisticas', async (req, res) => {
  try {
    const departamentoId = req.params.id;
    
    const queries = {
      total: `
        SELECT COUNT(*) as total 
        FROM solicitudes 
        WHERE departamento_actual_id = ?
      `,
      pendientes: `
        SELECT COUNT(*) as pendientes 
        FROM solicitudes 
        WHERE departamento_actual_id = ? AND finalizada = FALSE
      `,
      finalizadas: `
        SELECT COUNT(*) as finalizadas 
        FROM solicitudes 
        WHERE departamento_actual_id = ? AND finalizada = TRUE
      `,
      por_estado: `
        SELECT 
          e.nombre,
          e.color,
          COUNT(*) as cantidad
        FROM solicitudes s
        JOIN estados_solicitud e ON s.estado_id = e.id
        WHERE s.departamento_actual_id = ?
        GROUP BY s.estado_id, e.nombre, e.color
      `,
      por_urgencia: `
        SELECT 
          u.nombre,
          u.color,
          u.prioridad,
          COUNT(*) as cantidad
        FROM solicitudes s
        JOIN niveles_urgencia u ON s.urgencia_id = u.id
        WHERE s.departamento_actual_id = ?
        GROUP BY s.urgencia_id, u.nombre, u.color, u.prioridad
        ORDER BY u.prioridad DESC
      `,
      ultimas_24h: `
        SELECT COUNT(*) as nuevas_24h
        FROM solicitudes
        WHERE departamento_actual_id = ? 
        AND fecha_creacion >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
      `
    };

    const estadisticas = {};
    
    for (const [key, query] of Object.entries(queries)) {
      const result = await executeQuery(query, [departamentoId]);
      estadisticas[key] = result;
    }
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas del departamento:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/estados - Obtener todos los estados de solicitud
router.get('/maestros/estados', async (req, res) => {
  try {
    const estados = await EstadoSolicitud.findAll({
      where: { activo: true },
      order: [['id', 'ASC']],
      attributes: ['id', 'nombre', 'descripcion', 'color', 'activo']
    });
    
    res.json({
      success: true,
      data: estados
    });
  } catch (error) {
    console.error('Error obteniendo estados:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/urgencias - Obtener todos los niveles de urgencia
router.get('/maestros/urgencias', async (req, res) => {
  try {
    const urgencias = await NivelUrgencia.findAll({
      order: [['prioridad', 'DESC']],
      attributes: ['id', 'nombre', 'descripcion', 'prioridad', 'color']
    });
    
    res.json({
      success: true,
      data: urgencias
    });
  } catch (error) {
    console.error('Error obteniendo niveles de urgencia:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/urgencias - Ruta directa para urgencias (compatibilidad con frontend)
router.get('/urgencias', async (req, res) => {
  try {
    const urgencias = await NivelUrgencia.findAll({
      order: [['prioridad', 'DESC']],
      attributes: ['id', 'nombre', 'descripcion', 'prioridad', 'color']
    });
    
    res.json({
      success: true,
      data: urgencias
    });
  } catch (error) {
    console.error('Error obteniendo niveles de urgencia:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/estados - Ruta directa para estados (compatibilidad con frontend)
router.get('/estados', async (req, res) => {
  try {
    const estados = await EstadoSolicitud.findAll({
      where: { activo: true },
      order: [['id', 'ASC']],
      attributes: ['id', 'nombre', 'descripcion', 'color', 'activo']
    });
    
    res.json({
      success: true,
      data: estados
    });
  } catch (error) {
    console.error('Error obteniendo estados:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/maestros/todos - Obtener todos los datos maestros
router.get('/maestros/todos', async (req, res) => {
  try {
    const [departamentos, estados, urgencias] = await Promise.all([
      Departamento.findAll({
        where: { activo: true },
        order: [['nombre', 'ASC']],
        attributes: ['id', 'nombre', 'descripcion', 'activo']
      }),
      EstadoSolicitud.findAll({
        where: { activo: true },
        order: [['id', 'ASC']],
        attributes: ['id', 'nombre', 'descripcion', 'color', 'activo']
      }),
      NivelUrgencia.findAll({
        order: [['prioridad', 'DESC']],
        attributes: ['id', 'nombre', 'descripcion', 'prioridad', 'color']
      })
    ]);
    
    res.json({
      success: true,
      data: {
        departamentos,
        estados,
        urgencias
      }
    });
  } catch (error) {
    console.error('Error obteniendo datos maestros:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/dashboard/general - Dashboard general del sistema
router.get('/dashboard/general', async (req, res) => {
  try {
    const queries = {
      resumen_general: `
        SELECT 
          COUNT(*) as total_solicitudes,
          COUNT(CASE WHEN finalizada = FALSE THEN 1 END) as pendientes,
          COUNT(CASE WHEN finalizada = TRUE THEN 1 END) as finalizadas,
          COUNT(CASE WHEN DATE(fecha_creacion) = CURDATE() THEN 1 END) as hoy
        FROM solicitudes
      `,
      por_departamento: `
        SELECT 
          d.nombre as departamento,
          COUNT(*) as total,
          COUNT(CASE WHEN s.finalizada = FALSE THEN 1 END) as pendientes
        FROM solicitudes s
        JOIN departamentos d ON s.departamento_actual_id = d.id
        GROUP BY d.id, d.nombre
        ORDER BY pendientes DESC
      `,
      por_urgencia: `
        SELECT 
          u.nombre as urgencia,
          u.color,
          u.prioridad,
          COUNT(*) as cantidad
        FROM solicitudes s
        JOIN niveles_urgencia u ON s.urgencia_id = u.id
        WHERE s.finalizada = FALSE
        GROUP BY u.id, u.nombre, u.color, u.prioridad
        ORDER BY u.prioridad DESC
      `,
      necesidades_laboratorio: `
        SELECT 
          COUNT(*) as total_necesidades,
          COUNT(CASE WHEN completada = FALSE THEN 1 END) as pendientes,
          COUNT(CASE WHEN completada = TRUE THEN 1 END) as completadas
        FROM necesidades
      `,
      actividad_reciente: `
        SELECT 
          s.numero_solicitud,
          s.nombre_solicitante,
          s.nombre_materia_prima,
          d.nombre as departamento_actual,
          e.nombre as estado,
          e.color as estado_color,
          u.nombre as urgencia,
          u.color as urgencia_color,
          s.fecha_actualizacion
        FROM solicitudes s
        JOIN departamentos d ON s.departamento_actual_id = d.id
        JOIN estados_solicitud e ON s.estado_id = e.id
        JOIN niveles_urgencia u ON s.urgencia_id = u.id
        WHERE s.finalizada = FALSE
        ORDER BY s.fecha_actualizacion DESC
        LIMIT 10
      `,
      estadisticas_archivos: `
        SELECT 
          COUNT(*) as total_archivos,
          SUM(tamaño) as tamaño_total,
          COUNT(CASE WHEN DATE(fecha_subida) = CURDATE() THEN 1 END) as subidos_hoy
        FROM archivos_adjuntos
      `
    };

    const dashboard = {};
    
    for (const [key, query] of Object.entries(queries)) {
      const result = await executeQuery(query);
      dashboard[key] = result;
    }
    
    res.json({
      success: true,
      data: dashboard
    });
  } catch (error) {
    console.error('Error obteniendo dashboard:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/departamentos/reportes/flujo - Reporte de flujo de solicitudes
router.get('/reportes/flujo', async (req, res) => {
  try {
    const { fecha_desde, fecha_hasta } = req.query;
    
    let whereClause = 'WHERE 1=1';
    const params = [];
    
    if (fecha_desde) {
      whereClause += ' AND DATE(h.fecha_movimiento) >= ?';
      params.push(fecha_desde);
    }
    
    if (fecha_hasta) {
      whereClause += ' AND DATE(h.fecha_movimiento) <= ?';
      params.push(fecha_hasta);
    }

    const query = `
      SELECT 
        do.nombre as departamento_origen,
        dd.nombre as departamento_destino,
        COUNT(*) as cantidad_movimientos,
        AVG(TIMESTAMPDIFF(HOUR, s.fecha_creacion, h.fecha_movimiento)) as tiempo_promedio_horas
      FROM historial_solicitudes h
      JOIN solicitudes s ON h.solicitud_id = s.id
      LEFT JOIN departamentos do ON h.departamento_origen_id = do.id
      JOIN departamentos dd ON h.departamento_destino_id = dd.id
      ${whereClause}
      GROUP BY h.departamento_origen_id, h.departamento_destino_id, do.nombre, dd.nombre
      ORDER BY cantidad_movimientos DESC
    `;
    
    const flujo = await executeQuery(query, params);
    
    res.json({
      success: true,
      data: flujo
    });
  } catch (error) {
    console.error('Error obteniendo reporte de flujo:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

module.exports = router;