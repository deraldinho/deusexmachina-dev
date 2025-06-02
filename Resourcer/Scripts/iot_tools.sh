#!/bin/bash
set -e

echo "Instalando ferramentas IoT e automação..."

sudo apt-get install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto

sudo apt-get install -y libcoap2-bin

sudo npm install -g --unsafe-perm node-red
sudo npm install -g pm2

pm2 startup systemd

echo "Ferramentas IoT e automação instaladas."
