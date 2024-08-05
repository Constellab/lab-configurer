#!/bin/bash

# Install nvidia drivers (access to command nvidia-smi), this takes a while
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# Configure nvidia runtime for docker
# install nvidia-container-toolkit, instruction from 
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/experimental/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# configure nvidia runtime for docker (this modifies /etc/docker/daemon.json)
sudo nvidia-ctk runtime configure --runtime=docker

# restart docker to apply changes
sudo systemctl restart docker
