#!/usr/bin/env node

/**
 * Health Check Script para NaturePharma Services
 * Verifica el estado de todos los servicios
 */

const http = require('http');
const https = require('https');

// Configuración de servicios
const services = [
  {
    name: 'Auth Service',
    url: 'http://localhost:4001/health',
    timeout: 5000
  },
  {
    name: 'Calendar Service',
    url: 'http://localhost:3003/health',
    timeout: 5000
  },
  {
    name: 'Laboratorio Service',
    url: 'http://localhost:3004/health',
    timeout: 5000
  },
  {
    name: 'Solicitudes Service',
    url: 'http://localhost:3001/health',
    timeout: 5000
  },
  {
    name: 'MySQL Database',
    url: 'http://localhost:3306',
    timeout: 3000,
    skipHttpCheck: true // MySQL no responde HTTP
  },
  {
    name: 'phpMyAdmin',
    url: 'http://localhost:8080',
    timeout: 5000
  },
  {
    name: 'Nginx Gateway',
    url: 'http://localhost:80/health',
    timeout: 5000
  }
];

// Colores para output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Función para hacer request HTTP
function makeRequest(url, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const timeoutId = setTimeout(() => {
      reject(new Error('Timeout'));
    }, timeout);

    const req = lib.get(url, (res) => {
      clearTimeout(timeoutId);
      resolve({
        statusCode: res.statusCode,
        statusMessage: res.statusMessage
      });
    });

    req.on('error', (err) => {
      clearTimeout(timeoutId);
      reject(err);
    });

    req.setTimeout(timeout, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

// Función para verificar un servicio
async function checkService(service) {
  const startTime = Date.now();
  
  try {
    if (service.skipHttpCheck) {
      // Para servicios que no responden HTTP (como MySQL)
      return {
        name: service.name,
        status: 'unknown',
        responseTime: 0,
        message: 'HTTP check skipped'
      };
    }

    const response = await makeRequest(service.url, service.timeout);
    const responseTime = Date.now() - startTime;
    
    const isHealthy = response.statusCode >= 200 && response.statusCode < 400;
    
    return {
      name: service.name,
      status: isHealthy ? 'healthy' : 'unhealthy',
      statusCode: response.statusCode,
      responseTime,
      message: response.statusMessage
    };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    
    return {
      name: service.name,
      status: 'error',
      responseTime,
      error: error.message
    };
  }
}

// Función para mostrar resultados
function displayResults(results) {
  console.log(`\n${colors.bright}${colors.cyan}=== NaturePharma Services Health Check ===${colors.reset}\n`);
  
  let healthyCount = 0;
  let totalCount = results.length;
  
  results.forEach(result => {
    let statusColor = colors.red;
    let statusIcon = '❌';
    
    if (result.status === 'healthy') {
      statusColor = colors.green;
      statusIcon = '✅';
      healthyCount++;
    } else if (result.status === 'unknown') {
      statusColor = colors.yellow;
      statusIcon = '❓';
    }
    
    console.log(`${statusIcon} ${colors.bright}${result.name}${colors.reset}`);
    console.log(`   Status: ${statusColor}${result.status.toUpperCase()}${colors.reset}`);
    
    if (result.statusCode) {
      console.log(`   HTTP Status: ${result.statusCode}`);
    }
    
    if (result.responseTime !== undefined) {
      const timeColor = result.responseTime > 1000 ? colors.yellow : colors.green;
      console.log(`   Response Time: ${timeColor}${result.responseTime}ms${colors.reset}`);
    }
    
    if (result.error) {
      console.log(`   Error: ${colors.red}${result.error}${colors.reset}`);
    }
    
    if (result.message && result.message !== 'OK') {
      console.log(`   Message: ${result.message}`);
    }
    
    console.log('');
  });
  
  // Resumen
  const healthPercentage = Math.round((healthyCount / totalCount) * 100);
  const summaryColor = healthPercentage >= 80 ? colors.green : 
                      healthPercentage >= 60 ? colors.yellow : colors.red;
  
  console.log(`${colors.bright}Summary:${colors.reset}`);
  console.log(`${summaryColor}${healthyCount}/${totalCount} services healthy (${healthPercentage}%)${colors.reset}`);
  
  if (healthPercentage < 100) {
    console.log(`\n${colors.yellow}⚠️  Some services are not responding correctly${colors.reset}`);
  } else {
    console.log(`\n${colors.green}🎉 All services are healthy!${colors.reset}`);
  }
}

// Función principal
async function main() {
  const args = process.argv.slice(2);
  const isWatch = args.includes('--watch') || args.includes('-w');
  const interval = parseInt(args.find(arg => arg.startsWith('--interval='))) || 30;
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
NaturePharma Health Check Tool

Usage: node healthcheck.js [options]

Options:
  --watch, -w           Watch mode (continuous monitoring)
  --interval=<seconds>  Interval for watch mode (default: 30)
  --help, -h           Show this help

Examples:
  node healthcheck.js                    # Single check
  node healthcheck.js --watch            # Continuous monitoring
  node healthcheck.js -w --interval=60   # Monitor every 60 seconds
`);
    return;
  }
  
  async function runCheck() {
    console.log(`${colors.blue}Checking services...${colors.reset}`);
    
    const results = await Promise.all(
      services.map(service => checkService(service))
    );
    
    displayResults(results);
    
    // Exit code basado en el estado de los servicios
    const healthyServices = results.filter(r => r.status === 'healthy').length;
    const totalServices = results.filter(r => r.status !== 'unknown').length;
    
    if (!isWatch) {
      process.exit(healthyServices === totalServices ? 0 : 1);
    }
  }
  
  if (isWatch) {
    console.log(`${colors.cyan}Starting health check monitoring (interval: ${interval}s)${colors.reset}`);
    console.log(`${colors.cyan}Press Ctrl+C to stop${colors.reset}\n`);
    
    // Ejecutar inmediatamente
    await runCheck();
    
    // Luego ejecutar en intervalos
    setInterval(async () => {
      console.log(`\n${colors.blue}--- ${new Date().toLocaleString()} ---${colors.reset}`);
      await runCheck();
    }, interval * 1000);
  } else {
    await runCheck();
  }
}

// Manejo de señales para salida limpia
process.on('SIGINT', () => {
  console.log(`\n${colors.yellow}Health check monitoring stopped${colors.reset}`);
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log(`\n${colors.yellow}Health check monitoring terminated${colors.reset}`);
  process.exit(0);
});

// Ejecutar
if (require.main === module) {
  main().catch(error => {
    console.error(`${colors.red}Error: ${error.message}${colors.reset}`);
    process.exit(1);
  });
}

module.exports = { checkService, services };