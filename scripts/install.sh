#!/bin/bash

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Script variables
LOG_FILE="setup_$(date +%Y%m%d_%H%M%S).log"
NGINX_AUTH_FILE="./nginx/.htpasswd"
DEFAULT_USER=$(whoami)
PROMETHEUS_PASSWORD=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
INSTALL_DOCKER=true
INSTALL_REDIS_CLI=true
INSTALL_PSQL=true

for arg in "$@"; do
  case $arg in
    --skip-docker)
      INSTALL_DOCKER=false
      shift
      ;;
    --skip-redis-cli)
      INSTALL_REDIS_CLI=false
      shift
      ;;
    --skip-psql)
      INSTALL_PSQL=false
      shift
      ;;
    --help)
      echo "Usage: $0 [--skip-docker] [--skip-redis-cli] [--skip-psql]"
      exit 0
      ;;
  esac
done

# Functions
log() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "[${timestamp}] ${message}" | tee -a "${LOG_FILE}"
}

log_success() {
  log "${GREEN}✓ $1${NC}"
}

log_info() {
  log "${BLUE}ℹ $1${NC}"
}

log_warning() {
  log "${YELLOW}⚠ $1${NC}"
}

log_error() {
  log "${RED}✖ $1${NC}"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
  fi
}

check_dependencies() {
  log_info "Checking for required dependencies..."
  local deps=("curl" "apt" "gpg")
  local missing=()
  
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing+=("$dep")
    fi
  done
  
  if [ ${#missing[@]} -ne 0 ]; then
    log_error "Missing dependencies: ${missing[*]}"
    log_info "Installing missing dependencies..."
    apt update && apt install -y "${missing[@]}"
  else
    log_success "All dependencies available"
  fi
}

install_docker() {
  if ! $INSTALL_DOCKER; then
    log_info "Skipping Docker installation as requested"
    return 0
  fi

  log_info "Installing Docker & Docker Compose..."
  
  # Check if Docker is already installed
  if command -v docker &> /dev/null && command -v docker compose &> /dev/null; then
    log_warning "Docker already installed. Checking version..."
    docker --version
    docker compose version
    
    read -p "Do you want to reinstall Docker? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      log_info "Skipping Docker installation"
      return 0
    fi
  fi
  
  # Remove old versions if they exist
  log_info "Removing old Docker versions if they exist..."
  apt remove docker docker-engine docker.io containerd runc -y || true
  
  # Install required packages
  log_info "Installing dependencies..."
  apt update || { log_error "Failed to update apt"; exit 1; }
  apt install -y ca-certificates curl gnupg lsb-release || { log_error "Failed to install dependencies"; exit 1; }
  
  # Add Docker's official GPG key
  log_info "Adding Docker's GPG key..."
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  
  # Add Docker repo
  log_info "Adding Docker repository..."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Install Docker Engine and Compose plugin
  log_info "Installing Docker Engine and Compose plugin..."
  apt update || { log_error "Failed to update apt after adding Docker repo"; exit 1; }
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || { log_error "Failed to install Docker"; exit 1; }
  
  # Add user to docker group
  log_info "Adding ${DEFAULT_USER} to docker group..."
  usermod -aG docker ${DEFAULT_USER} || log_warning "Failed to add user to docker group"
  
  # Verify installation
  if command -v docker &> /dev/null; then
    log_info "Docker version: $(docker --version)"
    log_info "Docker Compose version: $(docker compose version)"
    log_success "Docker installation complete"
    
    # Start Docker service
    log_info "Ensuring Docker service is running and enabled..."
    systemctl enable docker
    systemctl start docker
  else
    log_error "Docker installation appears to have failed"
    return 1
  fi
}

install_redis_cli() {
  if ! $INSTALL_REDIS_CLI; then
    log_info "Skipping Redis CLI installation as requested"
    return 0
  fi

  log_info "Installing Redis CLI..."
  
  # Check if Redis CLI is already installed
  if command -v redis-cli &> /dev/null; then
    log_warning "Redis CLI is already installed"
    redis-cli --version
    
    read -p "Do you want to reinstall Redis CLI? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      log_info "Skipping Redis CLI installation"
      return 0
    fi
  fi
  
  # Install Redis CLI only
  log_info "Installing Redis CLI tools..."
  apt update || { log_error "Failed to update apt"; exit 1; }
  
  # Use redis-tools package which contains redis-cli without the server
  apt install -y redis-tools || { log_error "Failed to install Redis CLI"; exit 1; }
  
  # Verify installation
  if command -v redis-cli &> /dev/null; then
    log_info "Redis CLI version: $(redis-cli --version)"
    log_success "Redis CLI installation complete"
  else
    log_error "Redis CLI installation failed"
    return 1
  fi
}

install_psql_client() {
  if ! $INSTALL_PSQL; then
    log_info "Skipping PostgreSQL client installation as requested"
    return 0
  fi

  log_info "Installing PostgreSQL client..."
  
  # Check if PostgreSQL client is already installed
  if command -v psql &> /dev/null; then
    log_warning "PostgreSQL client is already installed"
    psql --version
    
    read -p "Do you want to reinstall PostgreSQL client? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      log_info "Skipping PostgreSQL client installation"
      return 0
    fi
  fi
  
  # Install PostgreSQL client tools only
  log_info "Installing PostgreSQL client tools..."
  apt update || { log_error "Failed to update apt"; exit 1; }
  apt install -y postgresql-client postgresql-client-common || { log_error "Failed to install PostgreSQL client"; exit 1; }
  
  # Verify installation
  if command -v psql &> /dev/null; then
    log_info "PostgreSQL client version: $(psql --version)"
    log_success "PostgreSQL client installation complete"
  else
    log_error "PostgreSQL client installation failed"
    return 1
  fi
}

setup_nginx_auth() {
  log_info "Setting up Nginx proxy authentication for Prometheus..."
  
  # Install Apache utilities for htpasswd
  log_info "Installing apache2-utils for htpasswd..."
  apt install -y apache2-utils || { log_error "Failed to install apache2-utils"; exit 1; }
  
  # Create nginx directory if it doesn't exist
  mkdir -p ./nginx
  
  # Generate password for Prometheus
  log_info "Enter password for Prometheus admin user: "
  read -rs PROMETHEUS_PASSWORD
  echo ""
  
  if [[ -z "$PROMETHEUS_PASSWORD" ]]; then
    log_warning "Empty password provided, generating a secure password instead..."
    PROMETHEUS_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&()*+,-./;<=>?@[]^_`{|}~' </dev/urandom | head -c 16)
    log_info "Generated password: $PROMETHEUS_PASSWORD"
  fi
  
  # Create htpasswd file
  log_info "Creating htpasswd file..."
  htpasswd -bc "${NGINX_AUTH_FILE}" admin "${PROMETHEUS_PASSWORD}" || { log_error "Failed to create htpasswd file"; exit 1; }
  chmod 644 "${NGINX_AUTH_FILE}"
  
  log_success "Nginx authentication setup complete"
}

# Main execution
main() {
  log_info "Starting environment setup (Docker, Redis CLI, PostgreSQL client)..."
  log_info "Logs will be saved to: ${LOG_FILE}"
  
  # Check if running as root
  check_root
  
  # Check dependencies
  check_dependencies
  
  # Install components
  install_docker
  install_redis_cli
  install_psql_client
  setup_nginx_auth
  
  log_success "Environment setup complete!"
  log_info "NOTE: You may need to log out and back in for Docker permissions to take effect"
  log_info "Setup completed at: $(date)"
}

# Run main function
main "$@"