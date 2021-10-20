FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG APP_VERSION="$(echo ${VERSION} | awk -F'-ls' '{print $1}')"
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    bash \
    curl \
    jsvc \
    libcap2 \
    logrotate \
    mongodb-server \
    openjdk-8-jre-headless && \
  echo "**** install omada ****" && \
  # Somehow figure out version detection and download URL here
  if [ -z ${APP_VERSION+x} ]; then \
    APP_VERSION=$(curl -sL https://www.tp-link.com/uk/support/download/omada-software-controller/ \
    | egrep -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}'); \
  fi && \
  mkdir -p /tmp/omada && \
  OMADA_DOWNLOAD=$(curl -sL https://www.tp-link.com/uk/support/download/omada-software-controller/ \
    | egrep -io "https?://[^ ]+${APP_VERSION}_linux_x64.tar.gz") && \
  # Download Omada package, try and handle their appalling packaging "standards"
  curl -o \
    /tmp/omada.tar.gz -L \
    ${OMADA_DOWNLOAD} && \
  if [ $(tar -tf /tmp/omada.tar.gz | awk -F "\n" '{print $1;exit}' | grep -i "omada") ]; then \
    tar xf \
      /tmp/omada.tar.gz -C \
      /tmp/omada/ --strip-components=1; \
  else \
    tar xf \
      /tmp/omada.tar.gz -C \
      /tmp/omada/; \
  fi && \
  mkdir -p /app/omada && \
  cd /tmp/omada && \
  for name in bin data properties webapps keystore lib install.sh uninstall.sh; do cp ${name} /app/omada -r; done && \
  ln -sf $(which mongod) /app/omada/bin/mongod && \
  chmod 755 /app/omada/bin/* && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /app/omada/bin/control.sh

ENV OMADA_USER="abc"

# add local files
COPY root/ /

# Volumes and Ports
VOLUME /config
EXPOSE 8088 8043 29810 29811 29812 29813
