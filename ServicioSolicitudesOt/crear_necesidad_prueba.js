const { Necesidad } = require('./models/sequelize');
const NecesidadModel = require('./models/Necesidad');

async function crearNecesidadPrueba() {
  try {
    console.log('Creando necesidad de prueba...');
    
    // Crear necesidad usando el modelo corregido
    const nuevaNecesidad = await NecesidadModel.crear({
      solicitud_id: 2, // La solicitud que acabamos de crear
      descripcion: 'Necesidad de prueba para verificar fecha_creacion',
      tipo_analisis: 'Análisis de Prueba',
      parametros_requeridos: 'Parámetros de prueba',
      created_by: 'admin'
    });
    
    console.log('Necesidad creada exitosamente:', {
      id: nuevaNecesidad.id,
      solicitud_id: nuevaNecesidad.solicitud_id,
      descripcion: nuevaNecesidad.descripcion,
      fecha_creacion: nuevaNecesidad.fecha_creacion,
      tipo_analisis: nuevaNecesidad.tipo_analisis
    });
    
    // Verificar que la fecha se estableció correctamente
    const necesidadVerificacion = await NecesidadModel.obtenerPorId(nuevaNecesidad.id);
    console.log('Verificación - Necesidad encontrada:', {
      id: necesidadVerificacion.id,
      fecha_creacion: necesidadVerificacion.fecha_creacion,
      fecha_creacion_tipo: typeof necesidadVerificacion.fecha_creacion
    });
    
  } catch (error) {
    console.error('Error creando necesidad:', error);
  } finally {
    process.exit(0);
  }
}

crearNecesidadPrueba();