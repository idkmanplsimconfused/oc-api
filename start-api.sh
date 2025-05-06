#!/bin/bash
# OpenCue API Client Setup Script for Linux

# Function to display help
show_help() {
    echo "Usage: ./start-api.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --cuebot-hostname HOSTNAME  The hostname or IP address of the Cuebot server (default: opencue-cuebot)"
    echo "                                  - For same-machine containers: use 'opencue-cuebot' (default)"
    echo "                                  - For different machines: use the actual IP address or hostname"
    echo "  -p, --cuebot-port PORT          The port to connect to on the Cuebot server (default: 8443)"
    echo "  -n, --name NAME                 The name to give to the API container (default: opencue-api)"
    echo "  -w, --network NETWORK           Docker network to connect to (default: cuebot_opencue-network)"
    echo "  -b, --build                     Build the Docker image locally instead of using pre-built"
    echo "  -h, --help                      Display this help message"
    exit 0
}

# Parse command line arguments
CUEBOT_HOSTNAME="opencue-cuebot"
CUEBOT_PORT="8443"
API_NAME="opencue-api"
NETWORK="cuebot_opencue-network"
BUILD=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--cuebot-hostname)
            CUEBOT_HOSTNAME="$2"
            shift 2
            ;;
        -p|--cuebot-port)
            CUEBOT_PORT="$2"
            shift 2
            ;;
        -n|--name)
            API_NAME="$2"
            shift 2
            ;;
        -w|--network)
            NETWORK="$2"
            shift 2
            ;;
        -b|--build)
            BUILD=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Error: Unknown option $1"
            show_help
            ;;
    esac
done

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install Docker and try again."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker is not running."
    echo "Please start the Docker service and try again."
    exit 1
fi

# Check if the specified Docker network exists
if ! docker network inspect "$NETWORK" &> /dev/null; then
    echo "Error: Docker network '$NETWORK' doesn't exist."
    echo "Please make sure your Cuebot services are running first."
    echo "Possible networks available:"
    docker network ls
    exit 1
fi

# Combine hostname and port for CUEBOT_HOSTS
CUEBOT_HOSTS="${CUEBOT_HOSTNAME}:${CUEBOT_PORT}"

# Print configuration summary
echo "OpenCue API Configuration Summary:"
echo "=================================="
echo "Cuebot Hosts: $CUEBOT_HOSTS"
echo "API Container Name: $API_NAME"
echo "Docker Network: $NETWORK"
echo ""

# Build the Docker image if requested
if [ "$BUILD" = true ]; then
    echo "Building OpenCue API Docker image..."
    docker build -t opencue/api ./
fi

# Check if the API container already exists
if docker container inspect "$API_NAME" &> /dev/null; then
    echo "API container '$API_NAME' already exists."
    
    # Check if the container is running
    if docker ps -q -f "name=$API_NAME" &> /dev/null; then
        echo "API container is already running."
    else
        echo "Starting existing API container..."
        docker start "$API_NAME"
    fi
else
    # Create a shared directory for the API
    API_SHARED_DIR="${HOME}/opencue-api"
    if [ ! -d "$API_SHARED_DIR" ]; then
        echo "Creating API shared directory at $API_SHARED_DIR..."
        mkdir -p "$API_SHARED_DIR"
    fi
    
    # Run the API container
    echo "Starting API container..."
    docker run -d --name "$API_NAME" \
        --network "$NETWORK" \
        --env CUEBOT_HOSTS="$CUEBOT_HOSTS" \
        --volume "${API_SHARED_DIR}:/opencue/shared" \
        opencue/api
fi

# Verify the container is running
if docker ps -q -f "name=$API_NAME" &> /dev/null; then
    echo "API container is now running."
    
    # Display the logs
    echo "API container logs:"
    echo "=================="
    docker logs "$API_NAME"
else
    echo "Error: Failed to start API container."
    echo "Check Docker logs for more information:"
    echo "docker logs $API_NAME"
    exit 1
fi

echo ""
echo "OpenCue API setup complete!"
echo "To stop the API container, run: docker stop $API_NAME"
echo "To view API logs, run: docker logs $API_NAME"
echo "To run Python commands with the API, run: docker exec -it $API_NAME python" 