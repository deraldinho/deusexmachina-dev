#!/bin/bash
set -e

echo "Updating system and installing basic tools..."

sudo apt-get update -y
# The -y flag automatically answers 'yes' to prompts, making the upgrade non-interactive.
sudo apt-get upgrade -y
	git \
	curl \
	wget \
	unzip \
	build-essential \
	software-properties-common
sudo apt-get install -y git curl wget unzip build-essential software-properties-common

echo "Ferramentas básicas instaladas."
