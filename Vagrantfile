# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'pathname'

# --- Função para Carregar Variáveis de Ambiente do .env ---
def load_env(file)
  File.readlines(file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    key, value = line.split('=', 2)
    next unless key && value
    key = key.strip
    value = value.strip.gsub(/\A['"]+|['"]+\z/, '') # Remove aspas do valor
    ENV[key] = value
  end
end

# Carrega o .env se existir na raiz do projeto
env_file = Pathname.new(File.dirname(__FILE__)).join('.env')
load_env(env_file) if env_file.file?

# --- Configurações e Variáveis Globais ---
VM_BOX_DEFAULT = "hashicorp/centos-stream-10"  # CentOS Stream 10
VM_BOX_VERSION_DEFAULT = "latest" # Usar a versão mais recente disponível
VM_HOSTNAME_DEFAULT = "DeusExMachina-VM"
VM_IP_PRIVATE_DEFAULT = "192.168.56.10" # Mudado do seu original para evitar conflitos comuns com 192.168.33.x
VM_MEMORY_DEFAULT = 4096 # Memória em MB (4GB)
VM_CPUS_DEFAULT = 2
VM_DISKSIZE_DEFAULT = '60GB' # Aumentado um pouco para acomodar Docker e dados

# Leitura das variáveis de ambiente ou uso dos padrões
VM_BOX = ENV.fetch('VM_BOX', VM_BOX_DEFAULT)
VM_BOX_VERSION = ENV.fetch('VM_BOX_VERSION', VM_BOX_VERSION_DEFAULT)
VM_HOSTNAME = ENV.fetch('VM_HOSTNAME', VM_HOSTNAME_DEFAULT)
VM_IP_PRIVATE = ENV.fetch('VM_IP_PRIVATE', VM_IP_PRIVATE_DEFAULT)
VM_MEMORY = ENV.fetch('VM_MEMORY', VM_MEMORY_DEFAULT).to_i
VM_CPUS = ENV.fetch('VM_CPUS', VM_CPUS_DEFAULT).to_i
VM_DISKSIZE = ENV.fetch('VM_DISKSIZE', VM_DISKSIZE_DEFAULT)

USE_EMOJIS = ENV.fetch('USE_EMOJIS', 'true').downcase == 'true' # Mantido o seu 'true' como padrão

# Caminho para os scripts de provisionamento no HOST (usado para 'path:' nos provisionadores)
# A variável PROVISION_SCRIPTS_DIR_HOST_PATHNAME é usada para construir os caminhos para a opção 'path'
# dos provisionadores de shell, onde Vagrant espera um caminho do host.
PROVISION_SCRIPTS_DIR_HOST_PATHNAME = Pathname.new(File.dirname(__FILE__)).join("Resourcer", "Scripts")

# Caminho para os scripts de provisionamento DENTRO DA VM (usado para 'inline' chmod)
# Assumindo que a pasta 'Resourcer' está na raiz do projeto Vagrant,
# ela será mapeada para '/vagrant/Resourcer' dentro da VM pela sincronização padrão.
PROVISION_SCRIPTS_DIR_GUEST = "/vagrant"


# Lista de portas a serem encaminhadas (mantendo a sua lista extensa)
FORWARDED_PORTS_LIST = [
  80, 443, 3000, 5000, 8000, 8080, # Web & APIs
  3306, 5432, 27017, 6379,          # Bancos de Dados
  1883, 8883,                       # MQTT
  5683,                             # CoAP (UDP, mas o encaminhamento padrão é TCP. Precisa especificar protocolo se UDP)
  502,                              # Modbus
  123,                              # NTP (UDP, mesma observação do CoAP)
  47808,                            # BACnet (UDP)
  9000,                             # Node-RED (Exemplo)
  4222,                             # NATS
  61616,                            # ActiveMQ
  19999,                            # Netdata (mantido do script, mas não do docker-compose atual)
  5678,                             # n8n UI/API
  11434,                            # Ollama API
  8086,                             # InfluxDB
  6333                              # Qdrant
  # 8080                            # OpenWebUI (removido para evitar duplicidade com APIs)
]

# --- Verificação de Plugins Vagrant Obrigatórios ---
REQUIRED_PLUGINS = {
  'vagrant-disksize' => 'Configure VM disk size',
  'vagrant-vbguest'  => 'Keep VirtualBox Guest Additions up to date',
  'vagrant-reload'   => 'Reload VM during provisioning if needed',
  'vagrant-scp'      => 'SCP file transfers to/from VM',
  'vagrant-env'      => 'Load environment variables from .env files'
}

puts "#{USE_EMOJIS ? '🔌' : '[INFO]'} Verificando plugins Vagrant necessários..."
all_plugins_ok = true
REQUIRED_PLUGINS.each do |plugin, description|
  unless Vagrant.has_plugin?(plugin)
    all_plugins_ok = false
    puts "================================================================"
    puts "#{USE_EMOJIS ? '🚨' : '[ERROR]'} Plugin Vagrant OBRIGATÓRIO '#{plugin}' não está instalado!"
    puts "#{USE_EMOJIS ? '👉' : '->'} Propósito: #{description}"
    puts "#{USE_EMOJIS ? '👉' : '->'} Execute: vagrant plugin install #{plugin}"
    puts "================================================================"
  end
end

unless all_plugins_ok
  puts "#{USE_EMOJIS ? '🛑' : '[FATAL]'} Por favor, instale os plugins faltantes e tente novamente."
  exit # Aborta se plugins essenciais não estiverem presentes
end
puts "#{USE_EMOJIS ? '✅' : '[INFO]'} Todos os plugins obrigatórios estão instalados."

# --- Configuração Principal do Vagrant ---
Vagrant.configure("2") do |config|
  # 1. Configurações da Box
  config.vm.box = VM_BOX
  config.vm.box_version = VM_BOX_VERSION
  config.vm.hostname = VM_HOSTNAME

  # 2. Configuração do Provider (Exemplo para VirtualBox)
  config.vm.provider "virtualbox" do |vb|
    vb.name = VM_HOSTNAME # Nome da VM no VirtualBox UI
    vb.memory = VM_MEMORY
    vb.cpus = VM_CPUS

    # Habilitar aceleração 3D e aumentar VRAM para melhor desempenho gráfico
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]

    # Otimizações de rede (opcional, pode ajudar em alguns casos)
    # vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"] # Geralmente oferece melhor performance
  end

  # Configurar tamanho do disco com vagrant-disksize
  if Vagrant.has_plugin?("vagrant-disksize")
    config.disksize.size = VM_DISKSIZE
    puts "#{USE_EMOJIS ? '💾' : '[INFO]'} Tamanho do disco configurado para #{VM_DISKSIZE} via vagrant-disksize."
  else
    puts "#{USE_EMOJIS ? '⚠️' : '[WARN]'} Plugin 'vagrant-disksize' não encontrado. O tamanho do disco padrão da box será usado."
  end

  # Manter VirtualBox Guest Additions atualizados
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = true
    # config.vbguest.no_remote = true # Se você não quiser que ele baixe novas ISOs
    puts "#{USE_EMOJIS ? '🛠️' : '[INFO]'} vagrant-vbguest configurado para auto-update."
  end

  # 3. Configuração de Rede
  # Rede privada para acesso via IP fixo
  config.vm.network "private_network", ip: VM_IP_PRIVATE

  # Encaminhamento de Portas
  puts "#{USE_EMOJIS ? '🔗' : '[INFO]'} Configurando encaminhamento de portas..."
  FORWARDED_PORTS_LIST.each do |port|
    if [5683, 123, 47808].include?(port) # Exemplo para portas UDP conhecidas da sua lista
        config.vm.network "forwarded_port", guest: port, host: port, protocol: "udp", auto_correct: true
        puts "  #{USE_EMOJIS ? '➡️' : '->'} Host #{port} (UDP) => VM #{port} (UDP)"
    else
        config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true # Padrão é TCP
        puts "  #{USE_EMOJIS ? '➡️' : '->'} Host #{port} (TCP) => VM #{port} (TCP)"
    end
  end

  # 4. Pastas Sincronizadas
  # A sincronização padrão de "." para "/vagrant" está ativa por padrão.
  # Se você quiser desabilitá-la completamente (conforme discutido para o Samba VM-Interno), descomente a linha abaixo e ajuste conforme necessário:
    config.vm.synced_folder ".", "/vagrant"
  # Por enquanto, para o chmod funcionar, vamos assumir que está ativa.
  # Se for desabilitada, a linha de chmod abaixo precisará ser removida ou repensada.

  # 5. Provisionamento da VM
  puts "#{USE_EMOJIS ? '⚙️' : '[INFO]'} Iniciando provisionamento da VM..."
  # Garante que os scripts tenham permissão de execução
  config.vm.provision "shell",
    name: "Set Execute Permissions",
    inline: "chmod +x #{PROVISION_SCRIPTS_DIR_GUEST}/Resourcer/Scripts/*.sh", # CORRIGIDO para usar o caminho da VM
    run: "once"

  # Lista ordenada dos scripts de provisionamento
  provision_scripts_ordered = [
    { name: "Essentials",         path: "essentials.sh" },
    { name: "Time & Locale",      path: "time_locale.sh" },
    { name: "Node.js & Python",   path: "node_python.sh" },
    { name: "Docker & Watchdog",  path: "docker_watchdog.sh" },
    { name: "Monitoring Tools",   path: "monitoring_tools.sh" },
    { name: "Firewall & Security",path: "firewall_security.sh" },
    { name: "Samba Share",        path: "setup_samba_dev_share.sh", args: "SAMBA_PASSWORD=\"#{ENV['SAMBA_PASSWORD']}\"" } # Script para Samba
  ]

  provision_scripts_ordered.each do |script_info|
    # Para a opção 'path', Vagrant espera um caminho no HOST.
    # PROVISION_SCRIPTS_DIR_HOST_PATHNAME é um objeto Pathname do host.
    full_script_path_on_host = PROVISION_SCRIPTS_DIR_HOST_PATHNAME.join(script_info[:path]).to_s
    config.vm.provision script_info[:name],
      type: "shell",
      path: full_script_path_on_host,
      privileged: true, # A maioria dos seus scripts precisa de sudo
      run: "once"
    puts "  #{USE_EMOJIS ? '📜' : '[PROVISION]'} Agendado: #{script_info[:name]} (#{script_info[:path]})"
  end
  
  # Adiciona o health check
  provision_scripts_ordered << { name: "Health Check", path: "health_check.sh" }

  # Mensagem final após o provisionamento
  config.vm.provision "shell",
    name: "Provisioning Complete Message",
    inline: "echo '#{USE_EMOJIS ? '✅ 🎉' : '[SUCCESS]'} Provisionamento da VM DeusExMachina concluído! Use \"vagrant ssh\" para conectar.' && echo '#{USE_EMOJIS ? '💡' : '[TIP]'} IP Privado da VM: #{VM_IP_PRIVATE}'",
    run: "always" # Mostra esta mensagem sempre
end
