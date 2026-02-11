#!/bin/bash
# ComfyUI Docker Pull, Mount and Run Script
# Run as: sudo bash run_comfyui.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo bash $0${NC}"
    exit 1
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  ComfyUI Docker Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Configuration
IMAGE_NAME="maheshcn83/comfyui-runpod:latest"
CONTAINER_NAME="comfyui-video-gen"
LOCAL_MODELS_DIR="/opt/models"
LOCAL_OUTPUT_DIR="/opt/comfyui-output"
LOCAL_INPUT_DIR="/opt/comfyui-input"
LOCAL_CACHE_DIR="/opt/comfyui-cache"

ACTUAL_USER="${SUDO_USER:-$USER}"

# ============================================
# STEP 1: Create Persistent Directories
# ============================================
echo -e "${YELLOW}[1/4] Creating persistent directories...${NC}"

mkdir -p "${LOCAL_MODELS_DIR}"
mkdir -p "${LOCAL_OUTPUT_DIR}"
mkdir -p "${LOCAL_INPUT_DIR}"
mkdir -p "${LOCAL_CACHE_DIR}/huggingface"
mkdir -p "${LOCAL_CACHE_DIR}/torch"

# Set ownership to actual user
if [ "$ACTUAL_USER" != "root" ]; then
    chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${LOCAL_MODELS_DIR}"
    chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${LOCAL_OUTPUT_DIR}"
    chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${LOCAL_INPUT_DIR}"
    chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${LOCAL_CACHE_DIR}"
fi

echo -e "${GREEN}✓ Persistent directories created:${NC}"
echo -e "    Models: ${LOCAL_MODELS_DIR}"
echo -e "    Output: ${LOCAL_OUTPUT_DIR}"
echo -e "    Input:  ${LOCAL_INPUT_DIR}"
echo -e "    Cache:  ${LOCAL_CACHE_DIR}"

# ============================================
# STEP 2: Stop Existing Container
# ============================================
echo -e "\n${YELLOW}[2/4] Removing existing container if present...${NC}"
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"

# ============================================
# STEP 3: Pull Docker Image
# ============================================
echo -e "\n${YELLOW}[3/4] Pulling ComfyUI image from Docker Hub...${NC}"
docker pull "${IMAGE_NAME}"
echo -e "${GREEN}✓ Image pulled successfully${NC}"

# ============================================
# STEP 4: Run ComfyUI Container
# ============================================
echo -e "\n${YELLOW}[4/4] Starting ComfyUI container...${NC}"

docker run -d \
    --name "${CONTAINER_NAME}" \
    --gpus all \
    --restart always \
    -p 8188:8188 \
    -p 8000:8000 \
    -p 2222:22 \
    -v "${LOCAL_MODELS_DIR}:/workspace/ComfyUI/models" \
    -v "${LOCAL_OUTPUT_DIR}:/workspace/ComfyUI/output" \
    -v "${LOCAL_INPUT_DIR}:/workspace/ComfyUI/input" \
    -v "${LOCAL_CACHE_DIR}/huggingface:/workspace/huggingface" \
    -v "${LOCAL_CACHE_DIR}/torch:/workspace/torch_cache" \
    -e UPDATE_COMFYUI=false \
    -e UPDATE_NODES=false \
    -e DOWNLOAD_MODELS=false \
    -e DISABLE_XFORMERS=true \
    -e USE_PYTORCH_CROSS_ATTENTION=true \
    "${IMAGE_NAME}"

# Wait a moment for container to start
sleep 3

# Check if container is running
if docker ps | grep -q "${CONTAINER_NAME}"; then
    echo -e "${GREEN}✓ ComfyUI container started successfully!${NC}"
    echo -e "${GREEN}✓ Container will auto-start on boot (--restart always)${NC}"
else
    echo -e "${RED}✗ Container failed to start. Check logs:${NC}"
    echo -e "  ${YELLOW}docker logs ${CONTAINER_NAME}${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  ComfyUI is Running!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}Access ComfyUI at:${NC}"
echo -e "  Web UI:       ${YELLOW}http://localhost:8188${NC}"
echo -e "  File Browser: ${YELLOW}http://localhost:8000${NC}"
echo ""
echo -e "${GREEN}Persistent directories:${NC}"
echo -e "  Models: ${YELLOW}${LOCAL_MODELS_DIR}${NC}"
echo -e "  Output: ${YELLOW}${LOCAL_OUTPUT_DIR}${NC}"
echo -e "  Input:  ${YELLOW}${LOCAL_INPUT_DIR}${NC}"
echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo -e "  View logs:     ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
echo -e "  Stop:          ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
echo -e "  Start:         ${YELLOW}docker start ${CONTAINER_NAME}${NC}"
echo -e "  Restart:       ${YELLOW}docker restart ${CONTAINER_NAME}${NC}"
echo -e "  Shell access:  ${YELLOW}docker exec -it ${CONTAINER_NAME} bash${NC}"
echo ""
