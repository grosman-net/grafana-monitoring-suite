#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root.${NC}" >&2
    exit 1
fi

# Main menu
show_menu() {
    echo -e "${GREEN}"
    echo "1. Full deploy (Grafana, Docker, Prometheus, Node Exporter)"
    echo "2. Choose components to install"
    echo "3. Cancel/Exit"
    echo -e "${NC}"
}

# Full deployment
full_deploy() {
    echo -e "${YELLOW}Starting full deployment...${NC}"
    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${GREEN}Installing Docker...${NC}"
        apt-get update
        apt-get install -y docker.io docker-compose
        systemctl enable --now docker
    else
        echo -e "${YELLOW}Docker is already installed.${NC}"
    fi

    # Deploy Grafana, Prometheus, Node Exporter via Docker
    echo -e "${GREEN}Deploying containers...${NC}"
    docker-compose up -d

    echo -e "${GREEN}Done!${NC}"
}

# Component selection
choose_components() {
    echo -e "${YELLOW}Select components to install:${NC}"
    # Здесь будет логика выбора компонентов
}

# Main logic
while true; do
    show_menu
    read -p "Select an option (1-3): " choice
    case $choice in
        1) full_deploy; break ;;
        2) choose_components; break ;;
        3) echo "Exiting..."; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
done
