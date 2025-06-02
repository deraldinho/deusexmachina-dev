#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🛡️  Iniciando a configuração do Firewall (UFW) e Fail2Ban..."
echo "---------------------------------------------------------------------"

# Variável para a porta SSH. Pode ser sobrescrita por uma variável de ambiente se definida.
SSH_PORT=${SSH_PORT:-22}

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do APT (pode ser rápido se já atualizado)..."
sudo apt-get update -y -qq
<<<<<<< HEAD


# Variável para a porta SSH. Pode ser sobrescrita por uma variável de ambiente se definida.
SSH_PORT=${SSH_PORT:-22}

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do APT (pode ser rápido se já atualizado)..."
sudo apt-get update -y
=======
>>>>>>> 58e387c (melhoria nos SH)

# 2. Instalar UFW e Fail2Ban
echo "🛠️  Instalando UFW e Fail2Ban..."
if dpkg -s ufw &> /dev/null && dpkg -s fail2ban &> /dev/null; then
    echo "✅ UFW e Fail2Ban já estão instalados."
else
    sudo apt-get install -y ufw fail2ban
    echo "✅ UFW e Fail2Ban instalados."
fi

# 3. Configurar UFW (Uncomplicated Firewall)
echo "🔥 Configurando regras do UFW..."

# Opcional: Resetar UFW para um estado limpo.
# Útil para garantir um estado conhecido no provisionamento inicial.
# CUIDADO: Isso remove TODAS as regras existentes. Descomente se necessário.
# echo "   ⚠️  Resetando todas as regras do UFW existentes..."
# sudo ufw --force reset # O --force é para evitar prompts

# Definir políticas padrão: negar tudo que entra, permitir tudo que sai.
# A política FORWARD é geralmente DROP por padrão em /etc/default/ufw.
echo "   Definindo políticas padrão do UFW: deny incoming, allow outgoing."
<<<<<<< HEAD
sudo ufw default deny incoming
sudo ufw default allow outgoing
# A linha 'sudo ufw default deny forwarded' foi removida pois é uma sintaxe inválida.
# Para controlar o tráfego encaminhado, edite /etc/default/ufw e defina DEFAULT_FORWARD_POLICY="DROP" (ou ACCEPT/REJECT)
# e depois use 'sudo ufw reload'. A política padrão já costuma ser segura (DROP).
# Definir políticas padrão: negar tudo que entra, permitir tudo que sai, negar encaminhamento.
echo "   Definindo políticas padrão do UFW: deny incoming, allow outgoing, deny forwarded."
=======
>>>>>>> 58e387c (melhoria nos SH)
sudo ufw default deny incoming
sudo ufw default allow outgoing
# A linha 'sudo ufw default deny forwarded' foi removida pois é uma sintaxe inválida.
# Para controlar o tráfego encaminhado, edite /etc/default/ufw e defina DEFAULT_FORWARD_POLICY="DROP" (ou ACCEPT/REJECT)
# e depois use 'sudo ufw reload'. A política padrão já costuma ser segura (DROP).

# Permitir tráfego na interface de loopback (essencial para muitos serviços locais)
echo "   Permitindo tráfego na interface de loopback (lo)."
sudo ufw allow in on lo
sudo ufw allow out on lo

# Permitir conexões SSH
echo "   Permitindo conexões SSH na porta ${SSH_PORT}/tcp."
sudo ufw allow "${SSH_PORT}/tcp"
# Para maior segurança contra ataques de força bruta na porta SSH, você pode usar 'limit'
# sudo ufw limit "${SSH_PORT}/tcp" # Isso limitará novas conexões se houver muitas tentativas em pouco tempo.

# Listas de portas a serem abertas
declare -a API_PORTS=(80 443 3000 5000 8000 8080)
declare -a DB_PORTS=(3306 5432 27017 6379) # MySQL, PostgreSQL, MongoDB, Redis

echo "   Liberando portas para APIs e Web (TCP): ${API_PORTS[*]}"
for port in "${API_PORTS[@]}"; do
    sudo ufw allow "${port}/tcp"
done

echo "   Liberando portas para Bancos de Dados (TCP): ${DB_PORTS[*]}"
for port in "${DB_PORTS[@]}"; do
    sudo ufw allow "${port}/tcp"
done

echo "   Liberando portas para IoT e Automação:"
sudo ufw allow 1883/tcp    # MQTT
sudo ufw allow 8883/tcp    # MQTT Secure
sudo ufw allow 5683/udp    # CoAP (UDP)
sudo ufw allow 502/tcp     # Modbus
# sudo ufw allow 123/udp     # NTP - O cliente NTP geralmente usa portas altas para origem.
                            # Abrir 123/udp na entrada só é necessário se a VM for um servidor NTP.

echo "   Liberando outras portas específicas (conforme script original):"
sudo ufw allow 47808/udp   # BACnet
sudo ufw allow 9000/tcp    # Exemplo: Node-RED (se exposto diretamente pela VM)
sudo ufw allow 4222/tcp    # NATS
sudo ufw allow 61616/tcp   # ActiveMQ
# Adicionada porta do Netdata, se não estiver coberta pelas API_PORTS
if [[ ! " ${API_PORTS[@]} " =~ " 19999 " ]]; then
    echo "   Liberando porta para Netdata (19999/tcp)."
    sudo ufw allow 19999/tcp
fi

<<<<<<< HEAD

# Habilitar UFW
if sudo ufw status | grep -q "Status: active"; then
    echo "   UFW já está ativo. Recarregando regras para aplicar quaisquer alterações..."
    sudo ufw reload
else
    echo "   Habilitando UFW (pode desconectar brevemente se estiver via SSH e a regra não estiver correta)..."
    sudo ufw --force enable # O --force evita o prompt de confirmação.
fi
echo "   Status atual do UFW:"
sudo ufw status verbose

# 4. Configurar Fail2Ban
echo "🛡️  Configurando Fail2Ban..."
=======
>>>>>>> 58e387c (melhoria nos SH)

# Habilitar UFW
if sudo ufw status | grep -q "Status: active"; then
    echo "   UFW já está ativo. Recarregando regras para aplicar quaisquer alterações..."
    sudo ufw reload
else
    echo "   Habilitando UFW (pode desconectar brevemente se estiver via SSH e a regra não estiver correta)..."
    sudo ufw --force enable # O --force evita o prompt de confirmação.
fi
echo "   Status atual do UFW:"
sudo ufw status verbose

# 4. Configurar Fail2Ban
echo "🛡️  Configurando Fail2Ban..."

# Criar um arquivo jail.local com configurações personalizadas para SSH.
# É uma prática recomendada não editar o jail.conf diretamente.
JAIL_LOCAL_FILE="/etc/fail2ban/jail.local"

if [ -f "${JAIL_LOCAL_FILE}" ]; then
    echo "   O arquivo ${JAIL_LOCAL_FILE} já existe."
    # Poderíamos verificar se a seção [sshd] está configurada e, se não, adicioná-la.
    # Por simplicidade, vamos assumir que se existe, está correto ou será gerenciado manualmente.
    # Se quiser garantir que sua config seja aplicada, pode deletar e recriar, ou usar sed/awk.
    echo "   Verifique o conteúdo de ${JAIL_LOCAL_FILE} para garantir que a proteção SSH está configurada como desejado."
else
    echo "   Criando configuração básica em ${JAIL_LOCAL_FILE} para proteção SSH na porta ${SSH_PORT}."
    sudo bash -c "cat > ${JAIL_LOCAL_FILE}" << EOF
[DEFAULT]
# Tempo de banimento em segundos. 1h = 3600s.
bantime = 1h
# Janela de tempo para detecção de falhas.
findtime = 10m
# Número de falhas antes de banir.
maxretry = 5

[sshd]
enabled = true
port = ${SSH_PORT}
# Para aumentar o rigor para SSH:
maxretry = 3
bantime = 2h
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 58e387c (melhoria nos SH)
# Se quiser usar o UFW para banir (recomendado):
# action = ufw[name=SSH, port=${SSH_PORT}, protocol=tcp]
# Se a sua versão do fail2ban for mais antiga, pode ser:
# action = ufw
<<<<<<< HEAD
=======
# Se quiser usar o UFW para banir:
# action = ufw[name=sshd, port=${SSH_PORT}, protocol=tcp]
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
=======
>>>>>>> 58e387c (melhoria nos SH)
EOF
    echo "   Configuração básica para SSH criada em ${JAIL_LOCAL_FILE}."
fi

# Habilitar e reiniciar o serviço Fail2Ban
echo "🔄 Habilitando e reiniciando o serviço Fail2Ban para aplicar as configurações..."
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 58e387c (melhoria nos SH)
# É importante que o fail2ban seja reiniciado APÓS o ufw estar ativo e configurado.
if sudo systemctl is-enabled --quiet fail2ban.service; then
    echo "   Serviço Fail2Ban já estava habilitado."
else
    sudo systemctl enable fail2ban.service
    echo "   Serviço Fail2Ban habilitado."
fi
<<<<<<< HEAD
sudo systemctl restart fail2ban.service
echo "   Serviço Fail2Ban reiniciado."

=======
sudo systemctl enable fail2ban.service
sudo systemctl restart fail2ban.service
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
=======
sudo systemctl restart fail2ban.service
echo "   Serviço Fail2Ban reiniciado."

>>>>>>> 58e387c (melhoria nos SH)

# Comandos úteis para verificar o status (descomente para debug manual):
# echo "   Status do serviço Fail2Ban:"
# sudo systemctl status fail2ban.service --no-pager -l
# echo "   Status da jail 'sshd' no Fail2Ban:"
# sudo fail2ban-client status sshd

echo "---------------------------------------------------------------------"
echo "✅ Firewall (UFW) e Fail2Ban configurados."
<<<<<<< HEAD
<<<<<<< HEAD
echo "---------------------------------------------------------------------"
=======
echo "---------------------------------------------------------------------"
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
=======
echo "---------------------------------------------------------------------"
>>>>>>> 58e387c (melhoria nos SH)
