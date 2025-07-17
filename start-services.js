const { exec } = require('child_process');
const path = require('path');

console.log('🚀 Iniciando servicios con PM2...');

// Función para ejecutar comandos
function runCommand(command, description) {
  return new Promise((resolve, reject) => {
    console.log(`\n📋 ${description}`);
    exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
      if (error) {
        console.error(`❌ Error: ${error.message}`);
        reject(error);
        return;
      }
      if (stderr) {
        console.log(`⚠️  ${stderr}`);
      }
      console.log(stdout);
      resolve(stdout);
    });
  });
}

async function startServices() {
  try {
    // Detener servicios existentes si están corriendo (ignorar si no hay procesos)
    try {
      await runCommand('pm2 delete all', 'Deteniendo servicios existentes (si los hay)');
    } catch (error) {
      console.log('ℹ️  No hay procesos PM2 ejecutándose actualmente');
    }
    
    // Iniciar servicios usando el archivo de configuración
    await runCommand('pm2 start ecosystem.config.js', 'Iniciando todos los servicios');
    
    // Mostrar estado de los servicios
    await runCommand('pm2 status', 'Estado actual de los servicios');
    
    // Mostrar logs en tiempo real
    console.log('\n📊 Para ver los logs en tiempo real, ejecuta: pm2 logs');
    console.log('📊 Para ver el monitoreo, ejecuta: pm2 monit');
    console.log('📊 Para detener todos los servicios, ejecuta: pm2 stop all');
    console.log('📊 Para reiniciar todos los servicios, ejecuta: pm2 restart all');
    
  } catch (error) {
    console.error('❌ Error al iniciar los servicios:', error.message);
  }
}

startServices();