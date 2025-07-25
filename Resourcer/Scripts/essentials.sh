#!/bin/bash

# Configurações para um script mais robusto:
# set -e: Sai imediatamente se um comando sair com status diferente de zero.
# set -u: Trata variáveis não definidas como um erro durante a substituição.
# set -o pipefail: O valor de retorno de um pipeline é o status do último comando
#                  a sair com um código de status diferente de zero, ou zero se
#                  nenhum comando sair com status diferente de zero.
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a atualização do sistema e instalação de ferramentas essenciais..."
echo "---------------------------------------------------------------------"

# 1. Atualizar a lista de pacotes do DNF
echo "🔄 Atualizando lista de pacotes do DNF..."
# O -q é para tornar a saída menos verbosa
sudo dnf check-update -y -q || true # check-update retorna 100 se houver atualizações, 0 se não, 1 se erro.
sudo dnf makecache -q

# 2. Realizar o upgrade dos pacotes já instalados de forma não interativa
echo "⬆️  Realizando upgrade de pacotes do sistema (pode levar alguns minutos)..."
sudo dnf upgrade -y -q

# 3. Lista de pacotes essenciais a serem instalados
# Usar um array torna a lista mais fácil de ler e gerenciar.
declare -a ESSENTIAL_PACKAGES=(
    git
    curl
    wget
    unzip
    @"Development Tools"          # Grupo de ferramentas de desenvolvimento
    ca-certificates             # Permite que o sistema verifique certificados SSL/TLS
    gnupg2                      # Para gerenciamento de chaves GPG
    lsb_release                 # Fornece informações sobre a distribuição Linux (lsb_release)
    dkms                        # Dynamic Kernel Module Support (IMPORTANTE para VirtualBox Guest Additions)
    jq                          # Ferramenta de linha de comando para processar JSON
    kernel-devel                # Desenvolvimento do kernel (necessário para VBox Guest Additions)
)

sudo dnf install -y -q epel-release

echo "🛠️  Instalando pacotes essenciais: ${ESSENTIAL_PACKAGES[*]}..."
sudo dnf install -y -q "${ESSENTIAL_PACKAGES[@]}"

# 4. Limpeza do DNF
# Remove pacotes que foram instalados automaticamente para satisfazer dependências
# de outros pacotes e que não são mais necessários.
echo "🧹 Removendo pacotes não mais necessários..."
sudo dnf autoremove -y -q

# Limpa o cache local de pacotes baixados.
echo "🧹 Limpando o cache de pacotes do DNF..."
sudo dnf clean all -y

echo "---------------------------------------------------------------------"
echo "✅ Ferramentas essenciais instaladas e sistema atualizado com sucesso!"
echo "---------------------------------------------------------------------"
