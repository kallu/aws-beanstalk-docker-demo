FROM nginx:latest

COPY index.html favicon.ico /usr/share/nginx/html/

EXPOSE 80 

CMD ["nginx", "-g", "daemon off;"]
