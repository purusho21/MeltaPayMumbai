#!/bin/bash

# Pre-deployment Checklist and Verification Script

echo "=========================================="
echo "MeltaPay Deployment Checklist"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check Docker
echo "1. Checking Docker installation..."
if command -v docker &> /dev/null; then
    check_pass "Docker is installed ($(docker --version))"
else
    check_fail "Docker is NOT installed"
    echo "   Run: sudo apt install -y docker.io"
fi
echo ""

# 2. Check Docker Compose
echo "2. Checking Docker Compose installation..."
if command -v docker-compose &> /dev/null; then
    check_pass "Docker Compose is installed ($(docker-compose --version))"
else
    check_fail "Docker Compose is NOT installed"
    echo "   Run: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "   Run: sudo chmod +x /usr/local/bin/docker-compose"
fi
echo ""

# 3. Check if user is in docker group
echo "3. Checking Docker permissions..."
if groups | grep -q docker; then
    check_pass "User is in docker group"
else
    check_warn "User is NOT in docker group"
    echo "   Run: sudo usermod -aG docker \$USER"
    echo "   Then log out and log back in"
fi
echo ""

# 4. Check project files
echo "4. Checking project files..."
if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml exists"
else
    check_fail "docker-compose.yml NOT found"
fi

if [ -f ".env" ]; then
    check_pass ".env file exists"
    
    # Check important env variables
    if grep -q "APP_URL=https://meltapay.com" .env; then
        check_pass "APP_URL is set to https://meltapay.com"
    else
        check_warn "APP_URL is not set correctly in .env"
    fi
    
    if grep -q "APP_ENV=production" .env; then
        check_pass "APP_ENV is set to production"
    else
        check_warn "APP_ENV is not set to production"
    fi
    
    if grep -q "APP_DEBUG=false" .env; then
        check_pass "APP_DEBUG is set to false"
    else
        check_warn "APP_DEBUG should be false in production"
    fi
    
    if grep -q "DB_HOST=db" .env; then
        check_pass "DB_HOST is set to 'db' (Docker service)"
    else
        check_warn "DB_HOST should be 'db' for Docker setup"
    fi
else
    check_fail ".env file NOT found"
    echo "   Create .env file with production settings"
fi
echo ""

# 5. Check DNS resolution
echo "5. Checking DNS configuration..."
DOMAIN_IP=$(dig +short meltapay.com | tail -n1)
WWW_IP=$(dig +short www.meltapay.com | tail -n1)

if [ "$DOMAIN_IP" = "3.6.61.66" ]; then
    check_pass "meltapay.com points to 3.6.61.66"
else
    check_fail "meltapay.com does NOT point to 3.6.61.66 (currently: $DOMAIN_IP)"
    echo "   Update A record in Namecheap: @ -> 3.6.61.66"
fi

if [ "$WWW_IP" = "3.6.61.66" ]; then
    check_pass "www.meltapay.com points to 3.6.61.66"
else
    check_fail "www.meltapay.com does NOT point to 3.6.61.66 (currently: $WWW_IP)"
    echo "   Update A record in Namecheap: www -> 3.6.61.66"
fi
echo ""

# 6. Check port availability
echo "6. Checking port availability..."
if ! sudo lsof -i :80 > /dev/null 2>&1; then
    check_pass "Port 80 is available"
else
    check_warn "Port 80 is already in use"
    sudo lsof -i :80
fi

if ! sudo lsof -i :443 > /dev/null 2>&1; then
    check_pass "Port 443 is available"
else
    check_warn "Port 443 is already in use"
    sudo lsof -i :443
fi
echo ""

# 7. Check disk space
echo "7. Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    check_pass "Disk space is adequate ($DISK_USAGE% used)"
else
    check_warn "Disk space is running low ($DISK_USAGE% used)"
    echo "   Consider cleaning up: docker system prune -a"
fi
echo ""

# 8. Check if containers are running
echo "8. Checking Docker containers..."
if docker-compose ps | grep -q "Up"; then
    check_warn "Docker containers are already running"
    echo "   Current containers:"
    docker-compose ps
else
    check_pass "No containers running (ready for fresh deployment)"
fi
echo ""

# 9. Check SSL certificate
echo "9. Checking SSL certificate..."
if [ -f "certbot/conf/live/meltapay.com/fullchain.pem" ]; then
    check_pass "SSL certificate exists"
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in certbot/conf/live/meltapay.com/fullchain.pem | cut -d= -f2)
    echo "   Certificate expires: $CERT_EXPIRY"
else
    check_warn "SSL certificate NOT found (will be generated during deployment)"
fi
echo ""

# 10. Check network connectivity
echo "10. Checking network connectivity..."
if ping -c 1 google.com > /dev/null 2>&1; then
    check_pass "Internet connectivity is working"
else
    check_fail "No internet connectivity"
fi
echo ""

# Summary
echo "=========================================="
echo "Checklist Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Fix any issues marked with ✗ or ⚠"
echo "2. Run: ./deploy.sh (to deploy application)"
echo "3. Run: ./init-ssl.sh (to setup SSL certificate)"
echo "4. Visit: https://meltapay.com"
echo ""
echo "=========================================="
