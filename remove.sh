#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root.${NC}" >&2
    exit 1
fi

# Confirmation
echo -e "${RED}This will COMPLETELY remove:${NC}"
echo "- All monitoring containers (Grafana, Prometheus, Node Exporter, cAdvisor)"
echo "- All Docker volumes and networks created by the stack"
echo "- All configuration files in ./config/"
echo 
echo -e "${YELLOW}It will NOT remove:${NC}"
echo "- docker-compose.yml file"
echo "- Docker engine or Docker Compose"
echo "- Any other system components"
read -p "Type 'I AGREE TO REMOVE MONITORING STACK' to confirm: " confirm
[ "$confirm" == "I AGREE TO REMOVE MONITORING STACK" ] || exit 1

# Load installation state
if [ ! -f .install_state ]; then
    echo -e "${YELLOW}No installation state found. Performing basic cleanup...${NC}"
fi

# Removal process
echo -e "\n${YELLOW}[1/3] Removing containers and networks...${NC}"
docker-compose down --remove-orphans 2>/dev/null || docker compose down --remove-orphans 2>/dev/null
docker rm -f grafana prometheus node-exporter cadvisor 2>/dev/null
docker network rm grafana-monitoring-suite_monitoring 2>/dev/null

echo -e "${YELLOW}[2/3] Removing volumes...${NC}"
docker volume rm grafana-monitoring-suite_grafana_data grafana-monitoring-suite_prometheus_data 2>/dev/null

echo -e "${YELLOW}[3/3] Cleaning configuration files...${NC}"
rm -rf ./config/ 2>/dev/null

# Final check
if [ -z "$(docker ps -a | grep -E 'grafana|prometheus|node-exporter|cadvisor')" ]; then
    echo -e "\n${GREEN}Complete removal finished successfully!${NC}"
    echo -e "${YELLOW}The docker-compose.yml file has been preserved.${NC}"
else
    echo -e "\n${YELLOW}Removal completed with possible warnings.${NC}"
    echo -e "${RED}Some components might still remain. Check manually with:${NC}"
    echo "docker ps -a"
    echo "docker volume ls"
fi