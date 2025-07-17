const express = require('express');
const router = express.Router();
const { ChatMensaje, Solicitud } = require('../models/sequelize');
const { Op } = require('sequelize');

// Obtener mensajes de chat de una solicitud
router.get('/:solicitudId/mensajes', async (req, res) => {
  try {
    const { solicitudId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    
    const offset = (page - 1) * limit;
    
    // Verificar que la solicitud existe
    const solicitud = await Solicitud.findByPk(solicitudId);
    if (!solicitud) {
      return res.status(404).json({ error: 'Solicitud no encontrada' });
    }
    
    const mensajes = await ChatMensaje.findAndCountAll({
      where: { solicitud_id: solicitudId },
      order: [['created_at', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.json({
      mensajes: mensajes.rows,
      total: mensajes.count,
      page: parseInt(page),
      totalPages: Math.ceil(mensajes.count / limit)
    });
    
  } catch (error) {
    console.error('Error obteniendo mensajes:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Enviar un mensaje
router.post('/:solicitudId/mensajes', async (req, res) => {
  try {
    const { solicitudId } = req.params;
    const { usuario_id, usuario_nombre, mensaje, tipo = 'mensaje', archivo_url, archivo_nombre } = req.body;
    
    // Validaciones
    if (!usuario_id || !usuario_nombre || !mensaje) {
      return res.status(400).json({ error: 'Faltan campos requeridos' });
    }
    
    // Verificar que la solicitud existe
    const solicitud = await Solicitud.findByPk(solicitudId);
    if (!solicitud) {
      return res.status(404).json({ error: 'Solicitud no encontrada' });
    }
    
    // Crear el mensaje
    const nuevoMensaje = await ChatMensaje.create({
      solicitud_id: solicitudId,
      usuario_id,
      usuario_nombre,
      mensaje,
      tipo,
      archivo_url,
      archivo_nombre,
      leido_por: [usuario_id] // El remitente ya ha "leído" su propio mensaje
    });
    
    // Emitir el mensaje a todos los usuarios conectados a esta solicitud
    req.io.to(`solicitud_${solicitudId}`).emit('nuevo_mensaje', {
      mensaje: nuevoMensaje,
      solicitud_id: solicitudId
    });
    
    // Emitir notificación de mensaje no leído a usuarios que no están en el chat
    req.io.emit('mensaje_no_leido', {
      solicitud_id: solicitudId,
      usuario_remitente: usuario_nombre,
      mensaje_preview: mensaje.substring(0, 50) + (mensaje.length > 50 ? '...' : ''),
      timestamp: nuevoMensaje.created_at
    });
    
    res.status(201).json(nuevoMensaje);
    
  } catch (error) {
    console.error('Error enviando mensaje:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Marcar mensajes como leídos
router.put('/:solicitudId/mensajes/marcar-leidos', async (req, res) => {
  try {
    const { solicitudId } = req.params;
    const { usuario_id } = req.body;
    
    if (!usuario_id) {
      return res.status(400).json({ error: 'usuario_id es requerido' });
    }
    
    // Obtener todos los mensajes no leídos por este usuario
    const mensajes = await ChatMensaje.findAll({
      where: {
        solicitud_id: solicitudId,
        leido_por: {
          [Op.not]: {
            [Op.contains]: [usuario_id]
          }
        }
      }
    });
    
    // Marcar como leídos
    for (const mensaje of mensajes) {
      const leidoPor = mensaje.leido_por || [];
      if (!leidoPor.includes(usuario_id)) {
        leidoPor.push(usuario_id);
        await mensaje.update({ leido_por: leidoPor });
      }
    }
    
    res.json({ mensaje: 'Mensajes marcados como leídos', count: mensajes.length });
    
  } catch (error) {
    console.error('Error marcando mensajes como leídos:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Obtener conteo de mensajes no leídos por solicitud para un usuario
router.get('/mensajes-no-leidos/:usuarioId', async (req, res) => {
  try {
    const { usuarioId } = req.params;
    
    const mensajesNoLeidos = await ChatMensaje.findAll({
      attributes: ['solicitud_id'],
      where: {
        usuario_id: {
          [Op.ne]: usuarioId // No incluir mensajes del propio usuario
        },
        leido_por: {
          [Op.not]: {
            [Op.contains]: [usuarioId]
          }
        }
      },
      group: ['solicitud_id'],
      raw: true
    });
    
    // Contar mensajes no leídos por solicitud
    const conteoPromises = mensajesNoLeidos.map(async (item) => {
      const count = await ChatMensaje.count({
        where: {
          solicitud_id: item.solicitud_id,
          usuario_id: {
            [Op.ne]: usuarioId
          },
          leido_por: {
            [Op.not]: {
              [Op.contains]: [usuarioId]
            }
          }
        }
      });
      
      return {
        solicitud_id: item.solicitud_id,
        mensajes_no_leidos: count
      };
    });
    
    const conteos = await Promise.all(conteoPromises);
    
    res.json(conteos);
    
  } catch (error) {
    console.error('Error obteniendo mensajes no leídos:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

module.exports = router;