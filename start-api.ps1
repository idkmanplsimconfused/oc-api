# OpenCue API Client Setup Script for Windows

# Parse command line arguments
param (
    [string]$CuebotHostname = "opencue-cuebot",
    [string]$CuebotPort = "8443",
    [string]$ApiName = "opencue-api",
    [string]$Network = "cuebot_opencue-network",
    [switch]$Build,
    [switch]$Help
)

# Display help if requested
if ($Help) {
    Write-Host "Usage: .\start-api.ps1 [-CuebotHostname <hostname or IP>] [-CuebotPort <port>] [-ApiName <API container name>] [-Network <docker network>] [-Build] [-Help]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -CuebotHostname    The hostname or IP address of the Cuebot server (default: opencue-cuebot)"
    Write-Host "                     - For same-machine containers: use 'opencue-cuebot' (default)"
    Write-Host "                     - For different machines: use the actual IP address or hostname"
    Write-Host "  -CuebotPort        The port to connect to on the Cuebot server (default: 8443)"
    Write-Host "  -ApiName           The name to give to the API container (default: opencue-api)"
    Write-Host "  -Network           Docker network to connect to (default: cuebot_opencue-network)"
    Write-Host "  -Build             Build the Docker image locally instead of using pre-built"
    Write-Host "  -Help              Display this help message"
    exit 0
}

# Check if Docker is installed and running
try {
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
}
catch {
    Write-Host "Error: Docker is not installed or not running."
    Write-Host "Please install Docker Desktop for Windows and start it before running this script."
    exit 1
}

# Check if the specified Docker network exists
$networkExists = $false
try {
    $networkInfo = docker network inspect $Network 2>&1
    if ($LASTEXITCODE -eq 0) {
        $networkExists = $true
    }
}
catch {
    # Network doesn't exist, which is a problem
}

if (-not $networkExists) {
    Write-Host "Error: Docker network '$Network' doesn't exist."
    Write-Host "Please make sure your Cuebot services are running first."
    Write-Host "Possible networks available:"
    docker network ls
    exit 1
}

# Combine hostname and port for CUEBOT_HOSTS
$CuebotHosts = "${CuebotHostname}:${CuebotPort}"

# Print configuration summary
Write-Host "OpenCue API Configuration Summary:"
Write-Host "=================================="
Write-Host "Cuebot Hosts: $CuebotHosts"
Write-Host "API Container Name: $ApiName"
Write-Host "Docker Network: $Network"
Write-Host ""

# Build the Docker image if requested
if ($Build) {
    Write-Host "Building OpenCue API Docker image..."
    docker build -t opencue/api ./
}

# Check if the API container already exists
$containerExists = $false
try {
    $containerInfo = docker container inspect $ApiName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $containerExists = $true
    }
}
catch {
    # Container doesn't exist, which is fine
}

if ($containerExists) {
    Write-Host "API container '$ApiName' already exists."
    
    # Check if the container is running
    $containerRunning = docker ps -q -f "name=$ApiName"
    
    if ($containerRunning) {
        Write-Host "API container is already running."
    }
    else {
        Write-Host "Starting existing API container..."
        docker start $ApiName
    }
}
else {
    # Create a shared directory for the API
    $ApiSharedDir = Join-Path $env:USERPROFILE "opencue-api"
    if (-not (Test-Path $ApiSharedDir)) {
        Write-Host "Creating API shared directory at $ApiSharedDir..."
        New-Item -ItemType Directory -Path $ApiSharedDir | Out-Null
    }

    # Format the path for Docker on Windows
    $volumeMount = "$($ApiSharedDir -replace '\\', '/' -replace ':', ''):/opencue/shared"
    
    # Run the API container
    Write-Host "Starting API container..."
    docker run -d --name $ApiName `
        --network $Network `
        --env CUEBOT_HOSTS=$CuebotHosts `
        --volume "/$volumeMount" `
        opencue/api
}

# Verify the container is running
$containerRunning = docker ps -q -f "name=$ApiName"
if ($containerRunning) {
    Write-Host "API container is now running."
    
    # Display the logs
    Write-Host "API container logs:"
    Write-Host "=================="
    docker logs $ApiName
}
else {
    Write-Host "Error: Failed to start API container."
    Write-Host "Check Docker logs for more information:"
    Write-Host "docker logs $ApiName"
    exit 1
}

Write-Host ""
Write-Host "OpenCue API setup complete!"
Write-Host "To stop the API container, run: docker stop $ApiName"
Write-Host "To view API logs, run: docker logs $ApiName"
Write-Host "To run Python commands with the API, run: docker exec -it $ApiName python" 