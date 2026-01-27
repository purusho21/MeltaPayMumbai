# 🚀 Quick Start - Deploy to AWS EC2

## Server Information
- **Elastic IP:** 3.6.61.66
- **Domain:** meltapay.com
- **SSL:** Auto-configured with Let's Encrypt

## 1️⃣ SSH into Server

```bash
ssh ubuntu@3.6.61.66
```

## 2️⃣ Navigate to Project

```bash
cd /var/www/meltapay/MeltaPayMumbai
```

## 3️⃣ Deploy Application

```bash
chmod +x deploy.sh
./deploy.sh
```

## 4️⃣ Setup SSL (HTTPS)

```bash
chmod +x init-ssl.sh
./init-ssl.sh
```

## 5️⃣ Access Your Application

🌐 **https://meltapay.com**

---

## 📚 Detailed Documentation

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for complete deployment instructions, troubleshooting, and maintenance.

## 🔧 Common Commands

### View Logs
```bash
docker-compose logs -f
```

### Restart Services
```bash
docker-compose restart
```

### Stop Services
```bash
docker-compose down
```

### Start Services
```bash
docker-compose up -d
```

### Clear Laravel Cache
```bash
docker exec -it meltapay_app php artisan cache:clear
docker exec -it meltapay_app php artisan config:clear
```

## ❓ Having Issues?

1. Check container status: `docker-compose ps`
2. View logs: `docker-compose logs`
3. Read troubleshooting guide in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
