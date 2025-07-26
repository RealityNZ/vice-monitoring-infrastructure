# Grafana Datasource Configuration Script for Windows
# Configures Prometheus as the default datasource

param(
    [string]$GrafanaUrl = "http://localhost:3000",
    [string]$GrafanaUser = "admin",
    [string]$GrafanaPassword = "viceadmin2024",
    [string]$PrometheusUrl = "http://prometheus:9090"
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

Write-Host "🔧 Configuring Grafana Prometheus Datasource" -ForegroundColor Cyan
Write-Host "📍 Grafana URL: $GrafanaUrl"
Write-Host "📍 Prometheus URL: $PrometheusUrl"
Write-Host ""

# Wait for Grafana to be ready
Write-Warning "Waiting for Grafana to be ready..."
do {
    try {
        $response = Invoke-WebRequest -Uri "$GrafanaUrl/api/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            break
        }
    }
    catch {
        Start-Sleep -Seconds 2
    }
} while ($true)

Write-Success "Grafana is ready"

# Create datasource configuration
$datasourceConfig = @{
    name = "Prometheus"
    type = "prometheus"
    access = "proxy"
    url = $PrometheusUrl
    isDefault = $true
    editable = $true
    jsonData = @{
        timeInterval = "15s"
        queryTimeout = "60s"
        httpMethod = "POST"
    }
} | ConvertTo-Json -Depth 10

# Create credentials for basic auth
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $GrafanaUser, $GrafanaPassword)))

# Add the datasource
Write-Warning "Adding Prometheus datasource..."
try {
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Basic $base64AuthInfo"
    }
    
    $response = Invoke-WebRequest -Uri "$GrafanaUrl/api/datasources" -Method POST -Body $datasourceConfig -Headers $headers -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Success "Prometheus datasource configured successfully"
    }
}
catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Warning "Datasource already exists, updating..."
        
        # Get datasource ID
        try {
            $dsResponse = Invoke-WebRequest -Uri "$GrafanaUrl/api/datasources/name/Prometheus" -Headers $headers -UseBasicParsing
            $dsData = $dsResponse.Content | ConvertFrom-Json
            $dsId = $dsData.id
            
            # Update the datasource
            Invoke-WebRequest -Uri "$GrafanaUrl/api/datasources/$dsId" -Method PUT -Body $datasourceConfig -Headers $headers -UseBasicParsing | Out-Null
            Write-Success "Prometheus datasource updated successfully"
        }
        catch {
            Write-Error "Failed to update existing datasource: $($_.Exception.Message)"
            exit 1
        }
    }
    else {
        Write-Error "Failed to configure datasource: $($_.Exception.Message)"
        exit 1
    }
}

# Test the datasource
Write-Warning "Testing datasource connection..."
try {
    $testBody = @{
        query = "up"
    } | ConvertTo-Json
    
    $testResponse = Invoke-WebRequest -Uri "$GrafanaUrl/api/datasources/proxy/1/api/v1/query" -Method POST -Body $testBody -Headers $headers -UseBasicParsing
    
    if ($testResponse.StatusCode -eq 200) {
        Write-Success "Datasource test successful"
    }
    else {
        Write-Warning "Datasource test failed. Status Code: $($testResponse.StatusCode)"
    }
}
catch {
    Write-Warning "Datasource test failed. This might be normal if Prometheus is still starting up"
    Write-Warning "Error: $($_.Exception.Message)"
}

Write-Host ""
Write-Success "🎉 Grafana datasource configuration completed!"
Write-Host ""
Write-Host "📊 You can now:" -ForegroundColor Cyan
Write-Host "   1. Access Grafana at: $GrafanaUrl"
Write-Host "   2. Create dashboards using Prometheus metrics"
Write-Host "   3. Import existing dashboards from the dashboards/ directory"
Write-Host ""
Write-Host "🔧 To test the connection:" -ForegroundColor Cyan
Write-Host "   1. Go to Grafana → Explore"
Write-Host "   2. Select Prometheus datasource"
Write-Host "   3. Run query: up"
Write-Host "" 