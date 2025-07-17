const { Solicitud, Departamento, EstadoSolicitud, NivelUrgencia } = require('./models/sequelize');

async function crearSolicitudLaboratorio() {
  try {
    console.log('Creando solicitud de prueba para laboratorio...');
    
    // Crear solicitud en departamento de laboratorio (ID: 3)
    const nuevaSolicitud = await Solicitud.create({
      nombre_solicitante: 'Usuario Laboratorio',
      nombre_materia_prima: 'Materia Prima para Análisis',
      lote: 'LOTE-LAB-001',
      proveedor: 'Proveedor Laboratorio',
      codigo_articulo: 'ART-LAB-001',
      comentarios: 'Solicitud de prueba para verificar funcionamiento del departamento de laboratorio',
      urgencia_id: 2, // Normal
      departamento_destino_id: 3, // Laboratorio
      departamento_actual_id: 3, // Laboratorio
      estado_id: 2, // En Proceso
      created_by: 'admin'
    });
    
    console.log('Solicitud creada exitosamente:', {
      id: nuevaSolicitud.id,
      numero: nuevaSolicitud.numero_solicitud,
      departamento: nuevaSolicitud.departamento_actual_id,
      estado: nuevaSolicitud.estado_id
    });
    
    // Verificar que se creó correctamente
    const solicitudVerificacion = await Solicitud.findByPk(nuevaSolicitud.id, {
      include: [
        { model: Departamento, as: 'departamentoActual' },
        { model: EstadoSolicitud, as: 'estado' }
      ]
    });
    
    console.log('Verificación - Solicitud encontrada:', {
      id: solicitudVerificacion.id,
      numero: solicitudVerificacion.numero_solicitud,
      departamento_nombre: solicitudVerificacion.departamentoActual?.nombre,
      estado_nombre: solicitudVerificacion.estado?.nombre
    });
    
  } catch (error) {
    console.error('Error creando solicitud:', error);
  } finally {
    process.exit(0);
  }
}

crearSolicitudLaboratorio();