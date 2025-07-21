const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const Docker = require('dockerode');
const winston = require('winston');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// Configurar logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/monitor.log' })
  ]
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Servicios a monitorear
const SERVICES = [
  'auth-service',
  'calendar-service',
  'laboratorio-service',
  'solicitudes-service',
  'cremer-backend',
  'tecnomaco-backend',
  'servidor-rps',
  'naturepharma-phpmyadmin',
  'naturepharma-nginx'
];

// Estado de los servicios
let servicesStatus = {};

// Función para obtener estado de contenedores
async function getContainerStatus() {
  try {
    const containers = await docker.listContainers({ all: true });
    const status = {};
    
    for (const container of containers) {
      const name = container.Names[0].replace('/', '');
      if (SERVICES.includes(name) || name.includes('naturepharma')) {
        status[name] = {
          id: container.Id,
          name: name,
          state: container.State,
          status: container.Status,
          image: container.Image,
          ports: container.Ports,
          created: container.Created
        };
      }
    }
    
    return status;
  } catch (error) {
    logger.error('Error getting container status:', error);
    return {};
  }
}

// Función para obtener logs de un contenedor
async function getContainerLogs(containerName, lines = 100) {
  try {
    const container = docker.getContainer(containerName);
    const logs = await container.logs({
      stdout: true,
      stderr: true,
      tail: lines,
      timestamps: true
    });
    
    return logs.toString('utf8');
  } catch (error) {
    logger.error(`Error getting logs for ${containerName}:`, error);
    return `Error: No se pudieron obtener los logs para ${containerName}`;
  }
}

// Función para obtener estadísticas de recursos
async function getContainerStats() {
  try {
    const containers = await docker.listContainers();
    const stats = {};
    
    for (const containerInfo of containers) {
      const name = containerInfo.Names[0].replace('/', '');
      if (SERVICES.includes(name) || name.includes('naturepharma')) {
        try {
          const container = docker.getContainer(containerInfo.Id);
          const stat = await container.stats({ stream: false });
          
          // Calcular porcentaje de CPU
          const cpuDelta = stat.cpu_stats.cpu_usage.total_usage - stat.precpu_stats.cpu_usage.total_usage;
          const systemDelta = stat.cpu_stats.system_cpu_usage - stat.precpu_stats.system_cpu_usage;
          const cpuPercent = (cpuDelta / systemDelta) * stat.cpu_stats.online_cpus * 100;
          
          // Calcular uso de memoria
          const memUsage = stat.memory_stats.usage;
          const memLimit = stat.memory_stats.limit;
          const memPercent = (memUsage / memLimit) * 100;
          
          stats[name] = {
            cpu: cpuPercent.toFixed(2),
            memory: {
              usage: (memUsage / 1024 / 1024).toFixed(2), // MB
              limit: (memLimit / 1024 / 1024).toFixed(2), // MB
              percent: memPercent.toFixed(2)
            },
            network: stat.networks
          };
        } catch (error) {
          logger.error(`Error getting stats for ${name}:`, error);
        }
      }
    }
    
    return stats;
  } catch (error) {
    logger.error('Error getting container stats:', error);
    return {};
  }
}

// Rutas API
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/services', async (req, res) => {
  try {
    const status = await getContainerStatus();
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/logs/:containerName', async (req, res) => {
  try {
    const { containerName } = req.params;
    const { lines = 100 } = req.query;
    const logs = await getContainerLogs(containerName, parseInt(lines));
    res.json({ logs });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/stats', async (req, res) => {
  try {
    const stats = await getContainerStats();
    res.json(stats);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Página principal
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Socket.IO para actualizaciones en tiempo real
io.on('connection', (socket) => {
  logger.info('Cliente conectado al monitor');
  
  // Enviar estado inicial
  getContainerStatus().then(status => {
    socket.emit('services-status', status);
  });
  
  // Manejar solicitud de logs
  socket.on('request-logs', async (data) => {
    const { containerName, lines = 100 } = data;
    try {
      const logs = await getContainerLogs(containerName, lines);
      socket.emit('logs-data', { containerName, logs });
    } catch (error) {
      socket.emit('logs-error', { containerName, error: error.message });
    }
  });
  
  socket.on('disconnect', () => {
    logger.info('Cliente desconectado del monitor');
  });
});

// Actualizar estado cada 5 segundos
setInterval(async () => {
  try {
    const status = await getContainerStatus();
    const stats = await getContainerStats();
    
    io.emit('services-status', status);
    io.emit('services-stats', stats);
    
    servicesStatus = status;
  } catch (error) {
    logger.error('Error updating services status:', error);
  }
}, 5000);

// Crear directorio de logs si no existe
if (!fs.existsSync('logs')) {
  fs.mkdirSync('logs');
}

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  logger.info(`Monitor de logs iniciado en puerto ${PORT}`);
  console.log(`Monitor de logs disponible en http://localhost:${PORT}`);
});