#!/bin/sh

# Script de inicialización del contenedor para laboratorio-service
# Este script se ejecuta al arrancar el contenedor para configurar permisos

echo "🚀 Iniciando configuración del contenedor laboratorio-service..."

# Crear directorio de uploads si no existe
echo "📁 Creando directorio de uploads..."
mkdir -p /app/uploads/defectos

# Establecer permisos correctos para el directorio uploads
echo "🔐 Configurando permisos del directorio uploads..."
chown -R laboratorio:nodejs /app/uploads
chmod -R 775 /app/uploads

# Verificar que el directorio existe y tiene permisos correctos
echo "✅ Verificando configuración:"
ls -la /app/uploads/
ls -la /app/uploads/defectos/

# Mostrar información del usuario actual
echo "👤 Usuario actual: $(whoami)"
echo "🆔 ID del usuario: $(id)"

# Verificar permisos de escritura
echo "📝 Probando permisos de escritura..."
touch /app/uploads/defectos/test-file.txt && rm /app/uploads/defectos/test-file.txt
if [ $? -eq 0 ]; then
    echo "✅ Permisos de escritura OK"
else
    echo "❌ Error: No se pueden escribir archivos en el directorio uploads"
    exit 1
fi

echo "🎯 Configuración del contenedor completada exitosamente"

# Ejecutar la aplicación
echo "🚀 Iniciando aplicación..."
exec "$@"