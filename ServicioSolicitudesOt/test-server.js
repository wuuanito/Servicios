const { testConnection } = require('./config/database');

// Script de prueba para verificar la configuración
async function testServer() {
  console.log('🧪 Iniciando pruebas del servidor...');
  
  try {
    // Probar conexión a base de datos
    console.log('\n📊 Probando conexión a base de datos...');
    const dbConnected = await testConnection();
    
    if (dbConnected) {
      console.log('✅ Conexión a base de datos exitosa');
    } else {
      console.log('❌ Error en conexión a base de datos');
      return;
    }
    
    // Verificar variables de entorno
    console.log('\n🔧 Verificando variables de entorno...');
    const requiredEnvVars = ['DB_HOST', 'DB_USER', 'DB_NAME'];
    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      console.log(`❌ Variables de entorno faltantes: ${missingVars.join(', ')}`);
    } else {
      console.log('✅ Variables de entorno configuradas correctamente');
    }
    
    // Verificar directorio de uploads
    console.log('\n📁 Verificando directorio de uploads...');
    const fs = require('fs');
    const uploadPath = process.env.UPLOAD_PATH || './uploads';
    
    if (fs.existsSync(uploadPath)) {
      console.log('✅ Directorio de uploads existe');
    } else {
      console.log('❌ Directorio de uploads no existe');
      console.log(`   Crear directorio: mkdir ${uploadPath}`);
    }
    
    console.log('\n🎉 Pruebas completadas');
    console.log('\n📝 Para iniciar el servidor:');
    console.log('   npm run dev    (desarrollo)');
    console.log('   npm start      (producción)');
    
  } catch (error) {
    console.error('❌ Error durante las pruebas:', error.message);
  }
  
  process.exit(0);
}

// Ejecutar pruebas
testServer();