#!/bin/bash
exec > /var/log/user-data.log 2>&1

yum update -y
yum install -y httpd

# Force Apache to listen on desired port
echo "Listen ${server_port}" > /etc/httpd/conf.d/port.conf

systemctl enable httpd
systemctl restart httpd

echo "<h1>${cluster_name} Web Server - Highly Available 🚀</h1>" > /var/www/html/index.html
