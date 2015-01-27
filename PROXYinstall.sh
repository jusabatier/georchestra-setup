#!/bin/bash

apt-get -y install nginx php5-fpm php5-pgsql

sed -i -e "s/worker_processes 4;/worker_processes $(nproc);/g" /etc/nginx/nginx.conf
sed -i -e "s/worker_connections 768;/worker_connections $(ulimit -n);/g" /etc/nginx/nginx.conf
sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini

update-rc.d nginx defaults
update-rc.d php5-fpm defaults

cat <<EOT >> /etc/nginx/sites-available/georchestra
server {
    listen          80;
    server_name     $SERVER_NAME;

    error_log /usr/share/nginx/www/georchestra/logs/error.log warn;
    access_log /usr/share/nginx/www/georchestra/logs/access.log;

    ## Redirige le HTTP vers le HTTPS ##
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
        listen 443;
        server_name $SERVER_NAME;

        index           index.php;
        root            /usr/share/nginx/www/georchestra/htdocs;

        include /usr/share/nginx/www/georchestra/conf/*.conf;
        error_log /usr/share/nginx/www/georchestra/logs/error.log warn;
        access_log /usr/share/nginx/www/georchestra/logs/access.log;

        ssl on;
        ssl_certificate /usr/share/nginx/www/georchestra/ssl/georchestra.crt;
        ssl_certificate_key /usr/share/nginx/www/georchestra/ssl/georchestra-unprotected.key;

        ssl_session_timeout 5m;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers 'AES128+EECDH:AES128+EDH:!aNULL';
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;

        location / {
			try_files \$uri \$uri/ /index.html;
        }

        location ~ \.php$ {
			include fastcgi_params;
			fastcgi_split_path_info ^(.+\.php)(/.+)$;
			fastcgi_pass unix:/var/run/php5-fpm.sock;
			fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;   
        }
}
EOT

rm /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/georchestra /etc/nginx/sites-enabled/georchestra

mkdir -p /usr/share/nginx/www/georchestra/htdocs
mkdir /usr/share/nginx/www/georchestra/conf 
mkdir /usr/share/nginx/www/georchestra/logs 
mkdir /usr/share/nginx/www/georchestra/ssl

chgrp www-data /usr/share/nginx/www/georchestra/logs/
chmod g+w /usr/share/nginx/www/georchestra/logs/
git clone https://github.com/georchestra/htdocs.git /usr/share/nginx/www/georchestra/htdocs

cat <<EOT >> /usr/share/nginx/www/georchestra/conf/global.conf
location  /casfailed.jsp {
	proxy_pass   http://localhost:8080;
	proxy_redirect     off;
	
	proxy_set_header   Host             \$host;
	proxy_set_header   X-Real-IP        \$remote_addr;
	proxy_set_header   X-Forwarded-For  \$proxy_add_x_forwarded_for;
	proxy_max_temp_file_size 0;

	client_max_body_size       20m;
	client_body_buffer_size    128k;

	proxy_connect_timeout      90;
	proxy_send_timeout         90;
	proxy_read_timeout         90;

	proxy_buffer_size          4k;
	proxy_buffers              4 32k;
	proxy_busy_buffers_size    64k;
	proxy_temp_file_write_size 64k;
}

location ~ ^/(analytics|cas|catalogapp|downloadform|mapfishapp|proxy|header|ldapadmin|_static|extractorapp|geoserver|geofence|geowebcache|geonetwork|gateway|testPage|j_spring_cas_security_check|j_spring_security_logout)(/?).*$ {
		proxy_pass         http://localhost:8080\$request_uri;
		proxy_redirect     off;

		proxy_set_header   Host             \$host;
		proxy_set_header   X-Real-IP        \$remote_addr;
		proxy_set_header   X-Forwarded-For  \$proxy_add_x_forwarded_for;
		proxy_max_temp_file_size 0;

		client_max_body_size       20m;
		client_body_buffer_size    128k;

		proxy_connect_timeout      90;
		proxy_send_timeout         90;
		proxy_read_timeout         90;

		proxy_buffer_size          4k;
		proxy_buffers              4 32k;
		proxy_busy_buffers_size    64k;
		proxy_temp_file_write_size 64k;
}

# some basic rewrites
rewrite ^/proxy$ /proxy/ permanent;
rewrite ^/geofence$ /geofence/ permanent;
rewrite ^/analytics$ /analytics/ permanent;
EOT

openssl genrsa -des3 -passout pass:$SSL_PASSPHRASE -out /usr/share/nginx/www/georchestra/ssl/georchestra.key 2048
chmod 400 /usr/share/nginx/www/georchestra/ssl/georchestra.key
openssl req -key /usr/share/nginx/www/georchestra/ssl/georchestra.key -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_LOCALITY/O=$SSL_ORGANISATION/OU=$SSL_UNIT/CN=$SERVER_NAME" -newkey rsa:2048 -sha256 -out /usr/share/nginx/www/georchestra/ssl/georchestra.csr -passin pass:$SSL_PASSPHRASE
openssl rsa -in /usr/share/nginx/www/georchestra/ssl/georchestra.key -out /usr/share/nginx/www/georchestra/ssl/georchestra-unprotected.key -passin pass:$SSL_PASSPHRASE
openssl x509 -req -days 365 -in /usr/share/nginx/www/georchestra/ssl/georchestra.csr -signkey /usr/share/nginx/www/georchestra/ssl/georchestra.key -out /usr/share/nginx/www/georchestra/ssl/georchestra.crt -passin pass:$SSL_PASSPHRASE

service nginx start
service php5-fpm start