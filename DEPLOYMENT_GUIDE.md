# MeltaPay Deployment Guide for AWS EC2

## 📋 Pre-requisites Checklist
- ✅ AWS EC2 Ubuntu instance running
- ✅ Elastic IP: 3.6.61.66
- ✅ Domain: meltapay.com (DNS configured)
- ✅ Security Group: Ports 80, 443, 22 open
- ✅ SSH access to server

## 🚀 Complete Deployment Steps

### Step 1: Clean the Server (Without removing security rules)

```bash
# SSH into your server
ssh ubuntu@3.6.61.66

# Stop any running Docker containers
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove all Docker images (optional - saves space)
docker rmi $(docker images -q) 2>/dev/null || true

# Clean up volumes (CAUTION: This removes database data)
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# Clean application files (if needed to start fresh)
sudo rm -rf /var/www/meltapay/MeltaPayMumbai/*

# Note: This DOES NOT remove security group rules or Elastic IP
```

### Step 2: Install Required Software

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group (no need for sudo)
sudo usermod -aG docker ubuntu

# IMPORTANT: Log out and log back in for group changes to take effect
exit
# Then SSH back in
ssh ubuntu@3.6.61.66

# Verify installations
docker --version
docker-compose --version
```

### Step 3: Deploy Your Application

```bash
# Create project directory
sudo mkdir -p /var/www/meltapay
sudo chown -R ubuntu:ubuntu /var/www/meltapay
cd /var/www/meltapay

# Clone or upload your project
# Option A: Clone from Git (recommended)
git clone https://github.com/purusho21/MeltaPayMumbai.git
cd MeltaPayMumbai

# Option B: If using SCP/FTP, navigate to the uploaded folder
# cd /var/www/meltapay/MeltaPayMumbai
```

### Step 4: Configure Environment

```bash
# Create .env file
cat > .env << 'EOF'
APP_NAME="HABB POS"
APP_TITLE=""
APP_ENV=production
APP_KEY=base64:W8UqtE9LHZW+gRag78o4BCbN1M0w4HdaIFdLqHJ/9PA=
APP_DEBUG=false
APP_LOG_LEVEL=debug
APP_URL=https://meltapay.com
APP_LOCALE=en
APP_TIMEZONE="Asia/Kolkata"

ADMINISTRATOR_USERNAMES=
ALLOW_REGISTRATION=true
ENABLE_GST_REPORT_INDIA=
SHOW_REPAIR_STATUS_LOGIN_SCREEN=true

LOG_CHANNEL=daily

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=habbpos
DB_USERNAME=root
DB_PASSWORD=root

BROADCAST_DRIVER=pusher
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME=

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=

ENVATO_PURCHASE_CODE=
MAC_LICENCE_CODE=

BACKUP_DISK="local"
DROPBOX_ACCESS_TOKEN=

STRIPE_PUB_KEY=
STRIPE_SECRET_KEY=

PAYPAL_CLIENT_ID=
PAYPAL_APP_SECRET=
PAYPAL_MODE=sandbox

RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=

PESAPAL_CONSUMER_KEY=
PESAPAL_CONSUMER_SECRET=
PESAPAL_CURRENCY=KES
PESAPAL_LIVE=false
GOOGLE_MAP_API_KEY=

PAYSTACK_PUBLIC_KEY=
PAYSTACK_SECRET_KEY=
PAYSTACK_PAYMENT_URL=https://api.paystack.co
MERCHANT_EMAIL=""

FLUTTERWAVE_PUBLIC_KEY=
FLUTTERWAVE_SECRET_KEY=
FLUTTERWAVE_ENCRYPTION_KEY=

OPENAI_API_KEY=
OPENAI_ORGANIZATION=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=
AWS_BUCKET=

MY_FATOORAH_API_KEY=
MY_FATOORAH_IS_TEST=
MY_FATOORAH_COUNTRY_ISO=

ENABLE_RECAPTCHA="false"
GOOGLE_RECAPTCHA_KEY=
GOOGLE_RECAPTCHA_SECRET=
EOF

# Set proper permissions
chmod 644 .env
```

### Step 5: Verify DNS Configuration

```bash
# Check if your domain points to the correct IP
nslookup meltapay.com
# Should return: 3.6.61.66

nslookup www.meltapay.com
# Should return: 3.6.61.66

# If not correct, update your Namecheap DNS settings:
# A Record: @ -> 3.6.61.66
# A Record: www -> 3.6.61.66
# Wait 5-10 minutes for DNS propagation
```

### Step 6: Build and Start Docker Containers

```bash
# Build the application container
docker-compose build

# Start services without SSL first
docker-compose up -d

# Check if services are running
docker-compose ps

# Should see:
# - meltapay_app (running)
# - meltapay_nginx (running)
# - meltapay_db (running)
# - meltapay_certbot (running)
```

### Step 7: Initialize Laravel Application

```bash
# Enter the app container
docker exec -it meltapay_app bash

# Inside the container:
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Wait for MySQL to be ready (10-15 seconds)
sleep 15

# Run migrations
php artisan migrate --force

# Seed database (if needed)
php artisan db:seed --force

# Set permissions
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Exit container
exit
```

### Step 8: Setup SSL Certificate (HTTPS)

```bash
# Make the init script executable
chmod +x init-ssl.sh

# Run the SSL initialization script
./init-ssl.sh

# This script will:
# 1. Obtain SSL certificate from Let's Encrypt
# 2. Configure nginx for HTTPS
# 3. Enable auto-renewal

# If the script succeeds, you'll see:
# "✓ Setup Complete! Your site should now be accessible at: https://meltapay.com"
```

### Step 9: Verify Deployment

```bash
# Check container logs
docker-compose logs -f web
docker-compose logs -f app

# Test the website
curl -I http://meltapay.com
# Should redirect to HTTPS

curl -I https://meltapay.com
# Should return 200 OK

# Open in browser:
# https://meltapay.com
```

## 🔧 Useful Commands

### Container Management
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Start services
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build
```

### Laravel Commands
```bash
# Enter app container
docker exec -it meltapay_app bash

# Clear cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Run migrations
php artisan migrate

# Check application status
php artisan optimize
```

### Database Management
```bash
# Enter MySQL container
docker exec -it meltapay_db mysql -uroot -proot

# Backup database
docker exec meltapay_db mysqldump -uroot -proot habbpos > backup_$(date +%Y%m%d).sql

# Restore database
docker exec -i meltapay_db mysql -uroot -proot habbpos < backup.sql
```

### SSL Certificate Renewal
```bash
# Manual renewal (auto-renewal runs every 12 hours)
docker-compose run --rm certbot renew

# Reload nginx after renewal
docker-compose restart web
```

## 🔍 Troubleshooting

### Problem: SSL certificate fails
**Solution:**
```bash
# Verify DNS
nslookup meltapay.com

# Check if port 80 is accessible
curl -I http://meltapay.com/.well-known/acme-challenge/test

# Check certbot logs
docker-compose logs certbot

# Try manual certificate
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d meltapay.com -d www.meltapay.com --email admin@meltapay.com --agree-tos --no-eff-email
```

### Problem: Database connection failed
**Solution:**
```bash
# Check if MySQL is running
docker-compose ps db

# Check MySQL logs
docker-compose logs db

# Verify database credentials in .env
cat .env | grep DB_

# Restart database
docker-compose restart db
```

### Problem: Permission denied errors
**Solution:**
```bash
docker exec -it meltapay_app bash
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache
exit
```

### Problem: 502 Bad Gateway
**Solution:**
```bash
# Check if PHP-FPM is running
docker-compose ps app

# Restart app container
docker-compose restart app

# Check nginx logs
docker-compose logs web
```

## 📊 Monitoring

### Check Disk Space
```bash
df -h
docker system df
```

### Check Container Resources
```bash
docker stats
```

### View Application Logs
```bash
docker exec -it meltapay_app tail -f storage/logs/laravel.log
```

## 🔐 Security Recommendations

1. **Change default database password**
   ```bash
   # Update in .env
   DB_PASSWORD=your_strong_password_here
   
   # Update in docker-compose.yml
   MYSQL_ROOT_PASSWORD: your_strong_password_here
   ```

2. **Setup firewall (if not using AWS Security Groups)**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. **Enable APP_DEBUG=false in production** (already set)

4. **Regular backups**
   ```bash
   # Create backup script
   echo '#!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   docker exec meltapay_db mysqldump -uroot -proot habbpos > /var/www/meltapay/backups/db_$DATE.sql
   tar -czf /var/www/meltapay/backups/uploads_$DATE.tar.gz /var/www/meltapay/MeltaPayMumbai/public/uploads
   find /var/www/meltapay/backups -type f -mtime +7 -delete
   ' > /var/www/meltapay/backup.sh
   
   chmod +x /var/www/meltapay/backup.sh
   
   # Add to crontab (daily backup at 2 AM)
   (crontab -l 2>/dev/null; echo "0 2 * * * /var/www/meltapay/backup.sh") | crontab -
   ```

## 🎉 Success Checklist

- [ ] Server is clean and updated
- [ ] Docker and Docker Compose installed
- [ ] Application deployed to /var/www/meltapay/MeltaPayMumbai
- [ ] .env configured with production settings
- [ ] DNS pointing to 3.6.61.66
- [ ] Docker containers running
- [ ] Laravel application initialized
- [ ] SSL certificate obtained
- [ ] Website accessible at https://meltapay.com
- [ ] Database migrations completed
- [ ] File permissions set correctly

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs: `docker-compose logs`
3. Verify DNS settings in Namecheap
4. Verify AWS Security Group rules (ports 80, 443, 22)
5. Check if Elastic IP is attached to the EC2 instance
