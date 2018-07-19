#!/bin/bash

echo "=================================================="
echo "Aloha! Now we will try to Install Ubuntu 12.04 LTS"
echo "with Apache 2.4, PHP 5.6, MySQL 5.6"
echo "and others dependencies needed for Magento 1."
echo "=================================================="
echo ""
echo "=================================================="
echo "SET LOCALES"
echo "=================================================="
export DEBIAN_FRONTEND=noninteractive
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_PAPER=en_US.UTF-8
export LC_ADDRESS=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TELEPHONE=en_US.UTF-8
export LC_IDENTIFICATION=en_US.UTF-8
export LC_MEASUREMENT=en_US.UTF-8
export LC_TIME=en_US.UTF-8
export LC_NAME=en_US.UTF-8

locale-gen en_US en_US.UTF-8
locale > /etc/default/locale
update-locale en_US en_US.UTF-8

if [ ! -d /vagrant/source ]; then
    mkdir /vagrant/source
fi

echo "=================================================="
echo "RUN UPDATE"
echo "=================================================="
add-apt-repository ppa:ondrej/php -y
apt-get update

if [ ! -f /vagrant/source/mysql-apt-config_0.8.10-1_all.deb ]; then
    wget -c https://dev.mysql.com/get/mysql-apt-config_0.8.10-1_all.deb -O /vagrant/source/mysql-apt-config_0.8.10-1_all.deb
fi

debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-server select mysql-5.6"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-tools select Enabled"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/enable-repo select mysql-5.6"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/tools-component string mysql-tools"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-product select Ok"
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/repo-url string http://repo.mysql.com/apt"
DEBIAN_FRONTEND=noninteractive dpkg -i /vagrant/source/mysql-apt-config_0.8.10-1_all.deb

apt-get update
apt-get -y --force-yes install php5.6 php5.6-curl php5.6-gd php5.6-mbstring php5.6-mcrypt php5.6-cli php5.6-xml php5.6-mysql php5.6-json php5.6-intl php5.6-soap libaio1 ntp mcrypt expect

debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password 123123q"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password 123123q"
DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

chown www-data:www-data /var/www/html/ -v
mkdir -p /var/www/html/magento
chown www-data:www-data /var/www/html/magento -Rv
chmod 2755 /var/www/html/magento -v

if [ ! -d /vagrant/public_html ]; then
  mkdir -p /vagrant/public_html -v
fi

sudo -u www-data /bin/sh <<\DEVOPS_BLOCK
cd /var/www/html/magento/
mkdir -p /var/www/html/magento/public_html -v
mkdir -p /var/www/html/magento/log -v
if [ -d /var/www/html/magento/public_html/app ]; then
    find . -type d -exec chmod 775 {} \;
    find . -type f -exec chmod 664 {} \;
fi
cd log
touch mage.conf-error_log
touch mage.conf-access_log
ls -alt

DEVOPS_BLOCK

VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@example.com
    DocumentRoot "/var/www/html/magento/public_html/"
    ServerName mage.tkhamlai.com
    ServerAlias www.mage.tkhamlai.com
    <Directory /var/www/html/magento/public_html/>
        Options Indexes FollowSymLinks
        AllowOverride all
        Require all granted
    </Directory>
    ErrorLog "/var/www/html/magento/log/mage.conf-error_log"
    CustomLog "/var/www/html/magento/log/mage.conf-access_log" common
    SetEnv MAGE_IS_DEVELOPER_MODE false
</VirtualHost>
EOF
)

a2enmod rewrite
a2enmod alias
phpenmod mcrypt
phpenmod mbstring
phpenmod soap
phpenmod mbstring
echo "$VHOST" > /etc/apache2/sites-available/000-default.conf
service apache2 reload

# echo "=================================================="
# echo "INSTALLING ADMINER"
# echo "=================================================="
# if [ ! -d "/vagrant/httpdocs/adminer" ]; then
# echo "Adminer not found at /vagrant/httpdocs/adminer and will be installed..."

# mkdir /vagrant/httpdocs/adminer
# wget -O /vagrant/httpdocs/adminer/index.php https://www.adminer.org/static/download/4.2.5/adminer-4.2.5.php

# echo "Adminer installed... Use http://mage.tkhamlai.com/adminer/ URL to use it."
# fi

echo "=================================================="
echo "INSTALLING MYSQL MAGENTO DATABASE"
echo "=================================================="


/usr/bin/expect << EOF
spawn /usr/bin/mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "123123q\r"
expect "Set root password?"
send "n\r"
# expect "New password:"
# send "123123q\r"
# expect "Re-enter new password:"
# send "123123q\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "y\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
# puts "Ended expect script."
send "exit\r"

EOF


# if [ ! -f /vagrant/source/VBoxGuestAdditions_5.1.38.iso ]; then
#     wget http://download.virtualbox.org/virtualbox/5.1.38/VBoxGuestAdditions_5.1.38.iso -O /vagrant/source/VBoxGuestAdditions_5.1.38.iso
# fi

# mkdir -p /media/iso
# mount -o loop /vagrant/source/VBoxGuestAdditions_5.1.38.iso /media/iso

# /media/iso/VBoxLinuxAdditions.run --nox11
# /usr/bin/expect << EOF
# spawn 

# expect "Do you wish to continue? [yes or no]"
# send "yes\r"

# EOF
# umount /media/iso

# apt-get -y upgrade
# apt-get -y autoclean

echo "=================================================="
echo "DOWNLOAD MAGENTO SOURCE AND SAMPLE"
echo "=================================================="
echo "Start download Magento 1.9.2.3 and sample data save version..."


sudo -u www-data /bin/sh <<\DEVOPS_BLOCK
# Become devops user here

if [ ! -f /vagrant/source/magento-1.9.2.4.tar.gz ]; then
    wget -c https://github.com/OpenMage/magento-mirror/archive/1.9.2.4.tar.gz -O /vagrant/source/magento-1.9.2.4.tar.gz
fi

if [ ! -f /vagrant/source/magento-sample-data-1.9.1.0.tar.gz ]; then
    wget -c https://raw.githubusercontent.com/aurmil/magento-compressed-sample-data/master/1.9.1.0/magento-sample-data-1.9.1.0.tar.gz -O /vagrant/source/magento-sample-data-1.9.1.0.tar.gz
fi

cd /var/www/html/magento/public_html
ls -alt

if [ ! -f /var/www/html/magento/public_html/index.php ]; then
echo "Extract Magento and sample data to /var/www/html/magento/public_html ..."
    cd /var/www/html/magento/public_html
    ls -alt
    tar xzf /vagrant/source/magento-1.9.2.4.tar.gz -C /var/www/html/magento/public_html --strip-components 1
    ls -alt
    tar xzf /vagrant/source/magento-sample-data-1.9.1.0.tar.gz -C /var/www/html/magento/public_html --strip-components 1
    ls -alt
fi

mysql -uroot -p123123q -e "DROP DATABASE IF EXISTS magento"
mysql -uroot -p123123q -e "CREATE DATABASE IF NOT EXISTS magento"
mysql -uroot -p123123q -e "GRANT ALL PRIVILEGES ON magento.* TO 'magento'@'localhost' IDENTIFIED BY '123123q'"
mysql -uroot -p123123q -e "FLUSH PRIVILEGES"

echo "Import Sample database..."

if [ ! -f /var/www/html/magento/public_html/magento_sample_data_for_1.9.1.0.sql ]; then
    cd /var/www/html/magento/public_html
    tar zxvf /vagrant/source/magento-sample-data-1.9.1.0.tar.gz magento-sample-data-1.9.1.0/magento_sample_data_for_1.9.1.0.sql --strip-components 1 -C /var/www/html/magento/public_html/magento_sample_data_for_1.9.1.0.sql
    cd -
fi

mysql -uroot -p123123q magento < /var/www/html/magento/public_html/magento_sample_data_for_1.9.1.0.sql
rm /var/www/html/magento/public_html/magento_sample_data_for_1.9.1.0.sql -v

cd /var/www/html/magento/public_html
find . -type d -exec chmod 775 {} \;
find . -type f -exec chmod 664 {} \;
DEVOPS_BLOCK

echo "=================================================="
echo "INSTALL MAGENTO"
echo "=================================================="

sudo -u www-data /bin/sh <<\DEVOPS_BLOCK
cd /var/www/html/magento/public_html
php -f install.php -- --license_agreement_accepted yes \
--locale en_US --timezone "Europe/Uzhgorod" --default_currency USD \
--db_host localhost --db_name magento --db_user magento --db_pass 123123q \
--skip_url_validation \
--url "http://mage.tkhamlai.com/" --use_rewrites yes \
--use_secure no --secure_base_url "http://mage.tkhamlai.com/" --use_secure_admin no \
--admin_lastname Khamlai --admin_firstname Tomash --admin_email "tomash.khamlai@gmail.com" \
--admin_username admin --admin_password 123123q
DEVOPS_BLOCK

apt-get -y autoremove

echo "done."

echo "=================================================="
echo "============= INSTALLATION COMPLETE =============="
echo "=================================================="
