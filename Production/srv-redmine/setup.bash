#!/bin/bash

##################################################
#      PARAMETERS 
##################################################

redmine_install_url=http://rubyforge.org/frs/download.php/76867/redmine-2.3.0.tar.gz
redmine_version=redmine-2.3.0

##################################################
#      INSTALLATION SCRIPT
##################################################
echo "create database redmine, user/password redmine/redmine":
mysql --user=root --password=root -e "CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'redmine';"
mysql --user=root --password=root -e "CREATE DATABASE IF NOT EXISTS redmine;"
mysql --user=root --password=root -e "use redmine; GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost' WITH GRANT OPTION;"

echo "install redmine dependencies"
yum -y install make gcc gcc-c++ zlib-devel ruby-devel rubygems ruby-libs apr-devel apr-util-devel httpd-devel mysql-devel mysql-server automake autoconf ImageMagick ImageMagick-devel curl-devel postgresql-devel sqlite-devel rubygem-nokogiri

echo "install bundle"
gem install bundle

echo "install nokogiri (because package rubygem-nokogiri has not the expected version (i.e. 1.5.9)"
yum install -y gcc ruby-devel libxml2 libxml2-devel libxslt libxslt-devel
gem install nokogiri

echo "install passenger"
gem install passenger
passenger-install-apache2-module -a

echo "configure httpd (create /etc/httpd/conf.d/redmine.conf)"
cat > /etc/httpd/conf.d/redmine.conf << "EOF"
LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-3.0.19/ext/apache2/mod_passenger.so
PassengerRoot               /usr/lib/ruby/gems/1.8/gems/passenger-3.0.19
PassengerRuby               /usr/bin/ruby

   
<VirtualHost *>
  ServerName YOUR_SERVER
  DocumentRoot /var/www/html
  RailsEnv production
  RailsBaseURI /redmine
  PassengerDefaultUser apache

   ErrorLog "|/usr/sbin/rotatelogs /etc/httpd/logs/redmine-error.%Y-%m-%d.log 86400"
   CustomLog "|/usr/sbin/rotatelogs /etc/httpd/logs/redmine-access.%Y-%m-%d.log 86400" "%h %l %u %t %D \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""

</VirtualHost>
EOF
ln -s /opt/redmine/redmine/public /var/www/html/redmine

echo "get redmine"
mkdir -p /opt/redmine/download
cd /opt/redmine/download
wget $redmine_install_url  # GET LATEST VERSION ON RUBYFORGE
tar xvfz $redmine_version.tar.gz
mv $redmine_version ../redmine

echo "configure database"
cd /opt/redmine/redmine/config
cp database.yml.example database.yml
sed -i "s/username: root/username: redmine/g" /opt/redmine/redmine/config/database.yml
sed -i "s/password: \"\"/password: redmine/g" /opt/redmine/redmine/config/database.yml

echo "install redmine"
cd /opt/redmine/redmine
bundle install

echo "now populate database"
cd /opt/redmine/redmine
rake generate_secret_token
rake db:migrate RAILS_ENV="production"
rake redmine:load_default_data RAILS_ENV="production"



echo "start httpd service"
service httpd restart

myip=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
echo "Now meet you here: http://$myip"
