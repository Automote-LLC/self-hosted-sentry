# Dockerfile for Railway deployment of Self-Hosted Sentry
# This Dockerfile sets up the environment with Docker and docker-compose

# Use a base image with Docker and common utilities
FROM docker:24-cli

# Install bash and other required utilities
RUN apk add --no-cache \
    bash \
    curl \
    git \
    openssl \
    make \
    grep \
    sed \
    coreutils \
    ncurses \
    wget

# Install docker-compose (standalone version)
RUN curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    docker-compose --version

# Set working directory
WORKDIR /app

# Copy all project files
COPY . .

# Make install script executable
RUN chmod +x install.sh && \
    chmod +x install/*.sh && \
    chmod +x scripts/*.sh 2>/dev/null || true

# Set environment variables for Railway detection
# These will be overridden by Railway's environment if set
ENV RAILWAY_ENVIRONMENT=1
ENV CONTAINER_ENGINE=docker
ENV DOCKER_PLATFORM=linux/amd64

# Expose port 80 (nginx)
EXPOSE 80

# Create entrypoint script that runs installation then starts services
# Note: Railway should provide Docker socket access, so we don't need to start dockerd
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Check if Docker is available' >> /entrypoint.sh && \
    echo 'if ! command -v docker &> /dev/null; then' >> /entrypoint.sh && \
    echo '  echo "Error: Docker is not available"' >> /entrypoint.sh && \
    echo '  exit 1' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Wait for Docker to be ready (Railway should provide this)' >> /entrypoint.sh && \
    echo 'echo "Checking Docker availability..."' >> /entrypoint.sh && \
    echo 'timeout=30' >> /entrypoint.sh && \
    echo 'while ! docker info >/dev/null 2>&1; do' >> /entrypoint.sh && \
    echo '  if [ $timeout -eq 0 ]; then' >> /entrypoint.sh && \
    echo '    echo "Docker is not available. Railway may need to be configured for Docker access."' >> /entrypoint.sh && \
    echo '    exit 1' >> /entrypoint.sh && \
    echo '  fi' >> /entrypoint.sh && \
    echo '  sleep 1' >> /entrypoint.sh && \
    echo '  timeout=$((timeout - 1))' >> /entrypoint.sh && \
    echo 'done' >> /entrypoint.sh && \
    echo 'echo "Docker is ready"' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Run installation script' >> /entrypoint.sh && \
    echo 'echo "Starting installation..."' >> /entrypoint.sh && \
    echo './install.sh --skip-user-creation --skip-commit-check' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start services with docker compose' >> /entrypoint.sh && \
    echo 'echo "Starting services..."' >> /entrypoint.sh && \
    echo 'exec docker compose up --wait' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
