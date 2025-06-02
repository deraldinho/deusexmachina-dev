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

# Instala plugins necessários
Write-Host "?? Instalando plugins do Vagrant..."
.\Resourcer\Scripts\install_vagrant_plugins.ps1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Plugins instalados com sucesso. Executando: vagrant $action $provision"
    vagrant $action $provision
} else {
    Write-Host "Falha na instalação de plugins, abortando Vagrant $action."
}
