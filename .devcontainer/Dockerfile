# Flutter stable SDK for web development in GitHub Codespaces / Dev Containers.
FROM ghcr.io/cirruslabs/flutter:stable

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/flutter/bin:${PATH}"

RUN flutter config --no-analytics --enable-web \
    && flutter precache --web
