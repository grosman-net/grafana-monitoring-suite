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

# List of services to manage
SERVICES=("grafana-server" "prometheus" "prometheus-node-exporter" "filebrowser")
PORTS=(3000 9090 9100 8080)

# Disable and stop services
disable_services() {
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}\.service"; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                echo -e "${YELLOW}Stopping and disabling ${service}${NC}"
                systemctl stop "$service" 2>/dev/null
                systemctl disable "$service" 2>/dev/null
                systemctl reset-failed "$service" 2>/dev/null
            fi
        fi
    done
    
    # Kill any remaining processes
    pkill -9 -f "$(echo "${SERVICES[@]}" | sed 's/ /\\|/g')" 2>/dev/null
}

# Kill process by port
kill_port_process() {
    local port=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if lsof -i :$port >/dev/null; then
            local pid=$(lsof -ti :$port | head -n1)
            local cmd=$(ps -p $pid -o cmd= 2>/dev/null)
            
            echo -e "${YELLOW}Attempt $attempt: Killing process on port $port (PID: $pid, CMD: $cmd)${NC}"
            
            # Try graceful kill first
            kill $pid 2>/dev/null
            sleep 1
            
            # Force kill if still running
            if ps -p $pid >/dev/null; then
                kill -9 $pid 2>/dev/null
            fi
            
            sleep 1
        else
            echo -e "${GREEN}Port $port is now free${NC}"
            return 0
        fi
        
        ((attempt++))
    done
    
    echo -e "${RED}Failed to free port $port after $max_attempts attempts${NC}"
    return 1
}

# Deep cleanup
deep_clean() {
    echo -e "${YELLOW}Performing deep cleanup...${NC}"
    
    # Stop and disable services (only active ones)
    disable_services
    
    # Docker cleanup
    docker-compose down --remove-orphans --timeout 1 2>/dev/null
    docker rm -f $(docker ps -aq --filter name=grafana-monitoring-suite) 2>/dev/null
    docker network rm grafana-monitoring-suite_monitoring 2>/dev/null
    docker volume prune -f 2>/dev/null
    
    # Kill processes on our ports
    local ports_clean=1
    for port in "${PORTS[@]}"; do
        if lsof -i :$port >/dev/null; then
            if ! kill_port_process $port; then
                ports_clean=0
            fi
        fi
    done
    
    if [ $ports_clean -eq 1 ]; then
        echo -e "${GREEN}All ports are now free${NC}"
        return 0
    else
        echo -e "${RED}Warning: Some ports could not be freed${NC}"
        return 1
    fi
}

# Deployment function
deploy_stack() {
    echo -e "${BLUE}Starting deployment...${NC}"
    
    deep_clean
    
    # Docker installation
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}Installing Docker...${NC}"
        apt-get update
        apt-get install -y docker.io docker-compose
        systemctl enable --now docker
    fi

    # Start deployment
    echo -e "${GREEN}Launching containers...${NC}"
    if ! docker-compose up -d; then
        echo -e "${RED}Failed to start containers!${NC}"
        docker-compose logs
        exit 1
    fi

    # Verify
    echo -e "\n${GREEN}Verification:${NC}"
    declare -A services=(
        ["grafana"]="3000"
        ["prometheus"]="9090"
        ["node-exporter"]="9100"
        ["cadvisor"]="8080"
    )
    
    for service in "${!services[@]}"; do
        if docker ps | grep -q "$service"; then
            echo -e "${GREEN}[✓] $service running on port ${services[$service]}${NC}"
        else
            echo -e "${RED}[×] $service failed to start${NC}"
            docker logs $service 2>&1 | tail -n 5
        fi
    done
}

# Port check
check_ports() {
    echo -e "${YELLOW}Current port status:${NC}"
    for port in "${PORTS[@]}"; do
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
    clear
    echo -e "${BLUE}"
    echo "===================================="
    echo "  Monitoring Stack Installer v1.6   "
    echo "===================================="
    echo -e "${NC}"
    echo -e "${GREEN}1. Deploy Monitoring Stack"
    echo "2. Full Cleanup"
    echo "3. Check Port Status"
    echo "4. Exit"
    echo -e "${NC}"
}

# Main
case $1 in
    "--clean") deep_clean; exit 0 ;;
    "--check") check_ports; exit 0 ;;
esac

while true; do
    show_menu
    read -p "Select option (1-4): " choice
    case $choice in
        1) deploy_stack; break ;;
        2) deep_clean ;;
        3) check_ports ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    read -p "Press Enter to continue..."
done

echo -e "\n${GREEN}Deployment complete! Access:${NC}"
echo -e "- Grafana:     http://$(hostname -I | awk '{print $1}'):3000 (admin/admin)"
echo -e "- Prometheus:  http://$(hostname -I | awk '{print $1}'):9090"
echo -e "- Node Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo -e "- cAdvisor:    http://$(hostname -I | awk '{print $1}'):8080"
