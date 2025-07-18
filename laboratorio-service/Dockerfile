# Usar imagen base de Node.js
FROM node:16-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias para sharp
RUN apk add --no-cache \
    libc6-compat \
    vips-dev

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production && npm cache clean --force

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs
RUN adduser -S laboratorio -u 1001

# Copiar código fuente
COPY . .

# Copiar y dar permisos al script de inicialización
COPY init-container.sh /usr/local/bin/init-container.sh
RUN chmod +x /usr/local/bin/init-container.sh

# Crear directorio para uploads con permisos correctos ANTES de cambiar usuario
RUN mkdir -p /app/uploads/defectos
RUN chown -R laboratorio:nodejs /app
RUN chmod -R 755 /app
RUN chmod -R 775 /app/uploads

# IMPORTANTE: No cambiar a usuario no-root aún para permitir corrección de permisos
# El script de inicialización manejará el cambio de usuario después de corregir permisos

# Exponer puerto
EXPOSE 3004

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3004

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Comando para iniciar la aplicación con script de inicialización
ENTRYPOINT ["/usr/local/bin/init-container.sh"]
CMD ["npm", "start"]