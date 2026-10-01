#!/bin/bash

apt install -y nginx

mkdir -p /var/www/orion
echo "<h1>Jalur Orion di Abbey</h1><p>Ini adalah halaman statis murni tanpa PHP.</p>" > /var/www/orion/index.html
chown -R www-data:www-data /var/www/orion
chmod -R 755 /var/www/orion

cat << "EOF" > /etc/nginx/sites-available/default
upstream core_cluster {
        server 10.85.1.6;
        server 10.85.1.7;
}

# Soal 13
server {
        listen 80;
        server_name abbey.k-43.com 10.85.2.2;
        return 302 http://static.k-43.com$request_uri;
}

server {
        listen 80;
        server_name static.k-43.com;

        location /orion {
                alias /var/www/orion;
                index index.html index.htm;
                try_files $uri $uri/ =404;
        }

        location / {
                proxy_pass http://core_cluster;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
        }
}
EOF
service nginx restart
