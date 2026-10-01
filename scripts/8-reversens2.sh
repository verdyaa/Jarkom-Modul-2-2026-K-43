#!/bin/bash

cat << "EOF" >> /etc/bind/named.conf.local

zone "1.85.10.in-addr.arpa" {
    type slave;
    file "/etc/bind/1.85.10.in-addr.arpa";
    masters { 10.85.1.2; };
};

zone "2.85.10.in-addr.arpa" {
    type slave;
    file "/etc/bind/2.85.10.in-addr.arpa";
    masters { 10.85.1.2; };
};

zone "5.85.10.in-addr.arpa" {
    type slave;
    file "/etc/bind/5.85.10.in-addr.arpa";
    masters { 10.85.1.2; };
};
EOF
