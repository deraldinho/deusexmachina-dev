#!/bin/bash

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
# Se o 'essentials.sh' sempre rodar antes, esta linha pode ser opcional aqui.
echo "🔄 Atualizando lista de pacotes do DNF (pode ser rápido se já atualizado)..."
sudo dnf makecache -q

# 2. Garantir dependências para adicionar repositórios
# Muitos destes já devem ter sido instalados pelo 'essentials.sh' melhorado.
echo "🛠️  Garantindo dependências para repositórios (ca-certificates, curl, gnupg2, redhat-lsb-core)..."
sudo dnf install -y ca-certificates curl gnupg2 lsb_release

# 3. Instalar Docker Engine
if command_exists docker; then
    CURRENT_DOCKER_VERSION=$(docker --version)
    echo "✅ Docker já parece estar instalado. Versão: ${CURRENT_DOCKER_VERSION}"
else
    echo "🔧 Instalando Docker Engine..."
    # Adicionar repositório Docker CE para CentOS
    echo "   Configurando o repositório do Docker..."
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Instalar Docker CE, CLI, Containerd, Buildx e Docker Compose plugin
    echo "   Instalando Docker CE, CLI, Containerd, Buildx e Docker Compose plugin..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "✅ Docker Engine instalado com sucesso."
    docker --version
fi

# 4. Adicionar usuário 'vagrant' ao grupo 'docker'
# Isso permite executar comandos docker sem sudo.
TARGET_USER="vagrant" # Usuário padrão do Vagrant
if groups "${TARGET_USER}" | grep -q -w "docker"; then
    echo "✅ Usuário '${TARGET_USER}' já pertence ao grupo 'docker'."
else
    echo "➕ Adicionando usuário '${TARGET_USER}' ao grupo 'docker'..."
    sudo usermod -aG docker "${TARGET_USER}"
    echo "   ‼️  AVISO IMPORTANTE: O usuário '${TARGET_USER}' precisará fazer logout e login novamente"
    echo "   (ou a VM ser reiniciada/nova sessão SSH iniciada) para que a alteração de grupo tenha efeito."
    echo "   Em um provisionamento Vagrant, isso geralmente significa que o grupo estará ativo na próxima vez que você fizer 'vagrant ssh',"
    echo "   ou se você usar 'su - ${TARGET_USER}' dentro de um script para simular um novo login."
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
if rpm -q watchdog >/dev/null 2>&1; then
    echo "✅ Watchdog já está instalado."
else
    sudo dnf install -y watchdog
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