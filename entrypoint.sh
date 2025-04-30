#!/bin/bash
set -e

echo "Starting OpenCue API container..."
echo "CUEBOT_HOSTS=$CUEBOT_HOSTS"
 
# Execute the command passed to docker run
exec "$@" 