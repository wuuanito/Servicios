const { executeQuery } = require('../config/database');
const fs = require('fs').promises;
const path = require('path');

class Archivo {
  constructor(data) {
    this.id = data.id;
    this.solicitud_id = data.solicitud_id;
    this.necesidad_id = data.necesidad_id;
    this.nombre_original = data.nombre_original;
    this.nombre_archivo = data.nombre_archivo;
    this.ruta_archivo = data.ruta_archivo;
    this.tipo_mime = data.tipo_mime;
    this.tamaño = data.tamaño;
    this.tipo_adjunto = data.tipo_adjunto;
    this.fecha_subida = data.fecha_subida;
    this.uploaded_by = data.uploaded_by;
  }

  // Crear nuevo archivo
  static async crear(archivoData) {
    const query = `
      INSERT INTO archivos_adjuntos (
        solicitud_id, necesidad_id, nombre_original, nombre_archivo,
        ruta_archivo, tipo_mime, tamaño, tipo_adjunto, uploaded_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const params = [
      archivoData.solicitud_id || null,
      archivoData.necesidad_id || null,
      archivoData.nombre_original,
      archivoData.nombre_archivo,
      archivoData.ruta_archivo,
      archivoData.tipo_mime,
      archivoData.tamaño,
      archivoData.tipo_adjunto || 'solicitud',
      archivoData.uploaded_by
    ];

    const result = await executeQuery(query, params);
    return await this.obtenerPorId(result.insertId);
  }

  // Obtener archivo por ID
  static async obtenerPorId(id) {
    const query = `
      SELECT 
        a.*,
        s.numero_solicitud,
        n.descripcion as necesidad_descripcion
      FROM archivos_adjuntos a
      LEFT JOIN solicitudes s ON a.solicitud_id = s.id
      LEFT JOIN necesidades n ON a.necesidad_id = n.id
      WHERE a.id = ?
    `;
    
    const results = await executeQuery(query, [id]);
    return results.length > 0 ? results[0] : null;
  }

  // Obtener archivos por solicitud
  static async obtenerPorSolicitud(solicitudId, tipoAdjunto = null) {
    let query = `
      SELECT 
        a.*,
        s.numero_solicitud
      FROM archivos_adjuntos a
      LEFT JOIN solicitudes s ON a.solicitud_id = s.id
      WHERE a.solicitud_id = ?
    `;
    
    const params = [solicitudId];
    
    if (tipoAdjunto) {
      query += ' AND a.tipo_adjunto = ?';
      params.push(tipoAdjunto);
    }
    
    query += ' ORDER BY a.fecha_subida DESC';
    
    return await executeQuery(query, params);
  }

  // Obtener archivos por necesidad
  static async obtenerPorNecesidad(necesidadId, tipoAdjunto = null) {
    let query = `
      SELECT 
        a.*,
        n.descripcion as necesidad_descripcion,
        s.numero_solicitud
      FROM archivos_adjuntos a
      LEFT JOIN necesidades n ON a.necesidad_id = n.id
      LEFT JOIN solicitudes s ON n.solicitud_id = s.id
      WHERE a.necesidad_id = ?
    `;
    
    const params = [necesidadId];
    
    if (tipoAdjunto) {
      query += ' AND a.tipo_adjunto = ?';
      params.push(tipoAdjunto);
    }
    
    query += ' ORDER BY a.fecha_subida DESC';
    
    return await executeQuery(query, params);
  }

  // Obtener todos los archivos con filtros
  static async obtenerTodos(filtros = {}) {
    let query = `
      SELECT 
        a.*,
        s.numero_solicitud,
        s.nombre_solicitante,
        n.descripcion as necesidad_descripcion
      FROM archivos_adjuntos a
      LEFT JOIN solicitudes s ON a.solicitud_id = s.id
      LEFT JOIN necesidades n ON a.necesidad_id = n.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (filtros.solicitud_id) {
      query += ' AND a.solicitud_id = ?';
      params.push(filtros.solicitud_id);
    }
    
    if (filtros.necesidad_id) {
      query += ' AND a.necesidad_id = ?';
      params.push(filtros.necesidad_id);
    }
    
    if (filtros.tipo_adjunto) {
      query += ' AND a.tipo_adjunto = ?';
      params.push(filtros.tipo_adjunto);
    }
    
    if (filtros.tipo_mime) {
      query += ' AND a.tipo_mime LIKE ?';
      params.push(`%${filtros.tipo_mime}%`);
    }
    
    if (filtros.fecha_desde) {
      query += ' AND DATE(a.fecha_subida) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      query += ' AND DATE(a.fecha_subida) <= ?';
      params.push(filtros.fecha_hasta);
    }
    
    if (filtros.busqueda) {
      query += ` AND (
        a.nombre_original LIKE ? OR 
        s.numero_solicitud LIKE ? OR 
        s.nombre_solicitante LIKE ?
      )`;
      const searchTerm = `%${filtros.busqueda}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }
    
    query += ' ORDER BY a.fecha_subida DESC';
    
    if (filtros.limite) {
      query += ' LIMIT ?';
      params.push(parseInt(filtros.limite));
    }
    
    return await executeQuery(query, params);
  }

  // Eliminar archivo (físico y de base de datos)
  static async eliminar(id) {
    const archivo = await this.obtenerPorId(id);
    if (!archivo) {
      throw new Error('Archivo no encontrado');
    }

    try {
      // Eliminar archivo físico
      await fs.unlink(archivo.ruta_archivo);
    } catch (error) {
      console.warn(`No se pudo eliminar el archivo físico: ${error.message}`);
    }

    // Eliminar registro de base de datos
    const query = 'DELETE FROM archivos_adjuntos WHERE id = ?';
    const result = await executeQuery(query, [id]);
    
    return result.affectedRows > 0;
  }

  // Verificar si el archivo existe físicamente
  static async verificarExistencia(id) {
    const archivo = await this.obtenerPorId(id);
    if (!archivo) {
      return false;
    }

    try {
      await fs.access(archivo.ruta_archivo);
      return true;
    } catch {
      return false;
    }
  }

  // Obtener estadísticas de archivos
  static async obtenerEstadisticas(filtros = {}) {
    let whereClause = 'WHERE 1=1';
    const params = [];
    
    if (filtros.fecha_desde) {
      whereClause += ' AND DATE(a.fecha_subida) >= ?';
      params.push(filtros.fecha_desde);
    }
    
    if (filtros.fecha_hasta) {
      whereClause += ' AND DATE(a.fecha_subida) <= ?';
      params.push(filtros.fecha_hasta);
    }

    const queries = {
      total: `SELECT COUNT(*) as total FROM archivos_adjuntos a ${whereClause}`,
      tamaño_total: `SELECT SUM(tamaño) as tamaño_total FROM archivos_adjuntos a ${whereClause}`,
      por_tipo: `
        SELECT 
          tipo_adjunto,
          COUNT(*) as cantidad,
          SUM(tamaño) as tamaño_total
        FROM archivos_adjuntos a 
        ${whereClause} 
        GROUP BY tipo_adjunto
      `,
      por_mime: `
        SELECT 
          tipo_mime,
          COUNT(*) as cantidad,
          SUM(tamaño) as tamaño_total
        FROM archivos_adjuntos a 
        ${whereClause} 
        GROUP BY tipo_mime
        ORDER BY cantidad DESC
        LIMIT 10
      `,
      por_mes: `
        SELECT 
          DATE_FORMAT(fecha_subida, '%Y-%m') as mes,
          COUNT(*) as cantidad,
          SUM(tamaño) as tamaño_total
        FROM archivos_adjuntos a 
        ${whereClause} 
        GROUP BY DATE_FORMAT(fecha_subida, '%Y-%m')
        ORDER BY mes DESC
        LIMIT 12
      `
    };

    const resultados = {};
    for (const [key, query] of Object.entries(queries)) {
      const result = await executeQuery(query, params);
      resultados[key] = result;
    }

    return resultados;
  }

  // Limpiar archivos huérfanos (sin solicitud o necesidad asociada)
  static async limpiarHuerfanos() {
    const query = `
      SELECT a.* FROM archivos_adjuntos a
      LEFT JOIN solicitudes s ON a.solicitud_id = s.id
      LEFT JOIN necesidades n ON a.necesidad_id = n.id
      WHERE s.id IS NULL AND n.id IS NULL
    `;
    
    const archivosHuerfanos = await executeQuery(query);
    
    let eliminados = 0;
    for (const archivo of archivosHuerfanos) {
      try {
        await this.eliminar(archivo.id);
        eliminados++;
      } catch (error) {
        console.error(`Error eliminando archivo huérfano ${archivo.id}:`, error.message);
      }
    }
    
    return {
      encontrados: archivosHuerfanos.length,
      eliminados
    };
  }

  // Validar tipo de archivo
  static validarTipoArchivo(tipoMime) {
    const tiposPermitidos = [
      'application/pdf',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ];
    
    return tiposPermitidos.includes(tipoMime);
  }

  // Generar nombre único para archivo
  static generarNombreUnico(nombreOriginal) {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    const extension = path.extname(nombreOriginal);
    const nombreSinExtension = path.basename(nombreOriginal, extension);
    
    return `${nombreSinExtension}_${timestamp}_${random}${extension}`;
  }
}

module.exports = Archivo;