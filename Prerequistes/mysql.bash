#!/bin/bash

echo "install mysql-server"
yum -y install mysql-server phpMyAdmin

echo "activate mysqld at startup"
chkconfig mysqld on

echo "start the server"
service mysqld start

echo "set password for root. WARN! for this example we choose unsecure password root"
/usr/bin/mysqladmin -u root password 'root'

echo "Note: by default only local users can access to phpMyAdmin."
echo "Let's update the file /etc/httpd/conf.d/phpMyAdmin.conf and allow everyone."
sed -i "s/\(Deny\s*from\s*All\)/#\1/i" /etc/httpd/conf.d/phpMyAdmin.conf
sed -i "s/\(Allow\s*from\s*127.0.0.1\)/#\1/i" /etc/httpd/conf.d/phpMyAdmin.conf
sed -i "s/\(Allow\s*from\s*::1\)/#\1/i" /etc/httpd/conf.d/phpMyAdmin.conf

echo "Now reload httpd"
service httpd reload