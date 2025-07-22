$args = $args

# Define o comando padrão
$action = "up"
$provision = ""

if ($args -contains "provision") {
    $provision = "--provision"
}

# Verifica estado atual da VM
$vmStatus = (& vagrant status --machine-readable) -join "\n"

if ($vmStatus -match "state,running") {
    Write-Host "A VM já está em execução. Utilizando 'reload'."
    $action = "reload"
} else {
    Write-Host "A VM não está em execução. Utilizando 'up'."
    $action = "up"
}

# O Vagrantfile agora gerencia a instalação de plugins.
Write-Host "✅ Verificando e instalando plugins do Vagrant (se necessário) via Vagrantfile..."
Write-Host "Executando: vagrant $action $provision"
vagrant $action $provision
