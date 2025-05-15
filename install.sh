#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root.${NC}" >&2
    exit 1
fi

# Initialize installation state
init_install_state() {
    echo "# Installation tracking" > .install_state
    echo "install_dir=$(pwd)" >> .install_state
    echo "timestamp=$(date +%s)" >> .install_state
}

# Install Docker if missing
install_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}Installing Docker...${NC}"
        apt-get update
        apt-get install -y docker.io
        systemctl enable --now docker
        echo "docker_installed=true" >> .install_state
        echo "docker_version=$(docker --version | awk '{print $3}' | tr -d ',')" >> .install_state
        
        # Restart Docker after installation
        echo -e "${YELLOW}Restarting Docker service...${NC}"
        systemctl restart docker
        sleep 3
    else
        echo -e "${YELLOW}Docker is already installed.${NC}"
    fi
    
    if ! command -v docker-compose &>/dev/null; then
        echo -e "${GREEN}Installing Docker Compose...${NC}"
        apt-get install -y docker-compose
        echo "docker_compose_installed=true" >> .install_state
        echo "docker_compose_version=$(docker-compose --version | awk '{print $3}' | tr -d ',')" >> .install_state
        
        # Restart Docker after compose installation
        echo -e "${YELLOW}Restarting Docker service...${NC}"
        systemctl restart docker
        sleep 3
    else
        echo -e "${YELLOW}Docker Compose is already installed.${NC}"
    fi
}

# Cleanup containers and ports
cleanup() {
    echo -e "${YELLOW}Performing pre-installation cleanup...${NC}"
    
    # Stop and remove existing containers
    if command -v docker-compose &>/dev/null && [ -f docker-compose.yml ]; then
        docker-compose down --remove-orphans 2>/dev/null
    fi
    
    # Remove any remaining containers
    docker rm -f $(docker ps -aq --filter name=grafana-monitoring-suite) 2>/dev/null
    
    # Free ports
    for port in 3000 9090 9100 8080; do
        pid=$(lsof -ti :$port)
        if [ ! -z "$pid" ]; then
            echo -e "${YELLOW}Killing process $pid using port $port${NC}"
            kill -9 $pid 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}Cleanup completed.${NC}"
}

# Deploy stack
deploy_stack() {
    echo -e "${GREEN}Deploying monitoring stack...${NC}"
    
    # Pull images with retries
    declare -A images=(
        ["prometheus"]="prom/prometheus"
        ["grafana"]="grafana/grafana"
        ["node-exporter"]="prom/node-exporter"
        ["cadvisor"]="gcr.io/cadvisor/cadvisor"
    )
    
    for service in "${!images[@]}"; do
        echo -e "${YELLOW}Pulling ${images[$service]}...${NC}"
        for attempt in {1..3}; do
            docker pull "${images[$service]}" && break
            echo -e "${RED}Attempt $attempt failed, retrying...${NC}"
            sleep 5
        done
    done
    
    # Record installed images
    echo "installed_images=${images[@]}" >> .install_state
    
    # Start containers
    echo -e "${YELLOW}Starting containers...${NC}"
    docker-compose up -d
    
    # Verify services
    echo -e "\n${YELLOW}Verifying services...${NC}"
    declare -A services=(
        ["grafana"]="3000"
        ["prometheus"]="9090"
        ["node-exporter"]="9100"
        ["cadvisor"]="8080"
    )
    
    all_ok=true
    for service in "${!services[@]}"; do
        if docker ps | grep -q "$service"; then
            echo -e "${GREEN}[✓] $service is running on port ${services[$service]}${NC}"
        else
            echo -e "${RED}[×] $service failed to start${NC}"
            docker logs $service 2>/dev/null | tail -n 5
            all_ok=false
        fi
    done
    
    if $all_ok; then
        echo -e "\n${GREEN}All services started successfully!${NC}"
        echo "installation_success=true" >> .install_state
    else
        echo -e "\n${RED}Some services failed to start. Check logs above.${NC}"
        echo "installation_success=false" >> .install_state
    fi
}

# Check ports
check_ports() {
    echo -e "${YELLOW}Checking port availability:${NC}"
    for port in 3000 9090 9100 8080; do
        if lsof -i :$port >/dev/null; then
            echo -e "${RED}Port $port is in use by:${NC}"
            lsof -i :$port
        else
            echo -e "${GREEN}Port $port is available${NC}"
        fi
    done
}

# Main menu
show_menu() {
    echo -e "${BLUE}"
    echo "===================================="
    echo "  Monitoring Stack Installer v1.6.6 "
    echo "===================================="
    echo -e "${NC}"
    echo -e "${GREEN}1. Deploy Full Monitoring Stack"
    echo "2. Cleanup Only"
    echo "3. Check Port Status"
    echo "4. Exit"
    echo -e "${NC}"
}

# Main execution
init_install_state

case $1 in
    "--clean") cleanup; exit 0 ;;
    "--check") check_ports; exit 0 ;;
esac

while true; do
    show_menu
    read -p "Select option (1-4): " choice
    case $choice in
        1) 
            install_docker
            cleanup
            deploy_stack
            break
            ;;
        2) cleanup ;;
        3) check_ports ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
done

# Display access information
if [ -f .install_state ] && grep -q "installation_success=true" .install_state; then
    echo -e "\n${GREEN}Access Information:${NC}"
    echo -e "- Grafana Dashboard: http://$(hostname -I | awk '{print $1}'):3000 (admin/admin)"
    echo -e "- Prometheus:       http://$(hostname -I | awk '{print $1}'):9090"
    echo -e "- Node Exporter:    http://$(hostname -I | awk '{print $1}'):9100/metrics"
    echo -e "- cAdvisor:         http://$(hostname -I | awk '{print $1}'):8080"
    echo -e "\n${YELLOW}Installation tracking file created: .install_state${NC}"
fi