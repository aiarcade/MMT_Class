#!/bin/bash
# Docker + NVIDIA Container Toolkit Setup Script
# For Ubuntu 22.04
# Run as: sudo bash setup_docker_nvidia.sh

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
echo -e "${BLUE}  Docker + NVIDIA Container Toolkit Installer${NC}"
echo -e "${BLUE}  Ubuntu 22.04${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ============================================
# STEP 0: Fix apt sources if repos return 403
# ============================================
echo -e "${YELLOW}[0/6] Checking apt repositories...${NC}"
if apt-get update 2>&1 | grep -q "403\|no longer signed"; then
    echo -e "${YELLOW}  Fixing stale Ubuntu repositories (switching to old-releases)...${NC}"
    sed -i 's|http://security.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list
    sed -i 's|http://[a-z]*\.archive\.ubuntu\.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list
    sed -i 's|http://archive\.ubuntu\.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list
    apt-get update
    echo -e "${GREEN}✓ Apt repositories fixed${NC}"
else
    echo -e "${GREEN}✓ Apt repositories OK${NC}"
fi

# ============================================
# STEP 1: Remove old Docker versions
# ============================================
echo -e "${YELLOW}[1/6] Removing old Docker versions...${NC}"
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
echo -e "${GREEN}✓ Old Docker versions removed${NC}"

# ============================================
# STEP 2: Install Docker prerequisites
# ============================================
echo -e "\n${YELLOW}[2/6] Installing prerequisites...${NC}"
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

echo -e "${GREEN}✓ Prerequisites installed${NC}"

# ============================================
# STEP 3: Install Docker Engine
# ============================================
echo -e "\n${YELLOW}[3/6] Installing Docker Engine...${NC}"

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "${GREEN}✓ Docker Engine installed${NC}"

# ============================================
# STEP 4: Enable and start Docker
# ============================================
echo -e "\n${YELLOW}[4/6] Enabling Docker service...${NC}"
systemctl enable docker
systemctl start docker
echo -e "${GREEN}✓ Docker service started${NC}"

# ============================================
# STEP 5: Install NVIDIA Container Toolkit
# ============================================
echo -e "\n${YELLOW}[5/6] Installing NVIDIA Container Toolkit...${NC}"

# Add NVIDIA GPG key and repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

echo -e "${GREEN}✓ NVIDIA Container Toolkit installed and configured${NC}"

# ============================================
# STEP 6: Add current user to docker group
# ============================================
echo -e "\n${YELLOW}[6/6] Adding user to docker group...${NC}"
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" != "root" ]; then
    usermod -aG docker "$ACTUAL_USER"
    echo -e "${GREEN}✓ User '${ACTUAL_USER}' added to docker group${NC}"
    echo -e "${YELLOW}  (Log out and back in for group changes to take effect)${NC}"
else
    echo -e "${YELLOW}  Running as root, skipping user group setup${NC}"
fi

# ============================================
# VERIFICATION
# ============================================
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Verification${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo -e "${YELLOW}Docker version:${NC}"
docker --version

echo ""
echo -e "${YELLOW}Docker Compose version:${NC}"
docker compose version

echo ""
echo -e "${YELLOW}NVIDIA Container Toolkit:${NC}"
nvidia-ctk --version 2>/dev/null || echo "nvidia-ctk installed"

echo ""
echo -e "${YELLOW}Testing GPU access in Docker...${NC}"
if docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi 2>/dev/null; then
    echo -e "\n${GREEN}✓ GPU is accessible from Docker!${NC}"
else
    echo -e "\n${RED}✗ GPU test failed. Check NVIDIA driver installation.${NC}"
    echo -e "${YELLOW}  Make sure NVIDIA drivers are installed: nvidia-smi${NC}"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Docker + NVIDIA Setup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ============================================
# STEP 7: Pull and Run ComfyUI Container
# ============================================
echo -e "${YELLOW}[7/8] Pulling ComfyUI image...${NC}"

# Configuration
IMAGE_NAME="maheshcn83/comfyui-runpod:latest"
CONTAINER_NAME="comfyui-video-gen"
LOCAL_MODELS_DIR="/opt/models"
LOCAL_OUTPUT_DIR="/opt/comfyui-output"
LOCAL_INPUT_DIR="/opt/comfyui-input"
LOCAL_CACHE_DIR="/opt/comfyui-cache"

# Create local directories for persistence
echo -e "${YELLOW}  Creating persistent directories...${NC}"
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

# Stop and remove existing container if it exists
echo -e "\n${YELLOW}  Removing existing container if present...${NC}"
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

# Pull the image from Docker Hub
echo -e "${YELLOW}  Pulling image from Docker Hub...${NC}"
docker pull "${IMAGE_NAME}"

# ============================================
# STEP 8: Run ComfyUI Container
# ============================================
echo -e "\n${YELLOW}[8/8] Starting ComfyUI container...${NC}"

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
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}ComfyUI is running at:${NC}"
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
echo -e "${YELLOW}Note: Log out and back in for docker group changes to take effect.${NC}"
echo -e "${YELLOW}You can also use run_comfyui.sh to restart the container separately.${NC}"
echo ""
