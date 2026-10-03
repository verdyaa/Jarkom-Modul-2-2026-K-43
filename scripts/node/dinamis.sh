#!/bin/bash

apt install php php-fpm nginx -y

cat << "EOF" > /etc/nginx/sites-available/default 
server {
	listen 80 default_server;
	listen [::]:80 default_server;

root /var/www/html;
	index index.php index.html index.htm index.nginx-debian.html;

	server_name _;
  
  set_real_ip_from 10.85.2.2;
  real_ip_header X-Real-IP;
	
  location / {
		try_files $uri $uri/ $uri.php?$args;
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
	}
}
EOF

echo "<?php echo '<h1>Halaman Beranda</h1><p>Selamat datang di ' . gethostname() . '</p>'; ?>" > /var/www/html/index.php
echo "<?php echo '<h1>Halaman Profil</h1><p>Ini adalah profil entitas ' . gethostname() . '</p>'; ?>" > /var/www/html/profil.php

rm -f /var/www/html/index.html

service php8.4-fpm start
service nginx restart
