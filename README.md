# OpenCue API Service

This directory contains files for setting up and running the OpenCue API service in a Docker container.

## Overview

The OpenCue API service provides a containerized interface to the OpenCue services. It includes:
- PyCue and PyOutline Python API libraries
- Access to the Cuebot API server
- A container environment with all necessary dependencies pre-installed

## Prerequisites

1. Docker installed and running
2. A running Cuebot server (see the cuebot-server directory)
3. Network connectivity between containers

## Setup and Usage

### Windows

Run the API service using PowerShell:

```powershell
.\start-api.ps1 [options]
```

Options:
- `-CuebotHostname <hostname>`: Hostname or IP of the Cuebot server (default: opencue-cuebot)
- `-CuebotPort <port>`: Port on the Cuebot server (default: 8443)
- `-ApiName <name>`: Name for the API container (default: opencue-api)
- `-Network <network>`: Docker network to connect to (default: cuebot-server_opencue-network)
- `-Build`: Build the Docker image locally instead of using pre-built
- `-Help`: Display help message

### Linux/macOS

Run the API service using Bash:

```bash
./start-api.sh [options]
```

Options:
- `-c, --cuebot-hostname <hostname>`: Hostname or IP of the Cuebot server (default: opencue-cuebot)
- `-p, --cuebot-port <port>`: Port on the Cuebot server (default: 8443)
- `-a, --api-name <name>`: Name for the API container (default: opencue-api)
- `-n, --network <network>`: Docker network to connect to (default: cuebot-server_opencue-network)
- `-b, --build`: Build the Docker image locally
- `-h, --help`: Display help message

## Connecting to a Remote Cuebot

To connect to a Cuebot server running on a different machine:

1. Use the IP address or hostname of the remote machine:
   ```
   # Windows
   .\start-api.ps1 -CuebotHostname 192.168.1.100
   
   # Linux/macOS
   ./start-api.sh -c 192.168.1.100
   ```

2. Make sure the network settings allow communication between the machines.

## Using the API Service

After starting the API container, you can connect to it to run Python scripts using the OpenCue libraries:

```bash
docker exec -it opencue-api bash
```

Inside the container, you can use the OpenCue Python API libraries:

```python
import opencue
import outline

# Configure Cuebot connection (already set by environment variable)
# opencue.Cuebot.setHosts(['opencue-cuebot:8443'])

# Use the API
jobs = opencue.api.getJobs()
print(f"Found {len(jobs)} jobs")
```

## Troubleshooting

### Connection to Cuebot fails

1. Verify that the Cuebot server is running
2. Check network connectivity between containers or machines
3. Verify the correct hostname/IP and port are being used

### API container exits unexpectedly

1. Check container logs: `docker logs opencue-api`
2. Verify that all environment variables are set correctly
3. Ensure that the Cuebot server is accessible

## Building Custom Images

To build a custom API Docker image:

```
cd api
docker build -t opencue/api .
``` 