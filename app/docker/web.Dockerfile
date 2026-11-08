FROM nginx:1.27-alpine

RUN rm -rf /usr/share/nginx/html/*

COPY web/index.html web/app.js web/styles.css /usr/share/nginx/html/

COPY web/nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 8080
