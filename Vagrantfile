# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'pathname'

# Load environment variables from .env file
def load_env(file)
  File.readlines(file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    key, value = line.split('=', 2)
    next unless key && value
    key = key.strip
    value = value.strip.gsub(/\A['"]+|['"]+\z/, '')
    ENV[key] = value
  end
end

# Load .env if present
env_file = Pathname.new(File.dirname(__FILE__)).join('.env')
load_env(env_file) if env_file.file?

# Default values
DEFAULT_MEMORY   = 2048
DEFAULT_CPUS     = 2
DEFAULT_DISKSIZE = '50GB'

# Required plugins
REQUIRED_PLUGINS = {
  'vagrant-disksize' => 'Configure VM disk size',
  'vagrant-vbguest'  => 'Keep VirtualBox Guest Additions up to date',
  'vagrant-reload'   => 'Reload VM during provisioning'
}

USE_EMOJIS = ENV.fetch('USE_EMOJIS', 'false').downcase == 'true'

REQUIRED_PLUGINS.each do |plugin, description|
  unless Vagrant.has_plugin?(plugin)
    puts "================================================================"
    puts "#{USE_EMOJIS ? '🚨' : '[ERROR]'} Plugin '#{plugin}' is not installed!"
    puts "#{USE_EMOJIS ? '👉' : '->'} Purpose: #{description}"
    puts "#{USE_EMOJIS ? '👉' : '->'} Run: vagrant plugin install #{plugin}"
    puts "================================================================"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "DeusExMachina"
  config.vm.network "private_network", ip: "192.168.33.10"

  # Forward common ports
  [
    80, 443, 3000, 5000, 8000, 8080,
    22,
    3306, 5432, 27017, 6379,
    1883, 8883, 5683, 502, 123,
    47808, 9000, 4222, 61616
  ].each do |port|
    config.vm.network "forwarded_port", guest: port, host: port, auto_correct: true
  end

  # Provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "DeusExMachina"
    vb.memory = ENV.fetch('VM_MEMORY', DEFAULT_MEMORY).to_i
    vb.cpus   = ENV.fetch('VM_CPUS', DEFAULT_CPUS).to_i

    # Set disk size if plugin is available
    if Vagrant.has_plugin?("vagrant-disksize")
      config.disksize.size = ENV.fetch('VM_DISKSIZE', DEFAULT_DISKSIZE)
    else
      puts "⚠️ 'vagrant-disksize' plugin not found. Disk size will not be set."
    end
  end

  # Provisioning scripts
  scripts_path = ".\\Resourcer\\Scripts"
  provision_scripts = %w[
    time_locale.sh
    essentials.sh
    node_python.sh
    iot_tools.sh
    docker_watchdog.sh
    firewall_security.sh
    monitoring_tools.sh
  ]

  provision_scripts.each do |script|
    script_path = File.join(scripts_path, script)
    config.vm.provision "shell", path: script_path, privileged: true
  end
end
