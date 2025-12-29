#!/bin/bash
###############################################################################
# Roxy-WI Docker Build and Push Script
#
# Builds the Docker image and pushes to DockerHub with:
#   - "latest" tag
#   - Date-based tag (yyyy.mm.dd.hhmm)
#
# Usage:
#   ./scripts/docker-build-push.sh [options]
#
# Options:
#   -r, --repo      DockerHub repository (default: roxy-wi/roxy-wi)
#   -p, --platform  Build platform (default: linux/amd64,linux/arm64)
#   -n, --no-push   Build only, don't push to DockerHub
#   -h, --help      Show this help message
#
# Environment Variables:
#   DOCKERHUB_USERNAME  DockerHub username (required for push)
#   DOCKERHUB_TOKEN     DockerHub access token (required for push)
#
# Prerequisites:
#   - Docker with buildx support
#   - DockerHub credentials (for push)
###############################################################################

set -euo pipefail

# Default values
REPO="roxy-wi/roxy-wi"
PLATFORMS="linux/amd64,linux/arm64"
PUSH=true
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Show help
show_help() {
    sed -n '2,24p' "$0" | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo) REPO="$2"; shift 2 ;;
        -p|--platform) PLATFORMS="$2"; shift 2 ;;
        -n|--no-push) PUSH=false; shift ;;
        -h|--help) show_help ;;
        *) log_error "Unknown option: $1"; show_help ;;
    esac
done

# Generate date-based tag (yyyy.mm.dd.hhmm)
DATE_TAG=$(date -u +"%Y.%m.%d.%H%M")
LATEST_TAG="latest"

log_info "=== Roxy-WI Docker Build Script ==="
log_info "Repository: $REPO"
log_info "Date Tag: $DATE_TAG"
log_info "Platforms: $PLATFORMS"
log_info "Push: $PUSH"
log_info "Project Root: $PROJECT_ROOT"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    log_error "Docker buildx is not available"
    exit 1
fi

# Authenticate to DockerHub if pushing
if [ "$PUSH" = true ]; then
    if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
        log_error "DOCKERHUB_USERNAME and DOCKERHUB_TOKEN environment variables are required for push"
        log_info "Set these variables or use -n/--no-push for local build only"
        exit 1
    fi
    
    log_info "Authenticating to DockerHub..."
    echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    log_success "DockerHub authentication successful"
fi

# Create/use buildx builder for multi-platform
BUILDER_NAME="roxy-wi-builder"
if ! docker buildx inspect "$BUILDER_NAME" &> /dev/null; then
    log_info "Creating buildx builder: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --use --bootstrap
else
    log_info "Using existing buildx builder: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# Build the image
log_info "Building Docker image..."
cd "$PROJECT_ROOT"

BUILD_ARGS=(
    --file docker/Dockerfile
    --tag "$REPO:$LATEST_TAG"
    --tag "$REPO:$DATE_TAG"
    --platform "$PLATFORMS"
    --builder "$BUILDER_NAME"
)

if [ "$PUSH" = true ]; then
    BUILD_ARGS+=(--push)
    log_info "Building and pushing to DockerHub..."
else
    BUILD_ARGS+=(--load)
    # --load only works with single platform
    BUILD_ARGS=(
        --file docker/Dockerfile
        --tag "$REPO:$LATEST_TAG"
        --tag "$REPO:$DATE_TAG"
        --builder "$BUILDER_NAME"
        --load
    )
    log_warn "Local build only supports single platform, using current architecture"
fi

docker buildx build "${BUILD_ARGS[@]}" .

# Output results
echo ""
log_success "=== Build Complete ==="
log_success "Image: $REPO:$LATEST_TAG"
log_success "Image: $REPO:$DATE_TAG"

if [ "$PUSH" = true ]; then
    log_success "Images pushed to DockerHub successfully!"
    echo ""
    log_info "Pull commands:"
    echo "  docker pull $REPO:latest"
    echo "  docker pull $REPO:$DATE_TAG"
else
    log_info "Images built locally (not pushed)"
    echo ""
    log_info "To push manually:"
    echo "  docker push $REPO:latest"
    echo "  docker push $REPO:$DATE_TAG"
fi

