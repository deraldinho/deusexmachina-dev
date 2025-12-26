#!/bin/bash
#
# Script para instalar e configurar o Nginx como reverse proxy
# para os serviços internos da VM DeuxExMachina, associado ao domínio configurado.
#

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a instalação e configuração do Nginx como reverse proxy..."
echo "---------------------------------------------------------------------"

# Leitura dos argumentos passados pelo Vagrantfile
if [ -n "$1" ]; then
  eval "$1" # Transforma "DEV_DOMAIN=deusex.io" em uma variável bash
fi

# Variáveis com valores padrão
VM_IP="192.168.56.10"
DEV_DOMAIN=${DEV_DOMAIN:-deusex.io} # Usa o valor passado ou o padrão

# 1. Instalar Nginx
echo "🔄 Instalando Nginx..."
sudo dnf install -y nginx

# 2. Configurar Nginx como reverse proxy
echo "🛠️  Configurando Nginx como reverse proxy..."

# Backup da configuração padrão
if [ -f "/etc/nginx/nginx.conf" ]; then
    sudo cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.bak"
fi

# Configuração principal do Nginx
sudo bash -c "cat > /etc/nginx/nginx.conf" <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Configurações de segurança básicas
    server_tokens off;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Configuração de upstreams para os serviços internos
    upstream brain_input_processor {
        server localhost:5000;
    }

    upstream processing_brain_1 {
        server localhost:8000;
    }

    upstream processing_brain_2 {
        server localhost:8080;
    }

    upstream storage_brain {
        server localhost:3000;
    }

    upstream output_brain {
        server localhost:4000;
    }

    upstream mqtt_broker {
        server localhost:1883;
    }

    # Servidor principal para o domínio
    server {
        listen 80;
        server_name ${DEV_DOMAIN} *.${DEV_DOMAIN};
        root /usr/share/nginx/html;

        # Logs específicos para o domínio
        access_log /var/log/nginx/${DEV_DOMAIN}.access.log main;
        error_log /var/log/nginx/${DEV_DOMAIN}.error.log;

        # Página de status padrão
        location / {
            try_files \$uri \$uri/ =404;
        }

        # Proxy para brain_input_processor (API principal)
        location /api/ {
            proxy_pass http://brain_input_processor/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy para processing_brain_1
        location /brain1/ {
            proxy_pass http://processing_brain_1/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy para processing_brain_2
        location /brain2/ {
            proxy_pass http://processing_brain_2/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy para storage_brain
        location /storage/ {
            proxy_pass http://storage_brain/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy para output_brain
        location /output/ {
            proxy_pass http://output_brain/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # WebSocket proxy para MQTT (se necessário para interfaces web)
        location /mqtt {
            proxy_pass http://mqtt_broker;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }

    # Servidor catch-all para outros domínios (opcional)
    server {
        listen 80 default_server;
        server_name _;
        return 444;
    }
}
EOF

# 3. Criar diretório para logs se não existir
sudo mkdir -p /var/log/nginx

# 4. Testar configuração do Nginx
echo "🔍 Testando configuração do Nginx..."
sudo nginx -t

# 5. Habilitar e iniciar o serviço Nginx
echo "🚀 Habilitando e iniciando o serviço Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# 6. Configurar firewall para permitir HTTP (porta 80)
if systemctl is-active --quiet firewalld; then
    echo "🔥 Configurando firewall para permitir tráfego HTTP..."
    sudo firewall-cmd --add-service=http --permanent
    sudo firewall-cmd --reload
    echo "✅ Porta 80 (HTTP) aberta no firewall."
else
    echo "ℹ️  firewalld não está ativo, pulando configuração de firewall."
fi

echo "---------------------------------------------------------------------"
echo "✅ Nginx configurado como reverse proxy com sucesso!"
echo "   Domínio: *.${DEV_DOMAIN}"
echo "   Porta: 80"
echo "   Acesse: http://${DEV_DOMAIN}/ (ou http://*.${DEV_DOMAIN}/)"
echo "---------------------------------------------------------------------"
