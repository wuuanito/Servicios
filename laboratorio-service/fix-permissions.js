#!/usr/bin/env node

/**
 * Script para verificar y corregir permisos de archivos
 * Se ejecuta antes de iniciar la aplicación principal
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const UPLOAD_DIR = '/app/uploads';
const DEFECTOS_DIR = '/app/uploads/defectos';

console.log('🔧 Iniciando verificación y corrección de permisos...');

// Función para verificar si un directorio existe y es escribible
function checkDirectoryPermissions(dirPath) {
  try {
    // Verificar si el directorio existe
    if (!fs.existsSync(dirPath)) {
      console.log(`📁 Creando directorio: ${dirPath}`);
      fs.mkdirSync(dirPath, { recursive: true, mode: 0o775 });
    }

    // Verificar permisos de escritura
    const testFile = path.join(dirPath, 'test-write-permission.tmp');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);
    
    console.log(`✅ Directorio ${dirPath} - Permisos OK`);
    return true;
  } catch (error) {
    console.error(`❌ Error en directorio ${dirPath}:`, error.message);
    return false;
  }
}

// Función para corregir permisos usando comandos del sistema
function fixPermissions() {
  try {
    console.log('🔐 Aplicando corrección de permisos...');
    
    // Crear directorios si no existen
    execSync(`mkdir -p ${UPLOAD_DIR}`, { stdio: 'inherit' });
    execSync(`mkdir -p ${DEFECTOS_DIR}`, { stdio: 'inherit' });
    
    // Aplicar permisos
    execSync(`chmod -R 775 ${UPLOAD_DIR}`, { stdio: 'inherit' });
    
    // Verificar el propietario actual
    const currentUser = execSync('whoami', { encoding: 'utf8' }).trim();
    console.log(`👤 Usuario actual: ${currentUser}`);
    
    // Mostrar información de permisos
    console.log('📋 Estado actual de permisos:');
    execSync(`ls -la ${UPLOAD_DIR}`, { stdio: 'inherit' });
    
    return true;
  } catch (error) {
    console.error('❌ Error aplicando permisos:', error.message);
    return false;
  }
}

// Función principal
function main() {
  console.log('🚀 Iniciando verificación de permisos para laboratorio-service');
  
  // Verificar directorios
  const uploadDirOK = checkDirectoryPermissions(UPLOAD_DIR);
  const defectosDirOK = checkDirectoryPermissions(DEFECTOS_DIR);
  
  if (!uploadDirOK || !defectosDirOK) {
    console.log('🔧 Intentando corregir permisos...');
    const fixed = fixPermissions();
    
    if (!fixed) {
      console.error('❌ No se pudieron corregir los permisos automáticamente');
      process.exit(1);
    }
    
    // Verificar nuevamente después de la corrección
    const uploadDirFixed = checkDirectoryPermissions(UPLOAD_DIR);
    const defectosDirFixed = checkDirectoryPermissions(DEFECTOS_DIR);
    
    if (!uploadDirFixed || !defectosDirFixed) {
      console.error('❌ Los permisos siguen siendo incorrectos después de la corrección');
      process.exit(1);
    }
  }
  
  console.log('✅ Verificación de permisos completada exitosamente');
  console.log('🎯 El servicio puede proceder a iniciar normalmente');
}

// Ejecutar solo si es llamado directamente
if (require.main === module) {
  main();
}

module.exports = { checkDirectoryPermissions, fixPermissions };