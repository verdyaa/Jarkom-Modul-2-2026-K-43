#!/bin/bash

apt install -y nginx

cat << "EOF" > /etc/nginx/sites-available/default
upstream core_cluster {
        server 10.85.1.6;
        server 10.85.1.7;
}

server {
        listen 80;
        server_name abbey.k-43.com;

        location / {
                proxy_pass http://core_cluster;
                
                # Meneruskan identitas pengunjung
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
        }
}
EOF
service nginx restart
