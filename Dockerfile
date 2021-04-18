FROM nginx:mainline

COPY nginx-default.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

ENV REMOTE_URL="http://localhost:8080/"
ENV HTTP_PORT=80
ENV HTTPS_PORT=443

CMD ["/run.sh"]
