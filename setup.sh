#!/usr/bin/env bash
# ==============================================================================
# Script Otomatisasi Instalasi Docmost Stack (KDJK Kelompok 8)
# Layanan: Docmost + PostgreSQL 16 + Redis 7.2 via Docker Compose
# ==============================================================================
  
set -e

INSTALL_DIR="${HOME}/docmost"
APP_PORT="8305"
DB_USER="docmost"
DB_NAME="docmost"

echo "=========================================================="
echo "    Instalasi Otomatis Docmost Stack - Kelompok 8 KDJK    "
echo "=========================================================="

# 1. Pastikan Docker dan Docker Compose tersedia
if ! command -v docker &> /dev/null; then
    echo "[!] Docker tidak ditemukan. Menginstal Docker Engine..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
else
    echo "[✓] Docker Engine sudah terpasang."
fi

# 2. Buat direktori instalasi
echo "[+] Menyiapkan direktori kerja: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# 3. Generate Secret Key & Database Password
echo "[+] Menghasilkan encryption secret key dan password database..."
APP_SECRET=$(openssl rand -hex 32)
DB_PASS=$(openssl rand -hex 16)

# 4. Buat file docker-compose.yml
echo "[+] Menulis berkas docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  docmost:
    image: docmost/docmost:latest
    depends_on:
      - db
      - redis
    environment:
      APP_URL: "http://localhost:${APP_PORT}"
      APP_SECRET: "${APP_SECRET}"
      DATABASE_URL: "postgresql://${DB_USER}:${DB_PASS}@db:5432/${DB_NAME}?schema=public"
      REDIS_URL: "redis://redis:6379"
    ports:
      - "${APP_PORT}:3000"
    restart: unless-stopped
    volumes:
      - docmost_storage:/app/data/storage

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASS}
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7.2-alpine
    command: ["redis-server", "--appendonly", "yes", "--maxmemory-policy", "noeviction"]
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  docmost_storage:
  db_data:
  redis_data:
EOF

# 5. Jalankan stack container di background
echo "[+] Menjalankan stack Docker Compose..."
docker compose up -d

# 6. Verifikasi Healthcheck
echo "[+] Menunggu inisialisasi container (10 detik)..."
sleep 10
docker compose ps

echo "[+] Melakukan health check ke http://127.0.0.1:${APP_PORT}..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${APP_PORT} || echo "000")

echo ""
echo "=========================================================="
if [ "$HTTP_STATUS" == "200" ] || [ "$HTTP_STATUS" == "302" ]; then
    echo " [✓] SUKSES! Docmost berhasil aktif (HTTP Response: $HTTP_STATUS)"
else
    echo " [!] Docmost sedang dalam proses startup (HTTP Response: $HTTP_STATUS)."
    echo "     Cek status container dengan: docker compose ps"
fi
echo "=========================================================="
echo " Alamat Akses Lokal   : http://localhost:${APP_PORT}"
echo " Port Host Mapping    : ${APP_PORT} -> Container Port 3000"
echo " Lokasi Konfigurasi   : ${INSTALL_DIR}/docker-compose.yml"
echo " APP_SECRET           : ${APP_SECRET}"
echo " Database Password    : ${DB_PASS}"
echo "=========================================================="
