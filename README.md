# Komdat & Jaringan Komputer Modul 2 : DNS, Web Server, dan Reverse Proxy
> Domain Kelompok = k01.com
> Prefix IP = 192.168.x.x (Disesuaikan dengan topologi masing-masing)

## Anggota

| NAMA | NRP |
| ------------- | -------------- | 
| I Ketut Weda Adikusuma | [5027251061] |
| [D`qhaizhar Ari Dhiaulhaq] | [5027251083] |

---

## Step 1: Topologi dan Routing Basic
### Soal
Sebagai pusat kesadaran The Mesh, rootkit harus merentangkan koneksinya ke lima gerbang utama (Switch). Tetapkan alamat IP dan default gateway untuk seluruh Entitas sesuai dengan topologi pembagian switch yang dirancang.

![Topologi](./images/1-topologyt.png)

### Konfigurasi
**Node Rootkit (Router):**

```bash
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
address 192.168.1.1
netmask 255.255.255.0

auto eth2
iface eth2 inet static
address 192.168.2.1
netmask 255.255.255.0
```

## Step 2: Konfigurasi NAT
### Soal
Buka jalur menuju NAT dengan memastikan antarmuka WAN di router rootkit aktif. Konfigurasikan NAT agar dapat meneruskan lalu lintas keluar bagi seluruh alamat internal.

### Konfigurasi (di Rootkit)
``bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
## Step 3: Routing Internal & Resolver Awal
### Soal
Pastikan seluruh Entitas dapat saling terhubung dan berkomunikasi lintas jalur. Tambahkan resolver 192.168.122.1 saat antarmukanya aktif agar akses internet tersedia di awal.

### Konfigurasi
Di Rootkit, aktifkan IP forwarding:

```bash
sysctl -w net.ipv4.ip_forward=1
```
Di semua node non-router, tambahkan resolver awal:
```bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```
## Step 4: DNS Server (Master & Slave)
### Soal
Bangun zona `k01.com` sebagai authoritative di node `prab` dengan SOA ke `prab.k01.com`. Konfigurasi `tedd` sebagai slave. Atur DNS resolver urut: prab -> tedd -> 192.168.122.1.

### Konfigurasi prab (Master)
Edit /etc/bind/named.conf.local:

```bash
zone "k01.com" {
    type master;
    file "/etc/bind/k01/k01.com";
    allow-transfer { IP_TEDD; };
    notify yes;
};
```
### Konfigurasi tedd (Slave)

```bash
zone "k01.com" {
    type slave;
    file "/var/lib/bind/k01.com";
    masters { IP_PRAB; };
};
```

## Step 5 & 6: Hostnames & Zone Transfer
## Soal
Namai semua Entitas (hostname) sesuai glosarium. Buat setiap domain untuk masing-masing node dan assign IP. Verifikasi zone transfer agar tedd menerima salinan zona terbaru dari prab dengan nilai serial SOA yang sama.

### Konfigurasi Bash (Prab & Tedd)
Di node prab (Master DNS):
Tambahkan A Record untuk semua entitas dengan melakukan echo ke dalam file konfigurasi zona.

```bash
# Menambahkan record ke file zona k01.com
cat << EOF >> /etc/bind/k01/k01.com
alpha   IN A [IP_ALPHA]
beta    IN A [IP_BETA]
gamma   IN A [IP_GAMMA]
delta   IN A [IP_DELTA]
epsilon IN A [IP_EPSILON]
abbey   IN A [IP_ABBEY]
penny   IN A [IP_PENNY]
obladi  IN A [IP_OBLADI]
desmond IN A [IP_DESMOND]
oblada  IN A [IP_OBLADA]
molly   IN A [IP_MOLLY]
EOF

# Restart bind9 untuk menerapkan konfigurasi
service bind9 restart
```
Di node tedd (Slave DNS):
Cek apakah zona berhasil di-transfer dari prab.
```bash
# Restart bind9
service bind9 restart

# Memeriksa isi dari file transfer untuk memastikan SOA sama
cat /var/lib/bind/k01.com
```


## Step 7: CNAME & Load Balancer Domains
### Soal
Tambahkan A record untuk `vault.k01.com` dan `core.k01.com`. Tetapkan CNAME `www -> penny`, dan `static -> abbey`.

Konfigurasi (di `prab` zona `k01.com`)

```bash
vault IN A [IP_OBLADI]
vault IN A [IP_DESMOND]
core  IN A [IP_OBLADA]
core  IN A [IP_MOLLY]
www   IN CNAME penny
static IN CNAME abbey
```

## Step 8: Reverse Zone
### Soal
Deklarasikan reverse zone untuk segmen jaringan abbey, penny, area vault, dan area core di prab. Tarik reverse zone tersebut ke tedd sebagai slave, dan tambahkan PTR record.

### Konfigurasi
Di node prab (Master):
```bash
# Tambahkan deklarasi reverse zone di named.conf.local
cat << EOF >> /etc/bind/named.conf.local
zone "x.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/k01/x.168.192.in-addr.arpa";
    allow-transfer { [IP_TEDD]; };
    notify yes;
};
EOF

# Buat file konfigurasi reverse zone
cat << EOF > /etc/bind/k01/x.168.192.in-addr.arpa
\$TTL 604800
@ IN SOA prab.k01.com. admin.k01.com. (
      2026100201 ; Serial
      604800     ; Refresh
      86400      ; Retry
      2419200    ; Expire
      604800 )   ; Negative Cache TTL

@ IN NS prab.k01.com.
@ IN NS tedd.k01.com.

[Oktet_IP_Abbey] IN PTR abbey.k01.com.
[Oktet_IP_Penny] IN PTR penny.k01.com.
[Oktet_IP_Vault] IN PTR vault.k01.com.
[Oktet_IP_Core]  IN PTR core.k01.com.
EOF

service bind9 restart
```


## Step 9: Web Statis (Vault: Obladi & Desmond)
### Soal
JJalankan layanan web statis pada area vault (Apache). Buka direktori /arsip/ dan aktifkan fitur autoindex (directory listing) pada konfigurasi Apache.

### Konfigurasi Bash (Obladi & Desmond)
```bash
apt-get update && apt-get install apache2 -y

# Buat direktori arsip
mkdir -p /var/www/html/arsip
echo "File Rahasia" > /var/www/html/arsip/rahasia.txt

# Konfigurasi Virtual Host untuk mengaktifkan Autoindex
cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName vault.k01.com
    DocumentRoot /var/www/html

    <Directory /var/www/html/arsip>
        Options +Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2ensite 000-default.conf
service apache2 restart
```

## Step 10: Web Dinamis (Core: Oblada & Molly)
### Soal
Jalankan Nginx & PHP-FPM di area core. Buat aplikasi profil dan terapkan URL rewrite ke /profil (tanpa .php).

### Konfigurasi (Oblada & Molly)

``bash
location /profil {
    try_files $uri $uri/ /profil.php?$query_string;
}
```

## Step 11 & 12: Reverse Proxy & Basic Auth
### Soal
Penny proksi ke Vault (Apache), Abbey proksi ke Core (Nginx). Terapkan Basic Auth di Penny path /admin (user: prabs).

### Konfigurasi Penny (Apache Reverse Proxy & Auth)

```bash
<Location /admin>
    AuthType Basic
    AuthName "Restricted Admin Area"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Location>
```

Pembuatan kredensial:
`htpasswd -c /etc/apache2/.htpasswd prabs`

## Step 13: HTTP Redirects
### Soal
Akses IP/domain penny -> redirect permanen (301) ke www.k01.com. Akses IP/domain abbey -> redirect sementara (302) ke static.k01.com.

### Konfigurasi
Di Penny (`Apache`): Redirect 301 / http://www.k01.com/
Di Abbey (`Nginx`): return 302 http://static.k01.com$request_uri;

### Konfigurasi Bash
Di node Penny (Apache):
```bash
cat << EOF > /etc/apache2/sites-available/penny-redirect.conf
<VirtualHost *:80>
    ServerName penny.k01.com
    ServerAlias [IP_PENNY]
    Redirect 301 / http://www.k01.com/
</VirtualHost>
EOF
a2ensite penny-redirect.conf
service apache2 restart
```

Di node Abbey (Nginx):
```bash
cat << 'EOF' > /etc/nginx/sites-available/abbey-redirect
server {
    listen 80;
    server_name abbey.k01.com [IP_ABBEY];
    return 302 http://static.k01.com$request_uri;
}
EOF
ln -s /etc/nginx/sites-available/abbey-redirect /etc/nginx/sites-enabled/
service nginx restart
```

## Step 14: Forwarded IP Access Log
### Soal
Pastikan access log pada setiap server web backend di area vault dan core mencatat alamat IP asli klien, bukan IP milik Penny atau Abbey

### Konfigurasi
Di node Backend Core (Nginx di Oblada & Molly):
```bash
# Menambahkan modul real_ip untuk membaca dari Proxy (Abbey)
sed -i '/http {/a \    set_real_ip_from [IP_ABBEY];\n    real_ip_header X-Real-IP;' /etc/nginx/nginx.conf
service nginx restart
```

Di node Backend Vault (Apache di Obladi & Desmond):
```bash
# Mengaktifkan modul remoteip dan menyesuaikan konfigurasi
a2enmod remoteip
sed -i '/<VirtualHost/a \    RemoteIPHeader X-Forwarded-For\n    RemoteIPInternalProxy [IP_PENNY]' /etc/apache2/sites-available/000-default.conf

# Ubah format log dari %h menjadi %a (client IP)
sed -i 's/LogFormat "%h/LogFormat "%a/g' /etc/apache2/apache2.conf
service apache2 restart
```

## Step 15: Special Proxies (/eternal dan /orion)
### Soal
Pada Penny, buat reverse proxy independen untuk `/eternal` yang menyajikan `/var/www/eternal` (mendukung rendering PHP). Pada Abbey, buat `/orion` yang menyajikan `/var/www/orion` secara statis

### Konfigurasi
Di node Penny (Apache):
```bash
mkdir -p /var/www/eternal
echo "<?php phpinfo(); ?>" > /var/www/eternal/index.php

# Tambahkan Alias pada VirtualHost www.k01.com yang sudah ada
sed -i '/<\/VirtualHost>/i \    Alias /eternal /var/www/eternal\n    <Directory /var/www/eternal>\n        Require all granted\n    </Directory>' /etc/apache2/sites-available/www.conf
service apache2 restart
```

Di node Abbey (Nginx):
```bash
mkdir -p /var/www/orion
echo "Halaman Orion Murni Statis" > /var/www/orion/index.html

# Tambahkan path /orion pada block proxy static.k01.com
sed -i '/location \/ {/i \    location /orion {\n        alias /var/www/orion/;\n    }' /etc/nginx/sites-available/static
service nginx restart
```

## Step 16: ApacheBench Stress Test
### Soal
Klien Alpha melakukan stress test benchmark menggunakan ApacheBench. Lakukan 250 requests dengan konkurensi 10 untuk [www.xxx.com](https://www.xxx.com) dan static.xxx.com

### Konfigurasi Bash (di node Alpha/Client)
```bash
apt-get update && apt-get install apache2-utils -y

# Test endpoint dinamis (www)
ab -n 250 -c 10 http://www.k01.com/

# Test endpoint statis (static)
ab -n 250 -c 10 http://static.k01.com/
```

## Step 17: TXT Record Klien
### Soal
Tambahkan TXT record untuk mengembalikan nama hostname klien sayap kiri dan kanan.

### Konfigurasi (di prab)
```bash
alpha IN TXT "alpha"
beta IN TXT "beta"
```

## Step 18: TTL dan DNS Cache Check
### Soal
Ubah A record milik abbey.xxx.com ke alamat IP fiktif secara acak[cite: 12]. Naikkan serial SOA, tetapkan TTL sebesar 15 detik[cite: 12]. Verifikasi dari klien sebelum perubahan, saat 15 detik berjalan (cache), dan setelah batas kadaluarsa.

### Konfigurasi Bash
Di node prab (Master):
```bash
# Ubah IP abbey menjadi IP fiktif (misal 10.99.99.99) dengan TTL 15
sed -i 's/abbey IN A .*/abbey 15 IN A 10.99.99.99/g' /etc/bind/k01/k01.com

# Ingat untuk memperbarui nilai serial secara manual di file zona
# Setelah itu restart service
service bind9 restart
```

Pengujian di Alpha (Client):
```bash
# 1. Cek pertama
dig abbey.k01.com

# 2. Tunggu 15 Detik
sleep 15

# 3. Cek kedua, IP harus sudah berubah ke IP fiktif
dig abbey.k01.com
```

## Step 19: Outbound CNAME
### Soal
Buat CNAME record dari outbound.xxx.com menuju http.badssl.com[cite: 12]. Verifikasi output menggunakan curl[cite: 12].

### Konfigurasi Bash
Di node prab (Master):
```bash
echo "outbound IN CNAME http.badssl.com." >> /etc/bind/k01/k01.com
service bind9 restart
```

Di node Alpha (Client):
```bash
curl http://outbound.k01.com
```

## Step 20: Persistence (Autostart Services)
### Soal
Pastikan semua service dan konfigurasi berjalan normal dan berstatus autostart saat node di-restart[cite: 12].

### Konfigurasi Bash
Agar aman setiap kali node GNS3 dinyalakan ulang, kita perlu mendaftarkan command start ke dalam /root/.bashrc.

Di Node DNS (prab & tedd):
```bash
echo "service bind9 start" >> ~/.bashrc
```

Di Node Apache (Penny, Obladi, Desmond):
```bash
echo "service apache2 start" >> ~/.bashrc
```

Di Node Nginx & PHP (Abbey, Oblada, Molly):
```bash
echo "service nginx start" >> ~/.bashrc
echo "service php8.1-fpm start" >> ~/.bashrc # Sesuaikan versi PHP
```

Khusus Router (Rootkit) untuk IPTables:
```bash
cat << 'EOF' >> ~/.bashrc
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
```