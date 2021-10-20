#!/usr/bin/env bash

APP_VERSION=$(curl -sL https://www.tp-link.com/uk/support/download/omada-software-controller/ \
    | grep -E -m 1 -io 'https?://[^ ]+.tar.gz' \
    | awk -F "/" '{print $NF}' \
    | awk -F '_' '{print $4}');
  
printf "%s" "${APP_VERSION}"