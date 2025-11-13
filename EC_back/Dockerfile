# 1. Começa com uma imagem oficial do PHP (versão 8.2) com o servidor Apache
FROM php:8.2-apache

# 2. Instala as extensões PHP (PDO e MySQL)
RUN docker-php-ext-install pdo pdo_mysql

# 3. Habilita o 'mod_rewrite' (para .htaccess)
RUN a2enmod rewrite

# 4. Corrige as permissões do Apache (o que já fizemos)
RUN echo "<Directory /var/www/html>\n    Options Indexes FollowSymLinks\n    AllowOverride All\n    Require all granted\n</Directory>" > /etc/apache2/sites-available/000-default.conf

# 5. --- (NOVO!) AUMENTA OS LIMITES DE UPLOAD DO PHP ---
# Esta linha cria um arquivo .ini no servidor para permitir uploads de até 20MB
RUN echo "file_uploads = On\npost_max_size = 20M\nupload_max_filesize = 20M" > /usr/local/etc/php/conf.d/uploads.ini

# 6. Copia todo o seu código para o servidor
COPY . /var/www/html/

# 7. --- (NOVO!) CRIA A PASTA DE UPLOADS E DÁ PERMISSÃO ---
# Cria a estrutura de pastas (mesmo que ela já exista)
RUN mkdir -p /var/www/html/uploads/eventos
# Dá ao servidor Apache (www-data) a "posse" da pasta de uploads
RUN chown -R www-data:www-data /var/www/html/uploads