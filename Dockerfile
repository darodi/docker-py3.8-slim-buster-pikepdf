FROM --platform=linux/arm/v7 python:3.8-slim-buster
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN echo "I'm building for $TARGETOS/$TARGETARCH/$TARGETVARIANT"

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=en_US:en

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## qpdf and pikepdf need to be built from source on armv7
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Packages only required during build
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(make) && \
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(libssl-dev) && \
    TEMP_PACKAGES+=(libfreetype6-dev) && \
    TEMP_PACKAGES+=(libfontconfig1-dev) && \
    TEMP_PACKAGES+=(libjpeg-dev) && \
    TEMP_PACKAGES+=(libqpdf-dev) && \
    TEMP_PACKAGES+=(libxft-dev) && \
    TEMP_PACKAGES+=(libxml2-dev) && \
    TEMP_PACKAGES+=(libxslt1-dev) && \
    TEMP_PACKAGES+=(zlib1g-dev) && \
    # Packages kept in the image
    KEPT_PACKAGES+=(bash) && \
    KEPT_PACKAGES+=(ca-certificates) && \
    KEPT_PACKAGES+=(locales) && \
    KEPT_PACKAGES+=(locales-all) && \
    KEPT_PACKAGES+=(python3) && \
    TEMP_PACKAGES+=(python3-dev) && \
    KEPT_PACKAGES+=(python3-pip) && \
    KEPT_PACKAGES+=(chrpath) && \
    KEPT_PACKAGES+=(libfreetype6) && \
    KEPT_PACKAGES+=(libfontconfig1) && \
    KEPT_PACKAGES+=(python3-wheel) && \
    # Install packages
    DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get -yq upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    git config --global advice.detachedHead false && \
    # Install required python modules
    python -m pip install --upgrade pip && \
    python -m pip install --no-cache-dir pybind11 && \
    ## qpdf and pikepdf need to be built from source on armv7
    cd /opt \
    && git clone --branch release-qpdf-10.6.3 https://github.com/qpdf/qpdf.git \
    && git clone --branch v5.1.1 https://github.com/pikepdf/pikepdf.git \
    && cd /opt/qpdf \
    && ./configure \
    && make \
    && make install \
    && cd /opt/pikepdf \
    && pip install . && \
    # Clean-up
    DEBIAN_FRONTEND=noninteractive apt-get remove -y ${TEMP_PACKAGES[@]} && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
    DEBIAN_FRONTEND=noninteractive apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /src /opt/qpdf /opt/pikepdf

COPY /IMAGE_VERSION /IMAGE_VERSION