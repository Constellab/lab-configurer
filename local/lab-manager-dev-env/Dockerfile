# Dockerfile to build an image to run the lab manager in it to test the lab manager.
# Based on the source lab-manager Dockerfile
FROM constellab/lab-manager:latest

# Additional environment variables for local development
# don't name it PIP_VERSION because it will be overwritten by pip
ENV CUSTOM_PIP_VERSION=24.0
ENV DEBIAN_FRONTEND=noninteractive

# All Python work happens inside a labuser-owned venv at /home/labuser/.venv.
# Putting its bin dir first on PATH and exporting VIRTUAL_ENV auto-activates
# the venv for every shell (interactive or not) — `python3`, `pip`, and any
# bare `uv pip install` invocation resolve to and install into this venv.
ENV VIRTUAL_ENV=/home/labuser/.venv
ENV PATH="/home/labuser/.venv/bin:${PATH}"

# Switch to root to install additional packages
USER root

# Install python and additional development tools
RUN apt-get -y update && \
    apt-get -y install jq && \
    apt-get -y install python3.10 python3-distutils && \
    apt-get -y install git bzip2 wget rsync && \
    apt-get -y install pipenv && \
    rm -rf /var/lib/apt/lists/*

# Install pip system-wide so bootstrap tooling still has it available
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py "pip==${CUSTOM_PIP_VERSION}" && \
    python3 -m pip install --upgrade setuptools && \
    rm get-pip.py

# Install uv (fast Python package installer) system-wide so it's on PATH
# for both root and labuser. Pinned version from https://github.com/astral-sh/uv/releases
ENV UV_VERSION=0.5.11
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | \
    env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh && \
    uv --version

# Install nest CLI for development (needs root for global npm install)
RUN npm i -g @nestjs/cli

# Switch back to labuser before creating the venv so it's owned by labuser
USER labuser

# Create the labuser-owned venv that VIRTUAL_ENV/PATH point at.
# --system-site-packages lets code in the venv still import system-installed
# packages when needed. `uv venv` is used instead of `python3 -m venv` because
# the base image may not include python3-venv (the stdlib ensurepip module).
RUN uv venv --system-site-packages --python python3 "${VIRTUAL_ENV}"

# Install ruff into the venv. uv auto-detects VIRTUAL_ENV.
RUN uv pip install --no-cache ruff

# Override entrypoint and CMD to keep container running without starting the node process
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]