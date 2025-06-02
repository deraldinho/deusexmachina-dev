#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

echo "---------------------------------------------------------------------"
echo "📊 Iniciando a instalação de ferramentas de monitoramento..."
echo "---------------------------------------------------------------------"

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Atualizar lista de pacotes (se não foi feito recentemente por outro script)
# Se o 'essentials.sh' sempre rodar antes, esta linha pode ser opcional aqui.
echo "🔄 Atualizando lista de pacotes do APT (pode ser rápido se já atualizado)..."
sudo apt-get update -y

# 2. Instalar htop
echo " নজর Instalando htop..."
if command_exists htop; then
    echo "✅ htop já está instalado."
else
    sudo apt-get install -y htop
    echo "✅ htop instalado com sucesso."
fi

# 3. Instalar Glances
echo "📉 Instalando Glances..."
if command_exists glances; then
    echo "✅ Glances já está instalado."
else
    # Garante que python3-pip está instalado
    if ! command_exists pip3; then
        echo "   Instalando python3-pip como dependência para Glances..."
        sudo apt-get install -y python3-pip
        echo "   python3-pip instalado."
    fi
    echo "   Instalando Glances via pip3..."
    sudo pip3 install glances
    echo "✅ Glances instalado com sucesso."
fi

# 4. Instalar Netdata
echo "📈 Instalando Netdata..."
if command_exists netdata; then
    echo "✅ Netdata já parece estar instalado."
else
    echo "   Executando o script de instalação oficial do Netdata (kickstart.sh)..."
    # Adicionado -L ao curl para seguir redirecionamentos HTTP
    bash <(curl -SsL https://my-netdata.io/kickstart.sh) --disable-telemetry
    echo "✅ Script de instalação do Netdata concluído."
fi

# 5. Habilitar e iniciar o serviço Netdata
echo "⚙️  Habilitando e iniciando o serviço Netdata..."
if ! sudo systemctl is-enabled --quiet netdata.service; then
    sudo systemctl enable netdata.service
    echo "   Serviço Netdata habilitado."
else
    echo "   Serviço Netdata já estava habilitado."
fi

if ! sudo systemctl is-active --quiet netdata.service; then
    sudo systemctl start netdata.service
    echo "   Serviço Netdata iniciado."
else
    echo "   Serviço Netdata já estava ativo."
fi

# Comandos úteis para verificar o status (descomente para debug manual):
# echo "   Status do serviço Netdata:"
# sudo systemctl status netdata.service --no-pager -l

# 6. Limpeza do APT (Opcional)
# echo "🧹 Limpando o cache do APT e pacotes não mais necessários..."
# sudo apt-get autoremove -y
# sudo apt-get clean -y
# sudo rm -rf /var/lib/apt/lists/*

echo "---------------------------------------------------------------------"
echo "✅ Ferramentas de monitoramento instaladas e configuradas!"
echo "👉 Acesse o Netdata em: http://<IP-DA-SUA-VM>:19999"
echo "   Use 'htop' ou 'glances' no terminal para monitoramento em tempo real."
echo "---------------------------------------------------------------------"
