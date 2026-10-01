#!/bin/bash

htpasswd -c /etc/apache2/.htpasswd prabs

mkdir -p /var/www/admin
cat > /var/www/admin/index.html <<'HTML'
<!doctype html>
<html>
<head><title>Admin Dashboard</title></head>
<body>
    <h1>Area Terproteksi Admin (VPC1)</h1>
    <p>Login Basic Auth Berhasil!</p>
</body>
</html>
HTML
