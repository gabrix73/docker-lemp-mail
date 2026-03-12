FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    postfix \
    postfix-pcre \
    libsasl2-modules \
    sasl2-bin \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Rimuove il servizio init di Postfix (gestito dal nostro entrypoint)
RUN rm -f /etc/init.d/postfix

EXPOSE 25 587 465

CMD ["/usr/sbin/postfix", "start-fg"]
