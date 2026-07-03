FROM rocker/r-ver:4.4.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        postgresql-client \
        sudo \
    && rm -rf /var/lib/apt/lists/*

RUN install2.r --error \
        arrow \
        devtools \
        jsonlite \
        testthat \
        tibble

RUN useradd -m -s /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /workspaces/ahri-tre-r
