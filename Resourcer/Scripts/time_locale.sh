#!/bin/bash

# Configurações para um script mais robusto
set -euo pipefail

# --- Configurações Alvo ---
TARGET_TIMEZONE="America/Sao_Paulo"
TARGET_LOCALE_UTF8="pt_BR.UTF-8" # O locale completo com o encoding
TARGET_LANG="pt_BR.UTF-8"       # Para a variável LANG
TARGET_LANGUAGE="pt_BR:pt:en"   # Para a variável LANGUAGE (com fallbacks)
# --------------------------

echo "---------------------------------------------------------------------"
echo "🕰️  Iniciando a configuração de Timezone e Locale..."
echo "   Timezone Alvo: ${TARGET_TIMEZONE}"
echo "   Locale Alvo:   ${TARGET_LOCALE_UTF8}"
echo "---------------------------------------------------------------------"

# 1. Configurar Timezone
echo "➡️  Configurando Timezone..."
current_timezone=$(timedatectl status | grep 'Time zone' | awk '{print $3}') # Extrai o timezone atual

if [ "${current_timezone}" == "${TARGET_TIMEZONE}" ]; then
    echo "✅ Timezone já está configurado para ${TARGET_TIMEZONE}."
else
    echo "   Definindo timezone para ${TARGET_TIMEZONE}..."
    sudo timedatectl set-timezone "${TARGET_TIMEZONE}"
    if timedatectl status | grep -q "Time zone: ${TARGET_TIMEZONE}"; then
        echo "✅ Timezone configurado com sucesso para ${TARGET_TIMEZONE}."
    else
        echo "❌ Falha ao configurar o timezone para ${TARGET_TIMEZONE}. Verifique manualmente."
        # exit 1 # Descomente se quiser que o script falhe aqui
    fi
fi
echo "   Hora atual do sistema (após possível ajuste de timezone): $(date)"

# 2. Configurar Locale
echo "➡️  Configurando Locale..."

# Verificar se o pacote de locales está instalado
if ! rpm -q glibc-langpack-pt_BR &> /dev/null; then
    echo "   Pacote de locale 'glibc-langpack-pt_BR' não encontrado. Instalando..."
    sudo dnf install -y glibc-langpack-pt_BR
    echo "   Pacote de locale 'glibc-langpack-pt_BR' instalado."
fi

# Definir o locale padrão do sistema usando localectl
NEEDS_UPDATE=false
CURRENT_LANG=$(localectl status | grep "System Locale" | cut -d '=' -f2 | tr -d ' ')

if [ "${CURRENT_LANG}" != "${TARGET_LANG}" ]; then
    NEEDS_UPDATE=true
fi

if [ "${NEEDS_UPDATE}" = true ]; then
    echo "   Definindo locale padrão do sistema para LANG=${TARGET_LANG}, LC_ALL=${TARGET_LOCALE_UTF8}, LANGUAGE=${TARGET_LANGUAGE}..."
    sudo localectl set-locale "LANG=${TARGET_LANG}" "LC_ALL=${TARGET_LOCALE_UTF8}"
    # localectl não tem uma opção direta para LANGUAGE, mas LANG e LC_ALL são os mais importantes
    echo "✅ Locale padrão do sistema atualizado via localectl."
else
    echo "✅ Locale padrão do sistema já está configurado corretamente."
fi

echo "   Configurações de locale (podem requerer nova sessão para efeito completo):"
echo "   Saída do comando 'locale':"
locale

echo "---------------------------------------------------------------------"
echo "✅ Configuração de Timezone e Locale concluída."
echo "   ‼️  Pode ser necessário reiniciar a sessão ou a VM para que todas as"
echo "   alterações de locale tenham efeito completo em todos os processos e na sessão atual."
echo "---------------------------------------------------------------------"