# syntax=docker/dockerfile:1.7
FROM rocker/r-ver:4.4.2

ARG AHRI_TRE_RELEASE_TAG=v0.8.3
ARG AHRI_TRE_RELEASE_REPOSITORY=AHRIORG/ahri-tre-rs
ARG AHRI_TRE_ALLOW_LATEST_FALLBACK=1
ARG AHRI_TRE_RUNTIME_OPTIONAL=1
ARG AHRI_TRE_RUNTIME_LOCAL_ARCHIVE=
ARG AHRI_TRE_RUNTIME_LOCAL_CHECKSUM=

ENV AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime
ENV PATH="${AHRI_TRE_RUNTIME_ROOT}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${AHRI_TRE_RUNTIME_ROOT}/lib:${LD_LIBRARY_PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cifs-utils \
        curl \
        git \
        jq \
        keyutils \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        postgresql-client \
        sudo \
    && rm -rf /var/lib/apt/lists/*

COPY .devcontainer/install_ahri_tre_runtime.sh /usr/local/bin/install_ahri_tre_runtime
COPY .devcontainer/devcontainer_startup.sh /usr/local/bin/devcontainer_startup.sh
COPY .devcontainer/runtime/ /tmp/ahri-tre-runtime-cache/
RUN chmod +x /usr/local/bin/devcontainer_startup.sh
RUN --mount=type=secret,id=github_token,required=false \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    AHRI_TRE_RELEASE_TAG="${AHRI_TRE_RELEASE_TAG}" \
    AHRI_TRE_RELEASE_REPOSITORY="${AHRI_TRE_RELEASE_REPOSITORY}" \
    AHRI_TRE_ALLOW_LATEST_FALLBACK="${AHRI_TRE_ALLOW_LATEST_FALLBACK}" \
    AHRI_TRE_RUNTIME_OPTIONAL="${AHRI_TRE_RUNTIME_OPTIONAL}" \
    AHRI_TRE_RUNTIME_LOCAL_ARCHIVE="${AHRI_TRE_RUNTIME_LOCAL_ARCHIVE}" \
    AHRI_TRE_RUNTIME_LOCAL_CHECKSUM="${AHRI_TRE_RUNTIME_LOCAL_CHECKSUM}" \
    AHRI_TRE_RUNTIME_CACHE_DIR="/tmp/ahri-tre-runtime-cache" \
    bash /usr/local/bin/install_ahri_tre_runtime

RUN printf '%s\n' \
        'export AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime' \
        'export PATH="/opt/ahri-tre-runtime/bin:${PATH}"' \
        'export LD_LIBRARY_PATH="/opt/ahri-tre-runtime/lib:${LD_LIBRARY_PATH:-}"' \
        > /etc/profile.d/ahri-tre-runtime.sh

COPY DESCRIPTION /tmp/ahri-tre-r/DESCRIPTION
RUN bash -lc 'for i in 1 2 3; do install2.r --error remotes && exit 0; echo "retrying remotes install ($i/3)"; sleep 5; done; exit 1'
RUN R -q -e "remotes::install_deps('/tmp/ahri-tre-r', dependencies = TRUE, upgrade = 'never')"

RUN useradd -m -s /bin/bash vscode \
    && mkdir -p /home/vscode/.vscode-server \
    && chown -R vscode:vscode /home/vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /workspaces/ahri-tre-r
