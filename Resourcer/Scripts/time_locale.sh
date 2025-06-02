#!/bin/bash
set -e

echo "Configurando timezone e locale..."

sudo timedatectl set-timezone America/Sao_Paulo
sudo locale-gen pt_BR.UTF-8

echo "Timezone e locale configurados."