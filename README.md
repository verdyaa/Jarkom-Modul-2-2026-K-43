# Komdat & Jaringan Komputer Modul 2 : DNS, Web Server, dan Reverse Proxy
> Domain Kelompok = k-43.com
> Prefix IP = 10.85.x.x

## Anggota

| NAMA | NRP |
| ------------- | -------------- | 
| I Ketut Weda Adikusuma | 5027251061 |
| D`qhaizhar Ari Dhiaulhaq | 5027251083 |

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
address 10.85.1.1
netmask 255.255.255.0

auto eth2
iface eth2 inet static
address 10.85.2.1
netmask 255.255.255.0

auto eth3
iface eth3 inet static
address 10.85.3.1
netmask 255.255.255.0

auto eth4
iface eth4 inet static
address 10.85.4.1
netmask 255.255.255.0

auto eth5
iface eth5 inet static
address 10.85.5.1
netmask 255.255.255.0
```
![Router](./images/1-router.png)


## Step 2: Konfigurasi NAT
### Soal
Buka jalur menuju NAT dengan memastikan antarmuka WAN di router rootkit aktif. Konfigurasikan NAT agar dapat meneruskan lalu lintas keluar bagi seluruh alamat internal.

### Konfigurasi (di Rootkit)
```bash
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

Di semua node non-router, tambahkan resolver awal pada `/etc/resolv.conf`:
```bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```
![Resolve Test](./images/3-resolve.png)


## Step 4: DNS Server (Master & Slave)
### Soal
Bangun zona `k-43.com` sebagai authoritative di node `prab` dengan SOA ke `prab.k-43.com`. Konfigurasi `tedd` sebagai slave. Atur DNS resolver berurut: prab -> tedd -> 192.168.122.1.

### Konfigurasi prab (Master)
Edit `/etc/bind/named.conf.local`:
```bash
zone "k-43.com" {
  type master;
  file "/etc/bind/jarkom/k-43.com";
  allow-transfer { 10.85.1.3; };
  notify yes;
};
```
![Zone Config](./images/4-zone.png)
![SOA Config](./images/4-soa.png)

### Konfigurasi tedd (Slave)
Edit `/etc/bind/named.conf.local`:
```bash
zone "k-43.com" {
  type slave;
  file "/etc/bind/k-43.com";
  masters { 10.85.1.2; };
};
```
![Ping Test](./images/4-ping.png)


## Step 5 & 6: Hostnames & Zone Transfer
### Soal
Namai semua Entitas (hostname) sesuai glosarium. Buat setiap domain untuk masing-masing node dan assign IP. Verifikasi zone transfer agar tedd menerima salinan zona terbaru dari prab dengan nilai serial SOA yang sama.

### Konfigurasi (Prab)
Menambahkan A Record untuk semua entitas:
```bash
cat << "EOF" > /etc/bind/jarkom/k-43.com
$TTL    604800
@       IN      SOA     prab.k-43.com. root.k-43.com. (
                        2026092903 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.k-43.com.
@       IN      NS      tedd.k-43.com.

prab    IN      A       10.85.1.2       
tedd    IN      A       10.85.1.3
rootkit IN      A       10.85.1.1
alpha   IN      A       10.85.3.2
beta    IN      A       10.85.3.3
gamma   IN      A       10.85.3.4
delta   IN      A       10.85.4.2
epsilon IN      A       10.85.4.3
abbey   IN      A       10.85.2.2
penny   IN      A       10.85.5.2
obladi  IN      A       10.85.1.4
desmond IN      A       10.85.1.5
oblada  IN      A       10.85.1.6
molly   IN      A       10.85.1.7
EOF
service bind9 restart
```
![Hostname Set](./images/5-name.png)
![Serial Match](./images/6-serial.png)


## Step 7: CNAME & Load Balancer Domains
### Soal
Tambahkan A record untuk `vault.k-43.com` dan `core.k-43.com` (Load Balancer 2 node). Tetapkan CNAME `www -> penny`, dan `static -> abbey`.

### Konfigurasi (di prab)
Tambahkan pada file zona `k-43.com`:
```bash
vault   IN      A       10.85.1.4
vault   IN      A       10.85.1.5

core    IN      A       10.85.1.6
core    IN      A       10.85.1.7

www     IN      CNAME   penny
static  IN      CNAME   abbey
```
![CNAME Setup](./images/7-CNAME.png)
![Test DNS 1](./images/7-tesdev1.png)
![Test DNS 2](./images/7-tesdev2.png)


## Step 8: Reverse Zone
### Soal
Deklarasikan reverse zone untuk segmen jaringan abbey, penny, area vault, dan area core di prab. Tarik reverse zone tersebut ke tedd sebagai slave, dan tambahkan PTR record.

### Konfigurasi (Prab)
```bash
cat << "EOF" >> /etc/bind/named.conf.local
zone "1.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/1.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
};
zone "2.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/2.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
};
zone "5.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/5.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
};
EOF
```
Lalu buat PTR Record:
```bash
4 IN PTR vault.k-43.com.
5 IN PTR vault.k-43.com.
6 IN PTR core.k-43.com.
7 IN PTR core.k-43.com.
```
![Reverse Master](./images/8-author.png)
![Reverse Slave](./images/8-reverse-slave.png)
![Reverse Testing](./images/8-query.png)


## Step 9: Web Statis (Vault: Obladi & Desmond)
### Soal
Jalankan layanan web statis pada area vault (Apache). Buka direktori `/arsip/` dan aktifkan fitur autoindex (directory listing) pada konfigurasi Apache.

### Konfigurasi Bash (Obladi & Desmond)
```bash
apt-get install apache2 -y
mkdir -p /var/www/html/arsip

cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html/arsip>
        Options +Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF
service apache2 restart
```
![Autoindex](./images/9-autoindex.png)
![Directory Listing](./images/9-directory.png)


## Step 10: Web Dinamis (Core: Oblada & Molly)
### Soal
Jalankan Nginx & PHP-FPM di area core. Buat aplikasi profil dan terapkan URL rewrite ke `/profil` (tanpa .php).

### Konfigurasi (Oblada & Molly)
```bash
apt install php php-fpm nginx -y

# Konfigurasi Nginx Default
cat << "EOF" > /etc/nginx/sites-available/default 
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html index.htm;
    
    location / {
        try_files $uri $uri/ $uri.php?$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
EOF

echo "<?php echo '<h1>Halaman Profil</h1><p>Ini adalah profil entitas ' . gethostname() . '</p>'; ?>" > /var/www/html/profil.php
service php8.4-fpm start
service nginx restart
```
![Nginx Test](./images/10-curl.png)
![Profil Page](./images/10-dinamiss.png)


## Step 11: Reverse Proxy 
### Soal
Penny diproyeksikan sebagai proksi menuju Vault (Apache), dan Abbey menuju Core (Nginx). Konfigurasi Penny dan Abbey untuk melakukan *Load Balancing* ke backend masing-masing.

### Konfigurasi Penny (Apache Reverse Proxy)
```bash
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers

cat << "EOF" > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName penny.k-43.com
    ProxyPreserveHost On
    RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}

    <Proxy balancer://vaultcluster>
        BalancerMember http://10.85.1.4
        BalancerMember http://10.85.1.5
    </Proxy>

    ProxyPass / balancer://vaultcluster/
    ProxyPassReverse / balancer://vaultcluster/
</VirtualHost>
EOF
service apache2 restart
```
![Abbey Proxy Test](./images/11-staticipx.png)


## Step 12: Basic Auth
### Soal
Terapkan Basic Auth di Penny pada direktori khusus `/admin` menggunakan otentikasi valid-user.

### Konfigurasi (Penny)
```bash
htpasswd -c /etc/apache2/.htpasswd prabs

# Konfigurasi Apache virtual host
<Location /admin>
    AuthType Basic
    AuthName "Restricted Area"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Location>
```
![Admin Test](./images/12-admindir.png)
![Auth Prompt](./images/12-pasword.png)
![Auth Access](./images/12-pennyadmin.png)
![Testing Auth](./images/12-test.png)


## Step 13: HTTP Redirects
### Soal
Akses ke IP/domain penny harus di-redirect permanen (301) ke `www.k-43.com`. Akses ke IP/domain abbey harus di-redirect sementara (302) ke `static.k-43.com`.

### Konfigurasi (Abbey - Nginx Redirect 302)
```nginx
server {
    listen 80;
    server_name abbey.k-43.com 10.85.2.2;
    return 302 http://static.k-43.com$request_uri;
}
```
### Konfigurasi (Penny - Apache Redirect 301)
```apache
<VirtualHost *:80>
    ServerName penny.k-43.com
    ServerAlias 10.85.5.2
    Redirect 301 / http://www.k-43.com/
</VirtualHost>
```
![Redirect Abbey Test](./images/13-nginxredir.png)
![Redirect Abbey Config](./images/13-nginxredirtest.png)
![Redirect Penny Config](./images/13-redir.png)
![Redirect Penny Test](./images/13-redirtest.png)


## Step 14: Forwarded IP Access Log
### Soal
Pastikan access log pada server web backend (Vault dan Core) mencatat IP asli klien, bukan IP milik Penny atau Abbey.

### Konfigurasi
Untuk backend Vault (Apache), gunakan `RemoteIPHeader` dengan modul `remoteip`:
```bash
a2enmod remoteip
```
Ubah format log menjadi `%a` di `apache2.conf`.

Untuk backend Core (Nginx), tambahkan modul `realip`:
```nginx
set_real_ip_from 10.85.2.2;
real_ip_header X-Real-IP;
```
![Logs Vault](./images/14-logs.png)
![Logs Core](./images/14-curls.png)


## Step 15: Special Proxies (/eternal dan /orion)
### Soal
Pada Penny, buat reverse proxy untuk path `/eternal` yang menyajikan direktori lokal (bukan ke vault). Pada Abbey, buat path `/orion` yang disajikan murni statis secara lokal.

### Konfigurasi (Penny)
Gunakan direktif `Alias` di luar blok Load Balancer agar tidak diforward ke backend:
```apache
Alias /eternal /var/www/eternal
ProxyPass /eternal !
```
### Konfigurasi (Abbey)
Tambahkan blok `location /orion` untuk melayani isi direktori secara lokal:
```nginx
location /orion {
    alias /var/www/orion/;
}
```
![Penny Eternal Test](./images/15-pennyeternal.png)
![Penny Proxy Test](./images/15-pennyproxy.png)


## Step 16: ApacheBench Stress Test
### Soal
Klien melakukan stress test benchmark menggunakan ApacheBench dengan total 250 request dan level konkurensi 10.

### Konfigurasi Bash
```bash
# Test endpoint dinamis (www)
ab -n 250 -c 10 http://www.k-43.com/

# Test endpoint statis (static)
ab -n 250 -c 10 http://static.k-43.com/
```


## Step 17: TXT Record Klien
### Soal
Tambahkan TXT record pada Authoritative DNS (Prab) untuk mengembalikan informasi teks berisikan nama-nama klien.

### Konfigurasi (di prab)
```bash
alpha   IN      TXT     "alpha"
beta    IN      TXT     "beta"
gamma   IN      TXT     "gamma"
delta   IN      TXT     "delta"
epsilon IN      TXT     "epsilon"
```
![Adding TXT](./images/17-addingtxt.png)
![Test TXT](./images/17-test.png)


## Step 18: TTL dan DNS Cache Check
### Soal
Ubah A record milik `abbey` ke alamat IP fiktif secara acak dengan TTL sebesar 15 detik. Naikkan serial SOA. Verifikasi dari klien efek pergantian alamat IP tersebut saat cache masih berlaku dan sesudahnya.

### Konfigurasi (di prab)
```bash
abbey   15      IN      A       67.67.67.67
```
![TTL Check Test](./images/18-ip67.png)


## Step 19: Outbound CNAME
### Soal
Buat CNAME record dari `outbound.k-43.com` menuju domain `http.badssl.com` untuk memfasilitasi akses keluar, dan buktikan dengan `curl`.

### Konfigurasi (di prab)
```bash
outbound IN CNAME http.badssl.com.
```
```bash
curl -I http://outbound.k-43.com
```


## Step 20: Persistence (Autostart Services)
### Soal
Seluruh pengerjaan dan konfigurasi jaringan di atas tidak boleh hilang apabila GNS3 dan setiap node-nya di-*restart*.

### Konfigurasi Bash
Agar aman, command startup instalasi package dan menjalankan service ditempatkan pada script khusus yang akan dijalankan oleh `/root/.bashrc` di tiap-tiap node, misalnya:
```bash
if [ ! -f /tmp/boot_setup_done ]; then
    apt update && apt upgrade -y && apt install nginx -y
    service nginx start
    touch /tmp/boot_setup_done
fi
```
Ini memastikan saat server mati dan hidup kembali, seluruh pengaturan akan dikembalikan secara otomatis seperti semula tanpa intervensi manusia.