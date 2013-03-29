#!/bin/bash
 
echo "import sonar repository"
sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo

echo "create database sonar, user/password sonar/sonar":
mysql --user=root --password=root -e "CREATE USER 'sonar'@'localhost' IDENTIFIED BY 'sonar';"
mysql --user=root --password=root -e "CREATE DATABASE IF NOT EXISTS sonar;"
mysql --user=root --password=root -e "use sonar; GRANT ALL PRIVILEGES ON sonar.* TO 'sonar'@'localhost' WITH GRANT OPTION;"

echo "install sonar"
yum -y install sonar

echo "start sonar on boot"
chkconfig sonar on

echo "Append firewall rule to open port 9000"
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 9000 -j ACCEPT
service iptables save
service iptables restart

echo "Configure sonar"
# add # before each sonar.jdbc.url that are not commented:
sed -i "s/^\(sonar.jdbc.url\)/#\1/" /opt/sonar/conf/sonar.properties
# add # before each sonar.jdbc.driverClassName that are not commented:
sed -i "s/^\(sonar.jdbc.driverClassName\)/#\1/" /opt/sonar/conf/sonar.properties

# remove comment for the sonar.jdbc.url in mysql part:
sed -i "s/^#\(sonar.jdbc.url:.*jdbc:mysql\)/\1/" /opt/sonar/conf/sonar.properties
# remove comment for the sonar.jdbc.driverClassName in mysql part:
sed -i "s/^#\(sonar.jdbc.driverClassName:.*com.mysql.jdbc.Driver\)/\1/" /opt/sonar/conf/sonar.properties

echo "copy mysql-connector to /opt/sonar/lib"
cp -f /opt/sonar/extensions/jdbc-driver/mysql/mysql-connector-java*.jar /opt/sonar/lib

echo "start service"
service sonar start

myip=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
echo "Now meet you here: http://$myip:9000"
