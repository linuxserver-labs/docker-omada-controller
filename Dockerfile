FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG APP_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    bash \
    curl \
    gnupg \
    jsvc \
    libcap2 \
    logrotate \
    openjdk-8-jre-headless && \
  echo "**** install mongodb ****" && \
  curl -s https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add - && \
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
  apt-get update && \
  apt-get install -y \
    mongodb-org-server && \
  echo "**** download omada ****" && \
  # Somehow figure out version detection and download URL here
  if [ -z ${APP_VERSION+x} ]; then \
    echo "**** No APP_VERSION supplied, detecting ****" && \
    APP_VERSION=$(curl -sL https://www.tp-link.com/uk/support/download/omada-software-controller/ \
    | grep -E -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}'); \
  fi && \
  if [ -z ${APP_VERSION} ]; then \
    echo "**** No current version found, trying previous major versions ****" && \
    PREVIOUS_MAJOR_VER=$(curl -sL "https://www.tp-link.com/uk/support/download/omada-software-controller" | grep -E -io 'https://www.tp-link.com/uk/support/download/omada-software-controller/\S{2}' | awk -F '/' '{print $8}' | awk 'NR==2{print $1}') && \
    echo "**** Previous major version was $PREVIOUS_MAJOR_VER ****" && \
    APP_VERSION=$(curl -sL "https://www.tp-link.com/uk/support/download/omada-software-controller/${PREVIOUS_MAJOR_VER}" \
    | grep -E -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}'); \
  fi && \ 
  echo "**** App version is ${APP_VERSION} ****" && \  
  mkdir -p /tmp/omada && \
  OMADA_DOWNLOAD=$(curl -sL "https://www.tp-link.com/uk/support/download/omada-software-controller/$(echo $APP_VERSION | cut -c 1-2)" \
    | grep -E -io "https?://[^ ]+${APP_VERSION}_linux_x64.tar.gz") && \
  # Download Omada package, try and handle their appalling packaging "standards"
  curl -o \
    /tmp/omada.tar.gz -L \
    ${OMADA_DOWNLOAD} && \
  echo "**** unpack omada ****" && \
  if [ $(tar -tf /tmp/omada.tar.gz | awk -F "\n" '{print $1;exit}' | grep -i "omada") ]; then \
    tar xf \
      /tmp/omada.tar.gz -C \
      /tmp/omada/ --strip-components=1; \
  else \
    tar xf \
      /tmp/omada.tar.gz -C \
      /tmp/omada/; \
  fi && \
  echo "**** install omada ****" && \  
  mkdir -p /app/omada && \
  cd /tmp/omada && \
  for name in bin data properties keystore lib install.sh uninstall.sh; do cp ${name} /app/omada -r; done && \
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
