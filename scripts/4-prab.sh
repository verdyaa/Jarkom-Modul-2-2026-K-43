#!/bin/bash

apt-get install bind9 -y
ln -s /etc/init.d/named /etc/init.d/bind9

mkdir /etc/bind/jarkom

cat << "EOF" > /etc/bind/named.conf.local
zone "k-43.com" {
  type master;
  file "/etc/bind/jarkom/k-43.com";
  allow-transfer { 10.85.1.3; };
  notify yes;
};
EOF

cat << "EOF" > /etc/bind/zone.template
$TTL    604800          ; Waktu cache default (detik)
@       IN      SOA     localhost. root.localhost. (
                        2025100401 ; Serial (format YYYYMMDDXX)
                        604800     ; Refresh (1 minggu)
                        86400      ; Retry (1 hari)
                        2419200    ; Expire (4 minggu)
                        604800 )   ; Negative Cache TTL
;

@       IN      NS      localhost.
@       IN      A       127.0.0.1
EOF

cat << "EOF" > /etc/bind/jarkom/k-43.com
$TTL    604800          ; Waktu cache default (detik)
@       IN      SOA     prab.k-43.com. root.k-43.com. (
                        2026092903 ; Serial diperbarui untuk memicu sinkronisasi
                        604800     ; Refresh (1 minggu)
                        86400      ; Retry (1 hari)
                        2419200    ; Expire (4 minggu)
                        604800 )   ; Negative Cache TTL
;

@       IN      NS      prab.k-43.com.
@       IN      NS      tedd.k-43.com.

@       IN      A       10.85.5.2     
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

vault   IN      A       10.85.1.4
vault   IN      A       10.85.1.5

core    IN      A       10.85.1.6
core    IN      A       10.85.1.7

www     IN      CNAME   penny
static  IN      CNAME   abbey
EOF

cat << "EOF" > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders { 192.168.122.1; };
    dnssec-validation no;
    allow-query{any;};
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

service bind9 restart
