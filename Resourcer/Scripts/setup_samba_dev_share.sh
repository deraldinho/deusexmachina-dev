#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

# --- Variáveis de Configuração ---
# Diretório base na VM que será criado e compartilhado (NÃO sincronizado com o host)
VM_INTERNAL_BASE_DIR="/home/vagrant"
# Subdiretório para os projetos de IA dentro do diretório base
PROJECTS_SUBDIR="projetos"
# Caminho completo na VM para a pasta de projetos
PROJECTS_FULL_PATH="${VM_INTERNAL_BASE_DIR}/${PROJECTS_SUBDIR}"

# Nome do compartilhamento Samba que aparecerá na rede
SAMBA_SHARE_NAME="DeusExMachina" # Nome para o compartilhamento de /vagrant
# Usuário do sistema que terá acesso ao compartilhamento Samba
SAMBA_USER="vagrant"
# Grupo do sistema para o diretório compartilhado
SAMBA_GROUP="vagrant"
# Arquivo de configuração do Samba
SMB_CONF="/etc/samba/smb.conf"

echo "---------------------------------------------------------------------"
echo "🚀 Iniciando a configuração do Compartilhamento Samba para ${VM_INTERNAL_BASE_DIR} (VM-Interna)..."
echo "   Diretório Raiz Compartilhado na VM: ${VM_INTERNAL_BASE_DIR}"
echo "   Pasta de Projetos de IA na VM:    ${PROJECTS_FULL_PATH}"
echo "   Nome do Compartilhamento Samba:     ${SAMBA_SHARE_NAME}"
echo "   Usuário Samba:                    ${SAMBA_USER}"
echo "   NOTA: Este diretório (${VM_INTERNAL_BASE_DIR}) NÃO é sincronizado com o host via Vagrant."
echo "---------------------------------------------------------------------"

# 1. Atualizar lista de pacotes
echo "🔄 Atualizando lista de pacotes do APT..."
sudo apt-get update -y

# 2. Instalar Samba e suas dependências
echo "🛠️  Instalando Samba e dependências..."
if dpkg -s samba &> /dev/null; then
    echo "✅ Samba já está instalado."
else
    sudo apt-get install -y samba samba-common-bin
    echo "✅ Samba instalado."
fi

# 3. Criar o diretório base ${VM_INTERNAL_BASE_DIR} e a subpasta ${PROJECTS_SUBDIR}
# Estes diretórios serão criados DENTRO da VM e não são sincronizados.
echo "📁 Criando o diretório ${VM_INTERNAL_BASE_DIR} e ${PROJECTS_FULL_PATH} (se não existirem)..."
sudo mkdir -p "${PROJECTS_FULL_PATH}" # Cria o caminho completo
sudo chown -R "${SAMBA_USER}:${SAMBA_GROUP}" "${VM_INTERNAL_BASE_DIR}" # Define o dono para todo o diretório base
sudo chmod -R 0775 "${VM_INTERNAL_BASE_DIR}" # Permissões para o dono e grupo, leitura para outros
echo "✅ Diretório ${PROJECTS_FULL_PATH} criado/configurado em ${VM_INTERNAL_BASE_DIR}."

# 4. Configurar o Samba (smb.conf)
echo "⚙️  Configurando o compartilhamento Samba em ${SMB_CONF}..."

if [ ! -f "${SMB_CONF}.original" ]; then
    sudo cp "${SMB_CONF}" "${SMB_CONF}.original"
    echo "   Backup do ${SMB_CONF} original criado."
fi

if grep -q "\[${SAMBA_SHARE_NAME}\]" "${SMB_CONF}"; then
    echo "✅ Configuração para [${SAMBA_SHARE_NAME}] já existe em ${SMB_CONF}."
    echo "   Verifique se está correta ou remova-a manualmente para reconfigurar."
else
    echo "   Adicionando configuração para [${SAMBA_SHARE_NAME}]..."
    # Compartilhando o diretório VM_INTERNAL_BASE_DIR (/vagrant)
    sudo bash -c "cat >> ${SMB_CONF}" << EOF

[${SAMBA_SHARE_NAME}]
   comment = Workspace DeusExMachina na VM (${VM_INTERNAL_BASE_DIR})
   path = ${VM_INTERNAL_BASE_DIR}
   browseable = yes
   writable = yes
   guest ok = no
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = ${SAMBA_USER}
   force user = ${SAMBA_USER}
   force group = ${SAMBA_GROUP}
EOF
    echo "✅ Configuração de [${SAMBA_SHARE_NAME}] adicionada."
fi

echo "🧪 Testando a configuração do Samba (testparm)..."
sudo testparm -s

# 5. Configurar usuário Samba
echo "👤 Configurando o usuário '${SAMBA_USER}' para o Samba..."

# Extrai SAMBA_PASSWORD dos argumentos
SAMBA_PASSWORD=""
for arg in "$@"; do
    if [[ "$arg" == SAMBA_PASSWORD=* ]]; then
        SAMBA_PASSWORD="${arg#SAMBA_PASSWORD=}"
        # Remove as aspas se existirem
        SAMBA_PASSWORD="${SAMBA_PASSWORD%\"}"
        SAMBA_PASSWORD="${SAMBA_PASSWORD#\"}"
        break
    fi
done

if [ -n "${SAMBA_PASSWORD}" ]; then
    echo "   Definindo senha para o usuário '${SAMBA_USER}'..."
    # Cria o usuário Samba e define a senha de forma não interativa
    # O 'pdbedit -a -u vagrant' garante que o usuário existe no banco de dados do Samba
    # O 'echo -e' com a senha duas vezes e 'smbpasswd -s' define a senha
    echo -e "${SAMBA_PASSWORD}\n${SAMBA_PASSWORD}" | sudo smbpasswd -a -s "${SAMBA_USER}"
    if [ $? -eq 0 ]; then
        echo "✅ Senha do usuário '${SAMBA_USER}' definida com sucesso."
    else
        echo "❌ Falha ao definir a senha para o usuário '${SAMBA_USER}'. Verifique o log."
    fi
else
    echo "   ⚠️  Variável SAMBA_PASSWORD não fornecida ou vazia no .env."
    echo "   A senha para o usuário Samba '${SAMBA_USER}' NÃO será definida automaticamente."
    echo "   Para proteger o compartilhamento, você precisará definir a senha manualmente:"
    echo "   Execute na VM (via 'vagrant ssh'): sudo smbpasswd -a ${SAMBA_USER}"
    # Garante que o usuário esteja habilitado no Samba, mesmo sem senha definida
    sudo smbpasswd -e "${SAMBA_USER}" &> /dev/null || true
fi

# 6. Reiniciar serviços Samba
echo "🔄 Reiniciando os serviços Samba (smbd e nmbd)..."
sudo systemctl restart smbd.service
sudo systemctl restart nmbd.service
sudo systemctl enable smbd.service
sudo systemctl enable nmbd.service

echo "   Status do smbd:"
sudo systemctl status smbd.service --no-pager -l || true
echo "   Status do nmbd:"
sudo systemctl status nmbd.service --no-pager -l || true

# 7. Configurar Firewall (UFW) para Samba
if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo "🔥 Configurando UFW para permitir tráfego Samba..."
    sudo ufw allow samba
    sudo ufw reload
    echo "✅ Regras do UFW para Samba aplicadas."
else
    echo "⚠️  UFW não está ativo ou não foi encontrado."
fi

echo "---------------------------------------------------------------------"
echo "✅ Configuração do Compartilhamento Samba para ${VM_INTERNAL_BASE_DIR} concluída!"
echo ""
echo "➡️  Para acessar o compartilhamento '${SAMBA_SHARE_NAME}' do seu computador HOST:"
echo "   1. Defina uma senha para o usuário Samba '${SAMBA_USER}' na VM:"
echo "      Execute na VM: sudo smbpasswd -a ${SAMBA_USER}"
echo "   2. Acesse via explorador de arquivos do HOST (substitua SEU_IP_VM pelo IP da VM, ex: 192.168.56.10):"
echo "      - Windows: \\\\SEU_IP_VM\\${SAMBA_SHARE_NAME}"
echo "      - macOS: Finder -> Ir -> Conectar ao Servidor -> smb://SEU_IP_VM/${SAMBA_SHARE_NAME}"
echo "      - Linux: smb://SEU_IP_VM/${SAMBA_SHARE_NAME}"
echo "   3. Use o usuário '${SAMBA_USER}' e a senha Samba definida."
echo "   4. Dentro do compartilhamento '${SAMBA_SHARE_NAME}', você encontrará a pasta '${PROJECTS_SUBDIR}'."
echo "      Todo o conteúdo desta pasta reside EXCLUSIVAMENTE na VM."
echo "---------------------------------------------------------------------"
# Fim do script de configuração do Samba para compartilhamento de /vagrant