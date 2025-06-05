#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a instalação de Node.js e Python 3..."
echo "---------------------------------------------------------------------"

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Versão desejada do Node.js (para o repositório NodeSource)
NODE_MAJOR_VERSION="18" # Você pode mudar para "20", "22", etc., conforme necessário

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do APT (pode ser rápido se já atualizado)..."
sudo apt-get update -y 

# 2. Garantir dependências para adicionar repositórios (já devem estar no essentials.sh, mas bom garantir)
echo "🛠️  Garantindo dependências para repositórios (curl, gnupg, ca-certificates)..."
sudo apt-get install -y curl gnupg ca-certificates

# 3. Instalar Node.js
echo "NODEJS: Instalando Node.js v${NODE_MAJOR_VERSION}.x..."
if command_exists node && node -v | grep -q "v${NODE_MAJOR_VERSION}\."; then
    echo "✅ Node.js v${NODE_MAJOR_VERSION}.x já parece estar instalado. Versão: $(node -v)"
    if command_exists npm; then
        echo "   Versão do npm: $(npm -v)"
    fi
else
    echo "   Configurando o repositório NodeSource para Node.js v${NODE_MAJOR_VERSION}.x..."
    
    KEYRING_DIR="/usr/share/keyrings"
    NODE_KEYRING_FILE="${KEYRING_DIR}/nodesource.gpg"
    
    # Garante que o diretório de keyrings exista
    sudo mkdir -p "${KEYRING_DIR}"
    
    # Baixa a chave GPG, dearmoriza e salva usando tee para garantir permissões corretas
    # e execução não interativa.
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo gpg --dearmor | sudo tee "${NODE_KEYRING_FILE}" > /dev/null
    
    if [ ! -f "${NODE_KEYRING_FILE}" ] || [ ! -s "${NODE_KEYRING_FILE}" ]; then
        echo "❌ Falha ao criar o arquivo de chave GPG do NodeSource: ${NODE_KEYRING_FILE}"
        exit 1
    fi
    sudo chmod 644 "${NODE_KEYRING_FILE}" # Garante permissões corretas para o arquivo de chave

    # Adiciona o repositório NodeSource
    echo "deb [signed-by=${NODE_KEYRING_FILE}] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    echo "deb-src [signed-by=${NODE_KEYRING_FILE}] https://deb.nodesource.com/node_${NODE_MAJOR_VERSION}.x $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

    echo "   Atualizando lista de pacotes após adicionar repo NodeSource..."
    sudo apt-get update -y 
    
    echo "   Instalando Node.js..."
    sudo apt-get install -y nodejs
    
    echo "✅ Node.js instalado com sucesso."
    echo "   Versão do Node.js: $(node -v)"
    echo "   Versão do npm: $(npm -v)"

    # Opcional: Atualizar npm para a versão mais recente
    # echo "   Atualizando npm para a versão mais recente..."
    # sudo npm install -g npm@latest
    # echo "   npm atualizado para: $(npm -v)"
fi

# 4. Instalar Python 3 e pip
echo "PYTHON: Instalando Python 3 e pip..."
PYTHON_INSTALLED=false
PIP_INSTALLED=false

if command_exists python3 && python3 --version &> /dev/null; then
    echo "✅ Python 3 já está instalado. Versão: $(python3 --version 2>&1)"
    PYTHON_INSTALLED=true
else
    sudo apt-get install -y python3
    echo "✅ Python 3 instalado. Versão: $(python3 --version 2>&1)"
    PYTHON_INSTALLED=true
fi

if command_exists pip3 && pip3 --version &> /dev/null; then
    echo "✅ pip3 já está instalado. Versão: $(pip3 --version 2>&1)"
    PIP_INSTALLED=true
else
    if [ "$PYTHON_INSTALLED" = true ]; then
        sudo apt-get install -y python3-pip
        echo "✅ pip3 instalado. Versão: $(pip3 --version 2>&1)"
        PIP_INSTALLED=true
    else
        echo "⚠️  Python 3 não foi instalado corretamente, pulando a instalação do pip3."
    fi
fi

# 5. Limpeza do APT (Opcional)
# echo "🧹 Limpando o cache do APT e pacotes não mais necessários..."
# sudo apt-get autoremove -y -qq
# sudo apt-get clean -y
# sudo rm -rf /var/lib/apt/lists/*

echo "---------------------------------------------------------------------"
echo "✅ Node.js e Python 3 configurados com sucesso!"
echo "---------------------------------------------------------------------"

