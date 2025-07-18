#!/bin/sh

# Script de inicialización del contenedor para laboratorio-service
# Este script se ejecuta como root para configurar permisos y luego cambia al usuario laboratorio

echo "🚀 Iniciando configuración del contenedor laboratorio-service..."
echo "👤 Usuario actual: $(whoami)"
echo "🆔 ID del usuario: $(id)"

# Crear directorio de uploads si no existe
echo "📁 Creando directorio de uploads..."
mkdir -p /app/uploads/defectos

# Establecer permisos correctos para el directorio uploads (como root)
echo "🔐 Configurando permisos del directorio uploads..."
chown -R laboratorio:nodejs /app/uploads
chmod -R 775 /app/uploads

# Si el directorio está montado desde el host, forzar permisos
if [ -d "/app/uploads" ]; then
    echo "📂 Directorio uploads detectado, aplicando permisos recursivos..."
    find /app/uploads -type d -exec chmod 775 {} \;
    find /app/uploads -type f -exec chmod 664 {} \;
    chown -R laboratorio:nodejs /app/uploads
fi

# Verificar que el directorio existe y tiene permisos correctos
echo "✅ Verificando configuración:"
ls -la /app/uploads/
ls -la /app/uploads/defectos/

# Cambiar al usuario laboratorio para probar permisos
echo "🔄 Cambiando al usuario laboratorio para verificar permisos..."
su laboratorio -c '
    echo "👤 Usuario actual: $(whoami)"
    echo "🆔 ID del usuario: $(id)"
    echo "📝 Probando permisos de escritura..."
    if touch /app/uploads/defectos/test-file.txt 2>/dev/null; then
        rm /app/uploads/defectos/test-file.txt
        echo "✅ Permisos de escritura OK"
        exit 0
    else
        echo "❌ Error: No se pueden escribir archivos en el directorio uploads"
        exit 1
    fi
'

if [ $? -ne 0 ]; then
    echo "⚠️ Intentando corrección adicional de permisos..."
    chmod 777 /app/uploads/defectos
    chown -R laboratorio:nodejs /app/uploads
    
    # Verificar nuevamente
    su laboratorio -c 'touch /app/uploads/defectos/test-file.txt && rm /app/uploads/defectos/test-file.txt'
    if [ $? -ne 0 ]; then
        echo "❌ Error crítico: No se pueden corregir los permisos"
        exit 1
    fi
    echo "✅ Permisos corregidos exitosamente"
fi

echo "🎯 Configuración del contenedor completada exitosamente"

# Ejecutar la aplicación como usuario laboratorio
echo "🚀 Iniciando aplicación como usuario laboratorio..."
exec su laboratorio -c "$*"