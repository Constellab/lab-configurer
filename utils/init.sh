#!/bin/bash

# Create the required networks
if [[ "$(docker network ls | grep "gencovery-network-manager")" == "" ]] ; then
  docker network create -d bridge gencovery-network-manager
fi

if [[ "$(docker network ls | grep "gencovery-network-dev")" == "" ]] ; then
  docker network create -d bridge gencovery-network-dev
fi

if [[ "$(docker network ls | grep "gencovery-network-dev")" == "" ]] ; then
  docker network create -d bridge gencovery-network-prod
fi

# Initialize variables
VIRTUAL_HOST=""
ENVIRONMENT_PROFILE=""
LAB_MANAGER_API_KEY=""
LAB_MANAGER_VERSION=""
# Parse the arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --virtual-host=*)
      VIRTUAL_HOST="${1#*=}"
      shift
      ;;
    --environment-profile=*)
      ENVIRONMENT_PROFILE="${1#*=}"
      shift
      ;;
    --lab-manager-api-key=*)
      LAB_MANAGER_API_KEY="${1#*=}"
      shift
      ;;
    --lab-manager-version=*)
      LAB_MANAGER_VERSION="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done

# Check if all required parameters are set
if [[ -z "$VIRTUAL_HOST" ]] || [[ -z "$ENVIRONMENT_PROFILE" ]] || [[ -z "$LAB_MANAGER_API_KEY" ]] || [[ -z "$LAB_MANAGER_VERSION" ]]; then
  echo "Missing parameters"
  echo "Usage: ./init.sh --virtual-host=<VIRTUAL_HOST> --environment-profile=<ENVIRONMENT_PROFILE> --lab-manager-api-key=<LAB_MANAGER_API_KEY> --lab-manager-version=<LAB_MANAGER_VERSION>"
  echo "Example: ./init.sh --virtual-host=\"*.gencovery.io\" --environment-profile=\"prod\" --lab-manager-api-key=\"1234567890abcdefg\" --lab-manager-version=\"1.0.0\""
  exit 1
fi

# Set the environment variables
sudo sed -i "/VIRTUAL_HOST/d" /etc/environment
sudo sh -c "echo VIRTUAL_HOST=$VIRTUAL_HOST >> /etc/environment"
export VIRTUAL_HOST=$VIRTUAL_HOST

sudo sed -i "/ENVIRONMENT_PROFILE/d" /etc/environment
sudo sh -c "echo ENVIRONMENT_PROFILE=$ENVIRONMENT_PROFILE >> /etc/environment"
export ENVIRONMENT_PROFILE=$ENVIRONMENT_PROFILE

sudo sed -i "/LAB_MANAGER_API_KEY/d" /etc/environment
sudo sh -c "echo LAB_MANAGER_API_KEY=$LAB_MANAGER_API_KEY >> /etc/environment"
export LAB_MANAGER_API_KEY=$LAB_MANAGER_API_KEY

sudo sed -i "/LAB_MANAGER_VERSION/d" /etc/environment
sudo sh -c "echo LAB_MANAGER_VERSION=$LAB_MANAGER_VERSION >> /etc/environment"
export LAB_MANAGER_VERSION=$LAB_MANAGER_VERSION
