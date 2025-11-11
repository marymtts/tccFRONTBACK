# 1. Começa com uma imagem oficial do PHP (versão 8.2) com o servidor Apache
FROM php:8.2-apache

# 2. Instala as extensões PHP que seu código precisa
# O seu 'database.php' usa PDO e se conecta a um banco MySQL
# Vamos instalar SÓ as extensões de MySQL (que não precisam de libs extras)
RUN docker-php-ext-install pdo pdo_mysql

# 3. Copia todo o seu código da pasta EC_back para a pasta pública do servidor
# O '.' (ponto) significa "tudo o que está nesta pasta"
# O '/var/www/html/' é o 'htdocs' do Apache dentro do Docker
COPY . /var/www/html/

# 4. (Boa prática) Habilita o 'rewrite' do Apache para URLs amigáveis
RUN a2enmod rewrite