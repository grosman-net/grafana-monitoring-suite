# Grafana Monitoring Stack for Ubuntu Server

![Monitoring Stack](https://i.imgur.com/JZkQlz9.png)

## Overview

Complete monitoring solution with:
- **Grafana** - Metrics visualization (port 3000)
- **Prometheus** - Metrics collection (port 9090)
- **Node Exporter** - System metrics (port 9100)
- **cAdvisor** - Container metrics (port 8080)

All components run in Docker containers with persistent storage.

## Prerequisites

- Ubuntu Server 20.04/22.04
- Docker and Docker Compose (will be installed automatically)
- 2+ GB RAM
- 10+ GB disk space

## Quick Start

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

## Access Services

After installation, access the services at:

| Service       | URL                                  | Credentials       |
|---------------|--------------------------------------|-------------------|
| Grafana       | http://<server-ip>:3000             | admin/admin       |
| Prometheus    | http://<server-ip>:9090             | -                 |
| Node Exporter | http://<server-ip>:9100/metrics     | -                 |
| cAdvisor      | http://<server-ip>:8080             | -                 |

## Management

### Start/Stop Services
```bash
docker-compose start   # Start all services
docker-compose stop    # Stop all services
```

### Check Status
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs -f [service]  # service = grafana/prometheus/node-exporter/cadvisor
```

## Removal

To completely remove the monitoring stack:

```bash
./remove.sh
```

This will:
- Stop and remove all containers
- Remove Docker volumes
- Cleanup configuration files
- Preserve docker-compose.yml for future use

## Configuration Files

| File                   | Description                          |
|------------------------|--------------------------------------|
| `docker-compose.yml`   | Container configuration              |
| `config/prometheus.yml`| Prometheus scrape targets            |

## Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   ./installer.sh --check
   ```

2. **Failed container starts**:
   ```bash
   docker logs <container-name>
   ```

3. **Reset Grafana admin password**:
   ```bash
   docker exec -it grafana grafana-cli admin reset-admin-password newpassword
   ```

### Reinstalling

1. First remove the stack:
   ```bash
   ./remove.sh
   ```

2. Clean Docker system:
   ```bash
   docker system prune -f
   ```

3. Reinstall:
   ```bash
   ./installer.sh
   ```

## Backup and Restore

### Backup Data
```bash
# Backup Grafana
docker run --rm --volumes-from grafana -v $(pwd):/backup ubuntu tar cvf /backup/grafana-backup.tar /var/lib/grafana

# Backup Prometheus
docker run --rm --volumes-from prometheus -v $(pwd):/backup ubuntu tar cvf /backup/prometheus-backup.tar /prometheus
```

### Restore Data
```bash
# Restore Grafana
docker run --rm --volumes-from grafana -v $(pwd):/backup ubuntu bash -c "cd / && tar xvf /backup/grafana-backup.tar"

# Restore Prometheus
docker run --rm --volumes-from prometheus -v $(pwd):/backup ubuntu bash -c "cd / && tar xvf /backup/prometheus-backup.tar"
```

## License

MIT License. See [LICENSE](LICENSE) for details.
