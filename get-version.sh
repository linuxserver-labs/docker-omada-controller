#!/usr/bin/env bash

APP_VERSION=$(curl -sL https://www.tp-link.com/uk/support/download/omada-software-controller/ \
    | grep -E -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}');

if [[ -z "$APP_VERSION" ]]; then
    PREVIOUS_MAJOR_VER=$(curl -sL "https://www.tp-link.com/uk/support/download/omada-software-controller" | grep -E -io 'https://www.tp-link.com/uk/support/download/omada-software-controller/\S{2}' | awk -F '/' '{print $8}' | awk 'NR==2{print $1}')

    APP_VERSION=$(curl -sL "https://www.tp-link.com/uk/support/download/omada-software-controller/${PREVIOUS_MAJOR_VER}" \
    | grep -E -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}');
fi

printf "%s" "${APP_VERSION}"
