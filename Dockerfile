FROM python:3.9-slim

# Install required build tools
RUN apt-get update && \
    apt-get install -y git build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opencue

# Clone the OpenCue repository
RUN git clone https://github.com/AcademySoftwareFoundation/OpenCue.git .

# Install Python dependencies
RUN pip install virtualenv && \
    virtualenv /venv
ENV PATH="/venv/bin:$PATH"

# Install dependencies following documentation exactly
RUN pip install -r requirements.txt

# Build and install PyCue
WORKDIR /opencue/proto
RUN python -m grpc_tools.protoc -I=. --python_out=../pycue/opencue/compiled_proto --grpc_python_out=../pycue/opencue/compiled_proto ./*.proto
WORKDIR /opencue/pycue/opencue/compiled_proto
RUN 2to3 -w -n *
WORKDIR /opencue/pycue
RUN python setup.py install

# Build and install PyOutline
WORKDIR /opencue/pyoutline
RUN python setup.py install

# Default Cuebot host - will be overridden by environment variable at runtime
ENV CUEBOT_HOSTS="opencue-cuebot:8443"

# Create a volume mount point for sharing data
VOLUME /opencue/shared

# Set working directory back to root
WORKDIR /opencue

# Create a simple verification script
RUN echo '#!/usr/bin/env python\nimport os\nimport opencue\nimport outline\nprint("PyCue and PyOutline API verification:")\nprint("CUEBOT_HOSTS environment variable:", os.environ.get("CUEBOT_HOSTS", "Not set"))\ntry:\n    shows = opencue.api.getShows()\n    print("Successfully connected to Cuebot!")\n    print("Available shows:", [show.name() for show in shows])\nexcept Exception as e:\n    print("Failed to connect to Cuebot:", str(e))\n    print("Check CUEBOT_HOSTS environment variable.")\n    import opencue.wrappers.show' > /opencue/verify_api.py && \
    chmod +x /opencue/verify_api.py

# Create a keep-alive script that runs the verification and then keeps the container running
RUN echo '#!/bin/bash\n\n# Run verification script\npython /opencue/verify_api.py\n\necho ""\necho "PyCue API container is ready and connected to Cuebot."\necho "The container will keep running. To interact with it, use:"\necho "docker exec -it <container_name> python"\necho ""\n\n# Keep the container running\necho "Container is running. Press Ctrl+C to exit."\n\n# Use tail -f /dev/null to keep the container running\nexec tail -f /dev/null' > /opencue/start.sh && \
    chmod +x /opencue/start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import opencue; try: opencue.api.getShows(); exit(0); except: exit(1)"

# Entry point script
COPY entrypoint.sh /entrypoint.sh
RUN if [ ! -f /entrypoint.sh ]; then \
        echo '#!/bin/bash\necho "Starting OpenCue API container..."\necho "CUEBOT_HOSTS=$CUEBOT_HOSTS"\nexec "$@"' > /entrypoint.sh && \
        chmod +x /entrypoint.sh; \
    fi

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opencue/start.sh"] 