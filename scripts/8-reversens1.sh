#!/bin/bash
#10.85.1.1
#10.85.2.1
#10.85.5.1

cat << "EOF" >> /etc/bind/named.conf.local

zone "1.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/1.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
    notify yes;
};

zone "2.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/2.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
    notify yes;
};

zone "5.85.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/5.85.10.in-addr.arpa";
    allow-transfer { 10.85.1.3; };
    notify yes;
};
EOF

cat << "EOF" > /etc/bind/jarkom/1.85.10.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k-43.com. root.k-43.com. (
                        2026092902 ; Jangan lupa naikkan Serial jika kamu menghapus baris
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.k-43.com.
@       IN      NS      tedd.k-43.com.

4       IN      PTR     obladi.k-43.com.
5       IN      PTR     desmond.k-43.com.
6       IN      PTR     oblada.k-43.com.
7       IN      PTR     molly.k-43.com.
EOF

cat << "EOF" > /etc/bind/jarkom/2.85.10.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k-43.com. root.k-43.com. (
                        2026092901 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.k-43.com.
@       IN      NS      tedd.k-43.com.

2       IN      PTR     abby.k-43.com.
EOF

cat << "EOF" > /etc/bind/jarkom/5.85.10.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k-43.com. root.k-43.com. (
                        2026092901 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      prab.k-43.com.
@       IN      NS      tedd.k-43.com.

2       IN      PTR     penny.k-43.com.
EOF

service bind9 restart
