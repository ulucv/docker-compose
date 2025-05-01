# Local Development Environment with Docker Compose

This project provides a complete local development environment using Docker Compose for a backend system, including:

- **PostgreSQL** – as a relational database

- **Redis** – as a fast in-memory cache

- **Prometheus** – for metrics collection

- **Grafana** – for real-time monitoring dashboards

- **Exporters for Redis and PostgreSQL** to enable Prometheus scraping

- **NGINX reverse proxy** to protect Prometheus with basic authentication

This setup is built for Ubuntu-based developer machines, with all configs, services, and monitoring bundled cleanly and professionally.

## Features

- Docker Compose orchestration for all services

- Shell script for one-click installation of Docker, PostgreSQL, Redis

- Monitoring stack (Prometheus + Grafana) with exporters

- Auto-provisioned Grafana dashboard and Prometheus datasource

- Basic authentication layer for Prometheus (via NGINX reverse proxy)

- Easily extendable for more services

## Directory Structure

```
.
├── docker-compose.yml
├── postgres/
│   └── init.sql
├── redis/
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   ├── dashboards/
│   │   └── main_dashboard.json
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml
│       └── dashboards/
│           └── dashboard.yml
├── nginx/
│   ├── prometheus.conf
│   └── .htpasswd
├── scripts/
│   ├── setup_environment.sh
│   ├── test_postgres.sh
│   └── test_redis.sh
└── README.md
```

## Getting Started

1. Clone the Repository

```
mkdir local-docker-compose
cd local-docker-compose
git clone https://github.com/ulucv/docker-compose.git
```

2. Run Installation Script (Ubuntu Only)

Installs Docker, PostgreSQL (server & client), Redis.

```
chmod +x scripts/install.sh
sudo bash scripts/install.sh
```

3. Start All Services

```
docker compose up -d
```

4. Test PostgreSQL & Redis via CLI

```
chmod +x scripts/test_postgres.sh
chmod +x scripts/test_redis.sh
bash scripts/test_postgres.sh
bash scripts/test_redis.sh
```

## Accessing Services

Service URL Default Credentials:

- Grafana http://localhost:3000 admin / StrongAdminPassword123
- Prometheus http://localhost:9090 admin / (via NGINX Basic Auth)
- PostgreSQL localhost:5432 devuser / devpass
- Redis localhost:6379 no password (default)

## Monitoring Dashboards

The Grafana dashboard is named "Dev Environment Overview" and is automatically provisioned when the container starts. It displays real-time metrics for PostgreSQL and Redis, collected via Prometheus.

Panels included:

- **PostgreSQL Uptime** : Shows whether the PostgreSQL service is running (1 = up, 0 = down).

- **Redis Uptime** : Shows whether the Redis service is running.

- **Redis Memory Usage** : Displays Redis memory usage as a gauge

- **PostgreSQL Connections** : Shows the number of active connections to PostgreSQL

## Security Layers

- Grafana is protected by a forced admin login

- Prometheus is secured behind NGINX with Basic Auth

  Passwords are defined using environment variables and .htpasswd

## Tear Down

```
docker compose down -v
```

This stops and removes containers, networks, volumes.

## Project Goals

This setup was designed to:

- Simulate real-world DevOps environments locally

- Provide an all-in-one stack for backend dev/testing

- Demonstrate clean architecture, monitoring, and security best practices

## Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)

- [Grafana Documentation](https://grafana.com/docs/)

- [Nginx Documentation](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
