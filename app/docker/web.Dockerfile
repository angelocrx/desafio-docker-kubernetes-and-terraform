FROM nginx:1.27-alpine

# Remove a página padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos estáticos (HTML/JS) da pasta ../web para o Nginx
COPY web/index.html /usr/share/nginx/html/
COPY web/app.js /usr/share/nginx/html/
COPY web/styles.css /usr/share/nginx/html/

# Copia a configuração do Nginx que está na mesma pasta
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]