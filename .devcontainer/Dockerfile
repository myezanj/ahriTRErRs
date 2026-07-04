# syntax=docker/dockerfile:1.7
FROM rocker/r-ver:4.4.2

ARG AHRI_TRE_RELEASE_TAG=v0.8.3

ENV AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime
ENV PATH="${AHRI_TRE_RUNTIME_ROOT}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${AHRI_TRE_RUNTIME_ROOT}/lib:${LD_LIBRARY_PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        postgresql-client \
        sudo \
    && rm -rf /var/lib/apt/lists/*

COPY .devcontainer/install-ahri-tre-runtime.sh /usr/local/bin/install-ahri-tre-runtime
RUN --mount=type=secret,id=github_token,required=false \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    AHRI_TRE_RELEASE_TAG="${AHRI_TRE_RELEASE_TAG}" \
    bash /usr/local/bin/install-ahri-tre-runtime

RUN printf '%s\n' \
        'export AHRI_TRE_RUNTIME_ROOT=/opt/ahri-tre-runtime' \
        'export PATH="/opt/ahri-tre-runtime/bin:${PATH}"' \
        'export LD_LIBRARY_PATH="/opt/ahri-tre-runtime/lib:${LD_LIBRARY_PATH:-}"' \
        > /etc/profile.d/ahri-tre-runtime.sh

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
