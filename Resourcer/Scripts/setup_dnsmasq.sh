#!/bin/bash
#
# Script para instalar e configurar o dnsmasq para resolver domínios .test
#

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a configuração do Servidor DNS (dnsmasq)..."
echo "---------------------------------------------------------------------"

# Leitura dos argumentos passados pelo Vagrantfile
if [ -n "$1" ]; then
  eval "$1" # Transforma "DEV_DOMAIN=deusex.io" em uma variável bash
fi

# Variáveis com valores padrão
VM_IP="192.168.56.10"
DEV_DOMAIN=${DEV_DOMAIN:-deusex.io} # Usa o valor passado ou o padrão
DNSMASQ_CONFIG_FILE="/etc/dnsmasq.conf"
DNSMASQ_DEV_DOMAIN_CONFIG_FILE="/etc/dnsmasq.d/${DEV_DOMAIN}.conf"

# 1. Instalar dnsmasq
echo "🔄 Instalando dnsmasq..."
sudo dnf install -y dnsmasq

# 2. Configurar o dnsmasq
echo "🛠️  Configurando o dnsmasq..."

# Cria um backup da configuração original
if [ -f "$DNSMASQ_CONFIG_FILE" ]; then
    sudo cp "$DNSMASQ_CONFIG_FILE" "${DNSMASQ_CONFIG_FILE}.bak"
fi

# Configura o dnsmasq para escutar no IP da VM e no localhost
# e para não ler o /etc/resolv.conf, pois ele mesmo será o resolver.
sudo bash -c "cat > $DNSMASQ_CONFIG_FILE" <<EOF
# --- Configuração Global do dnsmasq ---
# Não ler o resolv.conf do sistema, pois ele mesmo será o resolver.
no-resolv
# Escutar em todas as interfaces de rede
listen-address=::1,127.0.0.1,${VM_IP}
# Interface em que o dnsmasq vai escutar
interface=eth1 # A interface da private_network do Vagrant geralmente é eth1
# Adicionar servidores DNS de upstream (ex: Google, Cloudflare)
server=8.8.8.8
server=1.1.1.1
# --- Fim da Configuração Global ---
EOF

# 3. Configurar o domínio dinâmico
echo "📝 Configurando o domínio de desenvolvimento '.${DEV_DOMAIN}'..."
# Qualquer domínio terminado em .<DEV_DOMAIN> será resolvido para o IP da VM
sudo bash -c "echo 'address=/.${DEV_DOMAIN}/${VM_IP}' > ${DNSMASQ_DEV_DOMAIN_CONFIG_FILE}"

# 4. Configurar a VM para usar o dnsmasq como resolver principal
echo "⚙️  Configurando o resolvedor do sistema (systemd-resolved)..."
# Desabilita o DNS stub do systemd-resolved para que o dnsmasq possa usar a porta 53
# sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
# Reinicia o serviço para aplicar a mudança
# sudo systemctl restart systemd-resolved

# Aponta o /etc/resolv.conf para o localhost, onde o dnsmasq está escutando
sudo bash -c "echo 'nameserver 127.0.0.1' > /etc/resolv.conf"
# Previne que o NetworkManager sobrescreva o resolv.conf
sudo bash -c "echo '[main]' > /etc/NetworkManager/conf.d/99-dns-none.conf"
sudo bash -c "echo 'dns=none' >> /etc/NetworkManager/conf.d/99-dns-none.conf"
sudo systemctl reload NetworkManager


# 5. Habilitar e iniciar o serviço dnsmasq
echo "🚀 Habilitando e iniciando o serviço dnsmasq..."
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

# 6. Abrir a porta do DNS no firewall (se o firewalld estiver ativo)
if systemctl is-active --quiet firewalld; then
    echo "🔥 Configurando o firewall para permitir tráfego DNS..."
    sudo firewall-cmd --add-service=dns --permanent
    sudo firewall-cmd --reload
    echo "✅ Porta 53 (DNS) aberta no firewall."
else
    echo "ℹ️  firewalld não está ativo, pulando configuração de firewall."
fi


echo "---------------------------------------------------------------------"
echo "✅ dnsmasq configurado com sucesso!"
echo "   Todos os domínios *.test agora apontam para ${VM_IP}."
echo "---------------------------------------------------------------------"