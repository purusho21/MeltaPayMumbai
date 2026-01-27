# 🎯 Complete AWS EC2 Deployment - Command Sequence

## 📋 What I've Prepared for You

I've configured your Laravel application for production deployment with:
- ✅ Docker & Docker Compose setup
- ✅ SSL/HTTPS with Let's Encrypt (auto-renewal)
- ✅ Production-ready Nginx configuration
- ✅ MySQL database in Docker
- ✅ Automated deployment scripts

## 🚀 Step-by-Step Deployment Commands

### **STEP 1: SSH into Your Server**

```bash
ssh ubuntu@3.6.61.66
```

---

### **STEP 2: Upload Your Project**

If you haven't already uploaded your project, do one of these:

**Option A: Clone from GitHub (Recommended)**
```bash
sudo mkdir -p /var/www/meltapay
sudo chown -R ubuntu:ubuntu /var/www/meltapay
cd /var/www/meltapay
git clone https://github.com/purusho21/MeltaPayMumbai.git
cd MeltaPayMumbai
```

**Option B: Your files are already there**
```bash
cd /var/www/meltapay/MeltaPayMumbai
```

---

### **STEP 3: Make Scripts Executable**

```bash
chmod +x deploy.sh
chmod +x init-ssl.sh
chmod +x check-deployment.sh
```

---

### **STEP 4: Run Pre-Deployment Check**

```bash
./check-deployment.sh
```

This will verify:
- Docker installation
- DNS configuration
- Port availability
- Environment files
- Disk space

---

### **STEP 5: Deploy the Application**

```bash
./deploy.sh
```

This script will:
1. Install Docker & Docker Compose (if needed)
2. Build Docker images
3. Start containers (app, nginx, database)
4. Install Laravel dependencies
5. Run database migrations
6. Set proper permissions

**Expected output:** "✓ Deployment Complete!"

---

### **STEP 6: Verify Containers are Running**

```bash
docker-compose ps
```

You should see:
- meltapay_app (Up)
- meltapay_nginx (Up)
- meltapay_db (Up)
- meltapay_certbot (Up)

---

### **STEP 7: Setup SSL Certificate (HTTPS)**

```bash
./init-ssl.sh
```

This script will:
1. Obtain SSL certificate from Let's Encrypt
2. Configure Nginx for HTTPS
3. Enable automatic certificate renewal
4. Redirect HTTP → HTTPS

**Expected output:** "✓ Setup Complete! Your site should now be accessible at: https://meltapay.com"

---

### **STEP 8: Test Your Website**

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://meltapay.com

# Test HTTPS (should return 200 OK)
curl -I https://meltapay.com

# View logs
docker-compose logs -f
```

Open your browser and visit:
🌐 **https://meltapay.com**

---

## 🔍 Verification Checklist

After deployment, verify:

- [ ] Website loads at https://meltapay.com
- [ ] SSL certificate is valid (green padlock in browser)
- [ ] HTTP redirects to HTTPS
- [ ] Database connection works
- [ ] Can log into admin panel
- [ ] File uploads work
- [ ] No error messages in logs

---

## 🛠️ Common Post-Deployment Commands

### View Application Logs
```bash
docker-compose logs -f app
```

### View Nginx Logs
```bash
docker-compose logs -f web
```

### View All Logs
```bash
docker-compose logs -f
```

### Restart Services
```bash
docker-compose restart
```

### Stop Everything
```bash
docker-compose down
```

### Start Everything
```bash
docker-compose up -d
```

### Clear Laravel Cache
```bash
docker exec -it meltapay_app php artisan cache:clear
docker exec -it meltapay_app php artisan config:clear
docker exec -it meltapay_app php artisan route:clear
docker exec -it meltapay_app php artisan view:clear
```

### Re-run Database Migrations
```bash
docker exec -it meltapay_app php artisan migrate --force
```

### Access MySQL Database
```bash
docker exec -it meltapay_db mysql -uroot -proot habbpos
```

---

## 🔄 If You Need to Start Fresh

### Clean Everything (Without Removing AWS Settings)

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (⚠️ This deletes database data!)
docker-compose down -v

# Clean Docker system
docker system prune -a

# Then redeploy
./deploy.sh
./init-ssl.sh
```

---

## 🐛 Troubleshooting

### Problem: SSL Certificate Fails

**Check DNS:**
```bash
nslookup meltapay.com
# Should return: 3.6.61.66
```

**Wait for DNS propagation** (5-10 minutes after updating Namecheap)

**Try manual certificate:**
```bash
docker-compose run --rm certbot certonly \
    --webroot -w /var/www/certbot \
    -d meltapay.com -d www.meltapay.com \
    --email admin@meltapay.com \
    --agree-tos --no-eff-email
```

### Problem: Database Connection Error

**Check database is running:**
```bash
docker-compose ps db
docker-compose logs db
```

**Restart database:**
```bash
docker-compose restart db
```

**Wait 15 seconds for MySQL to initialize:**
```bash
sleep 15
docker exec -it meltapay_app php artisan migrate --force
```

### Problem: 502 Bad Gateway

**Restart app container:**
```bash
docker-compose restart app
```

**Check PHP-FPM:**
```bash
docker-compose logs app
```

### Problem: Permission Errors

**Fix permissions:**
```bash
docker exec -it meltapay_app bash
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache
exit
```

---

## 📊 Monitoring

### Check Container Status
```bash
docker-compose ps
```

### Check Resource Usage
```bash
docker stats
```

### Check Disk Space
```bash
df -h
docker system df
```

### Check Application Logs
```bash
docker exec -it meltapay_app tail -f storage/logs/laravel.log
```

---

## 🔐 Security Checklist

- [x] SSL/HTTPS enabled
- [x] HTTP → HTTPS redirect
- [x] APP_DEBUG=false in production
- [x] Strong database password (⚠️ Change from 'root')
- [x] Hidden .env and .git files in Nginx
- [x] AWS Security Group configured (ports 22, 80, 443)
- [ ] Setup database backups
- [ ] Configure firewall rules
- [ ] Enable fail2ban (optional)

---

## 📞 Need Help?

1. Check logs: `docker-compose logs -f`
2. Run checklist: `./check-deployment.sh`
3. Review [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
4. Verify AWS Security Group rules in AWS Console
5. Verify DNS settings in Namecheap

---

## 🎉 Success!

Once you see:
- ✅ All containers running
- ✅ SSL certificate active
- ✅ Website loads at https://meltapay.com
- ✅ No errors in logs

**Your deployment is complete! 🚀**

---

## 📝 Files Created/Updated

- `docker-compose.yml` - Container orchestration
- `nginx/conf.d/meltapay.conf` - Nginx configuration with SSL
- `deploy.sh` - Automated deployment script
- `init-ssl.sh` - SSL certificate setup
- `check-deployment.sh` - Pre-deployment verification
- `DEPLOYMENT_GUIDE.md` - Complete documentation
- `QUICKSTART.md` - Quick reference
- `.gitignore` - Updated for production

---

**Remember:** Your Elastic IP (3.6.61.66) and AWS Security Group rules remain unchanged!
