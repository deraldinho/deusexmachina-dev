#!/bin/bash
set -e

echo "Configurando firewall UFW e Fail2Ban..."

# Instalar UFW e Fail2Ban
sudo apt-get update -y
sudo apt-get install -y ufw fail2ban

# Resetar regras antigas (cuidado se já tem regras configuradas)
read -p "This will reset all existing UFW rules. Are you sure you want to proceed? (yes/no): " confirm
if [[ "$confirm" == "yes" ]]; then
# Permitir SSH
SSH_PORT=${SSH_PORT:-22}  # Use default port 22 if SSH_PORT is not set
sudo ufw allow ${SSH_PORT}/tcp
	echo "UFW reset canceled."
	exit 1
fi

# Permitir SSH
sudo ufw allow 22/tcp

# Liberar portas de APIs
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 8080/tcp

# Liberar portas de bancos de dados
sudo ufw allow 3306/tcp    # MySQL
sudo ufw allow 5432/tcp    # PostgreSQL
sudo ufw allow 27017/tcp   # MongoDB
sudo ufw allow 6379/tcp    # Redis

# Liberar portas IoT e automação
sudo ufw allow 1883/tcp    # MQTT
sudo ufw allow 8883/tcp    # MQTT Secure
sudo ufw allow 5683/udp    # CoAP (UDP)
sudo ufw allow 502/tcp     # Modbus
sudo ufw allow 123/udp     # NTP

# Liberar outras portas específicas
sudo ufw allow 47808/udp   # BACnet
sudo ufw allow 9000/tcp    # Node-RED (exemplo)
sudo ufw allow 4222/tcp    # NATS
sudo ufw allow 61616/tcp   # ActiveMQ

# Ativar firewall
sudo ufw --force enable
# Configurar fail2ban para SSH
sudo cp ./templates/jail.local /etc/fail2ban/jail.local
EOF

# Reiniciar fail2ban para aplicar regras
sudo systemctl restart fail2ban

echo "Firewall e Fail2Ban configurados!"
maxretry = 3
