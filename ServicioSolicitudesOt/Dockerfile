# Dockerfile para ServicioSolicitudesOt
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production && npm cache clean --force

# Copiar el resto del código de la aplicación
COPY . .

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S nodejs
RUN adduser -S solicitudesuser -u 1001

# Crear directorio para uploads si es necesario
RUN mkdir -p uploads && chown -R solicitudesuser:nodejs uploads

# Cambiar a usuario no-root
USER solicitudesuser

# Exponer el puerto
EXPOSE 3001

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Comando para iniciar la aplicación
CMD ["npm", "start"]