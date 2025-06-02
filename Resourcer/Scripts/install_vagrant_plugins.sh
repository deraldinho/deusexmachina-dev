 #!/bin/bash

# Versão mínima exigida do Vagrant
MIN_VAGRANT_VERSION="2.3.0"

# Função para comparar versões
version_ge() {
  # retorna 0 (true) se $1 >= $2
  # retorna 1 (false) caso contrário
  printf '%s\n%s\n' "$1" "$2" | sort -C -V
}

# Checa a versão atual do Vagrant
if ! command -v vagrant &> /dev/null; then
  echo "❌ Vagrant não encontrado. Instale antes de continuar."
  exit 1
fi

CURRENT_VERSION=$(vagrant --version | awk '{print $2}')

if ! version_ge "$CURRENT_VERSION" "$MIN_VAGRANT_VERSION"; then
  echo "❌ Versão do Vagrant insuficiente: $CURRENT_VERSION"
  echo "👉 Atualize para a versão >= $MIN_VAGRANT_VERSION"
  exit 1
fi

echo "✅ Versão do Vagrant OK: $CURRENT_VERSION"

# Lista de plugins obrigatórios
plugins=("vagrant-disksize" "vagrant-vbguest" "vagrant-reload")

echo "🔍 Verificando plugins do Vagrant..."

for plugin in "${plugins[@]}"; do
  if ! vagrant plugin list | grep -q "^${plugin} "; then
    echo "🔧 Instalando plugin: $plugin"
    vagrant plugin install "$plugin"
  else
    echo "✅ Plugin já instalado: $plugin"
  fi
done

echo "✅ Todos os plugins obrigatórios estão instalados!"
