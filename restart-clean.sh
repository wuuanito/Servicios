#!/bin/bash
echo "🛑 Deteniendo servicios PM2..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

echo "🔥 Liberando puertos..."
# Método 1: netstat + kill
for port in 3001 3003 3004 3005; do
    echo "Liberando puerto $port..."
    # Buscar procesos usando el puerto
    PIDS=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
    if [ ! -z "$PIDS" ]; then
        echo "Matando procesos en puerto $port: $PIDS"
        echo $PIDS | xargs -r kill -9 2>/dev/null || true
    fi
    
    # Método 2: fuser (si está disponible)
    fuser -k ${port}/tcp 2>/dev/null || true
done

echo "⏳ Esperando que se liberen los puertos..."
sleep 3

echo "🔍 Verificando puertos..."
for port in 3001 3003 3004 3005; do
    if netstat -tln 2>/dev/null | grep -q ":$port "; then
        echo "❌ Puerto $port aún ocupado"
        netstat -tlnp 2>/dev/null | grep ":$port "
    else
        echo "✅ Puerto $port liberado"
    fi
done

echo "⏳ Esperando 3 segundos más..."
sleep 3

echo "🚀 Iniciando servicios..."
pm2 start ecosystem.config.js
sleep 2
echo "📊 Estado de servicios:"
pm2 status