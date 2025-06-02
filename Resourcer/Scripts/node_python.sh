#!/bin/bash
set -e

echo "Instalando Node.js 18 LTS e Python 3..."

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y python3 python3-pip

echo "Node.js e Python instalados."
