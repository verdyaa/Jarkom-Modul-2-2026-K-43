#!/bin/bash

apt-get install bind9 -y
ln -s /etc/init.d/named /etc/init.d/bind9

mkdir /etc/bind/jarkom

cat << "EOF" > /etc/bind/named.conf.local
zone "k-43.com" {
  type slave;
  file "/etc/bind/k-43.com";
  masters { 10.85.1.2; };
};
EOF

service bind9 restart
 
echo "Restart Service di prab"
