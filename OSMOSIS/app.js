const express = require('express');
const { Sequelize, DataTypes, Op } = require('sequelize');
const WebSocket = require('ws');
const cors = require('cors');

// Configuración de constantes
const WS_URL = 'ws://192.168.20.103:8765'; // URL de tu Raspberry Pi
const PORT = 8000;

// Configuración de etiquetas de señales
const SIGNAL_LABELS = {
  lowWaterTank: 'Depósito de Agua Bajo',
  phAlarm: 'Alarma Ph/fx',
  dosingOperation: 'Funcionamiento Dosificación',
  inhibitRegeneration: 'INHIBIT Regeneración',
  bwtAlarm: 'Alarma BWT',
  pumpStop: 'Parada de Bomba'
};

// Inicialización de Express
const app = express();
app.use(cors());
app.use(express.json());

// Configuración de la base de datos
const sequelize = new Sequelize('osmosis_monitor', 'root', 'root', {
  host: 'localhost',
  dialect: 'mysql',
  logging: false,
  timezone: '+01:00',
  port:3050
});

// Modelo de datos
const SignalHistory = sequelize.define('SignalHistory', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  signalName: {
    type: DataTypes.STRING,
    allowNull: false
  },
  signalLabel: {
    type: DataTypes.STRING,
    allowNull: false
  },
  startTime: {
    type: DataTypes.DATE,
    allowNull: false
  },
  endTime: {
    type: DataTypes.DATE,
    allowNull: true
  },
  duration: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  value: {
    type: DataTypes.BOOLEAN,
    allowNull: false
  }
});

// Cliente WebSocket
class WSClient {
  constructor() {
    this.ws = null;
    this.previousStates = {};
    this.activeSignals = {};
    this.connected = false;
    this.reconnectTimeout = null;
  }

  connect() {
    try {
      this.ws = new WebSocket(WS_URL);
      
      this.ws.on('open', () => {
        console.log('Conectado al servidor WebSocket');
        this.connected = true;
        this.startHeartbeat();
      });

      this.ws.on('message', async (data) => {
        try {
          const states = JSON.parse(data.toString());
          await this.processSignalStates(states);
        } catch (error) {
          console.error('Error procesando mensaje:', error);
        }
      });

      this.ws.on('close', () => {
        console.log('Desconectado del servidor WebSocket');
        this.connected = false;
        this.scheduleReconnect();
      });

      this.ws.on('error', (error) => {
        console.error('Error en WebSocket:', error);
        this.scheduleReconnect();
      });

    } catch (error) {
      console.error('Error conectando al WebSocket:', error);
      this.scheduleReconnect();
    }
  }

  scheduleReconnect() {
    if (!this.reconnectTimeout) {
      this.reconnectTimeout = setTimeout(() => {
        console.log('Intentando reconexión...');
        this.reconnectTimeout = null;
        this.connect();
      }, 5000);
    }
  }

  startHeartbeat() {
    setInterval(() => {
      if (this.connected && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send('ping');
      }
    }, 30000);
  }

  async processSignalStates(states) {
    const timestamp = new Date(states.timestamp);

    for (const [signalName, currentValue] of Object.entries(states)) {
      if (signalName === 'timestamp') continue;

      // Invertir lógica para lowWaterTank y pumpStop
      let value = signalName === 'lowWaterTank' || signalName === 'pumpStop' 
        ? !currentValue 
        : currentValue;

      const previousValue = this.previousStates[signalName];

      if (previousValue !== value) {
        // Si hay una señal activa, la cerramos
        if (this.activeSignals[signalName]) {
          const activeSignal = await SignalHistory.findByPk(this.activeSignals[signalName]);
          if (activeSignal) {
            const endTime = timestamp;
            const duration = Math.floor((endTime - activeSignal.startTime) / 1000);
            await activeSignal.update({
              endTime,
              duration
            });
            console.log(`Señal cerrada: ${signalName}, duración: ${duration}s`);
          }
          delete this.activeSignals[signalName];
        }

        // Si la señal está activa, creamos un nuevo registro
        if (value) {
          const newSignal = await SignalHistory.create({
            signalName,
            signalLabel: SIGNAL_LABELS[signalName],
            startTime: timestamp,
            value
          });
          this.activeSignals[signalName] = newSignal.id;
          console.log(`Nueva señal registrada: ${signalName}`);
        }

        this.previousStates[signalName] = value;
      }
    }
  }
}

// Función auxiliar para determinar el tipo de señal
function getSignalType(signalName) {
  switch (signalName) {
    case 'lowWaterTank':
    case 'phAlarm':
    case 'bwtAlarm':
    case 'pumpStop':
      return 'error';
    case 'inhibitRegeneration':
      return 'warning';
    case 'dosingOperation':
      return 'success';
    default:
      return 'info';
  }
}

// Rutas API
app.get('/api/signals/history', async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      signalName,
      page = 1,
      limit = 100
    } = req.query;

    const whereClause = {};
    
    if (startDate && endDate) {
      whereClause.startTime = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    }
    
    if (signalName) {
      whereClause.signalName = signalName;
    }

    const offset = (page - 1) * limit;

    const signals = await SignalHistory.findAll({
      where: whereClause,
      order: [['startTime', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // Transformar al formato del componente LogsPanel
    const logs = signals.map(signal => ({
      id: signal.id,
      timestamp: signal.startTime,
      event: signal.signalLabel,
      status: signal.endTime ? `Duración: ${signal.duration}s` : 'Activo',
      type: getSignalType(signal.signalName)
    }));

    res.json({ logs });
  } catch (error) {
    console.error('Error obteniendo historial:', error);
    res.status(500).json({ error: error.message });
  }
});

// Ruta de estado del servidor
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    wsConnected: wsClient?.connected || false,
    timestamp: new Date().toISOString()
  });
});

// Inicialización del servidor
async function startServer() {
  try {
    // Sincronizar base de datos
    await sequelize.sync();
    console.log('Base de datos sincronizada');

    // Iniciar servidor HTTP
    app.listen(PORT, () => {
      console.log(`Servidor API iniciado en puerto ${PORT}`);
      
      // Iniciar cliente WebSocket
      const wsClient = new WSClient();
      wsClient.connect();
    });

  } catch (error) {
    console.error('Error iniciando servidor:', error);
    process.exit(1);
  }
}

// Manejo de señales de terminación
process.on('SIGTERM', async () => {
  console.log('Recibida señal SIGTERM, cerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('Recibida señal SIGINT, cerrando servidor...');
  process.exit(0);
});

// Iniciar servidor
startServer();