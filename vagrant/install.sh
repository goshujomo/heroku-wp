#!/bin/bash

MYSQL_PASSWORD="password"
MYSQL_USERNAME="herokuwp"

HHVM_VER="3.3.1"

#
# End Config
#

echo "###############################"
echo "## Provisioning Heroku WP VM ##"
echo "###############################"

#
# Update Package Manager
#

apt-get update -y

#
# Install MySQL
#

echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections

apt-get install -y mysql-server

echo "CREATE USER '$MYSQL_USERNAME'@'127.0.0.1' IDENTIFIED BY '$MYSQL_PASSWORD'" | mysql -uroot "-p$MYSQL_PASSWORD"
echo "CREATE DATABASE herokuwp" | mysql -uroot "-p$MYSQL_PASSWORD"
echo "GRANT ALL ON herokuwp.* TO '$MYSQL_USERNAME'@'127.0.0.1'" | mysql -uroot "-p$MYSQL_PASSWORD"
echo "FLUSH PRIVILEGES" | mysql -uroot "-p$MYSQL_PASSWORD"

#
# Install Memcached
#

apt-get install -y memcached

#
# Install Nginx
#

apt-get install -y nginx

#
# Install HHVM
#

wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -
echo deb http://dl.hhvm.com/ubuntu trusty main | tee /etc/apt/sources.list.d/hhvm.list
apt-get update
apt-get install -y hhvm

#
# Install Composer
#

curl -o /usr/local/bin/composer.phar https://getcomposer.org/composer.phar
echo '#!/bin/bash' > /usr/local/bin/composer
echo 'hhvm -v ResourceLimit.SocketDefaultTimeout=30 -v Http.SlowQueryThreshold=30000 /usr/local/bin/composer.phar $@' >> /usr/local/bin/composer
chmod 755 /usr/local/bin/composer

#
# Make Some Swap
#

/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1

#
# Copy Config Files
#

cp -a /app/vagrant/root/* /

#
# Restart Services
#

/etc/init.d/hhvm stop
/etc/init.d/hhvm start

/etc/init.d/nginx stop
/etc/init.d/nginx start

#
# Build Heroku-WP
#

sudo -u vagrant composer --working-dir=/app install
