#!/bin/bash
set -e

echo "Instalando Docker e watchdog..."

sudo apt-get update -y
sudo apt-get install -y apt-transport-https
sudo apt-get install -y ca-certificates gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo apt-get install -y watchdog
sudo systemctl enable --now watchdog

# Adiciona o usuário atual ao grupo docker
sudo usermod -aG docker vagrant

echo "Docker and watchdog installed."
echo "Docker e watchdog instalados."
