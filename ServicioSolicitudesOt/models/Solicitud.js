const { executeQuery, executeTransaction } = require('../config/database');

class Solicitud {
  constructor(data) {
    this.id = data.id;
    this.numero_solicitud = data.numero_solicitud;
    this.nombre_solicitante = data.nombre_solicitante;
    this.nombre_materia_prima = data.nombre_materia_prima;
    this.lote = data.lote;
    this.proveedor = data.proveedor;
    this.codigo_articulo = data.codigo_articulo;
    this.comentarios = data.comentarios;
    this.departamento_destino_id = data.departamento_destino_id;
    this.departamento_actual_id = data.departamento_actual_id;
    this.urgencia_id = data.urgencia_id;
    this.estado_id = data.estado_id;
    this.fecha_creacion = data.fecha_creacion;
    this.fecha_actualizacion = data.fecha_actualizacion;
    this.finalizada = data.finalizada;
    this.fecha_finalizacion = data.fecha_finalizacion;
    this.created_by = data.created_by;
  }

  // Crear nueva solicitud
  static async crear(solicitudData) {
    const query = `
      INSERT INTO solicitudes (
        nombre_solicitante, nombre_materia_prima, lote, proveedor, 
        codigo_articulo, comentarios, departamento_destino_id, 
        departamento_actual_id, urgencia_id, estado_id, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const params = [
      solicitudData.nombre_solicitante,
      solicitudData.nombre_materia_prima,
      solicitudData.lote,
      solicitudData.proveedor,
      solicitudData.codigo_articulo,
      solicitudData.comentarios,
      solicitudData.departamento_destino_id,
      solicitudData.departamento_destino_id, // departamento_actual_id inicialmente igual al destino
      solicitudData.urgencia_id,
      1, // estado inicial: Pendiente
      solicitudData.created_by
    ];

    const result = await executeQuery(query, params);
    return await this.obtenerPorId(result.insertId);
  }

  // Obtener solicitud por ID con información completa
  static async obtenerPorId(id) {
    const query = `
      SELECT 
        s.*,
        dd.nombre as departamento_destino_nombre,
        da.nombre as departamento_actual_nombre,
        u.nombre as urgencia_nombre,
        u.color as urgencia_color,
        e.nombre as estado_nombre,
        e.color as estado_color
      FROM solicitudes s
      LEFT JOIN departamentos dd ON s.departamento_destino_id = dd.id
      LEFT JOIN departamentos da ON s.departamento_actual_id = da.id
      LEFT JOIN niveles_urgencia u ON s.urgencia_id = u.id
      LEFT JOIN estados_solicitud e ON s.estado_id = e.id
      WHERE s.id = ?
    `;
    
    const results = await executeQuery(query, [id]);
    return results.length > 0 ? results[0] : null;
  }

  // Obtener todas las solicitudes con filtros
  static async obtenerTodas(filtros = {}) {
    let query = `
      SELECT 
        s.*,
        dd.nombre as departamento_destino_nombre,
        da.nombre as departamento_actual_nombre,
        u.nombre as urgencia_nombre,
        u.color as urgencia_color,
        u.prioridad as urgencia_prioridad,
        e.nombre as estado_nombre,
        e.color as estado_color
      FROM solicitudes s
      LEFT JOIN departamentos dd ON s.departamento_destino_id = dd.id
      LEFT JOIN departamentos da ON s.departamento_actual_id = da.id
      LEFT JOIN niveles_urgencia u ON s.urgencia_id = u.id
      LEFT JOIN estados_solicitud e ON s.estado_id = e.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (filtros.departamento_actual_id) {
      query += ' AND s.departamento_actual_id = ?';
      params.push(filtros.departamento_actual_id);
    }
    
    if (filtros.estado_id) {
      query += ' AND s.estado_id = ?';
      params.push(filtros.estado_id);
    }
    
    if (filtros.urgencia_id) {
      query += ' AND s.urgencia_id = ?';
      params.push(filtros.urgencia_id);
    }
    
    if (filtros.finalizada !== undefined) {
      query += ' AND s.finalizada = ?';
      params.push(filtros.finalizada);
    }
    
    if (filtros.fecha_desde) {
      query += ' AND DATE(s.fecha_creacion) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      query += ' AND DATE(s.fecha_creacion) <= ?';
      params.push(filtros.fecha_hasta);
    }
    
    if (filtros.busqueda) {
      query += ` AND (
        s.numero_solicitud LIKE ? OR 
        s.nombre_solicitante LIKE ? OR 
        s.nombre_materia_prima LIKE ? OR 
        s.lote LIKE ? OR 
        s.proveedor LIKE ? OR 
        s.codigo_articulo LIKE ?
      )`;
      const searchTerm = `%${filtros.busqueda}%`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm);
    }
    
    query += ' ORDER BY u.prioridad DESC, s.fecha_creacion DESC';
    
    if (filtros.limite) {
      query += ' LIMIT ?';
      params.push(parseInt(filtros.limite));
    }
    
    return await executeQuery(query, params);
  }

  // Actualizar estado y departamento de solicitud
  static async actualizarEstado(id, nuevoEstadoId, nuevoDepartamentoId = null, comentario = null) {
    const solicitud = await this.obtenerPorId(id);
    if (!solicitud) {
      throw new Error('Solicitud no encontrada');
    }

    const queries = [];
    
    // Actualizar solicitud
    let updateQuery = 'UPDATE solicitudes SET estado_id = ?';
    let updateParams = [nuevoEstadoId];
    
    if (nuevoDepartamentoId) {
      updateQuery += ', departamento_actual_id = ?';
      updateParams.push(nuevoDepartamentoId);
    }
    
    updateQuery += ' WHERE id = ?';
    updateParams.push(id);
    
    queries.push({ query: updateQuery, params: updateParams });
    
    // Registrar en historial
    const historialQuery = `
      INSERT INTO historial_solicitudes (
        solicitud_id, departamento_origen_id, departamento_destino_id, 
        estado_anterior_id, estado_nuevo_id, comentario
      ) VALUES (?, ?, ?, ?, ?, ?)
    `;
    
    const historialParams = [
      id,
      solicitud.departamento_actual_id,
      nuevoDepartamentoId || solicitud.departamento_actual_id,
      solicitud.estado_id,
      nuevoEstadoId,
      comentario
    ];
    
    queries.push({ query: historialQuery, params: historialParams });
    
    await executeTransaction(queries);
    return await this.obtenerPorId(id);
  }

  // Finalizar solicitud
  static async finalizar(id, comentario = null) {
    const queries = [
      {
        query: 'UPDATE solicitudes SET finalizada = TRUE, fecha_finalizacion = NOW(), estado_id = 4 WHERE id = ?',
        params: [id]
      },
      {
        query: `INSERT INTO historial_solicitudes (solicitud_id, estado_nuevo_id, comentario) VALUES (?, 4, ?)`,
        params: [id, comentario || 'Solicitud finalizada']
      }
    ];
    
    await executeTransaction(queries);
    return await this.obtenerPorId(id);
  }

  // Obtener historial de una solicitud
  static async obtenerHistorial(solicitudId) {
    const query = `
      SELECT 
        h.*,
        do.nombre as departamento_origen_nombre,
        dd.nombre as departamento_destino_nombre,
        ea.nombre as estado_anterior_nombre,
        en.nombre as estado_nuevo_nombre,
        en.color as estado_nuevo_color
      FROM historial_solicitudes h
      LEFT JOIN departamentos do ON h.departamento_origen_id = do.id
      LEFT JOIN departamentos dd ON h.departamento_destino_id = dd.id
      LEFT JOIN estados_solicitud ea ON h.estado_anterior_id = ea.id
      LEFT JOIN estados_solicitud en ON h.estado_nuevo_id = en.id
      WHERE h.solicitud_id = ?
      ORDER BY h.fecha_movimiento DESC
    `;
    
    return await executeQuery(query, [solicitudId]);
  }

  // Obtener estadísticas
  static async obtenerEstadisticas(filtros = {}) {
    let whereClause = 'WHERE 1=1';
    const params = [];
    
    if (filtros.departamento_id) {
      whereClause += ' AND departamento_actual_id = ?';
      params.push(filtros.departamento_id);
    }
    
    if (filtros.fecha_desde) {
      whereClause += ' AND DATE(fecha_creacion) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      whereClause += ' AND DATE(fecha_creacion) <= ?';
      params.push(filtros.fecha_hasta);
    }

    const queries = {
      total: `SELECT COUNT(*) as total FROM solicitudes ${whereClause}`,
      finalizadas: `SELECT COUNT(*) as finalizadas FROM solicitudes ${whereClause} AND finalizada = TRUE`,
      pendientes: `SELECT COUNT(*) as pendientes FROM solicitudes ${whereClause} AND finalizada = FALSE`,
      por_estado: `
        SELECT e.nombre, e.color, COUNT(*) as cantidad 
        FROM solicitudes s 
        JOIN estados_solicitud e ON s.estado_id = e.id 
        ${whereClause} 
        GROUP BY s.estado_id, e.nombre, e.color
      `,
      por_urgencia: `
        SELECT u.nombre, u.color, COUNT(*) as cantidad 
        FROM solicitudes s 
        JOIN niveles_urgencia u ON s.urgencia_id = u.id 
        ${whereClause} 
        GROUP BY s.urgencia_id, u.nombre, u.color
      `
    };

    const resultados = {};
    for (const [key, query] of Object.entries(queries)) {
      const result = await executeQuery(query, params);
      resultados[key] = result;
    }

    return resultados;
  }
}

module.exports = Solicitud;