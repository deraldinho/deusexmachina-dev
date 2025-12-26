#!/bin/bash

# Configurações para um script mais robusto:
# set -e: Sai imediatamente se um comando sair com status diferente de zero.
# set -u: Trata variáveis não definidas como um erro durante a substituição.
# set -o pipefail: O valor de retorno de um pipeline é o status do último comando
#                  a sair com um código de status diferente de zero, ou zero se
#                  nenhum comando sair com status diferente de zero.
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🔐 Iniciando importação de certificados e atualização do sistema CentOS..."
echo "---------------------------------------------------------------------"

# Diretório onde os certificados estão localizados (relativo ao script)
CERT_DIR="$(dirname "$0")/../certificados"

# Verificar se o diretório de certificados existe
if [[ ! -d "$CERT_DIR" ]]; then
    echo "❌ Erro: Diretório de certificados '$CERT_DIR' não encontrado."
    exit 1
fi

# 1. Atualizar o sistema CentOS
echo "⬆️  Atualizando o sistema CentOS..."
sudo dnf clean all -y
sudo dnf makecache -q
sudo dnf upgrade -y -q --best --allowerasing || echo "⚠️  Alguns pacotes podem não ter sido atualizados devido a conflitos. Continuando..."

# 2. Importar certificados
echo "📄 Importando certificados de '$CERT_DIR'..."

# Encontrar todos os arquivos .crt e .pem no diretório de certificados
CERT_FILES=("$CERT_DIR"/*.crt "$CERT_DIR"/*.pem)

# Verificar se há arquivos de certificado
if [[ "${CERT_FILES[0]}" == "$CERT_DIR/*.crt" && "${CERT_FILES[1]}" == "$CERT_DIR/*.pem" ]]; then
    echo "⚠️  Nenhum arquivo de certificado (.crt ou .pem) encontrado em '$CERT_DIR'."
else
    # Copiar certificados para o diretório de confiança do sistema
    for cert in "${CERT_FILES[@]}"; do
        if [[ -f "$cert" ]]; then
            echo "📋 Copiando $(basename "$cert") para /etc/pki/ca-trust/source/anchors/..."
            sudo cp "$cert" /etc/pki/ca-trust/source/anchors/
        fi
    done

    # Forçar habilitação do trust store e atualizar
    echo "🔄 Forçando habilitação e atualização do armazenamento de confiança de CA..."
    sudo update-ca-trust force-enable
    sudo update-ca-trust extract
    echo "✅ Certificados importados e armazenamento de confiança atualizado."

    # Verificar presença do Zscaler no trust store
    if trust list | grep -i zscaler > /dev/null; then
        echo "✅ Certificado Zscaler detectado no trust store."
    else
        echo "⚠️  Certificado Zscaler não encontrado no trust store. Verifique o arquivo."
    fi
fi

# 3. Limpeza
echo "🧹 Limpando cache do DNF..."
sudo dnf clean all -y

echo "---------------------------------------------------------------------"
echo "✅ Importação de certificados e atualização do sistema concluídas com sucesso!"
echo "---------------------------------------------------------------------"
