const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const socketIo = require('socket.io');
require('dotenv').config();

// Configuración de Sequelize
const { sequelize, testConnection, syncDatabase } = require('./config/sequelize');
const { initializeDefaultData } = require('./models/sequelize');

const solicitudesRoutes = require('./routes/solicitudes');
const necesidadesRoutes = require('./routes/necesidades');
const archivosRoutes = require('./routes/archivos');
const departamentosRoutes = require('./routes/departamentos');
const chatRoutes = require('./routes/chat');
const auditoriaRoutes = require('./routes/auditoria');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Rate limiting - más permisivo para desarrollo
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minuto
  max: 1000, // límite de 1000 requests por ventana de tiempo
  message: {
    error: 'Demasiadas solicitudes desde esta IP, por favor intenta de nuevo más tarde.'
  }
});

// Middlewares
app.use(helmet());
app.use(limiter);
app.use(cors({
  origin: "*",
  credentials: false
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Hacer io disponible en todas las rutas
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Rutas
app.use('/api/solicitudes', solicitudesRoutes);
app.use('/api/necesidades', necesidadesRoutes);
app.use('/api/archivos', archivosRoutes);
app.use('/api/departamentos', departamentosRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/auditoria', auditoriaRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Error interno del servidor',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Algo salió mal'
  });
});

// Socket.IO para tiempo real
io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);
  
  // Unirse a un departamento
  socket.on('join_department', (department) => {
    socket.join(department);
    console.log(`Cliente ${socket.id} se unió al departamento: ${department}`);
  });
  
  // Unirse al chat de una solicitud específica
  socket.on('join_solicitud_chat', (solicitudId) => {
    socket.join(`solicitud_${solicitudId}`);
    console.log(`Cliente ${socket.id} se unió al chat de la solicitud: ${solicitudId}`);
  });
  
  // Salir del chat de una solicitud
  socket.on('leave_solicitud_chat', (solicitudId) => {
    socket.leave(`solicitud_${solicitudId}`);
    console.log(`Cliente ${socket.id} salió del chat de la solicitud: ${solicitudId}`);
  });
  
  // Indicar que el usuario está escribiendo
  socket.on('typing', (data) => {
    socket.to(`solicitud_${data.solicitudId}`).emit('user_typing', {
      usuario_nombre: data.usuario_nombre,
      solicitud_id: data.solicitudId
    });
  });
  
  // Indicar que el usuario dejó de escribir
  socket.on('stop_typing', (data) => {
    socket.to(`solicitud_${data.solicitudId}`).emit('user_stop_typing', {
      usuario_nombre: data.usuario_nombre,
      solicitud_id: data.solicitudId
    });
  });
  
  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
  });
});

const PORT = process.env.PORT || 3001;

// Función para inicializar la aplicación
const initializeApp = async () => {
  try {
    // Probar conexión a la base de datos
    await testConnection();
    
    // Sincronizar la base de datos (crear tablas si no existen)
    await syncDatabase();
    
    // Inicializar datos por defecto
    await initializeDefaultData();
    
    // Iniciar el servidor
    server.listen(PORT, () => {
      console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
      console.log(`📊 Modo: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 Base de datos sincronizada correctamente`);
    });
    
  } catch (error) {
    console.error('❌ Error inicializando la aplicación:', error);
    process.exit(1);
  }
};

// Inicializar la aplicación
initializeApp();

module.exports = { app, io };