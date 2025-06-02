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

# Verificar se o pacote de locales está instalado (geralmente está, mas é uma boa checagem)
if ! dpkg -s locales &> /dev/null; then
    echo "   Pacote 'locales' não encontrado. Instalando..."
    sudo apt-get update -y # Atualizar se não foi feito recentemente
    sudo apt-get install -y locales
    echo "   Pacote 'locales' instalado."
fi

# Verificar se o locale alvo já está gerado
# Usamos sed para escapar o ponto no nome do locale para o grep
ESCAPED_TARGET_LOCALE_UTF8=$(echo "${TARGET_LOCALE_UTF8}" | sed 's/\./\\./g')
if locale -a | grep -q "^${ESCAPED_TARGET_LOCALE_UTF8}$"; then
    echo "✅ Locale ${TARGET_LOCALE_UTF8} já está gerado."
else
    echo "   Gerando locale ${TARGET_LOCALE_UTF8}..."
    # Adiciona a linha ao /etc/locale.gen se não existir e então roda locale-gen
    if ! grep -q "^${TARGET_LOCALE_UTF8} UTF-8$" /etc/locale.gen; then
        echo "   Adicionando ${TARGET_LOCALE_UTF8} UTF-8 ao /etc/locale.gen"
        sudo sed -i "/^# ${TARGET_LOCALE_UTF8} UTF-8$/s/^# //" /etc/locale.gen # Tenta descomentar primeiro
        if ! grep -q "^${TARGET_LOCALE_UTF8} UTF-8$" /etc/locale.gen; then # Se não encontrou para descomentar
             echo "${TARGET_LOCALE_UTF8} UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
        fi
    fi
    sudo locale-gen "${TARGET_LOCALE_UTF8}"
    echo "✅ Locale ${TARGET_LOCALE_UTF8} gerado."
fi

# Definir o locale padrão do sistema
# Verificamos o arquivo /etc/default/locale para ver se já está correto.
LOCALE_CONFIG_FILE="/etc/default/locale"
NEEDS_UPDATE=false

if [ -f "${LOCALE_CONFIG_FILE}" ]; then
    if ! grep -Fxq "LANG=${TARGET_LANG}" "${LOCALE_CONFIG_FILE}" || \
       ! grep -Fxq "LC_ALL=${TARGET_LOCALE_UTF8}" "${LOCALE_CONFIG_FILE}" || \
       ! grep -Fxq "LANGUAGE=${TARGET_LANGUAGE}" "${LOCALE_CONFIG_FILE}"; then
        NEEDS_UPDATE=true
    fi
else
    NEEDS_UPDATE=true # Arquivo não existe, precisa ser criado/atualizado
fi

if [ "${NEEDS_UPDATE}" = true ]; then
    echo "   Definindo locale padrão do sistema para LANG=${TARGET_LANG}, LC_ALL=${TARGET_LOCALE_UTF8}, LANGUAGE=${TARGET_LANGUAGE}..."
    # update-locale é a ferramenta padrão para isso no Debian/Ubuntu
    sudo update-locale "LANG=${TARGET_LANG}" \
                       "LC_ALL=${TARGET_LOCALE_UTF8}" \
                       "LANGUAGE=${TARGET_LANGUAGE}"
    echo "✅ Locale padrão do sistema atualizado via update-locale."
else
    echo "✅ Locale padrão do sistema já está configurado corretamente em ${LOCALE_CONFIG_FILE}."
fi

echo "   Configurações de locale (podem requerer nova sessão para efeito completo):"
echo "   Conteúdo de ${LOCALE_CONFIG_FILE}:"
if [ -f "${LOCALE_CONFIG_FILE}" ]; then
    cat "${LOCALE_CONFIG_FILE}"
else
    echo "   Arquivo ${LOCALE_CONFIG_FILE} não encontrado."
fi
echo "   Saída do comando 'locale':"
locale

echo "---------------------------------------------------------------------"
echo "✅ Configuração de Timezone e Locale concluída."
echo "   ‼️  Pode ser necessário reiniciar a sessão ou a VM para que todas as"
echo "   alterações de locale tenham efeito completo em todos os processos e na sessão atual."
echo "---------------------------------------------------------------------"