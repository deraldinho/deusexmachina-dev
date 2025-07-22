#!/bin/bash

# Script para verificar a saúde dos serviços essenciais da VM

set -euo pipefail

echo "---------------------------------------------------------------------"
echo "🩺 Iniciando Verificações de Saúde da VM..."
echo "---------------------------------------------------------------------"

# 1. Verificar status do Docker
echo "
🐳 Verificando status do Docker..."
if sudo systemctl is-active --quiet docker;
then
    echo "✅ Docker está ativo e rodando."
else
    echo "❌ Docker NÃO está ativo. Verifique o serviço: sudo systemctl status docker"
    exit 1
fi

# 2. Verificar status do Samba (smbd e nmbd)
echo "
📁 Verificando status do Samba..."
if sudo systemctl is-active --quiet smbd && sudo systemctl is-active --quiet nmbd;
then
    echo "✅ Serviços Samba (smbd e nmbd) estão ativos e rodando."
else
    echo "❌ Um ou ambos os serviços Samba (smbd, nmbd) NÃO estão ativos. Verifique: sudo systemctl status smbd nmbd"
    exit 1
fi

echo "
---------------------------------------------------------------------"
echo "✅ Todas as verificações de saúde essenciais concluídas com sucesso!"
echo "---------------------------------------------------------------------"
