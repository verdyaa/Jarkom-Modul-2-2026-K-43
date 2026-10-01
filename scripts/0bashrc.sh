#!/bin/bash

echo "setting up bashrc...."

cat << 'EOF' >> ~/.bashrc
if [ ! -f /tmp/boot_setup_done ]; then
    echo "nameserver 10.85.1.2" > /etc/resolv.conf
    echo "nameserver 10.85.1.3" >> /etc/resolv.conf
    echo "nameserver 192.168.122.1" >> /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf

    ntpd -q -g 2>/dev/null || date -s "$(wget -qS --spider http://google.com 2>&1 | grep 'Date:' | sed 's/.*Date: //')"

    apt update && apt upgrade -y && apt install vim -y
    
    touch /tmp/boot_setup_done
fi
EOF

source .bashrc
echo "done"

cat << "EOF" >> .bashrc
echo "beta" > /etc/hostname
hostname beta
EOF
