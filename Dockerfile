#Dockerfile for a Postfix email relay service
FROM alpine:3.15

ARG POSTFIX_VERSION

RUN apk update && apk add \
    bash \
    gawk \
    mailx \
    curl \
    ca-certificates \
    cyrus-sasl \
    cyrus-sasl-crammd5 \
    cyrus-sasl-digestmd5 \
    cyrus-sasl-login \
    rsyslog \
    supervisor \
    postfix=${POSTFIX_VERSION} && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /var/log/supervisor/ /var/run/supervisor/ && \
    sed -i -e 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf

COPY /conf/etc/* /etc/
COPY .env /
COPY configure.sh /

# RUN mkdir /etc/aliases
RUN mkdir /etc/aliases
RUN chmod +x /configure.sh
RUN ./configure.sh
RUN newaliases

EXPOSE 25/tcp
VOLUME [ "/var/spool/postfix"]
WORKDIR /etc/postfix

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD printf "EHLO healthcheck\n" | nc 127.0.0.1 25 | grep -qE "^220.*ESMTP Postfix" || exit 1

CMD ["/usr/bin/supervisord", "--configuration", "/etc/supervisord.conf"]