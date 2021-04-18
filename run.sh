#!/bin/bash

sed -i -e "s|XX_REMOTE_URL_XX|$REMOTE_URL|g" /etc/nginx/conf.d/default.conf
sed -i -e "s|XX_HTTP_PORT_XX|$HTTP_PORT|g" /etc/nginx/conf.d/default.conf
sed -i -e "s|XX_HTTPS_PORT_XX|$HTTPS_PORT|g" /etc/nginx/conf.d/default.conf

exec nginx -g "daemon off;"
