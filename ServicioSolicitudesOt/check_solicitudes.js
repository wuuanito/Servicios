const { Solicitud, Departamento, EstadoSolicitud, NivelUrgencia, Necesidad } = require('./models/sequelize');
const { sequelize } = require('./config/sequelize');

(async () => {
  try {
    await sequelize.authenticate();
    console.log('Conectado a la base de datos');
    
    const solicitudes = await Solicitud.findAll({
      include: [
        { model: Departamento, as: 'departamentoActual', attributes: ['id', 'nombre'] },
        { model: EstadoSolicitud, as: 'estado', attributes: ['id', 'nombre'] },
        { model: Necesidad, as: 'necesidades' }
      ]
    });
    
    console.log('Total de solicitudes:', solicitudes.length);
    
    solicitudes.forEach(s => {
      console.log(`ID: ${s.id}, Número: ${s.numero_solicitud}, Departamento Actual: ${s.departamentoActual?.nombre} (ID: ${s.departamento_actual_id}), Estado: ${s.estado?.nombre}, Necesidades: ${s.necesidades?.length || 0}`);
    });
    
    // Verificar necesidades específicamente
    const necesidades = await Necesidad.findAll();
    console.log('\nTotal de necesidades:', necesidades.length);
    necesidades.forEach(n => {
      console.log(`Necesidad ID: ${n.id}, Solicitud ID: ${n.solicitud_id}, Tipo: ${n.tipo_analisis}, Fecha Creación: ${n.fecha_creacion}`);
    });
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
})();