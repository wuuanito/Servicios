const { executeQuery, executeTransaction } = require('../config/database');

class Necesidad {
  constructor(data) {
    this.id = data.id;
    this.solicitud_id = data.solicitud_id;
    this.descripcion = data.descripcion;
    this.tipo_analisis = data.tipo_analisis;
    this.parametros_requeridos = data.parametros_requeridos;
    this.fecha_creacion = data.fecha_creacion;
    this.fecha_completada = data.fecha_completada;
    this.completada = data.completada;
    this.resultado = data.resultado;
    this.observaciones = data.observaciones;
    this.created_by = data.created_by;
  }

  // Crear nueva necesidad
  static async crear(necesidadData) {
    const query = `
      INSERT INTO necesidades (
        solicitud_id, descripcion, tipo_analisis, 
        parametros_requeridos, created_by, fecha_creacion
      ) VALUES (?, ?, ?, ?, ?, NOW())
    `;
    
    const params = [
      necesidadData.solicitud_id,
      necesidadData.descripcion,
      necesidadData.tipo_analisis,
      necesidadData.parametros_requeridos,
      necesidadData.created_by
    ];

    const result = await executeQuery(query, params);
    return await this.obtenerPorId(result.insertId);
  }

  // Obtener necesidad por ID
  static async obtenerPorId(id) {
    const query = `
      SELECT 
        n.*,
        s.numero_solicitud,
        s.nombre_solicitante,
        s.nombre_materia_prima,
        s.lote,
        s.proveedor
      FROM necesidades n
      LEFT JOIN solicitudes s ON n.solicitud_id = s.id
      WHERE n.id = ?
    `;
    
    const results = await executeQuery(query, [id]);
    return results.length > 0 ? results[0] : null;
  }

  // Obtener necesidades por solicitud
  static async obtenerPorSolicitud(solicitudId) {
    const query = `
      SELECT 
        n.*,
        s.numero_solicitud,
        s.nombre_solicitante,
        s.nombre_materia_prima
      FROM necesidades n
      LEFT JOIN solicitudes s ON n.solicitud_id = s.id
      WHERE n.solicitud_id = ?
      ORDER BY n.fecha_creacion DESC
    `;
    
    return await executeQuery(query, [solicitudId]);
  }

  // Obtener todas las necesidades con filtros
  static async obtenerTodas(filtros = {}) {
    let query = `
      SELECT 
        n.*,
        s.numero_solicitud,
        s.nombre_solicitante,
        s.nombre_materia_prima,
        s.lote,
        s.proveedor,
        u.nombre as urgencia_nombre,
        u.color as urgencia_color,
        u.prioridad as urgencia_prioridad
      FROM necesidades n
      LEFT JOIN solicitudes s ON n.solicitud_id = s.id
      LEFT JOIN niveles_urgencia u ON s.urgencia_id = u.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (filtros.completada !== undefined) {
      query += ' AND n.completada = ?';
      params.push(filtros.completada);
    }
    
    if (filtros.tipo_analisis) {
      query += ' AND n.tipo_analisis LIKE ?';
      params.push(`%${filtros.tipo_analisis}%`);
    }
    
    if (filtros.fecha_desde) {
      query += ' AND DATE(n.fecha_creacion) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      query += ' AND DATE(n.fecha_creacion) <= ?';
      params.push(filtros.fecha_hasta);
    }
    
    if (filtros.busqueda) {
      query += ` AND (
        s.numero_solicitud LIKE ? OR 
        s.nombre_solicitante LIKE ? OR 
        s.nombre_materia_prima LIKE ? OR 
        n.descripcion LIKE ? OR 
        n.tipo_analisis LIKE ?
      )`;
      const searchTerm = `%${filtros.busqueda}%`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm, searchTerm);
    }
    
    query += ' ORDER BY n.completada ASC, u.prioridad DESC, n.fecha_creacion DESC';
    
    if (filtros.limite) {
      query += ' LIMIT ?';
      params.push(parseInt(filtros.limite));
    }
    
    return await executeQuery(query, params);
  }

  // Completar necesidad con resultado
  static async completar(id, resultado, observaciones = null, completedBy = null) {
    const query = `
      UPDATE necesidades 
      SET 
        completada = TRUE,
        fecha_completada = NOW(),
        resultado = ?,
        observaciones = ?
      WHERE id = ?
    `;
    
    await executeQuery(query, [resultado, observaciones, id]);
    return await this.obtenerPorId(id);
  }

  // Actualizar necesidad
  static async actualizar(id, datos) {
    const campos = [];
    const valores = [];
    
    if (datos.descripcion !== undefined) {
      campos.push('descripcion = ?');
      valores.push(datos.descripcion);
    }
    
    if (datos.tipo_analisis !== undefined) {
      campos.push('tipo_analisis = ?');
      valores.push(datos.tipo_analisis);
    }
    
    if (datos.parametros_requeridos !== undefined) {
      campos.push('parametros_requeridos = ?');
      valores.push(datos.parametros_requeridos);
    }
    
    if (datos.resultado !== undefined) {
      campos.push('resultado = ?');
      valores.push(datos.resultado);
    }
    
    if (datos.observaciones !== undefined) {
      campos.push('observaciones = ?');
      valores.push(datos.observaciones);
    }
    
    if (campos.length === 0) {
      throw new Error('No hay campos para actualizar');
    }
    
    valores.push(id);
    
    const query = `UPDATE necesidades SET ${campos.join(', ')} WHERE id = ?`;
    await executeQuery(query, valores);
    
    return await this.obtenerPorId(id);
  }

  // Eliminar necesidad
  static async eliminar(id) {
    const query = 'DELETE FROM necesidades WHERE id = ?';
    const result = await executeQuery(query, [id]);
    return result.affectedRows > 0;
  }

  // Obtener estadísticas de necesidades
  static async obtenerEstadisticas(filtros = {}) {
    let whereClause = 'WHERE 1=1';
    const params = [];
    
    if (filtros.fecha_desde) {
      whereClause += ' AND DATE(n.fecha_creacion) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      whereClause += ' AND DATE(n.fecha_creacion) <= ?';
      params.push(filtros.fecha_hasta);
    }

    const queries = {
      total: `SELECT COUNT(*) as total FROM necesidades n ${whereClause}`,
      completadas: `SELECT COUNT(*) as completadas FROM necesidades n ${whereClause} AND n.completada = TRUE`,
      pendientes: `SELECT COUNT(*) as pendientes FROM necesidades n ${whereClause} AND n.completada = FALSE`,
      por_tipo: `
        SELECT 
          COALESCE(n.tipo_analisis, 'Sin especificar') as tipo,
          COUNT(*) as cantidad 
        FROM necesidades n 
        ${whereClause} 
        GROUP BY n.tipo_analisis
      `,
      tiempo_promedio: `
        SELECT 
          AVG(TIMESTAMPDIFF(HOUR, n.fecha_creacion, n.fecha_completada)) as horas_promedio
        FROM necesidades n 
        ${whereClause} 
        AND n.completada = TRUE 
        AND n.fecha_completada IS NOT NULL
      `
    };

    const resultados = {};
    for (const [key, query] of Object.entries(queries)) {
      const result = await executeQuery(query, params);
      resultados[key] = result;
    }

    return resultados;
  }

  // Obtener necesidades pendientes por urgencia
  static async obtenerPendientesPorUrgencia() {
    const query = `
      SELECT 
        u.nombre as urgencia,
        u.color,
        u.prioridad,
        COUNT(*) as cantidad
      FROM necesidades n
      JOIN solicitudes s ON n.solicitud_id = s.id
      JOIN niveles_urgencia u ON s.urgencia_id = u.id
      WHERE n.completada = FALSE
      GROUP BY u.id, u.nombre, u.color, u.prioridad
      ORDER BY u.prioridad DESC
    `;
    
    return await executeQuery(query);
  }
}

module.exports = Necesidad;