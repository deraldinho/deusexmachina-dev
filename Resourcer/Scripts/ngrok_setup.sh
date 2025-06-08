#!/bin/bash
# Script para instalar o ngrok na VM

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🌍 Iniciando a instalação do ngrok..."
echo "---------------------------------------------------------------------"

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if command_exists ngrok; then
    echo "✅ ngrok já está instalado. Versão: $(ngrok --version)"
    exit 0
fi

# 1. Determinar a arquitetura do sistema (amd64 ou arm64)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    NGROK_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    NGROK_ARCH="arm64"
else
    echo "❌ Arquitetura não suportada: $ARCH"
    exit 1
fi
echo "   Arquitetura detectada: $NGROK_ARCH"

# 2. Baixar o binário do ngrok
NGROK_ZIP="ngrok-stable-linux-${NGROK_ARCH}.zip"
NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/${NGROK_ZIP}"

echo "   Baixando ngrok de ${NGROK_URL}..."
# Usamos -L para seguir redirecionamentos e -o para salvar em um arquivo
curl -L "${NGROK_URL}" -o "/tmp/${NGROK_ZIP}"

# 3. Descompactar e instalar
echo "   Instalando o binário do ngrok em /usr/local/bin/..."
sudo unzip -o "/tmp/${NGROK_ZIP}" -d /usr/local/bin/
# -o: sobrescreve sem pedir confirmação
# -d: diretório de destino

# 4. Verificar a instalação
if command_exists ngrok; then
    echo "✅ ngrok instalado com sucesso!"
    ngrok --version
else
    echo "❌ Falha na instalação do ngrok."
    exit 1
fi

# 5. Limpar o arquivo baixado
rm "/tmp/${NGROK_ZIP}"

echo "---------------------------------------------------------------------"
echo "✅ Instalação do ngrok concluída."
echo "👉 Para usar, acesse a VM com 'vagrant ssh' e configure seu authtoken:"
echo "   ngrok config add-authtoken SEU_TOKEN_AQUI"
echo "---------------------------------------------------------------------"

