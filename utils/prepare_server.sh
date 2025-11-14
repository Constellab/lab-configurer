#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


sudo apt-get -y update
sudo apt-get -y install curl ca-certificates gnupg

# Install docker and docker-compose (latest version)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -y update

# Ensure docker group has GID 999 before Docker installation
sudo bash "${SCRIPT_DIR}/ensure_docker_gid.sh"

# Install latest Docker version
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sudo apt-get -y install docker-compose

sudo usermod -aG docker $USER

# Configure the docker daemon if file does not exist
if [ ! -f /etc/docker/daemon.json ]; then
    sudo cp "${SCRIPT_DIR}/docker/daemon.json" /etc/docker/daemon.json
fi

# Detect GPU and install
if [[ "`lspci | grep -i nvidia`" != "" ]]; then
    bash "${SCRIPT_DIR}/gpu/install_nvidia.sh"
fi

