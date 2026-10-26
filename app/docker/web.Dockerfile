FROM nginx:alpine

# Remove a página padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos estáticos (HTML/JS) da pasta ../web para o Nginx
COPY ../web/ /usr/share/nginx/html/

# Copia a configuração do Nginx que está na mesma pasta
COPY ../docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]