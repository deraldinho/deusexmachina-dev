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

# 1. Atualizar a lista de pacotes do APT
echo "🔄 Atualizando lista de pacotes do APT..."
# O -qq é para tornar a saída menos verbosa
sudo apt-get update -y -qq

# 2. Realizar o upgrade dos pacotes já instalados de forma não interativa
echo "⬆️  Realizando upgrade de pacotes do sistema (pode levar alguns minutos)..."
# DEBIAN_FRONTEND=noninteractive evita a maioria dos prompts de configuração.
# As opções Dpkg tentam manter as configurações atuais ou usar padrões em caso de conflito.
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
    -o Dpkg::Options::="--force-confold" \
    -o Dpkg::Options::="--force-confdef"

# 3. Lista de pacotes essenciais a serem instalados
# Usar um array torna a lista mais fácil de ler e gerenciar.
declare -a ESSENTIAL_PACKAGES=(
    git
    curl
    wget
    unzip
    build-essential             # Compiladores C/C++ e ferramentas de desenvolvimento
    software-properties-common  # Gerenciamento de repositórios PPA (add-apt-repository)
    ca-certificates             # Permite que o sistema verifique certificados SSL/TLS
    gnupg                       # Para gerenciamento de chaves GPG (usado por muitos instaladores)
    lsb-release                 # Fornece informações sobre a distribuição Linux
    apt-transport-https         # Permite o uso de repositórios apt via https
    dkms                        # Dynamic Kernel Module Support (IMPORTANTE para VirtualBox Guest Additions)
    # linux-headers-generic       # Geralmente instalado como dependência do dkms ou pela box, mas pode ser explícito se necessário
    # linux-headers-$(uname -r) # Instala os headers para o kernel ATUALMENTE em execução.
                                # É mais seguro se o 'vagrant-vbguest' for rodar na mesma sessão de provisionamento.
                                # No entanto, dkms geralmente lida bem com isso se os headers genéricos estiverem presentes.
)

# Adicionar headers específicos do kernel atual pode ser mais preciso
# mas requer que uname -r já reflita o kernel final após qualquer upgrade.
# Se houver um reboot ou kernel update que não seja imediato, isso pode não pegar a versão certa.
# Por isso, confiar no dkms e nos headers genéricos/da box é muitas vezes suficiente.
# Se você continuar tendo problemas com Guest Additions, descomentar a linha abaixo pode ajudar:
# ESSENTIAL_PACKAGES+=("linux-headers-$(uname -r)")


echo "🛠️  Instalando pacotes essenciais: ${ESSENTIAL_PACKAGES[*]}..."
sudo apt-get install -y -qq "${ESSENTIAL_PACKAGES[@]}"

# 4. Limpeza do APT
# Remove pacotes que foram instalados automaticamente para satisfazer dependências
# de outros pacotes e que não são mais necessários.
echo "🧹 Removendo pacotes não mais necessários..."
sudo apt-get autoremove -y -qq

# Limpa o cache local de pacotes baixados (.deb files).
echo "🧹 Limpando o cache de pacotes do APT..."
sudo apt-get clean -y

# Remove as listas de pacotes baixadas pelo apt-get update.
# Isso pode ser útil para economizar espaço, especialmente em imagens Docker ou VMs finais.
# Elas serão recriadas na próxima vez que 'apt-get update' for executado.
echo "🧹 Removendo listas de pacotes do APT..."
sudo rm -rf /var/lib/apt/lists/*

echo "---------------------------------------------------------------------"
echo "✅ Ferramentas essenciais instaladas e sistema atualizado com sucesso!"
echo "---------------------------------------------------------------------"
