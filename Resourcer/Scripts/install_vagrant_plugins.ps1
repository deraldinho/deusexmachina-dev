# Lista de plugins necessários
$plugins = @(
    "vagrant-vbguest",
    "vagrant-disksize",
    "vagrant-scp",
    "vagrant-reload"
)

Write-Host "Verificando plugins do Vagrant..."

foreach ($plugin in $plugins) {
    $installed = vagrant plugin list | Select-String -Pattern "^$plugin "
    if (-not $installed) {
        Write-Host "Instalando plugin: $plugin"
        vagrant plugin install $plugin
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Falha ao instalar o plugin: $plugin"
            exit 1
        }
    } else {
        Write-Host "Plugin já instalado: $plugin"
    }
}

Write-Host "Todos os plugins verificados/instalados com sucesso!"
exit 0
""