#!/bin/bash
set -e

# Colors
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
RESET='\e[0m'

# Tracking what was installed or skipped
INSTALLED=()
SKIPPED=()

echo -e "${YELLOW}🔧 Starting environment setup...${RESET}"

# ---- Prerequisites ----
echo -e "${YELLOW}📦 Installing prerequisites...${RESET}"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# ---- Helm ----
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}🪖 Installing Helm...${RESET}"
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" \
        | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install -y helm
    INSTALLED+=("Helm")
    echo -e "${GREEN}✅ Helm installed successfully!${RESET}"
else
    SKIPPED+=("Helm")
    echo -e "${YELLOW}⚠️ Helm already installed. Skipping...${RESET}"
fi

# ---- GNOME Terminal ----
if ! command -v gnome-terminal &> /dev/null; then
    echo -e "${YELLOW}🖥️ Installing GNOME Terminal...${RESET}"
    sudo apt-get install -y gnome-terminal
    INSTALLED+=("GNOME Terminal")
    echo -e "${GREEN}✅ GNOME Terminal installed!${RESET}"
else
    SKIPPED+=("GNOME Terminal")
    echo -e "${YELLOW}⚠️ GNOME Terminal already installed. Skipping...${RESET}"
fi

# ---- kubectl ----
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}📦 Installing kubectl...${RESET}"
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mkdir -p ~/.local/bin
    mv ./kubectl ~/.local/bin/kubectl
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
    kubectl version --client
    INSTALLED+=("kubectl")
    echo -e "${GREEN}✅ kubectl installed successfully!${RESET}"
else
    SKIPPED+=("kubectl")
    echo -e "${YELLOW}⚠️ kubectl already installed. Skipping...${RESET}"
fi

# ---- Docker Repo Setup ----
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Setting up Docker repo and keys...${RESET}"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
else
    echo -e "${YELLOW}⚠️ Docker repo already configured. Skipping...${RESET}"
fi

# ---- Docker Desktop ----
DOCKER_DESKTOP_DEB="docker-desktop-amd64.deb"
if [ ! -f "$DOCKER_DESKTOP_DEB" ]; then
    echo -e "${YELLOW}🖥️ Docker Desktop .deb not found, downloading...${RESET}"
    wget https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -O $DOCKER_DESKTOP_DEB
    # Verify if the file was successfully downloaded
    if [ ! -s "$DOCKER_DESKTOP_DEB" ]; then
        echo -e "${RED}❌ Error: Docker Desktop .deb download failed or is corrupt.${RESET}"
        exit 1
    fi
else
    echo -e "${YELLOW}🖥️ Docker Desktop .deb already exists, checking if it is valid...${RESET}"
    # Check if the file is valid by verifying its integrity
    if ! dpkg-deb --info "$DOCKER_DESKTOP_DEB" > /dev/null 2>&1; then
        echo -e "${RED}❌ Invalid Docker Desktop .deb file. Redownloading...${RESET}"
        rm -f "$DOCKER_DESKTOP_DEB"
        wget https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -O $DOCKER_DESKTOP_DEB
        if [ ! -s "$DOCKER_DESKTOP_DEB" ]; then
            echo -e "${RED}❌ Error: Docker Desktop .deb download failed or is corrupt.${RESET}"
            exit 1
        fi
    fi
fi

# Install Docker Desktop
echo -e "${YELLOW}⬇️ Installing Docker Desktop...${RESET}"
sudo apt-get install ./$DOCKER_DESKTOP_DEB
INSTALLED+=("Docker Desktop")
echo -e "${GREEN}✅ Docker Desktop installed successfully!${RESET}"

# ---- figlet for banner ----
if ! command -v figlet &> /dev/null; then
    echo -e "${YELLOW}🆕 Installing figlet for final banner...${RESET}"
    sudo apt-get install -y figlet
    INSTALLED+=("figlet")
else
    SKIPPED+=("figlet")
fi

# ---- Final Banner and Summary ----
echo -e "\n${GREEN}🎉 All installations and checks are complete!${RESET}"
figlet -f slant "DONE ✅"

# ---- Print Summary ----
echo -e "\n${YELLOW}📋 Summary:${RESET}"
if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Installed:${RESET} ${INSTALLED[*]}"
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️ Skipped (already installed):${RESET} ${SKIPPED[*]}"
fi

# End of script
exit 0

