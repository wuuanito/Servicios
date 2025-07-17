# Dockerfile para auth-service
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
RUN adduser -S authuser -u 1001

# Crear directorio para logs
RUN mkdir -p logs && chown -R authuser:nodejs logs

# Cambiar a usuario no-root
USER authuser

# Exponer el puerto
EXPOSE 4001

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=4001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Comando para iniciar la aplicación
CMD ["npm", "start"]