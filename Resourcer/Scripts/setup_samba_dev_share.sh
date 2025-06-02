#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

# --- Variáveis de Configuração ---
<<<<<<< HEAD
# Diretório na VM que será criado e compartilhado (NÃO sincronizado com o host)
# Esta é a pasta home do usuário vagrant, onde geralmente se cai ao fazer 'vagrant ssh'
VM_INTERNAL_BASE_DIR="/home/vagrant"
=======
# Diretório base na VM que será criado e compartilhado (NÃO sincronizado com o host)
VM_INTERNAL_BASE_DIR="/vagrant"
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
# Subdiretório para os projetos de IA dentro do diretório base
PROJECTS_SUBDIR="Projetos"
# Caminho completo na VM para a pasta de projetos
PROJECTS_FULL_PATH="${VM_INTERNAL_BASE_DIR}/${PROJECTS_SUBDIR}"

# Nome do compartilhamento Samba que aparecerá na rede
<<<<<<< HEAD
SAMBA_SHARE_NAME="DeusExMachina" # Nome para o compartilhamento de /home/vagrant
=======
SAMBA_SHARE_NAME="DeusExMachina_VM_Workspace" # Nome para o compartilhamento de /vagrant
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
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
<<<<<<< HEAD
sudo apt-get update -y -qq
=======
sudo apt-get update -y
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b

# 2. Instalar Samba e suas dependências
echo "🛠️  Instalando Samba e dependências..."
if dpkg -s samba &> /dev/null; then
    echo "✅ Samba já está instalado."
else
    sudo apt-get install -y samba samba-common-bin
    echo "✅ Samba instalado."
fi

<<<<<<< HEAD
# 3. Criar o diretório ${PROJECTS_FULL_PATH} (/home/vagrant/Projetos) se não existir.
# A pasta /home/vagrant já deve existir e ser propriedade de vagrant:vagrant.
# Apenas garantimos a criação da subpasta Projetos.
echo "📁 Criando o diretório ${PROJECTS_FULL_PATH} (se não existir)..."
# O 'sudo -u' garante que a pasta seja criada com o usuário vagrant como dono,
# o que já deve ser o caso para /home/vagrant, mas é uma boa prática para subpastas.
sudo -u "${SAMBA_USER}" mkdir -p "${PROJECTS_FULL_PATH}"
# Garantir permissões adequadas para a pasta de projetos
sudo chown "${SAMBA_USER}:${SAMBA_GROUP}" "${PROJECTS_FULL_PATH}"
sudo chmod 0775 "${PROJECTS_FULL_PATH}"
echo "✅ Diretório ${PROJECTS_FULL_PATH} criado/verificado em ${VM_INTERNAL_BASE_DIR}."
=======
# 3. Criar o diretório base ${VM_INTERNAL_BASE_DIR} e a subpasta ${PROJECTS_SUBDIR}
# Estes diretórios serão criados DENTRO da VM e não são sincronizados.
echo "📁 Criando o diretório ${VM_INTERNAL_BASE_DIR} e ${PROJECTS_FULL_PATH} (se não existirem)..."
sudo mkdir -p "${PROJECTS_FULL_PATH}" # Cria o caminho completo
sudo chown -R "${SAMBA_USER}:${SAMBA_GROUP}" "${VM_INTERNAL_BASE_DIR}" # Define o dono para todo o diretório base
sudo chmod -R 0775 "${VM_INTERNAL_BASE_DIR}" # Permissões para o dono e grupo, leitura para outros
echo "✅ Diretório ${PROJECTS_FULL_PATH} criado/configurado em ${VM_INTERNAL_BASE_DIR}."
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b

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
<<<<<<< HEAD
    # Compartilhando o diretório VM_INTERNAL_BASE_DIR (/home/vagrant)
=======
    # Compartilhando o diretório VM_INTERNAL_BASE_DIR (/vagrant)
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
    sudo bash -c "cat >> ${SMB_CONF}" << EOF

[${SAMBA_SHARE_NAME}]
   comment = Workspace DeusExMachina na VM (${VM_INTERNAL_BASE_DIR})
   path = ${VM_INTERNAL_BASE_DIR}
   browseable = yes
   writable = yes
   guest ok = no
   read only = no
<<<<<<< HEAD
   create mask = 0664  # Arquivos criados terão permissão rw-rw-r--
   directory mask = 0775 # Pastas criadas terão permissão rwxrwxr-x
   valid users = ${SAMBA_USER}
   # Forçar o usuário e grupo garante que os arquivos criados via Samba
   # pertençam ao usuário 'vagrant' dentro da VM.
=======
   create mask = 0664
   directory mask = 0775
   valid users = ${SAMBA_USER}
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
   force user = ${SAMBA_USER}
   force group = ${SAMBA_GROUP}
EOF
    echo "✅ Configuração de [${SAMBA_SHARE_NAME}] adicionada."
fi

echo "🧪 Testando a configuração do Samba (testparm)..."
sudo testparm -s

# 5. Configurar usuário Samba
echo "👤 Configurando o usuário '${SAMBA_USER}' para o Samba..."
echo "   ‼️  IMPORTANTE: A senha para o usuário Samba '${SAMBA_USER}' precisa ser definida."
echo "   Execute na VM (via 'vagrant ssh'): sudo smbpasswd -a ${SAMBA_USER}"
<<<<<<< HEAD
# Habilita o usuário no Samba (não define a senha, apenas garante que ele pode ser usado se já tiver uma)
=======
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
sudo smbpasswd -e "${SAMBA_USER}" &> /dev/null || true

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
<<<<<<< HEAD
=======
# Fim do script de configuração do Samba para compartilhamento de /vagrant
>>>>>>> 9e9142979893d053db9985839d2f8ca44d82800b
