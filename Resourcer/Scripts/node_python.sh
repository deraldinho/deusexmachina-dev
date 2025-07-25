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
NODE_MAJOR_VERSION="22" # Você pode mudar para "20", "22", etc., conforme necessário

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
echo "🔄 Atualizando lista de pacotes do DNF (pode ser rápido se já atualizado)..."
sudo dnf makecache -q

# 2. Garantir dependências para adicionar repositórios (já devem estar no essentials.sh, mas bom garantir)
echo "🛠️  Garantindo dependências para repositórios (curl, gnupg2, ca-certificates)..."
sudo dnf install -y curl gnupg2 ca-certificates

# 3. Instalar Node.js
echo "NODEJS: Instalando Node.js v${NODE_MAJOR_VERSION}.x..."
if command_exists node && node -v | grep -q "v${NODE_MAJOR_VERSION}\."; then
    echo "✅ Node.js v${NODE_MAJOR_VERSION}.x já parece estar instalado. Versão: $(node -v)"
    if command_exists npm; then
        echo "   Versão do npm: $(npm -v)"
    fi
else
    echo "   Configurando o repositório NodeSource para Node.js v${NODE_MAJOR_VERSION}.x..."
    curl -fsSL https://rpm.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | sudo bash -

    echo "   Instalando Node.js..."
    sudo dnf install -y nodejs
    
    echo "✅ Node.js instalado com sucesso."
    echo "   Versão do Node.js: $(node -v)"
    echo "   Versão do npm: $(npm -v)"

    # Opcional: Atualizar npm para a versão mais recente
    # echo "   Atualizando npm para a versão mais recente..."
    # sudo npm install 
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
    sudo dnf install -y python3
    echo "✅ Python 3 instalado. Versão: $(python3 --version 2>&1)"
    PYTHON_INSTALLED=true
fi

if command_exists pip3 && pip3 --version &> /dev/null; then
    echo "✅ pip3 já está instalado. Versão: $(pip3 --version 2>&1)"
    PIP_INSTALLED=true
else
    if [ "$PYTHON_INSTALLED" = true ]; then
        sudo dnf install -y python3-pip
        echo "✅ pip3 instalado. Versão: $(pip3 --version 2>&1)"
        PIP_INSTALLED=true
    else
        echo "⚠️  Python 3 não foi instalado corretamente, pulando a instalação do pip3."
    fi
fi

echo "---------------------------------------------------------------------"
echo "✅ Node.js e Python 3 configurados com sucesso!"
echo "---------------------------------------------------------------------"