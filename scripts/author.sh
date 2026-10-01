#!/bin/bash

dig -x 10.85.2.2 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt
dig -x 10.85.5.2 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt
dig -x 10.85.1.4 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt
dig -x 10.85.1.5 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt
dig -x 10.85.1.6 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt
dig -x 10.85.1.7 @10.85.1.3 | grep -e 'DiG' -e 'qr' >> author.txt



