#!/bin/bash
# Script para instalar a versão LTS mais recente do Node.js e o Python 3.

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a instalação do Node.js (LTS mais recente) e Python 3..."
echo "---------------------------------------------------------------------"

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Instalação do Node.js (Versão LTS mais recente) ---
echo "NODEJS: Verificando a instalação do Node.js..."

# Mesmo que o node já esteja instalado, vamos rodar o setup do NodeSource
# para garantir que o repositório APT esteja configurado para a última versão LTS.
if command_exists node; then
    echo "✅ Node.js já está instalado. Versão atual: $(node -v)"
    echo "   Executando script de setup do NodeSource para garantir que o repositório esteja configurado para a LTS mais recente..."
fi

# Este comando baixa e executa o script oficial do NodeSource para a versão LTS (Long Term Support).
# Ele configura o repositório e a chave GPG automaticamente.
# É a maneira recomendada para garantir a instalação da versão LTS mais recente.
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

echo "   Instalando/Atualizando Node.js para a versão LTS mais recente..."
# O comando abaixo irá instalar o nodejs se não estiver presente, ou atualizá-lo
# para a última versão disponível no repositório LTS que acabamos de configurar.
sudo apt-get install -y nodejs

echo "✅ Node.js instalado/atualizado com sucesso."
echo "   Nova Versão do Node.js: $(node -v)"
echo "   Versão do npm: $(npm -v)"


# --- Instalação do Python 3 e Pip ---
# Esta parte continua a mesma, pois geralmente instala a versão estável do Python
# fornecida pela distribuição Ubuntu.
echo "PYTHON: Verificando a instalação do Python 3 e pip..."
PYTHON_INSTALLED=false

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
else
    if [ "$PYTHON_INSTALLED" = true ]; then
        sudo apt-get install -y python3-pip
        echo "✅ pip3 instalado. Versão: $(pip3 --version 2>&1)"
    else
        echo "⚠️  Python 3 não foi instalado corretamente, pulando a instalação do pip3."
    fi
fi

echo "---------------------------------------------------------------------"
echo "✅ Node.js e Python 3 configurados com sucesso!"
echo "---------------------------------------------------------------------"
