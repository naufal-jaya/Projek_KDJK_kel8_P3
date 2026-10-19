<div align="center">
  <h1>Docmost</h1>
  <p>Panduan instalasi dan menjalankan Docmost menggunakan Docker Compose</p>
</div>

> **Catatan gambar:** tambahkan logo Docmost di bagian atas jika diperlukan. Screenshot halaman Docmost dapat ditambahkan pada bagian verifikasi atau cara pemakaian.

[ Sekilas Tentang ](#sekilas-tentang) | [ Persiapan ](#persiapan) | [ Konfigurasi ](#konfigurasi) | [ Menjalankan Aplikasi ](#menjalankan-aplikasi) | [ Verifikasi ](#verifikasi) | [ Referensi ](#referensi)

# Sekilas Tentang

**Docmost** adalah aplikasi wiki dan dokumentasi kolaboratif _open source_. Docmost menyediakan ruang untuk menyusun dan berbagi dokumentasi bersama tim. Stack pada panduan ini menjalankan Docmost bersama PostgreSQL sebagai database dan Redis sebagai layanan pendukung, menggunakan Docker Compose.

# Persiapan

Pastikan server atau komputer sudah memiliki Docker Engine dan Docker Compose, serta akses terminal.

1. Buat direktori kerja khusus untuk Docmost, lalu masuk ke direktori tersebut:

   ```bash
   mkdir -p /home/baha/docmost
   cd /home/baha/docmost
   ```

2. Buat secret key acak untuk konfigurasi keamanan Docmost:

   ```bash
   openssl rand -hex 32
   ```

   Salin hasilnya untuk digunakan sebagai nilai `APP_SECRET` pada langkah konfigurasi.

# Konfigurasi

Buat file `docker-compose.yml` di dalam direktori kerja, lalu isi dengan konfigurasi berikut. Ganti `<hex_secret_tadi>` dengan secret yang dibuat sebelumnya dan `<password>` dengan password database yang kuat. Gunakan password yang sama pada `DATABASE_URL` dan `POSTGRES_PASSWORD`.

```yaml
services:
  docmost:
    image: docmost/docmost:latest
    depends_on:
      - db
      - redis
    environment:
      APP_URL: "http://localhost:8305"
      APP_SECRET: "<hex_secret_tadi>"
      DATABASE_URL: "postgresql://docmost:<password>@db:5432/docmost?schema=public"
      REDIS_URL: "redis://redis:6379"
    ports:
      - "8305:3000"
    restart: unless-stopped
    volumes:
      - docmost_storage:/app/data/storage

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: docmost
      POSTGRES_USER: docmost
      POSTGRES_PASSWORD: <password>
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7.2-alpine
    command:
      [
        "redis-server",
        "--appendonly",
        "yes",
        "--maxmemory-policy",
        "noeviction",
      ]
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  docmost_storage:
  db_data:
  redis_data:
```

Port host `8305` diteruskan ke port `3000` di dalam container Docmost. Data aplikasi, PostgreSQL, dan Redis disimpan pada Docker volumes agar tetap tersedia setelah container dimatikan atau dibuat ulang.

# Menjalankan Aplikasi

Dari direktori yang berisi `docker-compose.yml`, jalankan stack di background:

```bash
docker compose up -d
```

Docker Compose akan mengambil image yang diperlukan, membuat network dan volumes, lalu menjalankan Docmost, PostgreSQL, dan Redis.

# Verifikasi

Periksa status container:

```bash
docker compose ps
```

Pastikan layanan Docmost, database, dan Redis berstatus berjalan. Kemudian cek respons aplikasi:

```bash
curl -I http://127.0.0.1:8305
```

Jika server mengembalikan respons HTTP yang berhasil, Docmost dapat diakses melalui alamat berikut:

- `http://localhost:8305` dari komputer yang menjalankan Docker.
- `http://<alamat-ip-server>:8305` dari komputer lain yang dapat menjangkau server.

> **Catatan screenshot:** tambahkan screenshot halaman Docmost setelah aplikasi berhasil dibuka, jika diperlukan.

# Referensi

1. [Dokumentasi Docmost](https://docmost.com/docs) — Docmost
2. [Docker Compose](https://docs.docker.com/compose/) — Docker
