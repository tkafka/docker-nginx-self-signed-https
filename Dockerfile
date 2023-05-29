FROM nginx:mainline

COPY nginx-default.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

ENV REMOTE_URL="http://localhost:8080/"
ENV HTTP_PORT=80
ENV HTTPS_PORT=443
ENV HTTPS_PORT=443
ENV TIMEOUTS_S=10800
ENV CLIENT_MAX_BODY_SIZE=100G
ENV CLIENT_BODY_BUFFER_SIZE=32M

CMD ["/run.sh"]
