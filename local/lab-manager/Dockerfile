# Dockerfile to build an image to run the lab manager in it to test the lab manager. 
FROM ubuntu:22.04

# Set UTC timezone for the docker
ENV TZ=UTC
# use to prevent interaction during docker install
ENV DEBIAN_FRONTEND=noninteractive

ENV NODE_VERSION=20.12.2
# don't name it PIP_VERSION because it will be overwritten by pip
ENV CUSTOM_PIP_VERSION=24.0
ENV CUSTOM_RCLONE_VERSION=1.53.3-4ubuntu1.22.04.3
ENV DOCKER_COMPOSE_VERSION=2.26.1

# Install docker
RUN apt-get update && apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

RUN  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io

# Install node of a specific version globally
RUN apt-get update && apt install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# Install docker compose
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Install python and pip to be able to work on GPM
# install python & base packages
RUN apt-get -y update && \
    apt-get -y install jq && \
    apt-get -y install python3.10 python3-distutils && \
    apt-get -y install git curl zip unzip bzip2 wget rsync sudo && \
    apt-get -y install pipenv && \
    # # for lspci
    apt-get -y install pciutils 

# install pip 
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py "pip==${CUSTOM_PIP_VERSION}" && \
    python3 -m pip install --upgrade setuptools

# Install zip, unzip, rclone
RUN apt-get install zip -y && \
    apt install rclone=${CUSTOM_RCLONE_VERSION} -y && \
    apt install unzip -y

# Configure python
RUN pip install mypy pylint autopep8

# Install nest 
RUN npm i -g @nestjs/cli

# copy and run entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sed -i -e 's/\r$//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create non-root user matching host ubuntu user
ARG USER_ID=1000
ARG GROUP_ID=1000

# Create group and user, then change ownership of necessary directories
RUN groupadd -g ${GROUP_ID} labuser && \
    useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash labuser && \
    # add labuser to docker group
    usermod -aG docker labuser && \
    # give sudo permission to labuser
    echo "labuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER labuser

ENTRYPOINT [ "/entrypoint.sh" ]