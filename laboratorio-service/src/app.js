const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

const { connectDB } = require('./config/database');
const { syncModels } = require('./models');
const defectosRoutes = require('./routes/defectos');
const tareasRoutes = require('./routes/tareas');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3005;

// Conectar a la base de datos y sincronizar modelos
const initializeDatabase = async () => {
  try {
    console.log('🚀 Iniciando conexión a la base de datos...');
    await connectDB();
    
    console.log('🔄 Sincronizando modelos...');
    // Sincronizar modelos (crear tablas si no existen)
    await syncModels({ 
      alter: true, // Siempre permitir alteraciones de estructura
      force: false // No recrear tablas existentes
    });
    
    console.log('🎯 Base de datos inicializada correctamente');
  } catch (error) {
    console.error('❌ Error inicializando base de datos:', error.message);
    console.error('❌ Stack trace completo:', error.stack);
    console.error('❌ Detalles del error:', {
      name: error.name,
      code: error.code,
      errno: error.errno,
      sqlState: error.sqlState,
      sqlMessage: error.sqlMessage
    });
    process.exit(1);
  }
};

// Inicializar base de datos
initializeDatabase();

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // límite de 100 requests por ventana de tiempo
  message: {
    error: 'Demasiadas solicitudes desde esta IP, intenta de nuevo más tarde.'
  }
});

// Middlewares
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: '*', // Permite todos los orígenes
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-user-id', 'x-username', 'x-departamento', 'x-email', 'x-first-name', 'x-last-name'],
  credentials: false // Cambiar a false cuando origin es '*'
}));
app.use(morgan('combined'));
app.use(limiter);
// Conditional body parsing - exclude multipart/form-data
app.use((req, res, next) => {
  if (req.is('multipart/form-data')) {
    return next();
  }
  express.json({ limit: '10mb' })(req, res, () => {
    express.urlencoded({ extended: true, limit: '10mb' })(req, res, next);
  });
});

// Servir archivos estáticos (imágenes)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Debug middleware for laboratorio requests
app.use('/api/laboratorio', (req, res, next) => {
  console.log('=== LABORATORIO SERVICE DEBUG ===');
  console.log('Method:', req.method);
  console.log('URL:', req.originalUrl);
  console.log('Content-Type:', req.headers['content-type']);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  next();
});

// Rutas
app.use('/api/laboratorio/defectos', defectosRoutes);
app.use('/api/laboratorio/tareas', tareasRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'laboratorio-service',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Ruta 404
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    path: req.originalUrl
  });
});

// Middleware de manejo de errores
app.use(errorHandler);

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 Laboratorio Service ejecutándose en puerto ${PORT}`);
  console.log(`📊 Health check disponible en http://localhost:${PORT}/health`);
});

module.exports = app;