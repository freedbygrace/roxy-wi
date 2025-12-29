# Roxy-WI Docker Image
# Multi-stage build for optimized image size
# 
# Build: docker build -t roxy-wi:latest -f docker/Dockerfile .
# Run:   docker run -d -p 8080:80 -v roxy-wi-data:/var/lib/roxy-wi roxy-wi:latest

ARG PYTHON_VERSION=3.11
ARG BASE_IMAGE=python:${PYTHON_VERSION}-slim-bookworm

# =============================================================================
# Stage 1: Builder - Install dependencies and build wheels
# =============================================================================
FROM ${BASE_IMAGE} AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    libmariadb-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and build wheels
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir=/wheels -r requirements.txt

# =============================================================================
# Stage 2: Runtime - Final optimized image
# =============================================================================
FROM ${BASE_IMAGE} AS runtime

LABEL maintainer="Roxy-WI Community" \
      org.opencontainers.image.title="Roxy-WI" \
      org.opencontainers.image.description="Web interface for managing HAProxy, Nginx, Apache and Keepalived servers" \
      org.opencontainers.image.url="https://github.com/roxy-wi/roxy-wi" \
      org.opencontainers.image.source="https://github.com/roxy-wi/roxy-wi" \
      org.opencontainers.image.vendor="Roxy-WI" \
      org.opencontainers.image.licenses="Apache-2.0"

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ROXY_WI_HOME=/var/www/haproxy-wi \
    ROXY_WI_DATA=/var/lib/roxy-wi \
    ROXY_WI_LOGS=/var/log/roxy-wi \
    ROXY_WI_CONFIG=/etc/roxy-wi

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    openssh-client \
    openssl \
    libmariadb3 \
    nmap \
    ansible \
    git \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${ROXY_WI_HOME} ${ROXY_WI_DATA} ${ROXY_WI_LOGS} ${ROXY_WI_CONFIG} \
    && mkdir -p ${ROXY_WI_DATA}/keys \
    && mkdir -p ${ROXY_WI_DATA}/configs/hap_config \
    && mkdir -p ${ROXY_WI_DATA}/configs/kp_config \
    && mkdir -p ${ROXY_WI_DATA}/configs/nginx_config \
    && mkdir -p ${ROXY_WI_DATA}/configs/apache_config

# Create roxy-wi user
RUN groupadd -r roxy-wi && useradd -r -g roxy-wi -d ${ROXY_WI_HOME} -s /bin/bash roxy-wi

# Install Python wheels from builder
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*.whl && rm -rf /wheels

# Copy application code
COPY src/app ${ROXY_WI_HOME}/app
COPY requirements.txt ${ROXY_WI_HOME}/
COPY roxy-wi.cfg ${ROXY_WI_CONFIG}/roxy-wi.cfg
COPY favicon.png ${ROXY_WI_HOME}/favicon.png

# Copy Docker-specific configuration files
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/supervisord.conf /etc/supervisor/conf.d/roxy-wi.conf
COPY docker/nginx/roxy-wi.conf /etc/nginx/sites-available/roxy-wi.conf

# Setup nginx
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -sf /etc/nginx/sites-available/roxy-wi.conf /etc/nginx/sites-enabled/roxy-wi.conf

# Set permissions
RUN chmod +x /entrypoint.sh \
    && chown -R roxy-wi:roxy-wi ${ROXY_WI_HOME} ${ROXY_WI_DATA} ${ROXY_WI_LOGS}

# Create symlink for config
RUN ln -sf ${ROXY_WI_CONFIG}/roxy-wi.cfg ${ROXY_WI_HOME}/roxy-wi.cfg

WORKDIR ${ROXY_WI_HOME}

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/api/health || exit 1

# Volumes for persistent data
VOLUME ["${ROXY_WI_DATA}", "${ROXY_WI_LOGS}", "${ROXY_WI_CONFIG}"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

