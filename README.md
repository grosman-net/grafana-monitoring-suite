# Grafana Monitoring Suite for Ubuntu Server

![Grafana Logo](https://grafana.com/static/img/menu/grafana2.svg)

## Overview

Grafana Monitoring Suite is an automated solution for deploying a complete monitoring system on Ubuntu Server. The package includes:

- **Grafana** - Metrics visualization platform
- **Prometheus** - Metrics collection and storage system
- **Node Exporter** - System metrics collector
- **cAdvisor** - Container monitoring tool

All components run in isolated Docker containers.

## Key Features

✅ Fully automated installation  
✅ Isolated Docker containers  
✅ Comprehensive system and container monitoring  
✅ Pre-configured dashboards  
✅ Simple menu-driven management  
✅ Complete cleanup capability  

## System Requirements

- Ubuntu Server 20.04/22.04
- Minimum 2GB RAM
- Minimum 10GB disk space
- Internet access
- Docker (will be installed automatically if missing)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-repo/grafana-monitoring-suite.git
cd grafana-monitoring-suite
```

2. Make scripts executable:
```bash
chmod +x installer.sh remove.sh
```

3. Run the installer:
```bash
./installer.sh
```

## Usage

### Main Menu Options

1. **Full Deploy** - Installs all components automatically
2. **Cleanup** - Removes all containers and frees ports
3. **Port Check** - Displays current port usage
4. **Exit** - Quits the installer

### Accessing Services

After installation, access the services at:

- **Grafana**: `http://<your-server-ip>:3000` (admin/admin)
- **Prometheus**: `http://<your-server-ip>:9090`
- **Node Metrics**: `http://<your-server-ip>:9100/metrics`
- **cAdvisor**: `http://<your-server-ip>:8080`

### Removal

To completely remove all components:
```bash
./remove.sh
```
You will need to confirm removal by typing: "I understand I will lose all data"

## Included Components

### Grafana
- Pre-configured with Prometheus datasource
- Sample dashboards for system monitoring
- Persistent storage for configurations

### Prometheus
- Pre-configured to scrape:
  - Node Exporter (system metrics)
  - cAdvisor (container metrics)
  - Itself (Prometheus metrics)
- Data retention: 15 days

### Node Exporter
- Collects comprehensive system metrics:
  - CPU, memory, disk usage
  - Network statistics
  - System load averages

### cAdvisor
- Container resource usage monitoring
- Performance characteristics
- Historical resource usage

## Troubleshooting

### Port Conflicts
If you encounter port conflicts:
1. Run the cleanup option
2. Manually verify no processes are using the ports:
```bash
for port in 3000 9090 9100 8080; do
  sudo lsof -i :$port || echo "Port $port is free"
done
```

### Service Failures
If any service fails to start:
```bash
# Check container logs
docker-compose logs

# Verify running containers
docker ps -a
```

## Security Notes

- Default Grafana credentials: admin/admin (change immediately after installation)
- Exposed ports should be protected by firewall
- Consider setting up HTTPS reverse proxy for production use

## Support

For issues or feature requests, please open an issue on our [GitHub repository](https://github.com/your-repo/grafana-monitoring-suite).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.