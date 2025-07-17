const nodemailer = require('nodemailer');

// Configuración del transportador de correo
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'notificacionesnaturepharma@gmail.com',
    pass: 'ziuv kuih rwbp onlm'
  }
});

// Función para enviar notificación de solicitud enviada a almacén
const enviarNotificacionAlmacen = async (solicitud) => {
  try {
    const mailOptions = {
      from: 'notificacionesnaturepharma@gmail.com',
      to: 'desarrollos@naturepharma.es',
      subject: `Nueva Solicitud Enviada a Almacén - ${solicitud.numero_solicitud}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
            🏪 Nueva Solicitud en Almacén
          </h2>
          
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #495057; margin-top: 0;">Detalles de la Solicitud</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Número de Solicitud:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.numero_solicitud}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Solicitante:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.nombre_solicitante}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Materia Prima:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.nombre_materia_prima}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Lote:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.lote}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Proveedor:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.proveedor}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Código Artículo:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.codigo_articulo}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Urgencia:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.urgencia?.nombre || 'No especificada'}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Estado:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.estado?.nombre || 'En Proceso'}</td>
              </tr>
            </table>
          </div>
          
          <div style="background-color: #e3f2fd; padding: 15px; border-radius: 8px; border-left: 4px solid #2196f3;">
            <p style="margin: 0; color: #1565c0;">
              <strong>📋 Acción Requerida:</strong> Una nueva solicitud ha sido enviada al departamento de Almacén y requiere atención.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;">
            <p style="color: #6c757d; font-size: 12px; margin: 0;">
              Sistema de Solicitudes NaturePharma<br>
              Notificación automática - No responder a este correo
            </p>
          </div>
        </div>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Notificación de almacén enviada:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error enviando notificación de almacén:', error);
    return { success: false, error: error.message };
  }
};

// Función para enviar notificación de solicitud enviada a expediciones
const enviarNotificacionExpediciones = async (solicitud) => {
  try {
    const mailOptions = {
      from: 'notificacionesnaturepharma@gmail.com',
      to: 'desarrollos@naturepharma.es',
      subject: `Solicitud Finalizada y Enviada a Expediciones - ${solicitud.numero_solicitud}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2c3e50; border-bottom: 2px solid #28a745; padding-bottom: 10px;">
            🚚 Solicitud Enviada a Expediciones
          </h2>
          
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #495057; margin-top: 0;">Detalles de la Solicitud</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Número de Solicitud:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.numero_solicitud}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Solicitante:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.nombre_solicitante}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Materia Prima:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.nombre_materia_prima}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Lote:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.lote}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Proveedor:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.proveedor}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Código Artículo:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.codigo_articulo}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Urgencia:</td>
                <td style="padding: 8px; color: #212529;">${solicitud.urgencia?.nombre || 'No especificada'}</td>
              </tr>
              <tr>
                <td style="padding: 8px; font-weight: bold; color: #6c757d;">Estado:</td>
                <td style="padding: 8px; color: #212529;">Completada</td>
              </tr>
            </table>
          </div>
          
          <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745;">
            <p style="margin: 0; color: #155724;">
              <strong>✅ Solicitud Completada:</strong> La solicitud ha sido procesada exitosamente y enviada al departamento de Expediciones para su despacho final.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;">
            <p style="color: #6c757d; font-size: 12px; margin: 0;">
              Sistema de Solicitudes NaturePharma<br>
              Notificación automática - No responder a este correo
            </p>
          </div>
        </div>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Notificación de expediciones enviada:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error enviando notificación de expediciones:', error);
    return { success: false, error: error.message };
  }
};

// Función para probar la conectividad del correo
const probarConectividad = async () => {
  try {
    await transporter.verify();
    console.log('✅ Servidor de correo conectado correctamente');
    return { success: true, message: 'Conectividad verificada' };
  } catch (error) {
    console.error('❌ Error de conectividad del servidor de correo:', error);
    return { success: false, error: error.message };
  }
};

// Función de prueba para enviar un correo de test
const enviarCorreoPrueba = async () => {
  try {
    const mailOptions = {
      from: 'notificacionesnaturepharma@gmail.com',
      to: 'desarrollos@naturepharma.es',
      subject: 'Prueba de Conectividad - Sistema de Solicitudes',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
            🧪 Prueba de Conectividad
          </h2>
          
          <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; border-left: 4px solid #28a745;">
            <p style="margin: 0; color: #155724;">
              <strong>✅ Éxito:</strong> El sistema de notificaciones por correo electrónico está funcionando correctamente.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;">
            <p style="color: #6c757d; font-size: 12px; margin: 0;">
              Sistema de Solicitudes NaturePharma<br>
              Correo de prueba - ${new Date().toLocaleString()}
            </p>
          </div>
        </div>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Correo de prueba enviado:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('❌ Error enviando correo de prueba:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  enviarNotificacionAlmacen,
  enviarNotificacionExpediciones,
  probarConectividad,
  enviarCorreoPrueba
};