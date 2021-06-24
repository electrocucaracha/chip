FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y -qq --no-install-recommends \
  libavahi-common3=0.7-4ubuntu7 \
  libavahi-client3=0.7-4ubuntu7 \
  libssl1.1=1.1.1f-1ubuntu2.4 \
  libglib2.0-data=2.64.6-1~ubuntu20.04.3 \
  shared-mime-info=1.15-1 \
  xdg-user-dirs=0.17-2ubuntu1 \
  krb5-locales=1.17-6ubuntu4.1 \
  libmono-i18n-west4.0-cil=6.8.0.105+dfsg-2 \
  ca-certificates-mono=6.8.0.105+dfsg-2 \
  libmono-btls-interface4.0-cil=6.8.0.105+dfsg-2 \
  binfmt-support=2.2.0-2 \
  netbase=6.1 \
  libgio2.0-cil-dev=2.22.3-3 && \
  rm -rf /var/lib/apt/lists/*

COPY . /opt/connectedhomeip/bin
WORKDIR /opt/connectedhomeip/bin
