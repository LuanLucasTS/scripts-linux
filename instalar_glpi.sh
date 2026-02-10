#!/bin/bash
# Script de instalação do GLPI no Rocky Linux 8.10
# Autor: Eudes Paz
# Data: 2025-08-20

# ===== Variáveis =====
GLPI_VERSION="10.0.15"
DB_NAME="glpi"
DB_USER="glpiuser"
DB_PASS="S3nh@F0rt3254"
DOMAIN="glpi.seudominio.com"

# ===== Atualização do sistema =====
echo "[INFO] Atualizando pacotes..."
dnf update -y
dnf install -y epel-release wget unzip

# ===== Instalação do Apache e PHP =====
echo "[INFO] Instalando Apache e PHP 8.1..."
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y
dnf module reset php -y
dnf module enable php:remi-8.1 -y
dnf install -y httpd php php-cli php-common php-mysqlnd php-gd php-xml \
php-mbstring php-curl php-ldap php-zip php-bz2 php-intl php-opcache unzip

# ===== Instalação do MariaDB =====
echo "[INFO] Instalando MariaDB..."
dnf install -y mariadb-server mariadb
systemctl enable --now mariadb

# ===== Configuração do Banco de Dados =====
echo "[INFO] Criando banco e usuário do GLPI..."
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# ===== Download do GLPI =====
echo "[INFO] Baixando GLPI ${GLPI_VERSION}..."
cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz
tar -xvzf glpi-${GLPI_VERSION}.tgz
mv glpi /var/www/html/

# ===== Permissões =====
echo "[INFO] Ajustando permissões..."
chown -R apache:apache /var/www/html/glpi
chmod -R 755 /var/www/html/glpi

# ===== Configuração do Apache =====
echo "[INFO] Configurando Apache..."
cat <<EOF > /etc/httpd/conf.d/glpi.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/glpi
    ServerName ${DOMAIN}

    <Directory /var/www/html/glpi>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/glpi_error.log
    CustomLog /var/log/httpd/glpi_access.log combined
</VirtualHost>
EOF

systemctl enable --now httpd
systemctl restart httpd

# ===== SELinux & Firewall =====
echo "[INFO] Ajustando SELinux e Firewall..."
setsebool -P httpd_can_network_connect on
chcon -R -t httpd_sys_rw_content_t /var/www/html/glpi

firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# ===== Fim =====
echo "==================================================="
echo " GLPI ${GLPI_VERSION} instalado com sucesso!"
echo " Acesse: http://$(hostname -I | awk '{print $1}')"
echo " Usuário glpi: glpi"
echo " Senha: glpi: glpi"
echo " Banco de dados: ${DB_NAME}"
echo " Usuário DB: ${DB_USER}"
echo " Senha DB: ${DB_PASS}"
echo "==================================================="
