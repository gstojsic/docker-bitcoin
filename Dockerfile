FROM debian:bullseye-slim

COPY pubkeys/*.gpg /pubkeys/
COPY script/docker-entrypoint.sh /entrypoint.sh

LABEL org.opencontainers.image.source=https://github.com/gstojsic/docker-bitcoin
LABEL org.opencontainers.image.description="run bitcoin core in docker"
LABEL org.opencontainers.image.licenses=MIT

RUN useradd -r bitcoin \
  && apt-get update -y \
  && apt-get install -y curl gnupg gosu \
  && apt-get clean \
  && gpg --import /pubkeys/*.gpg \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /pubkeys/*

ARG TARGETPLATFORM=x86_64-linux-gnu
ARG BITCOIN_VERSION=24.0.1
ENV BITCOIN_DATA=/home/bitcoin/.bitcoin
ENV PATH=/opt/bitcoin-${BITCOIN_VERSION}/bin:$PATH

RUN set -ex \
  && for key in \
      0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 \
      590B7292695AFFA5B672CBB2E13FC145CD3F4304 \
      CFB16E21C950F67FA95E558F2EEB9F5CC09526C1 \
      F4FC70F07310028424EFC20A8E4256593F177720 \
      D1DBF2C4B96F2DEBF4C16654410108112E7EA81F \
      287AE4CA1187C68C08B49CB2D11BD4F33F1DB499 \
      9DEAE0DC7063249FB05474681E4AED62986CD25D \
      28E72909F1717FE9607754F8A7BEB2621678D37D \
      3EB0DEE6004A13BE5A0CC758BF2978B068054311 \
      ED9BDF7AD6A55E232E84524257FF9BDBCC301009 \
    ; do \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
        gpg --batch --keyserver keys.openpgp.org --recv-keys "$key" || \
        gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
        gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
      done \
  && curl -SLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${TARGETPLATFORM}.tar.gz \
  && curl -SLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS \
  && curl -SLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc \
  && gpg --verify SHA256SUMS.asc SHA256SUMS \
  && grep " bitcoin-${BITCOIN_VERSION}-${TARGETPLATFORM}.tar.gz" SHA256SUMS | sha256sum -c - \
  && tar -xzf *.tar.gz -C /opt \
  && rm *.tar.gz *.asc \
  && rm -rf /opt/bitcoin-${BITCOIN_VERSION}/bin/bitcoin-qt

VOLUME ["/home/bitcoin/.bitcoin"]

EXPOSE 8332 8333 18332 18333 18443 18444 38333 38332

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bitcoind"]
