#!/bin/bash

# Quick Deployment Script for MeltaPay
# Run this on your AWS EC2 server

set -e

echo "=========================================="
echo "MeltaPay Quick Deployment"
echo "=========================================="

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo "⚠️  Please run this script as ubuntu user"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
    echo "✓ Docker installed. Please log out and log back in, then run this script again."
    exit 0
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose installed"
fi

echo ""
echo "Current directory: $(pwd)"
echo ""

# Check if required files exist
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found. Are you in the project directory?"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Creating from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✓ Created .env from .env.example - Please configure it"
        exit 1
    else
        echo "❌ No .env.example found. Please create .env manually"
        exit 1
    fi
fi

# Stop existing containers
echo ""
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Build and start services
echo ""
echo "Building Docker images..."
docker-compose build --no-cache

echo ""
echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

# Check if containers are running
echo ""
echo "Checking container status..."
docker-compose ps

# Initialize Laravel
echo ""
echo "Initializing Laravel application..."
docker exec meltapay_app bash -c "
    composer install --no-dev --optimize-autoloader &&
    php artisan config:cache &&
    php artisan route:cache &&
    php artisan view:cache &&
    chown -R www-data:www-data /var/www/html/storage &&
    chown -R www-data:www-data /var/www/html/bootstrap/cache &&
    chmod -R 775 /var/www/html/storage &&
    chmod -R 775 /var/www/html/bootstrap/cache
"

echo ""
echo "Waiting for MySQL to be ready (20 seconds)..."
sleep 20

# Run migrations
echo ""
echo "Running database migrations..."
docker exec meltapay_app php artisan migrate --force

echo ""
echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify containers are running: docker-compose ps"
echo "2. Check logs: docker-compose logs -f"
echo "3. Setup SSL certificate: ./init-ssl.sh"
echo "4. Visit: http://$(curl -s ifconfig.me)"
echo ""
echo "For SSL setup, run: ./init-ssl.sh"
echo "=========================================="
