#!/bin/bash

# Set the version of the lab manager using env variable
# if $1 is empty
if [[ -z "$1" ]]; then
  # Ask for the value if not already provided. 
  if [[ -z "${LAB_MANAGER_VERSION}" ]]; then
    # Create env variable in /etc/environment file
    read -p "LAB_MANAGER_VERSION :" LAB_MANAGER_VERSION
    sudo sh -c "echo LAB_MANAGER_VERSION=$LAB_MANAGER_VERSION >> /etc/environment"
  fi
else

  # delete line if already exists
  sudo sed -i "/LAB_MANAGER_VERSION/d" /etc/environment
  sudo sh -c "echo 'LAB_MANAGER_VERSION=$1' >> /etc/environment"

  # set it in current session
  export LAB_MANAGER_VERSION=$1
fi


# Script to update the lab manager container
docker-compose pull lab_manager

docker-compose down

docker-compose up -d