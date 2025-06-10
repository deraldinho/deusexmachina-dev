#!/bin/bash
# Script para instalar Docker, Docker Compose e Watchdog.
# Versão corrigida para contornar problemas de certificado SSL (Kaspersky).

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a instalação e configuração do Docker e Watchdog..."
echo "---------------------------------------------------------------------"

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do APT (pode ser rápido se já atualizado)..."
sudo apt-get update -y -qq

# 2. Garantir dependências para adicionar repositórios
echo "🛠️  Garantindo dependências para repositórios (apt-transport-https, ca-certificates, curl, gnupg, lsb-release)..."
sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release

# 3. Instalar Docker Engine
if command_exists docker; then
    CURRENT_DOCKER_VERSION=$(docker --version)
    echo "✅ Docker já parece estar instalado. Versão: ${CURRENT_DOCKER_VERSION}"
else
    echo "🔧 Instalando Docker Engine..."
    
    # Adicionar chave GPG oficial do Docker
    echo "   Adicionando chave GPG do Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    # Adicionada a flag '-k' ou '--insecure' ao curl para ignorar a verificação de certificado SSL.
    # ADVERTÊNCIA: Use apenas em ambientes de desenvolvimento controlados.
    curl -kfsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Configurar o repositório do Docker
    echo "   Configurando o repositório do Docker..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualizar o índice de pacotes novamente após adicionar o novo repositório
    echo "   Atualizando lista de pacotes após adicionar repo Docker..."
    sudo apt-get update -y -qq

    echo "   Instalando Docker CE, CLI, Containerd, Buildx e Docker Compose plugin..."
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "✅ Docker Engine instalado com sucesso."
    docker --version
fi

# 4. Adicionar usuário 'vagrant' ao grupo 'docker'
TARGET_USER="vagrant"
if groups "${TARGET_USER}" | grep -q -w "docker"; then
    echo "✅ Usuário '${TARGET_USER}' já pertence ao grupo 'docker'."
else
    echo "➕ Adicionando usuário '${TARGET_USER}' ao grupo 'docker'..."
    sudo usermod -aG docker "${TARGET_USER}"
    echo "   ‼️  AVISO IMPORTANTE: O usuário '${TARGET_USER}' precisará de fazer logout e login novamente para que a alteração tenha efeito."
fi

# 5. Habilitar e iniciar o serviço Docker (systemd)
echo "🐳 Habilitando e iniciando o serviço Docker..."
if ! sudo systemctl is-enabled --quiet docker.service; then
    sudo systemctl enable docker.service
    echo "   Serviço Docker habilitado."
else
    echo "   Serviço Docker já estava habilitado."
fi

if ! sudo systemctl is-active --quiet docker.service; then
    sudo systemctl start docker.service
    echo "   Serviço Docker iniciado."
else
    echo "   Serviço Docker já estava ativo."
fi

# 6. Instalar e configurar Watchdog
echo "🐶 Instalando e configurando Watchdog..."
if dpkg -s watchdog >/dev/null 2>&1; then
    echo "✅ Watchdog já está instalado."
else
    sudo apt-get install -y -qq watchdog
    echo "✅ Watchdog instalado."
fi

echo "⚙️  Habilitando e iniciando o serviço Watchdog..."
if ! sudo systemctl is-enabled --quiet watchdog.service; then
    sudo systemctl enable watchdog.service
    echo "   Serviço Watchdog habilitado."
else
    echo "   Serviço Watchdog já estava habilitado."
fi

if ! sudo systemctl is-active --quiet watchdog.service; then
    sudo systemctl start watchdog.service
    echo "   Serviço Watchdog iniciado."
else
    echo "   Serviço Watchdog já estava ativo."
fi

echo "---------------------------------------------------------------------"
echo "✅ Docker e Watchdog configurados com sucesso!"
echo "---------------------------------------------------------------------"
