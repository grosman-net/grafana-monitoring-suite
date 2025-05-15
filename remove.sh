#!/bin/bash

# Warning message
WARNING="This will remove: Docker, Grafana, Prometheus, Node Exporter, and all configs."
CONFIRMATION_PHRASE="я понимаю что потеряю все данные"

echo -e "\033[1;31mWARNING: $WARNING\033[0m"
read -p "Type '$CONFIRMATION_PHRASE' to confirm: " user_input

if [ "$user_input" != "$CONFIRMATION_PHRASE" ]; then
    echo "Aborted."
    exit 1
fi

# Remove containers
docker-compose down
# Remove Docker
apt-get purge -y docker.io docker-compose
# Remove configs
rm -rf ./config/grafana-storage
# Other cleanup...
