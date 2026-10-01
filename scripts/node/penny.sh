#!/bin/bash

apt-get install -y apache2-utils apache2 php php-fpm libapache2-mod-fcgid

a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers proxy_fcgi setenvif
a2enconf php8.4-fpm

# Soal 12
htpasswd -bc /etc/apache2/.htpasswd prabs "pakar_pinter_jadi_gob***"

mkdir -p /var/www/html/admin
echo "Dokumen Rahasia Sindikat The Mesh" > /var/www/html/admin/index.html
chown -R www-data:www-data /var/www/html/admin

# Soal 15
mkdir -p /var/www/eternal
echo "<?php echo '<h1>Jalur Eternal di Penny</h1><p>PHP Berjalan sempurna! Hostname backend: ' . gethostname() . '</p>'; ?>" > /var/www/eternal/index.php
chown -R www-data:www-data /var/www/eternal
chmod -R 755 /var/www/eternal

cat << "EOF" > /etc/apache2/sites-available/000-default.conf
# Soal 13
<VirtualHost *:80>
        ServerName penny.k-43.com
        Redirect 301 / http://www.k-43.com/
</VirtualHost>

<VirtualHost *:80>
        ServerName www.k-43.com

        ProxyPreserveHost On
        RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}

        <Proxy balancer://vaultcluster>
                BalancerMember http://10.85.1.4
                BalancerMember http://10.85.1.5
        </Proxy>
        # soal 12
        ProxyPass /admin !        
    
        Alias /admin /var/www/html/admin

        <Location /admin>
                AuthType Basic
                AuthName "Restricted Area"
                AuthUserFile /etc/apache2/.htpasswd
                Require valid-user
        </Location>
        
        # Soal 15
        ProxyPass /eternal !
        Alias /eternal /var/www/eternal

        <Directory /var/www/eternal>
                Options Indexes FollowSymLinks
                AllowOverride None
                Require all granted
                
                <FilesMatch \.php$>
                        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
                </FilesMatch>
        </Directory>

        ProxyPass / balancer://vaultcluster/
        ProxyPassReverse / balancer://vaultcluster/
</VirtualHost>
EOF

service apache2 restart
service php8.4-fpm start
