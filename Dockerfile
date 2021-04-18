FROM nginx:mainline

COPY nginx-default.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

ENV REMOTE_URL="http://localhost:8080/"

CMD ["/run.sh"]
