#!/bin/sh

#Creates a self-signed CA and certificate and enables https on apache2 with redirection

apache80=/etc/apache2/sites-available/000-default.conf
apache443=/etc/apache2/sites-available/default-ssl.conf

read -p "Server's name or ip:" server_name
read -p "Certificate's password:" certpass

echo "Mise à jour et installation d'openssl" 
apt-get update 
apt-get install openssl -y 

#comment this whole section if you already got a certificate
echo "CA creation"
openssl genrsa -aes256 -out ca.key -passout pass:"$certpass" 4096
#change subj var depending on what you need
openssl req -new -x509 -key ca.key -passin pass:"$certpass" -out ca.cer -days 3650 -sha256 -subj "/C=FR/ST=Aquitaine/L=Bordeaux/O=Organization/OU=IT department/CN=Common Name CA"
echo "certificate creation"
#certificate's key
openssl genrsa -aes256 -out cert.key -passout pass:"$certpass" 4096
#request
openssl req -new -key cert.key -out cert.req -passin pass:"$certpass" -subj "/C=FR/ST=Aquitaine/L=Bordeaux/O=Organization/OU=IT department/CN=Common Name"
openssl x509 -req -in cert.req -out cert.cer -CA ca.cer -CAkey ca.key -passin pass:"$certpass" -sha256 -CAcreateserial
#remove password
openssl rsa -in cert.key -out cert.key -passin pass:"$certpass" 
#suppression de la request déplacement du  certificat dans le bon repertoire
rm cert.req
mkdir -p /etc/apache2/certificats
chown www-data /etc/apache2/certificats
mv cert.key cert.cer /etc/apache2/certificats
chmod 710 /etc/apache2/certificats
chown root:www-data /etc/apache2/certificats/*
chmod 640 /etc/apache2/certificats/*
mkdir /etc/apache2/CA
mv ca.* /etc/apache2/CA
mv cert.key.bak /etc/apache2/certificats

rm $apache443
touch $apache443
#config de default-ssl.conf
echo '<IfModule mod_ssl.c>' >> $apache443
echo '<VirtualHost _default_:443>' >> $apache443
echo '	ServerAdmin webmaster@localhost' >> $apache443
echo '	DocumentRoot /var/www/html' >> $apache443
echo '	<Directory />' >> $apache443
echo '		Options FollowSymLinks' >> $apache443
echo '		AllowOverride None' >> $apache443
echo '	</Directory>' >> $apache443
echo '	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/' >> $apache443
echo '	<Directory "/usr/lib/cgi-bin">' >> $apache443
echo '		AllowOverride None' >> $apache443
echo '		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch' >> $apache443
echo '		Order allow,deny' >> $apache443
echo '		Allow from all' >> $apache443
echo '	</Directory>' >> $apache443
echo '	LogLevel info ssl:warn' >> $apache443
echo '	ErrorLog ${APACHE_LOG_DIR}/error.log' >> $apache443
echo '	CustomLog ${APACHE_LOG_DIR}/access.log combined' >> $apache443
echo ' ' >> $apache443
echo '	SSLEngine on' >> $apache443
echo '	SSLCertificateFile	/etc/apache2/certificats/cert.cer' >> $apache443
echo '	SSLCertificateKeyFile /etc/apache2/certificats/cert.key' >> $apache443
echo ' ' >> $apache443
echo '	</VirtualHost>' >> $apache443
echo '</IfModule>' >> $apache443

#redirection
rm $apache80
touch $apache80
echo '<VirtualHost *:80>' >> $apache80
echo '	ServerAdmin webmaster@localhost' >> $apache80
echo '	DocumentRoot /var/www/html' >> $apache80
echo '	ErrorLog ${APACHE_LOG_DIR}/error.log' >> $apache80
echo '	CustomLog ${APACHE_LOG_DIR}/access.log combined' >> $apache80
echo ' ' >> $apache80
echo 'RewriteEngine On' >> $apache80
echo 'RewriteCond %{HTTPS} off' >> $apache80
#change 
echo "RewriteRule (.*) https://$server_name/$1 [R,L]" >> $apache80
echo '</VirtualHost>' >> $apache80

#activation des modules apache
a2enmod ssl
a2ensite default-ssl
a2enmod rewrite
service apache2 restart 
