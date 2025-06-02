#!/bin/bash
set -e

echo "Instalando ferramentas de monitoramento..."

# Atualizar pacotes
sudo apt-get update -y

# Instalar htop e glances
sudo apt-get install -y htop python3-pip
sudo pip3 install glances

# Instalar Netdata (via script oficial)
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-telemetry

# Ativar e iniciar Netdata
sudo systemctl enable netdata
sudo systemctl start netdata

echo "Ferramentas de monitoramento instaladas e rodando."
echo "Acesse o Netdata via http://<IP-da-VM>:19999"
