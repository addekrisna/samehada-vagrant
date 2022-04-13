#!/bin/bash

#Variable initialization
project=("landingpage" "wordpress" "sosmed")
length=${#project[@]}
download_url=("https://github.com/addekrisna/samehada-landingpage/archive/refs/heads/main.zip" "https://github.com/addekrisna/samehada-wordpress/archive/refs/heads/main.zip" "https://github.com/addekrisna/samehada-sosmed/archive/refs/heads/main.zip")
unzip_folder=("samehada-landingpage-main" "samehada-wordpress-main" "samehada-sosmed-main")
vhost_path="/etc/apache2/sites-available"
root_path="/var/www"
passwd=`date|md5sum|cut -c '1-12'`

#Install service package
apt update -y
apt install -y apache2 php php-mysql
apt install -y unzip
apt-get install -y mysql-server

#Install PHP extension
apt install -y php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

#Activate rewrite & SSL module
a2enmod rewrite
a2enmod ssl

#Copy SSL Files into Vagrant VM + set permission
cp ~/samehada-vagrant/cert/fullchain.cer /etc/ssl/certs/ && cp ~/samehada-vagrant/cert/star.addekrisna.com.key /etc/ssl/private/
chmod 700 /etc/ssl/certs/fullchain.cer

#Download website file and setup vhost
for (( j=0; j<length; j++ ));
do
   echo "test selalu jalan $j"
   #Download and copy files into targeted folder
   cd /tmp && wget ${download_url[$j]} -O ${project[$j]}.zip
   unzip ${project[$j]}.zip
   cp -RT ${unzip_folder[$j]} $root_path/${project[$j]}
   
   #vhost setup
   echo '<VirtualHost *:80>
 ServerName '${project[j]}'.addekrisna.com
 ServerAlias '${project[j]}'.addekrisna.com
 Redirect / https://'${project[j]}'.addekrisna.com/
</VirtualHost>

<VirtualHost *:443>
 ServerName '${project[j]}'.addekrisna.com
 ServerAlias '${project[j]}'.addekrisna.com
 ServerAdmin @localhost
 DocumentRoot '$root_path'/'${project[j]}'
 ErrorLog ${APACHE_LOG_DIR}/'${project[j]}'-error.log
 CustomLog ${APACHE_LOG_DIR}/'${project[j]}'-access.log combined
    <Directory '$root_path'/'${project[j]}'>
         Options FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
    </Directory>
 
 SSLEngine on
 SSLCertificateFile /etc/ssl/certs/fullchain.cer
 SSLCertificateKeyFile /etc/ssl/private/star.addekrisna.com.key
</VirtualHost>' > $vhost_path/${project[j]}.conf
   
   #enable site
   a2ensite ${project[$j]}.conf

   if [ ${project[$j]} = "wordpress" ]; 
   then
      
      echo "ini ${project[$j]} gaes"
      #Create WP DB and User
      mysql -u root -e "create database ${project[$j]}"
      mysql -u root -e "create user ${project[$j]}user@'localhost' identified by '$passwd'; grant all privileges on *.* to ${project[$j]}user@'localhost'"
      
      #Adding WP additional file and folder + set DB credentials
      touch $root_path/${project[j]}/.htaccess
      cp $root_path/${project[j]}/wp-config-sample.php $root_path/${project[j]}/wp-config.php
      sed -i "s/database_name_here/${project[j]}/g" $root_path/${project[j]}/wp-config.php
      sed -i "s/username_here/${project[$j]}user/g" $root_path/${project[j]}/wp-config.php
      sed -i "s/password_here/$passwd/g" $root_path/${project[j]}/wp-config.php
      mkdir $root_path/${project[j]}/wp-content/upgrade 

      #Set WP file and folder permission
      chown -R www-data:www-data $root_path/${project[j]}
      find $root_path/${project[j]}/ -type d -exec chmod 750 {} \;
      find $root_path/${project[j]}/ -type f -exec chmod 640 {} \;

      #Set WP Salts
      #grep -A50 'table_prefix' $root_path/${project[j]}/wp-config.php > /tmp/wp-config-temporary
      #sed -i '/**#@/,/$p/d' $root_path/${project[j]}/wp-config.php
      #curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> $root_path/${project[j]}/wp-config.php
      #cat /tmp/wp-config-temporary >> $root_path/${project[j]}/wp-config.php

   elif [ ${project[$j]} = "sosmed" ]; 
   then

      #Restore Database of sosmed website from dump file 
      mysql -u root -e "create user ${project[j]}user@'localhost' identified by '$passwd'; grant all privileges on *.* to ${project[j]}user@'localhost'"
      mysql -u root -e "create database db${project[j]}"
      cd $root_path/${project[j]}
      sed -i "s/devopscilsy/${project[j]}user/g" $root_path/${project[j]}/config.php
      sed -i "s/1234567890/$passwd/g" $root_path/${project[j]}/config.php
      mysql -u root db${project[j]} < dump.sql
  
   fi
done

service apache2 restart
echo $length
