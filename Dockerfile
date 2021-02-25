##########################
## INSTALLING GOSU PER INSTRUCTIONS FROM https://github.com/tianon/gosu/blob/master/INSTALL.md

FROM alpine:3.7 AS build

ENV GOSU_VERSION 1.12
ENV LITECOIN_VERSION 0.18.1

## install packages, setting up gpg keys, etc etc
RUN set -eux; \
	apk add --no-cache --virtual .gosu-deps ca-certificates dpkg gnupg bash \
        && for key in \
            B42F6819007F00F88E364FD4036A9C25BF357DD4 \
            FE3348877809386C \
        ; do \
            gpg --no-tty --keyserver pgp.mit.edu --recv-keys "$key" || \
            gpg --no-tty --keyserver keyserver.pgp.com --recv-keys "$key" || \
            gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
            gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
        done

## installing and configuring gosu
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
    export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
    echo gosu --version; \
	gosu nobody true 

RUN wget -O /usr/local/bin/litecoin.tar.gz https://download.litecoin.org/litecoin-$LITECOIN_VERSION/linux/litecoin-$LITECOIN_VERSION-x86_64-linux-gnu.tar.gz; \
    wget -O /usr/local/bin/litecoin.asc https://download.litecoin.org/litecoin-$LITECOIN_VERSION/linux/litecoin-$LITECOIN_VERSION-linux-signatures.asc | gpg --verify litecoin.asc; \
    cd usr/local/bin \
    && tar --strip-components=2 -xvf litecoin.tar.gz \
    && rm -rf litecoin.tar.gz litecoin-$LITECOIN_VERSION

## I tried to do this all from alpine, but I couldn't get it to work https://github.com/litecoin-project/litecoin/issues/407 :(
FROM bitnami/minideb:jessie

COPY --from=build /usr/local/bin/ /usr/local/bin/

EXPOSE 9332 9333 19332 19333 19444

CMD ["litecoind"]
