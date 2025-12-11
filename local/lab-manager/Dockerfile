# Dockerfile to build an image to run the lab manager in it to test the lab manager.
# Based on the source lab-manager Dockerfile
FROM constellab/lab-manager:latest

# Additional environment variables for local development
# don't name it PIP_VERSION because it will be overwritten by pip
ENV CUSTOM_PIP_VERSION=24.0
ENV DEBIAN_FRONTEND=noninteractive

# Switch to root to install additional packages
USER root

# Install python, pip, and additional development tools
RUN apt-get -y update && \
    apt-get -y install jq && \
    apt-get -y install python3.10 python3-distutils && \
    apt-get -y install git bzip2 wget rsync && \
    apt-get -y install pipenv && \
    rm -rf /var/lib/apt/lists/*

# Install pip 
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py "pip==${CUSTOM_PIP_VERSION}" && \
    python3 -m pip install --upgrade setuptools && \
    rm get-pip.py

# Configure python
RUN pip install ruff

# Install nest CLI for development
RUN npm i -g @nestjs/cli

# Switch back to labuser
USER labuser

# Override entrypoint and CMD to keep container running without starting the node process
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]