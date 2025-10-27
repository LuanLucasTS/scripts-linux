#!/bin/bash
# Script para instalar Zabbix Server no AlmaLinux 8

set -e

# Variáveis que você pode ajustar
DB_TYPE="mysql"           # mysql ou postgresql
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="ts#lad@2020"     # troque para uma senha segura
DB_HOST="localhost"
TIMEZONE="America/Campo_Grande"
WEB_SERVER="apache"       # apache ou nginx

# Instala Zabbix server, frontend e agente
if [ "$DB_TYPE" = "mysql" ]; then
    dnf -y install zabbix-server-mysql zabbix-web-mysql zabbix-${WEB_SERVER}-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
else
    dnf -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-${WEB_SERVER}-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
fi

# Cria banco de dados e usuário
if [ "$DB_TYPE" = "mysql" ]; then
    mysql -uroot <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';
FLUSH PRIVILEGES;
EOF

    # Importa schema inicial
    zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME}

elif [ "$DB_TYPE" = "postgresql" ]; then
    sudo -u postgres psql <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

    # Importa schema
    zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u postgres psql ${DB_NAME}
fi

# Ajusta configuração do Zabbix server
ZBX_CONF="/etc/zabbix/zabbix_server.conf"

sed -i "s/# DBHost=localhost/DBHost=${DB_HOST}/" ${ZBX_CONF}
sed -i "s/# DBName=zabbix/DBName=${DB_NAME}/" ${ZBX_CONF}
sed -i "s/# DBUser=zabbix/DBUser=${DB_USER}/" ${ZBX_CONF}
# substituir DBPassword
if grep -q "^# DBPassword=" ${ZBX_CONF}; then
    sed -i "s|^# DBPassword=.*|DBPassword=${DB_PASS}|" ${ZBX_CONF}
else
    echo "DBPassword=${DB_PASS}" >> ${ZBX_CONF}
fi

# Ajusta timezone no frontend (PHP)
PHP_FPM_CONF="/etc/php-fpm.d/zabbix.conf"
if [ -f "${PHP_FPM_CONF}" ]; then
    # Descomenta linha timezone, ajusta
    sed -i "s/# *php_value\[date.timezone\] =.*/php_value[date.timezone] = ${TIMEZONE}/" ${PHP_FPM_CONF}
else
    echo "php_value[date.timezone] = ${TIMEZONE}" >> ${PHP_FPM_CONF}
fi

# Ajustes SELinux (opcional, define permissivo)
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config

# Ajusta firewall
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Inicia e habilita serviços
systemctl enable --now zabbix-server zabbix-agent httpd php-fpm

if [ "$WEB_SERVER" = "nginx" ]; then
    systemctl enable --now nginx
fi

echo "Instalação do Zabbix concluída!"
echo "Acesse via browser: http://<IP-do-servidor>/zabbix"
echo "Usuário: Admin / senha padrão: zabbix"
