#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🛡️  Iniciando a configuração do Firewall (Firewalld) e Fail2Ban..."
echo "---------------------------------------------------------------------"

# Variável para a porta SSH. Pode ser sobrescrita por uma variável de ambiente se definida.
SSH_PORT=${SSH_PORT:-22}

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do DNF (pode ser rápido se já atualizado)..."
sudo dnf makecache -q

# 2. Instalar Firewalld e Fail2Ban
echo "🛠️  Instalando Firewalld e Fail2Ban..."
if rpm -q firewalld &> /dev/null && rpm -q fail2ban &> /dev/null; then
    echo "✅ Firewalld e Fail2Ban já estão instalados."
else
    sudo dnf install -y firewalld fail2ban
    echo "✅ Firewalld e Fail2Ban instalados."
fi

# 3. Configurar Firewalld
echo "🔥 Configurando regras do Firewalld..."

# Habilitar e iniciar o serviço Firewalld
echo "   Habilitando e iniciando o serviço Firewalld..."
sudo systemctl enable firewalld
sudo systemctl start firewalld

echo "   Habilitando e iniciando o serviço SSH..."
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Definir zona padrão (public é comum)
echo "   Definindo zona padrão para 'public'."
sudo firewall-cmd --set-default-zone=public

# Permitir conexões SSH
echo "   Permitindo conexões SSH na porta ${SSH_PORT}/tcp."
sudo firewall-cmd --zone=public --add-port=${SSH_PORT}/tcp

# Listas de portas a serem abertas
declare -a API_PORTS=(80 443 3000 5000 8000 8080)
declare -a DB_PORTS=(3306 5432 27017 6379) # MySQL, PostgreSQL, MongoDB, Redis

echo "   Liberando portas para APIs e Web (TCP): ${API_PORTS[*]}"
for port in "${API_PORTS[@]}"; do
    sudo firewall-cmd --zone=public --add-port=${port}/tcp
done

echo "   Liberando portas para Bancos de Dados (TCP): ${DB_PORTS[*]}"
for port in "${DB_PORTS[@]}"; do
    sudo firewall-cmd --zone=public --add-port=${port}/tcp
done

echo "   Liberando portas para IoT e Automação:"
sudo firewall-cmd --zone=public --add-port=1883/tcp     # MQTT
sudo firewall-cmd --zone=public --add-port=8883/tcp     # MQTT Secure
sudo firewall-cmd --zone=public --add-port=5683/udp     # CoAP (UDP)
sudo firewall-cmd --zone=public --add-port=502/tcp      # Modbus

echo "   Liberando outras portas específicas (conforme script original):"
sudo firewall-cmd --zone=public --add-port=47808/udp    # BACnet
sudo firewall-cmd --zone=public --add-port=9000/tcp     # Exemplo: Node-RED
sudo firewall-cmd --zone=public --add-port=4222/tcp     # NATS
sudo firewall-cmd --zone=public --add-port=61616/tcp    # ActiveMQ
sudo firewall-cmd --zone=public --add-port=19999/tcp    # Netdata

# Recarregar Firewalld para aplicar as regras
echo "   Tornando as regras permanentes..."
sudo firewall-cmd --runtime-to-permanent

echo "   Status atual do Firewalld:"
sudo firewall-cmd --list-all

# 4. Configurar Fail2Ban
echo "🛡️  Configurando Fail2Ban..."
JAIL_LOCAL_FILE="/etc/fail2ban/jail.local"

if [ -f "${JAIL_LOCAL_FILE}" ]; then
    echo "   O arquivo ${JAIL_LOCAL_FILE} já existe."
    echo "   Verifique o conteúdo de ${JAIL_LOCAL_FILE} para garantir que a proteção SSH está configurada como desejado."
else
    echo "   Criando configuração básica em ${JAIL_LOCAL_FILE} para proteção SSH na porta ${SSH_PORT}."
    sudo bash -c "cat > ${JAIL_LOCAL_FILE}" << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 3
bantime = 2h
EOF
    echo "   Configuração básica para SSH criada em ${JAIL_LOCAL_FILE}."
fi

echo "🔄 Habilitando e reiniciando o serviço Fail2Ban para aplicar as configurações..."
if sudo systemctl is-enabled --quiet fail2ban.service; then
    echo "   Serviço Fail2Ban já estava habilitado."
else
    sudo systemctl enable fail2ban.service
    echo "   Serviço Fail2Ban habilitado."
fi
sudo systemctl restart fail2ban.service
echo "   Serviço Fail2Ban reiniciado."

echo "---------------------------------------------------------------------"
echo "✅ Firewall (Firewalld) e Fail2Ban configurados."
echo "---------------------------------------------------------------------"