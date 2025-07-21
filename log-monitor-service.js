const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 8080;

// Middleware
app.use(cors());
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Lista de servicios disponibles
const services = [
    'auth-service',
    'calendar-service', 
    'laboratorio-service',
    'servicio-solicitudes-ot',
    'cremer-backend',
    'tecnomaco-backend',
    'servidor-rps',
    'nginx',
    'phpmyadmin',
    'mysql'
];

// Endpoint para obtener la lista de servicios
app.get('/api/services', (req, res) => {
    res.json(services);
});

// Endpoint para obtener logs de un servicio específico
app.get('/api/logs/:service', (req, res) => {
    const service = req.params.service;
    const lines = req.query.lines || 100;
    
    if (!services.includes(service)) {
        return res.status(404).json({ error: 'Servicio no encontrado' });
    }
    
    const command = `docker-compose logs --tail=${lines} ${service}`;
    
    exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error ejecutando comando: ${error}`);
            return res.status(500).json({ error: 'Error obteniendo logs' });
        }
        
        res.json({
            service: service,
            logs: stdout,
            timestamp: new Date().toISOString()
        });
    });
});

// Endpoint para obtener el estado de los contenedores
app.get('/api/status', (req, res) => {
    const command = 'docker-compose ps --format json';
    
    exec(command, { cwd: __dirname }, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error ejecutando comando: ${error}`);
            return res.status(500).json({ error: 'Error obteniendo estado' });
        }
        
        try {
            const containers = stdout.trim().split('\n')
                .filter(line => line.trim())
                .map(line => JSON.parse(line));
            
            res.json({
                containers: containers,
                timestamp: new Date().toISOString()
            });
        } catch (parseError) {
            console.error('Error parseando JSON:', parseError);
            res.status(500).json({ error: 'Error parseando estado de contenedores' });
        }
    });
});

// Endpoint para obtener estadísticas de recursos
app.get('/api/stats', (req, res) => {
    const command = 'docker stats --no-stream --format "table {{.Container}}\\t{{.CPUPerc}}\\t{{.MemUsage}}\\t{{.NetIO}}\\t{{.BlockIO}}"';
    
    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error ejecutando comando: ${error}`);
            return res.status(500).json({ error: 'Error obteniendo estadísticas' });
        }
        
        res.json({
            stats: stdout,
            timestamp: new Date().toISOString()
        });
    });
});

// Servir el dashboard HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Monitor de Logs iniciado en http://0.0.0.0:${PORT}`);
    console.log(`📊 Dashboard accesible desde la red en http://192.168.20.158:${PORT}`);
    console.log(`📋 Servicios monitoreados: ${services.join(', ')}`);
});