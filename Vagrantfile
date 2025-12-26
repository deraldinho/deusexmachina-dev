# -*- mode: ruby -*-
# vi: set ft=ruby :

# ==============================================================================
#  Vagrantfile - DeusExMachina AI Project
#  Ambiente: CentOS Stream | Provider: VirtualBox
# ==============================================================================

require 'fileutils'

# --- 1. Verificação e Instalação Automática de Plugins ---
# Garante que os plugins necessários estejam instalados antes de prosseguir.
required_plugins = %w(vagrant-disksize vagrant-vbguest vagrant-reload)
plugins_to_install = required_plugins.select { |plugin| !Vagrant.has_plugin?(plugin) }

if !plugins_to_install.empty?
  puts "🔧 Instalando plugins obrigatórios do Vagrant: #{plugins_to_install.join(', ')}..."
  if system("vagrant plugin install #{plugins_to_install.join(' ')}")
    puts "✅ Plugins instalados. Reiniciando o Vagrant para aplicar as mudanças..."
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "❌ Erro ao instalar plugins. Verifique sua conexão ou instale manualmente."
  end
end

# --- 2. Carregamento de Variáveis de Ambiente (.env) ---
# Permite configurar a VM sem alterar o Vagrantfile.
if File.exist?('.env')
  File.foreach('.env') do |line|
    next if line.strip.start_with?('#') || line.strip.empty?
    key, value = line.strip.split('=', 2)
    ENV[key] = value.gsub(/["']/, '').strip if key && value
  end
end

# --- 3. Configurações Globais ---
# Nota: O commit menciona CentOS Stream 10, mas boxes públicas estáveis
# geralmente vão até o Stream 9. Usando Stream 9 como base segura.
VM_BOX_NAME     = "bento/centos-stream-9"
VM_NAME         = "DeusExMachina_VM"
VM_HOSTNAME     = "deusex-machina"
VM_IP           = ENV['VM_IP'] || "192.168.56.10"
VM_MEMORY       = ENV['VM_MEMORY'] || "4096"
VM_CPUS         = ENV['VM_CPUS'] || "2"
DEV_DOMAIN      = ENV['VM_DEV_DOMAIN'] || "deusex.io"
SAMBA_PASSWORD  = ENV['SAMBA_PASSWORD'] || ""
SSH_PORT        = ENV['SSH_PORT'] || "22"

Vagrant.configure("2") do |config|

  # --- Configuração da Box ---
  config.vm.box = VM_BOX_NAME
  config.vm.hostname = VM_HOSTNAME

  # --- Configuração de Rede ---
  # Rede privada para comunicação com o Host e serviços (Samba, Nginx, DNS)
  config.vm.network "private_network", ip: VM_IP

  # --- Configuração de Pastas Compartilhadas ---
  # Mapeia a raiz do projeto para /vagrant para acesso aos scripts de provisionamento
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # --- Configuração do Provider (VirtualBox) ---
  config.vm.provider "virtualbox" do |vb|
    vb.name = VM_NAME
    vb.memory = VM_MEMORY
    vb.cpus = VM_CPUS
    vb.gui = false
    
    # Otimizações de performance e relógio
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--rtcuseutc", "on"]
    
    # Habilita virtualização aninhada (útil para Docker dentro da VM)
    # vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  end

  # --- Plugins Específicos ---
  # Define o tamanho do disco (requer vagrant-disksize)
  config.disksize.size = '50GB' if Vagrant.has_plugin?("vagrant-disksize")

  # Configura atualização do Guest Additions (requer vagrant-vbguest)
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false  # Desabilitado para evitar problemas de compilação
    config.vbguest.no_remote = true
  end

  # --- Provisionamento (Scripts Shell) ---
  # A ordem de execução é crítica para as dependências.

  # 0. Importação de Certificados (Prioritário para redes corporativas)
  config.vm.provision "shell", path: "Resourcer/Scripts/import_certificates.sh"

  # 1. Essenciais do Sistema (Git, Curl, DNF update)
  config.vm.provision "shell", path: "Resourcer/Scripts/essentials.sh"

  # 2. Configuração Regional (Timezone e Locale pt_BR)
  config.vm.provision "shell", path: "Resourcer/Scripts/time_locale.sh"

  # 3. DNS Local (Dnsmasq para domínios .test/.io)
  config.vm.provision "shell", path: "Resourcer/Scripts/setup_dnsmasq.sh", args: ["DEV_DOMAIN=#{DEV_DOMAIN}"]

  # 4. Runtimes (Node.js e Python)
  config.vm.provision "shell", path: "Resourcer/Scripts/node_python.sh"

  # 5. Docker Engine e Watchdog
  config.vm.provision "shell", path: "Resourcer/Scripts/docker_watchdog.sh"

  # 6. Monitoramento (Netdata, Glances, Htop)
  config.vm.provision "shell", path: "Resourcer/Scripts/monitoring_tools.sh"

  # 7. Segurança (Firewalld e Fail2Ban)
  config.vm.provision "shell", path: "Resourcer/Scripts/firewall_security.sh", env: { "SSH_PORT" => SSH_PORT }

  # 8. Compartilhamento Samba (Workspace Interno Isolado)
  config.vm.provision "shell", path: "Resourcer/Scripts/setup_samba_dev_share.sh", args: ["SAMBA_PASSWORD=#{SAMBA_PASSWORD}"]

  # 9. Proxy Reverso (Nginx)
  config.vm.provision "shell", path: "Resourcer/Scripts/setup_proxy.sh", args: ["DEV_DOMAIN=#{DEV_DOMAIN}"]

  # 10. Health Check (Executa sempre)
  config.vm.provision "shell", path: "Resourcer/Scripts/health_check.sh", run: "always"

  # 11. Reload (Se necessário após atualizações de kernel/plugins)
  config.vm.provision :reload if Vagrant.has_plugin?("vagrant-reload")
end