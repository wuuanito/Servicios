module.exports = {
  apps: [
    {
      name: 'solicitudes-service',
      script: 'server.js',
      cwd: './ServicioSolicitudesOt',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3003
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3003
      }
    },
    {
      name: 'calendar-service',
      script: 'src/main.js',
      cwd: './calendar-service',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3004
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3004
      }
    },
    {
      name: 'laboratorio-service',
      script: 'src/app.js',
      cwd: './laboratorio-service',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3005
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3005
      }
    },
    {
      name: 'auth-service',
      script: 'src/main.js',
      cwd: './auth-service',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3001
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3001
      }
    }
  ]
};