#!/bin/bash

echo '[*] Creating compose file'

cat > ./docker-compose.nginx.yml <<EOF
services:
    nginx-proxy:
        image: nginx:latest
        ports:
            - "80:80"
            - "443:443"
        volumes:
            - ./nginx-proxy/default.conf:/etc/nginx/conf.d/default.conf
            - ./nginx-proxy/html:/usr/share/nginx/html
            - ./nginx-proxy/base_nginx.conf:/etc/nginx/nginx.conf
            ### SSL
            - ./nginx-proxy/letsencrypt:/etc/letsencrypt
            ### Cert auth
            #- ./nginx-proxy/cert_auth/ca.crt:/etc/ssl/ca.crt
            ### Enable to add favicon
            #- ./nginx-proxy/favicon.ico:/usr/share/nginx/html/favicon.ico
EOF

echo '[*] Create folder struct'

mkdir -p 'nginx-proxy/html'
mkdir -p 'nginx-proxy/letsencrypt/live/cacerts'
mkdir -p 'nginx-proxy/cert_auth'

echo '[*] Creating config files'

cat > ./nginx-proxy/default.conf <<EOF
server {
    listen 80;
    location ~* {
       return 301 https://\$host\$request_uri;
    }
}

server {
   listen 443 ssl;
   server_name nginx-proxy;

   ### Enable for SSL
   ssl_certificate /etc/letsencrypt/live/cacerts/ca.pem;
   ssl_certificate_key /etc/letsencrypt/live/cacerts/ca.key;
   include /etc/letsencrypt/options-ssl-nginx.conf;
   ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

   ### Enable for cert auth
   #ssl_client_certificate /etc/ssl/ca.crt;
   #ssl_verify_client optional;

   ### Error logging
   #error_log /tmp/err_log.txt debug;

   location = /favicon.ico {
        alias /usr/share/nginx/html/favicon.ico;
   }

   ### Enable for prometheus-logs
   #location /nginx-status {
   #    stub_status;
   #    allow 127.0.0.1;
   #    deny all;
   #}

   location ~* {

       ### Enable for cert auth
       #if (\$ssl_client_verify != SUCCESS) {
       #   return 403;
       #}

       proxy_pass http://127.0.0.1:1337;
       proxy_set_header Host \$host;
       proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto \$scheme;
       proxy_set_header X-Real-IP \$remote_addr;
   }

}

EOF

cat > ./nginx-proxy/base_nginx.conf <<EOF

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}


EOF

echo '[*] Creating SSL configs'

cat > ./nginx-proxy/letsencrypt/options-ssl-nginx.conf <<EOF
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF

echo '[*] Generating DHParams'
openssl dhparam -out ./nginx-proxy/letsencrypt/ssl-dhparams.pem 2048


openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx-proxy/letsencrypt/live/cacerts/ca.key -out ./nginx-proxy/letsencrypt/live/cacerts/ca.pem
echo '[*] Done!'
