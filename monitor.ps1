# Script de monitoreo para NaturePharma Services
# Muestra el estado de todos los servicios en tiempo real

param(
    [switch]$Continuous,
    [int]$RefreshInterval = 5
)

function Show-Header {
    Clear-Host
    Write-Host "=== NaturePharma Services - Monitor ===" -ForegroundColor Cyan
    Write-Host "Actualizado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Test-ServiceHealth {
    param([string]$Url, [string]$ServiceName)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            return @{ Status = "✓ Online"; Color = "Green" }
        } else {
            return @{ Status = "⚠ Warning"; Color = "Yellow" }
        }
    } catch {
        return @{ Status = "✗ Offline"; Color = "Red" }
    }
}

function Show-ServiceStatus {
    Write-Host "=== Estado de Contenedores ===" -ForegroundColor Yellow
    
    try {
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | ConvertFrom-String -Delimiter "\t" -PropertyNames Name, Status, Ports
        
        if ($containers.Count -gt 1) {
            foreach ($container in $containers[1..($containers.Count-1)]) {
                $name = $container.Name
                $status = $container.Status
                $ports = $container.Ports
                
                if ($status -like "*Up*") {
                    Write-Host "✓ $name" -ForegroundColor Green -NoNewline
                    Write-Host " - $status" -ForegroundColor Gray
                } else {
                    Write-Host "✗ $name" -ForegroundColor Red -NoNewline
                    Write-Host " - $status" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "No hay contenedores ejecutándose" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al obtener estado de contenedores" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-ServiceHealth {
    Write-Host "=== Health Check de Servicios ===" -ForegroundColor Yellow
    
    $services = @(
        @{ Name = "Auth Service"; Url = "http://localhost:4001/health" },
        @{ Name = "Calendar Service"; Url = "http://localhost:3003/health" },
        @{ Name = "Laboratorio Service"; Url = "http://localhost:3004/health" },
        @{ Name = "Solicitudes Service"; Url = "http://localhost:3001/health" },
        @{ Name = "Cremer Backend"; Url = "http://localhost:3002/health" },
        @{ Name = "Tecnomaco Backend"; Url = "http://localhost:3006/health" },
        @{ Name = "Servidor RPS"; Url = "http://localhost:4000/health" },
        @{ Name = "phpMyAdmin"; Url = "http://localhost:8081" },
        @{ Name = "Nginx Gateway"; Url = "http://localhost/health" }
    )
    
    foreach ($service in $services) {
        $health = Test-ServiceHealth -Url $service.Url -ServiceName $service.Name
        Write-Host "$($health.Status) $($service.Name)" -ForegroundColor $health.Color
    }
    
    Write-Host ""
}

function Show-ResourceUsage {
    Write-Host "=== Uso de Recursos ===" -ForegroundColor Yellow
    
    try {
        $stats = docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        
        if ($stats) {
            $lines = $stats -split "`n"
            Write-Host $lines[0] -ForegroundColor Cyan
            
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i].Trim() -ne "") {
                    $parts = $lines[$i] -split "\s+"
                    if ($parts.Count -ge 4) {
                        $name = $parts[0]
                        $cpu = $parts[1]
                        $mem = $parts[2]
                        $memPerc = $parts[3]
                        
                        # Colorear según uso de CPU
                        $cpuValue = [float]($cpu -replace '%', '')
                        $cpuColor = if ($cpuValue -gt 80) { "Red" } elseif ($cpuValue -gt 50) { "Yellow" } else { "Green" }
                        
                        Write-Host "$name" -ForegroundColor White -NoNewline
                        Write-Host "\t$cpu" -ForegroundColor $cpuColor -NoNewline
                        Write-Host "\t$mem\t$memPerc" -ForegroundColor Gray
                    }
                }
            }
        } else {
            Write-Host "No hay contenedores ejecutándose" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al obtener estadísticas de recursos" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-QuickActions {
    Write-Host "=== Acciones Rápidas ===" -ForegroundColor Yellow
    Write-Host "• Ver logs: docker-compose logs -f [servicio]" -ForegroundColor Gray
    Write-Host "• Reiniciar servicio: docker-compose restart [servicio]" -ForegroundColor Gray
    Write-Host "• Detener todo: docker-compose down" -ForegroundColor Gray
    Write-Host "• Estado detallado: docker-compose ps" -ForegroundColor Gray
    Write-Host ""
    
    if ($Continuous) {
        Write-Host "Presiona Ctrl+C para salir del monitoreo continuo" -ForegroundColor Yellow
    } else {
        Write-Host "Usa -Continuous para monitoreo en tiempo real" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Show-NetworkInfo {
    Write-Host "=== Información de Red ===" -ForegroundColor Yellow
    
    try {
        $networks = docker network ls --filter "name=naturepharma" --format "{{.Name}}\t{{.Driver}}\t{{.Scope}}"
        if ($networks) {
            Write-Host "Redes activas:" -ForegroundColor Cyan
            $networks | ForEach-Object {
                Write-Host "• $_" -ForegroundColor Gray
            }
        } else {
            Write-Host "No hay redes de NaturePharma activas" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error al obtener información de red" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Función principal de monitoreo
function Start-Monitoring {
    do {
        Show-Header
        Show-ServiceStatus
        Show-ServiceHealth
        Show-ResourceUsage
        Show-NetworkInfo
        Show-QuickActions
        
        if ($Continuous) {
            Start-Sleep -Seconds $RefreshInterval
        }
    } while ($Continuous)
}

# Verificar si Docker está disponible
try {
    docker version | Out-Null
} catch {
    Write-Host "Error: Docker no está disponible" -ForegroundColor Red
    Write-Host "Asegúrate de que Docker Desktop esté ejecutándose" -ForegroundColor Yellow
    exit 1
}

# Iniciar monitoreo
Start-Monitoring