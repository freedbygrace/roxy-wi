#!/bin/bash
set -e

# Roxy-WI Docker Entrypoint Script
# Handles initialization, key generation, and database setup

ROXY_WI_HOME="${ROXY_WI_HOME:-/var/www/haproxy-wi}"
ROXY_WI_DATA="${ROXY_WI_DATA:-/var/lib/roxy-wi}"
ROXY_WI_LOGS="${ROXY_WI_LOGS:-/var/log/roxy-wi}"
ROXY_WI_CONFIG="${ROXY_WI_CONFIG:-/etc/roxy-wi}"
KEYS_DIR="${ROXY_WI_DATA}/keys"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Generate JWT RSA keys if they don't exist
generate_jwt_keys() {
    if [ ! -f "${KEYS_DIR}/roxy-wi-key" ] || [ ! -f "${KEYS_DIR}/roxy-wi-key.pub" ]; then
        log "Generating JWT RSA keys..."
        openssl genrsa -out "${KEYS_DIR}/roxy-wi-key" 2048
        openssl rsa -in "${KEYS_DIR}/roxy-wi-key" -pubout -out "${KEYS_DIR}/roxy-wi-key.pub"
        chmod 600 "${KEYS_DIR}/roxy-wi-key"
        chmod 644 "${KEYS_DIR}/roxy-wi-key.pub"
        chown roxy-wi:roxy-wi "${KEYS_DIR}/roxy-wi-key" "${KEYS_DIR}/roxy-wi-key.pub"
        log "JWT RSA keys generated successfully"
    else
        log "JWT RSA keys already exist"
    fi
}

# Generate secret phrase if not set
generate_secret_phrase() {
    if [ -z "${ROXY_WI_SECRET_PHRASE}" ]; then
        if grep -q "secret_phrase = _B8avTpFFL19M8P9VyTiX42NyeyUaneV26kyftB2E_4=" "${ROXY_WI_CONFIG}/roxy-wi.cfg" 2>/dev/null; then
            log "Generating new secret phrase..."
            NEW_SECRET=$(openssl rand -base64 32 | tr -d '/+=' | head -c 44)
            sed -i "s|secret_phrase = .*|secret_phrase = ${NEW_SECRET}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
            log "New secret phrase generated"
        fi
    else
        log "Using provided secret phrase from environment"
        sed -i "s|secret_phrase = .*|secret_phrase = ${ROXY_WI_SECRET_PHRASE}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
    fi
}

# Configure MySQL if enabled
configure_mysql() {
    if [ "${ROXY_WI_MYSQL_ENABLE:-0}" = "1" ]; then
        log "Configuring MySQL connection..."
        sed -i "s|enable = 0|enable = 1|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        sed -i "s|mysql_user = .*|mysql_user = ${ROXY_WI_MYSQL_USER:-roxy-wi}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        sed -i "s|mysql_password = .*|mysql_password = ${ROXY_WI_MYSQL_PASSWORD:-roxy-wi}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        sed -i "s|mysql_db = .*|mysql_db = ${ROXY_WI_MYSQL_DB:-roxywi}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        sed -i "s|mysql_host = .*|mysql_host = ${ROXY_WI_MYSQL_HOST:-127.0.0.1}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        sed -i "s|mysql_port = .*|mysql_port = ${ROXY_WI_MYSQL_PORT:-3306}|" "${ROXY_WI_CONFIG}/roxy-wi.cfg"
        log "MySQL configuration applied"
    fi
}

# Ensure directories exist with proper permissions
setup_directories() {
    log "Setting up directories..."
    
    # Create required directories
    mkdir -p "${ROXY_WI_DATA}/keys"
    mkdir -p "${ROXY_WI_DATA}/configs/hap_config"
    mkdir -p "${ROXY_WI_DATA}/configs/kp_config"
    mkdir -p "${ROXY_WI_DATA}/configs/nginx_config"
    mkdir -p "${ROXY_WI_DATA}/configs/apache_config"
    mkdir -p "${ROXY_WI_LOGS}"
    mkdir -p /var/log/nginx
    mkdir -p /var/log/supervisor
    
    # Set ownership
    chown -R roxy-wi:roxy-wi "${ROXY_WI_DATA}"
    chown -R roxy-wi:roxy-wi "${ROXY_WI_LOGS}"
    chown -R roxy-wi:roxy-wi "${ROXY_WI_HOME}"
    
    log "Directories setup complete"
}

# Wait for MySQL if enabled
wait_for_mysql() {
    if [ "${ROXY_WI_MYSQL_ENABLE:-0}" = "1" ]; then
        log "Waiting for MySQL to be ready..."
        MYSQL_HOST="${ROXY_WI_MYSQL_HOST:-127.0.0.1}"
        MYSQL_PORT="${ROXY_WI_MYSQL_PORT:-3306}"
        
        for i in $(seq 1 30); do
            if nc -z "${MYSQL_HOST}" "${MYSQL_PORT}" 2>/dev/null; then
                log "MySQL is ready"
                return 0
            fi
            log "Waiting for MySQL... (${i}/30)"
            sleep 2
        done
        
        log "WARNING: MySQL connection timeout, continuing anyway..."
    fi
}

# Main initialization
main() {
    log "Starting Roxy-WI initialization..."
    
    setup_directories
    generate_jwt_keys
    generate_secret_phrase
    configure_mysql
    wait_for_mysql
    
    log "Initialization complete, starting services..."
    
    # Execute the main command
    exec "$@"
}

main "$@"

