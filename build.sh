#!/bin/bash
# ==========================================================================
# Jetson GPU Passthrough Docker Compose Build Script
# ==========================================================================
# Version:      2.1.0
# Author:       Samir Singh <samir.singh@advantech.com> and Apoorv Saxena<apoorv.saxena@advantech.com>
# Created:      January 10, 2025
# Last Updated: May 19, 2025
# Description:
#   This script prepares a Docker environment optimized for GPU and display
#   passthrough on Advantech edge AI platforms. It:
#     • Creates standard project directories (src, models, data, diagnostics)
#     • Configures X11 or Wayland forwarding for GUI applications
#     • Sets up NVIDIA GPU device access and permissions in containers
#     • Enables display passthrough for accelerated rendering
#     • Launches containers with hardware acceleration support
#
# Terms and Conditions:
#   1. Provided by Advantech Corporation “as is,” with no express or implied
#      warranties of merchantability or fitness for a particular purpose.
#   2. Advantech Corporation shall not be liable for any direct, indirect,
#      incidental, special, exemplary, or consequential damages arising from
#      the use of this software.
#   3. Redistribution and use in source or binary form, with or without
#      modification, are permitted provided this notice appears in all copies.
#
# Copyright (c) 2025 Advantech Corporation. All rights reserved.
# ==========================================================================
clear


GREEN='\033[0;32m'

RED='\033[0;31m'

YELLOW='\033[0;33m'

BLUE='\033[0;34m'

CYAN='\033[0;36m'

BOLD='\033[1m'

PURPLE='\033[0;35m'

NC='\033[0m' # No Color



echo -e "${BLUE}"

echo "       █████╗ ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗     ██████╗ ██████╗ ███████╗"

echo "      ██╔══██╗██╔══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██╔═══██╗██╔════╝"

echo "      ███████║██║  ██║██║   ██║███████║██╔██╗ ██║   ██║   █████╗  ██║     ███████║    ██║     ██║   ██║█████╗  "

echo "      ██╔══██║██║  ██║╚██╗ ██╔╝██╔══██║██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔══██║    ██║     ██║   ██║██╔══╝  "

echo "      ██║  ██║██████╔╝ ╚████╔╝ ██║  ██║██║ ╚████║   ██║   ███████╗╚██████╗██║  ██║    ╚██████╗╚██████╔╝███████╗"

echo "      ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚══════╝"

echo -e "${WHITE}                                  Center of Excellence${NC}"

echo

echo -e "${CYAN}  This may take a moment...${NC}"

echo

sleep 7

# Create project directory structure
echo "Creating project directory structure..."
mkdir -p src models data diagnostics

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check X environment variables
echo "Checking X environment variables..."
echo "XAUTHORITY=$XAUTHORITY"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

# Only configure X11 if XAUTHORITY or XDG_RUNTIME_DIR is not set
if [ -z "$XAUTHORITY" ] || [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "Setting up X11 forwarding..."
    
    # Try to set XAUTHORITY if not defined
    if [ -z "$XAUTHORITY" ]; then
        XAUTH_PATH=$(xauth info 2>/dev/null | grep "Authority file" | awk '{print $3}')
        if [ -n "$XAUTH_PATH" ]; then
            export XAUTHORITY=$XAUTH_PATH
            echo "XAUTHORITY set to $XAUTHORITY"
        fi
    fi
    
    # Try to set XDG_RUNTIME_DIR if not defined
    if [ -z "$XDG_RUNTIME_DIR" ]; then
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        echo "XDG_RUNTIME_DIR set to $XDG_RUNTIME_DIR"
    fi
    
    # Configure X server access
    if command_exists xhost; then
        echo "Configuring xhost access..."
        xhost +local:docker
        
        # Create .docker.xauth file
        echo "Creating X authentication file..."
        touch /tmp/.docker.xauth
        xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -
        chmod 777 /tmp/.docker.xauth
    else
        echo "Warning: xhost command not found. X11 forwarding may not work properly."
    fi
else
    echo "X environment variables already set, skipping X11 setup."
fi

# Start Docker containers
echo "Starting Docker containers..."
if command_exists docker-compose; then
    echo "Using docker-compose command..."
    docker-compose up -d
elif command_exists docker && command_exists compose; then
    echo "Using docker compose command..."
    docker compose up -d
else
    echo "Error: Neither docker-compose nor docker compose commands are available."
    exit 1
fi

# Connect to container
echo "Connecting to container..."
docker exec -it advantech-l2-02 bash

