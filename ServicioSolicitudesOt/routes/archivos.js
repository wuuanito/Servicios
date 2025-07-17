const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { body, validationResult, query } = require('express-validator');
const Archivo = require('../models/Archivo');
const Solicitud = require('../models/Solicitud');
const Necesidad = require('../models/Necesidad');
const router = express.Router();

// Configuración de multer para subida de archivos
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadPath = process.env.UPLOAD_PATH || './uploads';
    
    // Crear directorio si no existe
    try {
      await fs.mkdir(uploadPath, { recursive: true });
      
      // Crear subdirectorios por tipo
      const tipoAdjunto = req.body.tipo_adjunto || 'solicitud';
      const subDir = path.join(uploadPath, tipoAdjunto);
      await fs.mkdir(subDir, { recursive: true });
      
      cb(null, subDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    // Generar nombre único
    const nombreUnico = Archivo.generarNombreUnico(file.originalname);
    cb(null, nombreUnico);
  }
});

// Filtro de archivos
const fileFilter = (req, file, cb) => {
  // Validar tipo de archivo
  if (Archivo.validarTipoArchivo(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}`), false);
  }
};

// Configuración de multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB por defecto
    files: 5 // Máximo 5 archivos por solicitud
  }
});

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

// Middleware para manejar errores de multer
const handleMulterError = (error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        error: 'Archivo demasiado grande',
        message: `El tamaño máximo permitido es ${process.env.MAX_FILE_SIZE || '10MB'}`
      });
    }
    if (error.code === 'LIMIT_FILE_COUNT') {
      return res.status(400).json({
        error: 'Demasiados archivos',
        message: 'Máximo 5 archivos por solicitud'
      });
    }
  }
  
  if (error.message.includes('Tipo de archivo no permitido')) {
    return res.status(400).json({
      error: 'Tipo de archivo no permitido',
      message: 'Solo se permiten archivos PDF, imágenes (JPG, PNG, GIF, WebP) y documentos de Office'
    });
  }
  
  next(error);
};

// GET /api/archivos - Obtener todos los archivos
router.get('/', [
  query('solicitud_id').optional().isInt(),
  query('necesidad_id').optional().isInt(),
  query('tipo_adjunto').optional().isIn(['solicitud', 'necesidad', 'resultado']),
  query('tipo_mime').optional().isString(),
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate(),
  query('busqueda').optional().isString(),
  query('limite').optional().isInt({ min: 1, max: 100 })
], async (req, res) => {
  try {
    const filtros = {
      solicitud_id: req.query.solicitud_id,
      necesidad_id: req.query.necesidad_id,
      tipo_adjunto: req.query.tipo_adjunto,
      tipo_mime: req.query.tipo_mime,
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta,
      busqueda: req.query.busqueda,
      limite: req.query.limite || 50
    };

    const archivos = await Archivo.obtenerTodos(filtros);
    
    res.json({
      success: true,
      data: archivos,
      total: archivos.length
    });
  } catch (error) {
    console.error('Error obteniendo archivos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/archivos/:id - Obtener información de archivo
router.get('/:id', async (req, res) => {
  try {
    const archivo = await Archivo.obtenerPorId(req.params.id);
    
    if (!archivo) {
      return res.status(404).json({
        error: 'Archivo no encontrado'
      });
    }

    res.json({
      success: true,
      data: archivo
    });
  } catch (error) {
    console.error('Error obteniendo archivo:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/archivos/:id/download - Descargar archivo
router.get('/:id/download', async (req, res) => {
  try {
    const archivo = await Archivo.obtenerPorId(req.params.id);
    
    if (!archivo) {
      return res.status(404).json({
        error: 'Archivo no encontrado'
      });
    }

    // Verificar que el archivo existe físicamente
    const existe = await Archivo.verificarExistencia(req.params.id);
    if (!existe) {
      return res.status(404).json({
        error: 'Archivo físico no encontrado'
      });
    }

    // Configurar headers para descarga
    res.setHeader('Content-Disposition', `attachment; filename="${archivo.nombre_original}"`);
    res.setHeader('Content-Type', archivo.tipo_mime);
    
    // Enviar archivo
    res.sendFile(path.resolve(archivo.ruta_archivo));
  } catch (error) {
    console.error('Error descargando archivo:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/archivos/solicitud/:solicitudId - Obtener archivos por solicitud
router.get('/solicitud/:solicitudId', [
  query('tipo_adjunto').optional().isIn(['solicitud', 'necesidad', 'resultado'])
], async (req, res) => {
  try {
    const archivos = await Archivo.obtenerPorSolicitud(
      req.params.solicitudId,
      req.query.tipo_adjunto
    );
    
    res.json({
      success: true,
      data: archivos,
      total: archivos.length
    });
  } catch (error) {
    console.error('Error obteniendo archivos por solicitud:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/archivos/necesidad/:necesidadId - Obtener archivos por necesidad
router.get('/necesidad/:necesidadId', [
  query('tipo_adjunto').optional().isIn(['necesidad', 'resultado'])
], async (req, res) => {
  try {
    const archivos = await Archivo.obtenerPorNecesidad(
      req.params.necesidadId,
      req.query.tipo_adjunto
    );
    
    res.json({
      success: true,
      data: archivos,
      total: archivos.length
    });
  } catch (error) {
    console.error('Error obteniendo archivos por necesidad:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/archivos/upload - Subir archivos
router.post('/upload', upload.array('archivos', 5), [
  body('solicitud_id').optional().isInt({ min: 1 }),
  body('necesidad_id').optional().isInt({ min: 1 }),
  body('tipo_adjunto').optional().isIn(['solicitud', 'necesidad', 'resultado']),
  body('uploaded_by').optional().isString()
], handleValidationErrors, async (req, res) => {
  try {
    const { solicitud_id, necesidad_id, tipo_adjunto, uploaded_by } = req.body;
    
    // Validar que se proporcione al menos solicitud_id o necesidad_id
    if (!solicitud_id && !necesidad_id) {
      return res.status(400).json({
        error: 'Debe proporcionar solicitud_id o necesidad_id'
      });
    }
    
    // Validar que la solicitud o necesidad existe
    if (solicitud_id) {
      const solicitud = await Solicitud.obtenerPorId(solicitud_id);
      if (!solicitud) {
        return res.status(404).json({
          error: 'Solicitud no encontrada'
        });
      }
    }
    
    if (necesidad_id) {
      const necesidad = await Necesidad.obtenerPorId(necesidad_id);
      if (!necesidad) {
        return res.status(404).json({
          error: 'Necesidad no encontrada'
        });
      }
    }
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        error: 'No se proporcionaron archivos'
      });
    }

    const archivosCreados = [];
    
    // Procesar cada archivo subido
    for (const file of req.files) {
      const archivoData = {
        solicitud_id: solicitud_id || null,
        necesidad_id: necesidad_id || null,
        nombre_original: file.originalname,
        nombre_archivo: file.filename,
        ruta_archivo: file.path,
        tipo_mime: file.mimetype,
        tamaño: file.size,
        tipo_adjunto: tipo_adjunto || 'solicitud',
        uploaded_by: uploaded_by
      };
      
      const archivo = await Archivo.crear(archivoData);
      archivosCreados.push(archivo);
    }
    
    // Emitir evento en tiempo real
    req.io.emit('archivos_subidos', {
      archivos: archivosCreados,
      solicitud_id,
      necesidad_id
    });
    
    res.status(201).json({
      success: true,
      message: `${archivosCreados.length} archivo(s) subido(s) exitosamente`,
      data: archivosCreados
    });
  } catch (error) {
    console.error('Error subiendo archivos:', error);
    
    // Limpiar archivos si hubo error
    if (req.files) {
      for (const file of req.files) {
        try {
          await fs.unlink(file.path);
        } catch (unlinkError) {
          console.error('Error eliminando archivo temporal:', unlinkError);
        }
      }
    }
    
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
}, handleMulterError);

// DELETE /api/archivos/:id - Eliminar archivo
router.delete('/:id', async (req, res) => {
  try {
    const archivo = await Archivo.obtenerPorId(req.params.id);
    
    if (!archivo) {
      return res.status(404).json({
        error: 'Archivo no encontrado'
      });
    }

    const eliminado = await Archivo.eliminar(req.params.id);
    
    if (eliminado) {
      // Emitir evento en tiempo real
      req.io.emit('archivo_eliminado', {
        archivo_id: req.params.id,
        solicitud_id: archivo.solicitud_id,
        necesidad_id: archivo.necesidad_id
      });
      
      res.json({
        success: true,
        message: 'Archivo eliminado exitosamente'
      });
    } else {
      res.status(500).json({
        error: 'No se pudo eliminar el archivo'
      });
    }
  } catch (error) {
    console.error('Error eliminando archivo:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// GET /api/archivos/stats/general - Obtener estadísticas de archivos
router.get('/stats/general', [
  query('fecha_desde').optional().isDate(),
  query('fecha_hasta').optional().isDate()
], async (req, res) => {
  try {
    const filtros = {
      fecha_desde: req.query.fecha_desde,
      fecha_hasta: req.query.fecha_hasta
    };

    const estadisticas = await Archivo.obtenerEstadisticas(filtros);
    
    res.json({
      success: true,
      data: estadisticas
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas de archivos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

// POST /api/archivos/cleanup - Limpiar archivos huérfanos
router.post('/cleanup', async (req, res) => {
  try {
    const resultado = await Archivo.limpiarHuerfanos();
    
    res.json({
      success: true,
      message: 'Limpieza completada',
      data: resultado
    });
  } catch (error) {
    console.error('Error en limpieza de archivos:', error);
    res.status(500).json({
      error: 'Error interno del servidor',
      message: error.message
    });
  }
});

module.exports = router;