#!/bin/bash
set -e

echo "🛠️ Starting full environment setup (Docker, PostgreSQL, Redis)..."

##################################
# Install Docker and Docker Compose
##################################
echo "🔧 Installing Docker & Docker Compose..."

# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc -y

# Install required packages
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

echo "✅ Docker installation complete."

##################################
# Install Redis
##################################
echo "🔧 Installing Redis..."

# Install Redis server
sudo apt update
sudo apt install -y redis-server

# Enable and start Redis
sudo systemctl enable redis-server.service
sudo systemctl start redis

echo "✅ Redis installation complete."

##################################
# Install PostgreSQL
##################################
echo "🔧 Installing PostgreSQL..."

# Install PostgreSQL server
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Install PostgreSQL client tools
sudo apt install -y postgresql-client-common postgresql-client

# Enable and start PostgreSQL server
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "✅ PostgreSQL installation complete."

# Install Nginx proxy for Prometheus

sudo apt install apache2-utils
htpasswd -c ./nginx/.htpasswd admin


##################################
# Final message
##################################
echo "🎉 Environment setup complete!"
echo "ℹ️  Please log out and log back in (or reboot) to apply Docker group permissions."
