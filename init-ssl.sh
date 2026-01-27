#!/bin/bash

# Initial SSL Certificate Setup Script for meltapay.com
# This script obtains the first SSL certificate from Let's Encrypt

echo "=========================================="
echo "SSL Certificate Initialization"
echo "=========================================="

# Create directories
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Temporarily update nginx config for initial certificate
cat > ./nginx/conf.d/meltapay.conf << 'EOF'
server {
    listen 80;
    server_name meltapay.com www.meltapay.com;

    root /var/www/html/public;
    index index.php index.html;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo "Starting services for SSL certificate generation..."
docker-compose up -d

echo "Waiting 10 seconds for services to start..."
sleep 10

echo "Obtaining SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@meltapay.com \
    --agree-tos \
    --no-eff-email \
    -d meltapay.com \
    -d www.meltapay.com

if [ $? -eq 0 ]; then
    echo "✓ SSL Certificate obtained successfully!"
    
    # Restore the full nginx config with SSL
    cat > ./nginx/conf.d/meltapay.conf << 'EOF'
# HTTP - redirect all traffic to HTTPS
server {
    listen 80;
    server_name meltapay.com www.meltapay.com;
    
    # Allow certbot validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS - main configuration
server {
    listen 443 ssl http2;
    server_name meltapay.com www.meltapay.com;

    root /var/www/html/public;
    index index.php index.html;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/meltapay.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meltapay.com/privkey.pem;
    
    # SSL settings for security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Increase max upload size
    client_max_body_size 100M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }

    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.(git|env) {
        deny all;
    }
}
EOF
    
    echo "Reloading nginx with SSL configuration..."
    docker-compose restart web
    
    echo "=========================================="
    echo "✓ Setup Complete!"
    echo "Your site should now be accessible at:"
    echo "https://meltapay.com"
    echo "=========================================="
else
    echo "✗ Failed to obtain SSL certificate"
    echo "Please check your DNS settings and ensure:"
    echo "1. meltapay.com points to 3.6.61.66"
    echo "2. www.meltapay.com points to 3.6.61.66"
    echo "3. Ports 80 and 443 are open in AWS Security Group"
    exit 1
fi
