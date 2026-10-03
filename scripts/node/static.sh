#!/bin/bash

apt-get install lynx -y && apt-get install apache2 php -y  

service apache2 start

php -v

rm -rf /var/www/html

mkdir -p /var/www/arsip/
touch /var/www/arsip/test.txt
touch /var/www/arsip/womp.md

cat << "EOF" > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
	ServerName static.k-43.com

	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/arsip/

	<Directory /var/www/arsip/>
		Options +Indexes +FollowSymLinks -Multiviews
		AllowOverride All
		Require all granted
	</Directory>

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

cat << "EOF" > /etc/apache2/apache2.conf
PidFile ${APACHE_PID_FILE}

Timeout 300

KeepAlive On

MaxKeepAliveRequests 100

KeepAliveTimeout 5

User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}

HostnameLookups Off

ErrorLog ${APACHE_LOG_DIR}/error.log

LogLevel warn

IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf

Include ports.conf


<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>

<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>

<Directory /var/www/>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>

#<Directory /srv/>
#	Options Indexes FollowSymLinks
#	AllowOverride None
#	Require all granted
#</Directory>

AccessFileName .htaccess

<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>

LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined

# Soal 14
LogFormat "%{X-Real-IP}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined 
LogFormat "%{X-Real-IP}i %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

IncludeOptional conf-enabled/*.conf

IncludeOptional sites-enabled/*.conf
EOF

a2enmod rewrite
a2enmod autoindex

cat << "EOF" > /var/www/arsip/.access
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^([^\.]+)$ $1.php [NC,L]
EOF

service apache2 restart
