FROM debian:jessie
ARG RUNNER_VERSION="2.279.0"
ARG GIT_VERSION="2.29.0"
ARG DUMB_INIT_VERSION="1.2.2"
ARG DOCKER_KEY="7EA0A9C3F273FCD8"

ENV GITHUB_PERSONAL_TOKEN ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""

ENV DOCKER_COMPOSE_VERSION="1.27.4"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8 
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Docker in docker

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    awscli \
    curl \
    tar \
    unzip \
    apt-transport-https \
    ca-certificates \
    sudo \
    gpg-agent \
    gnupg \
    software-properties-common \
    build-essential \
    zlib1g-dev \
    zstd \
    gettext \
    liblttng-ust0 \
    libcurl4-openssl-dev \
    inetutils-ping \
    jq \
    wget \
    dirmngr \
    openssh-client \
    locales \
    python3-pip \
    jq \
    dumb-init \
  && pip3 install --no-cache-dir awscliv2 \
  && locale-gen en_US.UTF-8 \
  && dpkg-reconfigure locales \
  && c_rehash \
  && cd /tmp \
  && curl -sL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz -o git.tgz \
  && tar zxf git.tgz \
  && cd git-${GIT_VERSION} \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && cd / \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ${DOCKER_KEY} \
  && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}')/gpg | apt-key add - \
  && ( add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$(lsb_release -is | awk '{print tolower($0)}') $(lsb_release -cs) stable" ) \
  && apt-get update \
  && apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends --allow-unauthenticated \
  && [[ $(lscpu -J | jq -r '.lscpu[] | select(.field == "Vendor ID:") | .data') == "ARM" ]] && echo "Not installing docker-compose. See https://github.com/docker/compose/issues/6831" || ( curl -sL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose ) \
  && chmod +x /usr/local/bin/docker-compose \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

# Docker runner

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        tar \
        gnupg2 \
        apt-transport-https \
        ca-certificates  \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
RUN useradd -m github && \
    usermod -aG sudo github && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER github
WORKDIR /home/github

RUN curl -O -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
RUN tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
RUN sudo ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]