#!/bin/bash
# Generate JWT RSA keys for Roxy-WI
#
# Usage: ./scripts/generate-keys.sh [output_directory]
#
# This script generates RSA key pairs for JWT authentication.
# The keys are used by Roxy-WI for API authentication.

set -e

OUTPUT_DIR="${1:-./keys}"
KEY_FILE="${OUTPUT_DIR}/roxy-wi-key"
PUB_FILE="${OUTPUT_DIR}/roxy-wi-key.pub"

echo "Generating JWT RSA keys..."

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Check if keys already exist
if [ -f "${KEY_FILE}" ] || [ -f "${PUB_FILE}" ]; then
    read -p "Keys already exist. Overwrite? (y/N): " confirm
    if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate private key
openssl genrsa -out "${KEY_FILE}" 2048

# Generate public key
openssl rsa -in "${KEY_FILE}" -pubout -out "${PUB_FILE}"

# Set permissions
chmod 600 "${KEY_FILE}"
chmod 644 "${PUB_FILE}"

echo ""
echo "Keys generated successfully:"
echo "  Private key: ${KEY_FILE}"
echo "  Public key:  ${PUB_FILE}"
echo ""
echo "For Docker deployment, mount these keys to /var/lib/roxy-wi/keys/"

