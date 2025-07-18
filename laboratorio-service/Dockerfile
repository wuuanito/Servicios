# Usar imagen base de Node.js
FROM node:18-alpine

# Crear usuario no-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S laboratorio -u 1001 -G nodejs

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar código fuente
COPY src/ ./src/
COPY healthcheck.js ./
COPY sync-database.js ./
COPY test-db-connection.js ./

# Crear directorio uploads
RUN mkdir -p /app/uploads/defectos

# Cambiar propietario de archivos
RUN chown -R laboratorio:nodejs /app

# Cambiar al usuario no-root
USER laboratorio

# Exponer puerto
EXPOSE 3004

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Comando por defecto
CMD ["npm", "start"]