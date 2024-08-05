#!/bin/bash

sudo apt-get -y update
sudo apt-get -y install curl 

# Install docker and docker-compose
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
sudo apt-get -y install docker-compose

sudo usermod -aG docker $USER

# Configure the docker daemon if file does not exist
if [ ! -f /etc/docker/daemon.json ]; then
    sudo cp ./docker/daemon.json /etc/docker/daemon.json
fi

# Detect GPU and install
if [[ "`lspci | grep -i nvidia`" != "" ]]; then
    bash ./gpu/install_nvidia.sh
fi

