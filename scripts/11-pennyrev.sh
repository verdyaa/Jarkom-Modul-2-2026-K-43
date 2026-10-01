#!/bin/bash

apt-get install -y apache2-utils apache2

a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers

cat << "EOF" > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
        ServerName penny.k-43.com

        # Meneruskan identitas pengunjung
        ProxyPreserveHost On
        RequestHeader set X-Real-IP expr=%{REMOTE_ADDR}

        # Konfigurasi Load Balancer ke Area Vault
        <Proxy balancer://vaultcluster>
                BalancerMember http://10.85.1.4
                BalancerMember http://10.85.1.5
        </Proxy>

        ProxyPass /admin !        
        # 2. Arahkan URL /admin ke folder lokal
        Alias /admin /var/www/html/admin
        # 3. Kunci area /admin dengan Basic Auth
        <Location /admin>
                AuthType Basic
                AuthName "Restricted Area"
                AuthUserFile /etc/apache2/.htpasswd
                Require valid-user
        </Location>

        ProxyPass / balancer://vaultcluster/
        ProxyPassReverse / balancer://vaultcluster/
</VirtualHost>
EOF

service apache2 restart
